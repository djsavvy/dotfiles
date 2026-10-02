import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { Type } from "@sinclair/typebox";
import { DatabaseSync } from "node:sqlite";
import * as path from "node:path";
import * as os from "node:os";
import * as fs from "node:fs";

interface FactItem {
  content: string;
  veracity: "stated" | "observed" | "verified";
  durability: "permanent_policy" | "transient_condition" | "fact";
  condition?: string | null;
  importance?: number;
}

interface TripleItem {
  subject: string;
  predicate: string;
  object: string;
}

interface ExtractionResponse {
  facts?: FactItem[];
  triples?: TripleItem[];
  episodic_gist?: string | null;
}

function initDatabase(dbPath: string): DatabaseSync {
  const db = new DatabaseSync(dbPath);

  db.exec(`
    CREATE TABLE IF NOT EXISTS working_memory (
      id TEXT PRIMARY KEY,
      content TEXT NOT NULL,
      source TEXT,
      session_id TEXT,
      importance REAL DEFAULT 0.5,
      veracity TEXT DEFAULT 'stated',
      durability TEXT DEFAULT 'fact',
      condition TEXT,
      valid_until TEXT,
      superseded_by TEXT,
      created_at TEXT NOT NULL
    );

    CREATE TABLE IF NOT EXISTS episodic_memory (
      id TEXT PRIMARY KEY,
      content TEXT NOT NULL,
      source TEXT,
      session_id TEXT,
      importance REAL DEFAULT 0.7,
      created_at TEXT NOT NULL
    );

    CREATE TABLE IF NOT EXISTS memoria_kg (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      subject TEXT NOT NULL,
      predicate TEXT NOT NULL,
      object TEXT NOT NULL,
      confidence REAL DEFAULT 0.8,
      source TEXT,
      created_at TEXT NOT NULL
    );

    CREATE VIRTUAL TABLE IF NOT EXISTS fts_working USING fts5(
      id UNINDEXED,
      content,
      condition
    );

    CREATE VIRTUAL TABLE IF NOT EXISTS fts_episodes USING fts5(
      id UNINDEXED,
      content
    );
  `);

  return db;
}

