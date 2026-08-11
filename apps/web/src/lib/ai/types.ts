/**
 * Tipi condivisi del layer AI.
 *
 * L'idea: la UI e le route API non sanno *chi* risponde. Parlano solo con
 * questa interfaccia. Aggiungere un provider (OpenAI, Gemini, un agente tuo)
 * significa scrivere un nuovo file in `providers/` e registrarlo — nessuna
 * modifica al resto dell'app.
 */

export type ProviderId = "anthropic" | "openai";

/** Un messaggio nella conversazione, nella forma neutra rispetto al provider. */
export interface ChatMessage {
  role: "user" | "assistant";
  content: string;
}

/** Pezzi che il provider emette mentre genera la risposta. */
export type StreamChunk =
  /** Riassunto del ragionamento del modello (mostrato in un blocco a parte). */
  | { type: "thinking"; text: string }
  /** Testo della risposta vera e propria. */
  | { type: "text"; text: string }
  /** Consumo finale, per tracciare i costi. */
  | { type: "usage"; inputTokens: number; outputTokens: number; model: string }
  /** Il modello ha rifiutato per motivi di sicurezza. Non è un errore tecnico. */
  | { type: "refusal"; message: string }
  /** Errore vero (rete, chiave mancante, rate limit...). */
  | { type: "error"; message: string };

export interface StreamChatOptions {
  model: string;
  system: string;
  messages: ChatMessage[];
  maxTokens: number;
  /** Profondità di ragionamento. Non tutti i modelli la supportano. */
  effort?: "low" | "medium" | "high" | "xhigh" | "max";
  /** Se true, il provider emette anche i chunk `thinking`. */
  showReasoning?: boolean;
  signal?: AbortSignal;
}

export interface ChatProvider {
  id: ProviderId;
  /** false se manca la API key: la UI lo segnala invece di fallire a runtime. */
  isConfigured(): boolean;
  streamChat(options: StreamChatOptions): AsyncIterable<StreamChunk>;
}
