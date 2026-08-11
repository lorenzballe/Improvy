"use client";

import { useEffect, useRef, useState } from "react";
import type { AgentSummary } from "@/lib/ai/agents";

export function AgentPicker({
  agents,
  value,
  onChange,
  disabled,
}: {
  agents: AgentSummary[];
  value: string;
  onChange: (id: string) => void;
  disabled?: boolean;
}) {
  const [open, setOpen] = useState(false);
  const ref = useRef<HTMLDivElement>(null);
  const current = agents.find((a) => a.id === value) ?? agents[0];

  // Chiude cliccando fuori o con Esc.
  useEffect(() => {
    if (!open) return;

    function onPointerDown(event: MouseEvent) {
      if (!ref.current?.contains(event.target as Node)) setOpen(false);
    }
    function onKeyDown(event: KeyboardEvent) {
      if (event.key === "Escape") setOpen(false);
    }

    document.addEventListener("mousedown", onPointerDown);
    document.addEventListener("keydown", onKeyDown);
    return () => {
      document.removeEventListener("mousedown", onPointerDown);
      document.removeEventListener("keydown", onKeyDown);
    };
  }, [open]);

  if (!current) return null;

  return (
    <div ref={ref} className="relative">
      <button
        type="button"
        onClick={() => setOpen((v) => !v)}
        disabled={disabled}
        aria-haspopup="listbox"
        aria-expanded={open}
        className="flex items-center gap-2 rounded-lg px-2.5 py-1.5 text-sm transition hover:bg-[var(--color-surface-2)] disabled:cursor-not-allowed disabled:opacity-50"
      >
        <span>{current.emoji}</span>
        <span className="font-medium">{current.name}</span>
        <span className="text-xs text-[var(--color-muted)]">▾</span>
      </button>

      {open && (
        <div
          role="listbox"
          className="absolute left-0 top-full z-20 mt-1 w-72 overflow-hidden rounded-xl border border-[var(--color-line)] bg-[var(--color-surface)] shadow-xl shadow-black/40"
        >
          {agents.map((agent) => (
            <button
              key={agent.id}
              type="button"
              role="option"
              aria-selected={agent.id === value}
              onClick={() => {
                onChange(agent.id);
                setOpen(false);
              }}
              className={`flex w-full items-start gap-3 px-3 py-2.5 text-left transition hover:bg-[var(--color-surface-2)] ${
                agent.id === value ? "bg-[var(--color-surface-2)]" : ""
              }`}
            >
              <span className="mt-0.5 text-base">{agent.emoji}</span>
              <span className="min-w-0 flex-1">
                <span className="block text-sm font-medium">{agent.name}</span>
                <span className="block text-xs text-[var(--color-muted)]">
                  {agent.tagline}
                </span>
                <span className="mt-0.5 block font-mono text-[10px] text-[var(--color-muted)]/60">
                  {agent.modelLabel}
                </span>
              </span>
            </button>
          ))}
        </div>
      )}
    </div>
  );
}
