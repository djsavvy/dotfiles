import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { convertToLlm, serializeConversation } from "@earendil-works/pi-coding-agent";

/**
 * Smart Compactor (OMP-style Lossless Tool-Pruned Epistemic Compaction)
 *
 * 1. Prunes giant tool outputs (bash, web fetch, large file dumps) into compact semantic pointers.
 * 2. Delegates summarization to GCP Vertex AI Gemini 3.7 Flash.
 * 3. Categorizes information into Permanent Invariants, Goals, Progress, and Transient States.
 */
export default function (pi: ExtensionAPI) {
  pi.on("session_before_compact", async (event, ctx) => {
    const { preparation, signal } = event;
    const { messagesToSummarize, turnPrefixMessages, tokensBefore, firstKeptEntryId, previousSummary } = preparation;

    // Use Gemini 3.7 Flash or 2.5 Flash on Vertex AI
    const geminiModel =
      ctx.modelRegistry.find("google-vertex", "gemini-3.7-flash") ??
      ctx.modelRegistry.find("google-vertex", "gemini-2.5-flash");

    if (!geminiModel) {
      ctx.ui.notify("Vertex Gemini model not available, falling back to default compactor", "warning");
      return;
    }

    const allMessages = [...messagesToSummarize, ...turnPrefixMessages];

    ctx.ui.notify(
      `Compacting ${allMessages.length} messages (${tokensBefore.toLocaleString()} tokens) with ${geminiModel.id}...`,
      "info"
    );

    // 1. Tool Output Pruning: Replace heavy tool results (> 2KB) with concise summaries
    const prunedMessages = allMessages.map((msg) => {
      const cloned = JSON.parse(JSON.stringify(msg));
      if (cloned.role === "toolResult" || cloned.role === "tool") {
        if (typeof cloned.content === "string" && cloned.content.length > 2000) {
          const preview = cloned.content.slice(0, 300);
          const lines = cloned.content.split("\n").length;
          cloned.content = `[Pruned Large Tool Output (${lines} lines, ${cloned.content.length} chars). Preview: ${preview}...]`;
        } else if (Array.isArray(cloned.content)) {
          for (const item of cloned.content) {
            if (item.type === "text" && item.text && item.text.length > 2000) {
              const preview = item.text.slice(0, 300);
              const lines = item.text.split("\n").length;
              item.text = `[Pruned Large Tool Output (${lines} lines, ${item.text.length} chars). Preview: ${preview}...]`;
            }
          }
        }
      }
      return cloned;
    });

    // 2. Serialize pruned conversation
    const conversationText = serializeConversation(convertToLlm(prunedMessages));
    const previousContext = previousSummary ? `\n\nPrevious session summary for context:\n${previousSummary}` : "";

    // 3. Structured Epistemic Compaction Prompt
    const compactionPrompt = `You are the Compaction Engine for Pi/OMP.
Create a structured, epistemic summary of this conversation.${previousContext}

Your summary MUST use the following markdown sections:

## Goal
Concise statement of the overarching objective(s).

## Constraints & Preferences
- Invariant policies (e.g. security rules, allowed providers, disallowed paths).
- User preferences and workflow constraints.

## Observed Transient Conditions
- Any temporary conditions observed during this session (e.g. network blocks, ephemeral test environments) with their conditions.

## Progress
### Done
- Specific completed items, tools executed, and verified results.
### In Progress
- Currently active items.
### Blocked
- Any active blockers or errors.

## Key Decisions
- Decisions made and their rationale.

## Critical Context & Artifacts
- Important file paths, IDs, configuration keys, or commands that will be needed in subsequent turns.

## Next Steps
- Exact recommended next actions.

<conversation>
${conversationText}
</conversation>`;

    try {
      const response = await ctx.modelRegistry.complete(
        geminiModel,
        {
          messages: [
            {
              role: "user",
              content: [{ type: "text", text: compactionPrompt }],
              timestamp: Date.now(),
            },
          ],
        },
        {
          maxTokens: 8192,
          signal,
          cacheRetention: "none",
        }
      );

      const summary = response.content
        .filter((c): c is { type: "text"; text: string } => c.type === "text")
        .map((c) => c.text)
        .join("\n");

      if (!summary.trim()) {
        if (!signal.aborted) ctx.ui.notify("Compaction summary was empty, using default", "warning");
        return;
      }

      return {
        compaction: {
          summary,
          firstKeptEntryId,
          tokensBefore,
          usage: response.usage,
        },
      };
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error);
      ctx.ui.notify(`Smart compaction failed: ${message}, using default`, "error");
      return;
    }
  });
}
