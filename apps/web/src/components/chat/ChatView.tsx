"use client";

import { useRouter } from "next/navigation";
import { useCallback, useEffect, useRef, useState } from "react";
import type { AgentSummary } from "@/lib/ai/agents";
import { AgentPicker } from "./AgentPicker";
import { Composer } from "./Composer";
import { MessageBubble } from "./MessageBubble";

export interface UiMessage {
  id: string;
  role: "user" | "assistant";
  content: string;
  /** Riassunto del ragionamento, se l'agente lo espone. */
  reasoning?: string;
  agentId?: string;
  error?: string;
  streaming?: boolean;
}

interface Props {
  agents: AgentSummary[];
  initialAgentId: string;
  conversationId: string | null;
  initialMessages: UiMessage[];
  userName: string;
}

export function ChatView({
  agents,
  initialAgentId,
  conversationId: initialConversationId,
  initialMessages,
  userName,
}: Props) {
  const router = useRouter();

  const [messages, setMessages] = useState<UiMessage[]>(initialMessages);
  const [agentId, setAgentId] = useState(initialAgentId);
  const [conversationId, setConversationId] = useState(initialConversationId);
  const [streaming, setStreaming] = useState(false);

  const abortRef = useRef<AbortController | null>(null);
  const bottomRef = useRef<HTMLDivElement>(null);
  const scrollerRef = useRef<HTMLDivElement>(null);
  // L'autoscroll si disattiva se l'utente scorre indietro per rileggere.
  const stickToBottom = useRef(true);

  useEffect(() => {
    if (stickToBottom.current) {
      bottomRef.current?.scrollIntoView({ block: "end" });
    }
  }, [messages]);

  const onScroll = useCallback(() => {
    const el = scrollerRef.current;
    if (!el) return;
    const distance = el.scrollHeight - el.scrollTop - el.clientHeight;
    stickToBottom.current = distance < 120;
  }, []);

  // Interrompe la richiesta in corso se si esce dalla pagina.
  useEffect(() => () => abortRef.current?.abort(), []);

  const patchLast = useCallback((patch: Partial<UiMessage>) => {
    setMessages((prev) => {
      if (prev.length === 0) return prev;
      const next = [...prev];
      const last = next[next.length - 1];
      next[next.length - 1] = { ...last, ...patch };
      return next;
    });
  }, []);

  const appendToLast = useCallback(
    (field: "content" | "reasoning", text: string) => {
      setMessages((prev) => {
        if (prev.length === 0) return prev;
        const next = [...prev];
        const last = next[next.length - 1];
        next[next.length - 1] = {
          ...last,
          [field]: (last[field] ?? "") + text,
        };
        return next;
      });
    },
    [],
  );

  async function send(text: string) {
    if (streaming) return;

    const controller = new AbortController();
    abortRef.current = controller;
    stickToBottom.current = true;
    setStreaming(true);

    setMessages((prev) => [
      ...prev,
      { id: `u-${Date.now()}`, role: "user", content: text },
      {
        id: `a-${Date.now()}`,
        role: "assistant",
        content: "",
        agentId,
        streaming: true,
      },
    ]);

    let createdId: string | null = null;

    try {
      const response = await fetch("/api/chat", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        signal: controller.signal,
        body: JSON.stringify({ message: text, agentId, conversationId }),
      });

      if (!response.ok || !response.body) {
        const detail = await response.json().catch(() => null);
        patchLast({
          streaming: false,
          error: detail?.error ?? `Errore ${response.status}.`,
        });
        return;
      }

      const reader = response.body.getReader();
      const decoder = new TextDecoder();
      let buffer = "";

      while (true) {
        const { done, value } = await reader.read();
        if (done) break;

        buffer += decoder.decode(value, { stream: true });
        // Gli eventi SSE sono separati da una riga vuota.
        const events = buffer.split("\n\n");
        buffer = events.pop() ?? "";

        for (const raw of events) {
          const line = raw.trim();
          if (!line.startsWith("data:")) continue;

          let event: Record<string, unknown>;
          try {
            event = JSON.parse(line.slice(5).trim());
          } catch {
            continue;
          }

          switch (event.type) {
            case "meta":
              if (!conversationId && typeof event.conversationId === "string") {
                createdId = event.conversationId;
                setConversationId(createdId);
                // Aggiorna l'URL senza rimontare il componente: una
                // navigazione Next qui interromperebbe lo stream in corso.
                window.history.replaceState(null, "", `/chat/${createdId}`);
              }
              break;
            case "thinking":
              appendToLast("reasoning", String(event.text ?? ""));
              break;
            case "text":
              appendToLast("content", String(event.text ?? ""));
              break;
            case "refusal":
              patchLast({ error: String(event.message ?? "") });
              break;
            case "error":
              patchLast({ error: String(event.message ?? "Errore.") });
              break;
            case "done":
              patchLast({ streaming: false });
              break;
          }
        }
      }
    } catch (error) {
      if ((error as Error).name === "AbortError") {
        patchLast({ streaming: false });
      } else {
        patchLast({
          streaming: false,
          error:
            error instanceof Error ? error.message : "Connessione interrotta.",
        });
      }
    } finally {
      patchLast({ streaming: false });
      setStreaming(false);
      abortRef.current = null;
      // Ricarica la sidebar (nuova conversazione, titolo, ordinamento).
      router.refresh();
    }
  }

  function stop() {
    abortRef.current?.abort();
  }

  const empty = messages.length === 0;

  return (
    <div className="flex h-full min-h-0 flex-col">
      <header className="flex shrink-0 items-center justify-between border-b border-[var(--color-line)] px-4 py-3">
        <AgentPicker
          agents={agents}
          value={agentId}
          onChange={setAgentId}
          disabled={streaming}
        />
        <form action="/auth/signout" method="post">
          <button
            type="submit"
            className="rounded-lg px-3 py-1.5 text-sm text-[var(--color-muted)] transition hover:bg-[var(--color-surface-2)] hover:text-[var(--color-text)]"
          >
            Esci
          </button>
        </form>
      </header>

      <div
        ref={scrollerRef}
        onScroll={onScroll}
        className="min-h-0 flex-1 overflow-y-auto"
      >
        {empty ? (
          <EmptyState userName={userName} onPick={send} />
        ) : (
          <div className="mx-auto max-w-3xl px-4 py-8">
            {messages.map((message) => (
              <MessageBubble
                key={message.id}
                message={message}
                agents={agents}
              />
            ))}
            <div ref={bottomRef} />
          </div>
        )}
      </div>

      <Composer onSend={send} onStop={stop} streaming={streaming} />
    </div>
  );
}

function EmptyState({
  userName,
  onPick,
}: {
  userName: string;
  onPick: (text: string) => void;
}) {
  const suggestions = [
    "Spiegami una cosa complicata in parole semplici",
    "Aiutami a scrivere un'email di lavoro",
    "Trova il bug in questo codice",
    "Dammi un'idea per un progetto",
  ];

  return (
    <div className="mx-auto flex h-full max-w-2xl flex-col items-center justify-center px-4 py-16 text-center">
      <h1 className="text-2xl font-semibold tracking-tight sm:text-3xl">
        {userName ? `Ciao ${userName}.` : "Ciao."}{" "}
        <span className="text-[var(--color-muted)]">Di cosa parliamo?</span>
      </h1>

      <div className="mt-8 grid w-full gap-2 sm:grid-cols-2">
        {suggestions.map((s) => (
          <button
            key={s}
            type="button"
            onClick={() => onPick(s)}
            className="rounded-xl border border-[var(--color-line)] bg-[var(--color-surface)] px-4 py-3 text-left text-sm text-[var(--color-muted)] transition hover:border-[var(--color-accent)]/50 hover:text-[var(--color-text)]"
          >
            {s}
          </button>
        ))}
      </div>
    </div>
  );
}
