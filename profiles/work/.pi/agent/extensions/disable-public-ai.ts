import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

/**
 * Keep this Pi install on approved enterprise/cloud routes only.
 *
 * Allowed:
 * - Azure OpenAI (`azure-openai-responses`)
 * - GCP Vertex AI (`google-vertex`)
 *
 * The machine may still have public provider API keys in the shell environment
 * for other tools, but Pi should not expose those providers in its model
 * registry or model picker.
 */
export default function (pi: ExtensionAPI) {
  const disabledProviders = [
    "anthropic",
    "ant-ling",
    "openai",
    "openai-codex",
    "google", // Google AI Studio / Gemini API, not Vertex AI
    "amazon-bedrock",
    "deepseek",
    "nvidia",
    "mistral",
    "groq",
    "cerebras",
    "cloudflare-ai-gateway",
    "cloudflare-workers-ai",
    "xai",
    "openrouter",
    "vercel-ai-gateway",
    "zai",
    "zai-coding-cn",
    "opencode",
    "opencode-go",
    "radius",
    "huggingface",
    "fireworks",
    "together",
    "baseten",
    "kimi-coding",
    "minimax",
    "minimax-cn",
    "qwen-token-plan",
    "qwen-token-plan-individual",
    "qwen-token-plan-cn",
    "xiaomi",
    "xiaomi-token-plan-cn",
    "xiaomi-token-plan-ams",
    "xiaomi-token-plan-sgp",
  ];

  for (const provider of disabledProviders) {
    pi.registerProvider(provider, {
      name: `${provider} (disabled - use Azure OpenAI or GCP Vertex AI)`,
      baseUrl: "http://127.0.0.1/disabled",
      apiKey: `$PI_DISABLED_${provider.toUpperCase().replace(/[^A-Z0-9]/g, "_")}_API_KEY`,
      api: "openai-completions",
      models: [],
    });
  }
}
