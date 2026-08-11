import type { ProviderId } from "./types";

/**
 * Catalogo dei modelli disponibili.
 *
 * `inputPer1M` / `outputPer1M` sono in dollari per milione di token e servono
 * a stimare il costo in dashboard. Vanno riverificati sul listino ufficiale
 * del provider prima di usarli per fatturare qualcosa.
 */
export interface ModelInfo {
  id: string;
  provider: ProviderId;
  label: string;
  contextWindow: number;
  inputPer1M: number;
  outputPer1M: number;
  /** Il parametro `effort` non è accettato da tutti i modelli. */
  supportsEffort: boolean;
  /** Ragionamento adattivo con riassunto visibile. */
  supportsReasoning: boolean;
}

export const MODELS = {
  "claude-opus-5": {
    id: "claude-opus-5",
    provider: "anthropic",
    label: "Claude Opus 5",
    contextWindow: 1_000_000,
    inputPer1M: 5,
    outputPer1M: 25,
    supportsEffort: true,
    supportsReasoning: true,
  },
  "claude-sonnet-5": {
    id: "claude-sonnet-5",
    provider: "anthropic",
    label: "Claude Sonnet 5",
    contextWindow: 1_000_000,
    inputPer1M: 3,
    outputPer1M: 15,
    supportsEffort: true,
    supportsReasoning: true,
  },
  "claude-haiku-4-5": {
    id: "claude-haiku-4-5",
    provider: "anthropic",
    label: "Claude Haiku 4.5",
    contextWindow: 200_000,
    inputPer1M: 1,
    outputPer1M: 5,
    // Haiku 4.5 rifiuta il parametro `effort` e non fa ragionamento adattivo.
    supportsEffort: false,
    supportsReasoning: false,
  },
} as const satisfies Record<string, ModelInfo>;

export type ModelId = keyof typeof MODELS;

export function getModel(id: string): ModelInfo | undefined {
  return (MODELS as Record<string, ModelInfo>)[id];
}

/** Costo stimato in dollari di una singola risposta. */
export function estimateCost(
  modelId: string,
  inputTokens: number,
  outputTokens: number,
): number | null {
  const model = getModel(modelId);
  if (!model) return null;
  return (
    (inputTokens / 1_000_000) * model.inputPer1M +
    (outputTokens / 1_000_000) * model.outputPer1M
  );
}
