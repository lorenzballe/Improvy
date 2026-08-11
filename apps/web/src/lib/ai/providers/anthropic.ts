import Anthropic from "@anthropic-ai/sdk";
import { getModel } from "../models";
import type { ChatProvider, StreamChatOptions, StreamChunk } from "../types";

/**
 * Provider Claude (Anthropic).
 *
 * Se un rifiuto di sicurezza è possibile, l'API può servire la risposta con un
 * modello di riserva nella stessa chiamata (`fallbacks: "default"`). È un beta:
 * se l'account non ce l'ha abilitato la richiesta verrebbe rifiutata, quindi al
 * primo 400 riproviamo una volta sola senza — vedi `runStream`.
 */

const FALLBACK_BETA = "server-side-fallback-2026-07-01";

let cached: Anthropic | null = null;

function client(): Anthropic {
  if (!cached) {
    cached = new Anthropic({ apiKey: process.env.ANTHROPIC_API_KEY });
  }
  return cached;
}

/** Il 400 che dice "questo beta non è disponibile per te". */
function isBetaRejection(error: unknown): boolean {
  if (!(error instanceof Anthropic.APIError) || error.status !== 400) {
    return false;
  }
  const message = String(error.message ?? "").toLowerCase();
  return message.includes("fallback") || message.includes("beta");
}

function buildParams(
  options: StreamChatOptions,
): Record<string, unknown> {
  const model = getModel(options.model);
  const params: Record<string, unknown> = {
    model: options.model,
    max_tokens: options.maxTokens,
    system: options.system,
    messages: options.messages.map((m) => ({
      role: m.role,
      content: m.content,
    })),
  };

  // `effort` non è accettato da tutti i modelli (Haiku 4.5 lo rifiuta).
  if (options.effort && model?.supportsEffort) {
    params.output_config = { effort: options.effort };
  }

  // Sui modelli che ragionano, il default non restituisce il testo del
  // ragionamento: senza `display: "summarized"` l'utente vedrebbe solo una
  // lunga pausa prima della risposta.
  if (model?.supportsReasoning && options.showReasoning) {
    params.thinking = { type: "adaptive", display: "summarized" };
  }

  return params;
}

async function* runStream(
  params: Record<string, unknown>,
  withFallback: boolean,
  signal?: AbortSignal,
): AsyncGenerator<StreamChunk> {
  const requestParams = withFallback
    ? { ...params, fallbacks: "default", betas: [FALLBACK_BETA] }
    : params;

  const api = withFallback ? client().beta.messages : client().messages;

  // I tipi dell'SDK non coprono ancora `fallbacks: "default"`; il campo viene
  // comunque inoltrato così com'è.
  const stream = (api as unknown as {
    stream: (p: unknown, o?: unknown) => AsyncIterable<Record<string, any>> & {
      finalMessage: () => Promise<Record<string, any>>;
    };
  }).stream(requestParams, signal ? { signal } : undefined);

  let model = String(params.model);
  let inputTokens = 0;
  let outputTokens = 0;

  for await (const event of stream) {
    switch (event.type) {
      case "message_start": {
        model = event.message?.model ?? model;
        inputTokens = event.message?.usage?.input_tokens ?? 0;
        break;
      }
      case "content_block_delta": {
        const delta = event.delta;
        if (delta?.type === "thinking_delta" && delta.thinking) {
          yield { type: "thinking", text: delta.thinking as string };
        } else if (delta?.type === "text_delta" && delta.text) {
          yield { type: "text", text: delta.text as string };
        }
        break;
      }
      case "message_delta": {
        outputTokens = event.usage?.output_tokens ?? outputTokens;
        break;
      }
    }
  }

  const final = await stream.finalMessage();

  // Un rifiuto arriva come risposta riuscita (HTTP 200) con stop_reason
  // "refusal": non è un errore tecnico e non va trattato come tale.
  if (final.stop_reason === "refusal") {
    yield {
      type: "refusal",
      message:
        "Il modello ha preferito non rispondere a questa richiesta. Prova a riformularla.",
    };
  }

  yield {
    type: "usage",
    model: final.model ?? model,
    inputTokens: final.usage?.input_tokens ?? inputTokens,
    outputTokens: final.usage?.output_tokens ?? outputTokens,
  };
}

export const anthropicProvider: ChatProvider = {
  id: "anthropic",

  isConfigured() {
    return Boolean(process.env.ANTHROPIC_API_KEY);
  },

  async *streamChat(options: StreamChatOptions): AsyncGenerator<StreamChunk> {
    if (!this.isConfigured()) {
      yield {
        type: "error",
        message:
          "ANTHROPIC_API_KEY non configurata. Aggiungila in .env.local e riavvia il server.",
      };
      return;
    }

    const params = buildParams(options);
    let emitted = false;

    try {
      for await (const chunk of runStream(params, true, options.signal)) {
        emitted = true;
        yield chunk;
      }
      return;
    } catch (error) {
      // Riproviamo senza il beta solo se non abbiamo ancora mandato nulla al
      // client: altrimenti duplicheremmo il testo già mostrato.
      if (!(emitted === false && isBetaRejection(error))) {
        yield { type: "error", message: describeError(error) };
        return;
      }
    }

    try {
      yield* runStream(params, false, options.signal);
    } catch (error) {
      yield { type: "error", message: describeError(error) };
    }
  },
};

function describeError(error: unknown): string {
  if (error instanceof Anthropic.RateLimitError) {
    return "Troppe richieste in poco tempo. Riprova tra qualche secondo.";
  }
  if (error instanceof Anthropic.AuthenticationError) {
    return "Chiave API Anthropic non valida. Controlla ANTHROPIC_API_KEY.";
  }
  if (error instanceof Anthropic.APIConnectionError) {
    return "Impossibile raggiungere l'API. Controlla la connessione.";
  }
  if (error instanceof Anthropic.APIError) {
    return `Errore API (${error.status}): ${error.message}`;
  }
  if (error instanceof Error && error.name === "AbortError") {
    return "Richiesta interrotta.";
  }
  return error instanceof Error ? error.message : "Errore sconosciuto.";
}
