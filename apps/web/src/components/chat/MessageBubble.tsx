"use client";

import { useState } from "react";
import type { AgentSummary } from "@/lib/ai/agents";
import type { UiMessage } from "./ChatView";
import { Markdown } from "./Markdown";

export function MessageBubble({
  message,
  agents,
}: {
  message: UiMessage;
  agents: AgentSummary[];
}) {
  const [showReasoning, setShowReasoning] = useState(false);

  if (message.role === "user") {
    return (
      <div className="mb-6 flex justify-end">
        <div className="max-w-[85%] rounded-2xl rounded-br-md bg-[var(--color-surface-2)] px-4 py-2.5 text-[0.95rem] leading-relaxed whitespace-pre-wrap">
          {message.content}
        </div>
      </div>
    );
  }

  const agent = agents.find((a) => a.id === message.agentId);
  const waiting = message.streaming && !message.content;

  return (
    <div className="mb-8">
      <div className="mb-2 flex items-center gap-2 text-xs text-[var(--color-muted)]">
        <span className="text-sm">{agent?.emoji ?? "✦"}</span>
        <span className="font-medium">{agent?.name ?? "Improvy"}</span>
        {agent && <span className="opacity-50">· {agent.modelLabel}</span>}
      </div>

      {message.reasoning && (
        <div className="mb-3">
          <button
            type="button"
            onClick={() => setShowReasoning((v) => !v)}
            className="text-xs text-[var(--color-muted)] transition hover:text-[var(--color-text)]"
          >
            {showReasoning ? "▾" : "▸"} Ragionamento
          </button>
          {showReasoning && (
            <div className="mt-2 rounded-lg border border-[var(--color-line)] bg-[var(--color-surface)] px-3 py-2 text-xs leading-relaxed whitespace-pre-wrap text-[var(--color-muted)]">
              {message.reasoning}
            </div>
          )}
        </div>
      )}

      {waiting ? (
        <p className="text-sm text-[var(--color-muted)]">
          {message.reasoning ? "Sto ragionando…" : "Un attimo…"}
        </p>
      ) : (
        <div className="prose-chat text-[0.95rem]">
          <Markdown text={message.content} />
          {message.streaming && <span className="caret" />}
        </div>
      )}

      {message.error && (
        <p
          className="mt-3 rounded-lg border border-red-500/30 bg-red-500/10 px-3 py-2 text-sm text-red-300"
          role="alert"
        >
          {message.error}
        </p>
      )}
    </div>
  );
}
