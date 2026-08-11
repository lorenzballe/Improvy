import type { ChatProvider, StreamChatOptions, StreamChunk } from "../types";

/**
 * Provider OpenAI — esiste per dimostrare che il layer è davvero neutro:
 * nessun agente in `agents.ts` lo usa di default.
 *
 * Per attivarlo: aggiungi il modello in `models.ts` con `provider: "openai"`,
 * poi un agente in `agents.ts` che lo referenzia. Serve OPENAI_API_KEY.
 *
 * Usa `fetch` invece dell'SDK ufficiale per non aggiungere una dipendenza a
 * un provider che potresti non usare mai.
 */

const ENDPOINT = "https://api.openai.com/v1/chat/completions";

export const openaiProvider: ChatProvider = {
  id: "openai",

  isConfigured() {
    return Boolean(process.env.OPENAI_API_KEY);
  },

  async *streamChat(options: StreamChatOptions): AsyncGenerator<StreamChunk> {
    if (!this.isConfigured()) {
      yield {
        type: "error",
        message: "OPENAI_API_KEY non configurata.",
      };
      return;
    }

    let response: Response;
    try {
      response = await fetch(ENDPOINT, {
        method: "POST",
        signal: options.signal,
        headers: {
          "Content-Type": "application/json",
          Authorization: `Bearer ${process.env.OPENAI_API_KEY}`,
        },
        body: JSON.stringify({
          model: options.model,
          max_completion_tokens: options.maxTokens,
          stream: true,
          stream_options: { include_usage: true },
          messages: [
            { role: "system", content: options.system },
            ...options.messages,
          ],
        }),
      });
    } catch (error) {
      yield {
        type: "error",
        message: error instanceof Error ? error.message : "Errore di rete.",
      };
      return;
    }

    if (!response.ok || !response.body) {
      yield {
        type: "error",
        message: `Errore API OpenAI (${response.status}).`,
      };
      return;
    }

    const reader = response.body.getReader();
    const decoder = new TextDecoder();
    let buffer = "";
    let inputTokens = 0;
    let outputTokens = 0;

    while (true) {
      const { done, value } = await reader.read();
      if (done) break;

      buffer += decoder.decode(value, { stream: true });
      const lines = buffer.split("\n");
      // L'ultima riga può essere incompleta: la riportiamo al giro dopo.
      buffer = lines.pop() ?? "";

      for (const line of lines) {
        if (!line.startsWith("data: ")) continue;
        const payload = line.slice(6).trim();
        if (payload === "[DONE]") continue;

        try {
          const event = JSON.parse(payload);
          const text = event.choices?.[0]?.delta?.content;
          if (text) yield { type: "text", text };
          if (event.usage) {
            inputTokens = event.usage.prompt_tokens ?? inputTokens;
            outputTokens = event.usage.completion_tokens ?? outputTokens;
          }
        } catch {
          // Frammento SSE non parsabile: lo saltiamo senza interrompere lo stream.
        }
      }
    }

    yield { type: "usage", model: options.model, inputTokens, outputTokens };
  },
};
