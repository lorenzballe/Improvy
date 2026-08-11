import { getAgent, type Agent } from "./agents";
import { getModel } from "./models";
import { anthropicProvider } from "./providers/anthropic";
import { openaiProvider } from "./providers/openai";
import type {
  ChatMessage,
  ChatProvider,
  ProviderId,
  StreamChunk,
} from "./types";

const PROVIDERS: Record<ProviderId, ChatProvider> = {
  anthropic: anthropicProvider,
  openai: openaiProvider,
};

export function getProvider(id: ProviderId): ChatProvider {
  return PROVIDERS[id];
}

/**
 * Punto d'ingresso unico: dato un agente e una conversazione, restituisce lo
 * stream di risposta. Chi chiama non sa (e non deve sapere) quale provider
 * c'è dietro.
 */
export async function* streamAgentReply(
  agentId: string,
  messages: ChatMessage[],
  signal?: AbortSignal,
): AsyncGenerator<StreamChunk> {
  const agent: Agent = getAgent(agentId);
  const model = getModel(agent.model);

  if (!model) {
    yield {
      type: "error",
      message: `Modello "${agent.model}" non presente nel catalogo.`,
    };
    return;
  }

  yield* getProvider(model.provider).streamChat({
    model: agent.model,
    system: agent.system,
    messages,
    maxTokens: agent.maxTokens,
    effort: agent.effort,
    showReasoning: agent.showReasoning,
    signal,
  });
}

export * from "./agents";
export * from "./models";
export * from "./types";