export default function (pi: ExtensionAPI) {
  const dbDir = process.env.PI_CODING_AGENT_DIR || path.join(os.homedir(), ".pi", "agent");
  fs.mkdirSync(dbDir, { recursive: true });
  const dbPath = path.join(dbDir, "memory.db");
  const db = initDatabase(dbPath);

  let currentSessionId = "default";

  pi.on("session_start", async (event) => {
    currentSessionId = (event as { sessionId?: string }).sessionId ?? "default";
  });

  pi.on("session_shutdown", async () => {
    try {
      db.close();
    } catch {
      // ignore
    }
  });

  // 1. Proactive Recall: Query memory before agent starts and inject into system prompt
  pi.on("before_agent_start", async (event, ctx) => {
    const promptText = event.prompt;
    if (!promptText || promptText.length < 4) return;

    // Clean tokens for FTS
    const terms = promptText
      .replace(/[^\w\s]/g, " ")
      .split(/\s+/)
      .filter((w) => w.length > 3)
      .slice(0, 5);

    if (terms.length === 0) return;

    const ftsQuery = terms.join(" OR ");
    const matches: string[] = [];

    try {
      const workingRows = db
        .prepare(
          `SELECT content, veracity, durability, condition FROM working_memory
           WHERE id IN (SELECT id FROM fts_working WHERE fts_working MATCH ?)
           AND superseded_by IS NULL
           ORDER BY importance DESC LIMIT 5`
        )
        .all(ftsQuery) as Array<{ content: string; veracity: string; durability: string; condition?: string }>;

      for (const row of workingRows) {
        const tag = row.durability === "permanent_policy" ? "[POLICY]" : row.condition ? `[CONDITION: ${row.condition}]` : "[FACT]";
        matches.push(`- ${tag} ${row.content} (${row.veracity})`);
      }

      const kgRows = db
        .prepare(
          `SELECT subject, predicate, object FROM memoria_kg 
           WHERE subject LIKE ? OR object LIKE ? LIMIT 4`
        )
        .all(`%${terms[0]}%`, `%${terms[0]}%`) as Array<{ subject: string; predicate: string; object: string }>;

      for (const kg of kgRows) {
        matches.push(`- [GRAPH] (${kg.subject}) -[${kg.predicate}]-> (${kg.object})`);
      }
    } catch {
      // FTS syntax or match error; ignore gracefully
    }

    if (matches.length > 0) {
      const injectedContext = `\n\n### Recalled Long-Term Memory:\n${matches.join("\n")}\n`;
      return {
        systemPrompt: event.systemPrompt + injectedContext,
      };
    }
  });

  // 2. Background Extraction: Ingest facts, durability, and KG triples after agent run settles
  pi.on("agent_settled", async (_event, ctx) => {
    if (!ctx.isIdle()) return;

    const geminiModel =
      ctx.modelRegistry.find("google-vertex", "gemini-3.7-flash") ??
      ctx.modelRegistry.find("google-vertex", "gemini-2.5-flash");

    if (!geminiModel) return;

    const entries = ctx.sessionManager.getBranch();
    const lastEntries = entries.slice(-6);
    if (lastEntries.length < 2) return;

    const textPayload = lastEntries
      .map((e) => {
        const msg = (e as { message?: { role: string; content: unknown } }).message;
        if (!msg) return "";
        const c = typeof msg.content === "string" ? msg.content : JSON.stringify(msg.content);
        return `${msg.role}: ${c.slice(0, 1500)}`;
      })
      .filter(Boolean)
      .join("\n");

    if (!textPayload || textPayload.length < 30) return;

    const extractionPrompt = `You are Mnemopi's Epistemic Memory Engine.
Extract long-term facts, policies, and knowledge-graph triples from this recent interaction.

Classification Rules:
- "permanent_policy": Invariant rules, configurations, security preferences.
- "transient_condition": Facts tied to temporary states, current network, or current machine.
- "fact": General verified truths.

Return valid JSON with schema:
{
  "facts": [
    {
      "content": "string",
      "veracity": "stated" | "observed" | "verified",
      "durability": "permanent_policy" | "transient_condition" | "fact",
      "condition": "string or null",
      "importance": 0.1 to 1.0
    }
  ],
  "triples": [
    {
      "subject": "string",
      "predicate": "string",
      "object": "string"
    }
  ],
  "episodic_gist": "1-sentence summary of task or null"
}

Conversation:
${textPayload}`;

    try {
      const res = await ctx.modelRegistry.complete(
        geminiModel,
        {
          messages: [
            {
              role: "user",
              content: [{ type: "text", text: extractionPrompt }],
              timestamp: Date.now(),
            },
          ],
        },
        { maxTokens: 2048, cacheRetention: "none" }
      );

      const text = res.content
        .filter((c): c is { type: "text"; text: string } => c.type === "text")
        .map((c) => c.text)
        .join("\n");

      const parsed: ExtractionResponse = JSON.parse(
        text.replace(/^```(?:json)?\s*/i, "").replace(/\s*```$/i, "").trim()
      );

      const now = new Date().toISOString();

      if (parsed.facts && Array.isArray(parsed.facts)) {
        for (const f of parsed.facts) {
          const id = "wm_" + Math.random().toString(36).slice(2, 11);
          db.prepare(
            `INSERT INTO working_memory (id, content, source, session_id, importance, veracity, durability, condition, created_at)
             VALUES (?, ?, 'agent_settled', ?, ?, ?, ?, ?, ?)`
          ).run(
            id,
            f.content,
            currentSessionId,
            f.importance ?? 0.7,
            f.veracity ?? "stated",
            f.durability ?? "fact",
            f.condition ?? null,
            now
          );

          db.prepare(`INSERT INTO fts_working (id, content, condition) VALUES (?, ?, ?)`).run(
            id,
            f.content,
            f.condition ?? ""
          );
        }
      }

      if (parsed.triples && Array.isArray(parsed.triples)) {
        for (const t of parsed.triples) {
          db.prepare(
            `INSERT INTO memoria_kg (subject, predicate, object, source, created_at)
             VALUES (?, ?, ?, 'agent_settled', ?)`
          ).run(t.subject, t.predicate, t.object, now);
        }
      }

      if (parsed.episodic_gist) {
        const epId = "ep_" + Math.random().toString(36).slice(2, 11);
        db.prepare(
          `INSERT INTO episodic_memory (id, content, source, session_id, importance, created_at)
           VALUES (?, ?, 'gist', ?, 0.6, ?)`
        ).run(epId, parsed.episodic_gist, currentSessionId, now);

        db.prepare(`INSERT INTO fts_episodes (id, content) VALUES (?, ?)`).run(epId, parsed.episodic_gist);
      }
    } catch {
      // Non-blocking background extraction error
    }
  });

  // 3. Register Explicit LLM Recall Tool
  pi.registerTool({
    name: "recall",
    label: "Recall Memory",
    description: "Search long-term persistent memory and knowledge graph across sessions",
    parameters: Type.Object({
      query: Type.String({ description: "Keywords or topic to recall" }),
    }),
    async execute(_id, params) {
      const q = params.query.replace(/[^\w\s]/g, " ").trim();
      if (!q) {
        return { content: [{ type: "text", text: "No query provided." }] };
      }

      const rows = db
        .prepare(
          `SELECT content, veracity, durability, condition, created_at FROM working_memory
           WHERE id IN (SELECT id FROM fts_working WHERE fts_working MATCH ?)
           AND superseded_by IS NULL LIMIT 8`
        )
        .all(q) as Array<{ content: string; veracity: string; durability: string; condition?: string; created_at: string }>;

      const triples = db
        .prepare(`SELECT subject, predicate, object FROM memoria_kg WHERE subject LIKE ? OR object LIKE ? LIMIT 6`)
        .all(`%${q}%`, `%${q}%`) as Array<{ subject: string; predicate: string; object: string }>;

      if (rows.length === 0 && triples.length === 0) {
        return { content: [{ type: "text", text: `No memories found matching "${params.query}".` }] };
      }

      let res = `### Memory Matches for "${params.query}":\n\n`;
      for (const r of rows) {
        const cond = r.condition ? ` [condition: ${r.condition}]` : "";
        res += `- [${r.durability.toUpperCase()}] ${r.content} (${r.veracity})${cond}\n`;
      }
      if (triples.length > 0) {
        res += `\n### Graph Triples:\n`;
        for (const t of triples) {
          res += `- (${t.subject}) -> [${t.predicate}] -> (${t.object})\n`;
        }
      }

      return { content: [{ type: "text", text: res }] };
    },
  });

  // 4. Register Explicit LLM Remember Tool
  pi.registerTool({
    name: "remember",
    label: "Remember Memory",
    description: "Explicitly store a permanent rule, preference, or fact into long-term memory",
    parameters: Type.Object({
      content: Type.String({ description: "Fact or invariant to remember" }),
      durability: Type.Union([
        Type.Literal("permanent_policy"),
        Type.Literal("transient_condition"),
        Type.Literal("fact"),
      ]),
      condition: Type.Optional(Type.String({ description: "Optional condition if transient" })),
    }),
    async execute(_id, params) {
      const memId = "wm_" + Math.random().toString(36).slice(2, 11);
      const now = new Date().toISOString();

      db.prepare(
        `INSERT INTO working_memory (id, content, source, session_id, importance, veracity, durability, condition, created_at)
         VALUES (?, ?, 'manual_tool', ?, 0.9, 'verified', ?, ?, ?)`
      ).run(memId, params.content, currentSessionId, params.durability, params.condition ?? null, now);

      db.prepare(`INSERT INTO fts_working (id, content, condition) VALUES (?, ?, ?)`).run(
        memId,
        params.content,
        params.condition ?? ""
      );

      return { content: [{ type: "text", text: `Stored memory [${params.durability}]: "${params.content}"` }] };
    },
  });

  // 5. Register /memory Command
  pi.registerCommand("memory", {
    description: "Inspect persistent memory stats or query entries (/memory or /memory <query>)",
    handler: async (args, ctx) => {
      if (!args || args.trim() === "" || args.trim() === "stats") {
        const wmCount = (db.prepare("SELECT COUNT(*) AS c FROM working_memory").get() as { c: number }).c;
        const epCount = (db.prepare("SELECT COUNT(*) AS c FROM episodic_memory").get() as { c: number }).c;
        const kgCount = (db.prepare("SELECT COUNT(*) AS c FROM memoria_kg").get() as { c: number }).c;
        ctx.ui.notify(
          `Mnemopi DB: ${wmCount} working facts, ${epCount} episodic summaries, ${kgCount} KG triples (${dbPath})`,
          "info"
        );
        return;
      }

      const q = args.replace(/[^\w\s]/g, " ").trim();
      const rows = db
        .prepare(
          `SELECT content, durability, condition FROM working_memory 
           WHERE id IN (SELECT id FROM fts_working WHERE fts_working MATCH ?) LIMIT 5`
        )
        .all(q) as Array<{ content: string; durability: string; condition?: string }>;

      if (rows.length === 0) {
        ctx.ui.notify(`No memories matching "${args}"`, "warning");
      } else {
        const lines = rows.map((r) => `• [${r.durability}] ${r.content}${r.condition ? ` (${r.condition})` : ""}`);
        ctx.ui.notify(`Memory results:\n${lines.join("\n")}`, "info");
      }
    },
  });
}
