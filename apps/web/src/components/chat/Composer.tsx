"use client";

import { useEffect, useRef, useState } from "react";

export function Composer({
  onSend,
  onStop,
  streaming,
}: {
  onSend: (text: string) => void;
  onStop: () => void;
  streaming: boolean;
}) {
  const [value, setValue] = useState("");
  const ref = useRef<HTMLTextAreaElement>(null);

  // Cresce con il testo, fino a un massimo.
  useEffect(() => {
    const el = ref.current;
    if (!el) return;
    el.style.height = "auto";
    el.style.height = `${Math.min(el.scrollHeight, 200)}px`;
  }, [value]);

  function submit() {
    const text = value.trim();
    if (!text || streaming) return;
    setValue("");
    onSend(text);
  }

  return (
    <div className="shrink-0 border-t border-[var(--color-line)] px-4 py-4">
      <div className="mx-auto max-w-3xl">
        <div className="flex items-end gap-2 rounded-2xl border border-[var(--color-line)] bg-[var(--color-surface)] px-3 py-2 focus-within:border-[var(--color-accent)]/60">
          <textarea
            ref={ref}
            value={value}
            onChange={(e) => setValue(e.target.value)}
            onKeyDown={(e) => {
              // Invio manda, Shift+Invio va a capo.
              if (e.key === "Enter" && !e.shiftKey && !e.nativeEvent.isComposing) {
                e.preventDefault();
                submit();
              }
            }}
            rows={1}
            placeholder="Scrivi un messaggio…"
            className="max-h-[200px] min-h-[24px] flex-1 resize-none bg-transparent py-1.5 text-[0.95rem] leading-relaxed outline-none placeholder:text-[var(--color-muted)]/60"
          />

          {streaming ? (
            <button
              type="button"
              onClick={onStop}
              aria-label="Interrompi"
              className="mb-0.5 shrink-0 rounded-lg border border-[var(--color-line)] px-3 py-1.5 text-sm transition hover:bg-[var(--color-surface-2)]"
            >
              Stop
            </button>
          ) : (
            <button
              type="button"
              onClick={submit}
              disabled={!value.trim()}
              aria-label="Invia"
              className="mb-0.5 shrink-0 rounded-lg bg-[var(--color-accent)] px-3.5 py-1.5 text-sm font-medium text-white transition hover:opacity-90 disabled:cursor-not-allowed disabled:opacity-30"
            >
              ↑
            </button>
          )}
        </div>

        <p className="mt-2 text-center text-[11px] text-[var(--color-muted)]/70">
          L&apos;AI può sbagliare. Verifica le informazioni importanti.
        </p>
      </div>
    </div>
  );
}
