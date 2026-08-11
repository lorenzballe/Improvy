"use client";

import { useRouter } from "next/navigation";
import { useState, useTransition } from "react";
import type { AgentSummary } from "@/lib/ai/agents";
import { completeOnboarding } from "./actions";

const ROLES = [
  "Studente",
  "Sviluppatore",
  "Imprenditore",
  "Marketing",
  "Designer",
  "Insegnante",
  "Altro",
];

const LEVELS = [
  { id: "principiante", label: "Principiante", hint: "È la mia prima volta" },
  { id: "intermedio", label: "Intermedio", hint: "Ne ho già usati altri" },
  { id: "esperto", label: "Esperto", hint: "Li uso tutti i giorni" },
];

const STEPS = 3;

export function OnboardingForm({
  agents,
  firstName,
}: {
  agents: AgentSummary[];
  firstName: string;
}) {
  const router = useRouter();
  const [pending, startTransition] = useTransition();

  const [step, setStep] = useState(0);
  const [role, setRole] = useState("");
  const [useCase, setUseCase] = useState("");
  const [level, setLevel] = useState("");
  const [agent, setAgent] = useState(agents[0]?.id ?? "generale");
  const [error, setError] = useState<string | null>(null);

  const canContinue =
    (step === 0 && role !== "") ||
    (step === 1 && level !== "") ||
    step === 2;

  function next() {
    setError(null);
    if (step < STEPS - 1) {
      setStep(step + 1);
      return;
    }

    startTransition(async () => {
      const result = await completeOnboarding({
        role,
        useCase,
        experienceLevel: level,
        preferredAgent: agent,
      });

      if (!result.ok) {
        setError(result.error);
        return;
      }
      router.replace("/chat");
      router.refresh();
    });
  }

  return (
    <div className="w-full max-w-lg">
      <div className="mb-8 flex gap-1.5">
        {Array.from({ length: STEPS }, (_, i) => (
          <div
            key={i}
            className={`h-1 flex-1 rounded-full transition ${
              i <= step
                ? "bg-[var(--color-accent)]"
                : "bg-[var(--color-line)]"
            }`}
          />
        ))}
      </div>

      <div className="rounded-2xl border border-[var(--color-line)] bg-[var(--color-surface)] p-7">
        {step === 0 && (
          <>
            <h1 className="text-xl font-semibold tracking-tight">
              Ciao{firstName ? ` ${firstName}` : ""} 👋
            </h1>
            <p className="mt-2 text-sm text-[var(--color-muted)]">
              Cosa fai? Serve a darti risposte più pertinenti.
            </p>
            <div className="mt-6 flex flex-wrap gap-2">
              {ROLES.map((r) => (
                <button
                  key={r}
                  type="button"
                  onClick={() => setRole(r)}
                  className={`rounded-lg border px-4 py-2 text-sm transition ${
                    role === r
                      ? "border-[var(--color-accent)] bg-[var(--color-accent)]/15 text-white"
                      : "border-[var(--color-line)] hover:bg-[var(--color-surface-2)]"
                  }`}
                >
                  {r}
                </button>
              ))}
            </div>
          </>
        )}

        {step === 1 && (
          <>
            <h1 className="text-xl font-semibold tracking-tight">
              Quanto hai già usato l&apos;AI?
            </h1>
            <p className="mt-2 text-sm text-[var(--color-muted)]">
              Regola il livello di dettaglio delle spiegazioni.
            </p>
            <div className="mt-6 space-y-2">
              {LEVELS.map((l) => (
                <button
                  key={l.id}
                  type="button"
                  onClick={() => setLevel(l.id)}
                  className={`flex w-full items-center justify-between rounded-lg border px-4 py-3 text-left transition ${
                    level === l.id
                      ? "border-[var(--color-accent)] bg-[var(--color-accent)]/15"
                      : "border-[var(--color-line)] hover:bg-[var(--color-surface-2)]"
                  }`}
                >
                  <span className="text-sm font-medium">{l.label}</span>
                  <span className="text-xs text-[var(--color-muted)]">
                    {l.hint}
                  </span>
                </button>
              ))}
            </div>
          </>
        )}

        {step === 2 && (
          <>
            <h1 className="text-xl font-semibold tracking-tight">
              Da quale agente vuoi partire?
            </h1>
            <p className="mt-2 text-sm text-[var(--color-muted)]">
              Puoi cambiarlo in qualsiasi momento durante la chat.
            </p>
            <div className="mt-6 space-y-2">
              {agents.map((a) => (
                <button
                  key={a.id}
                  type="button"
                  onClick={() => setAgent(a.id)}
                  className={`flex w-full items-center gap-3 rounded-lg border px-4 py-3 text-left transition ${
                    agent === a.id
                      ? "border-[var(--color-accent)] bg-[var(--color-accent)]/15"
                      : "border-[var(--color-line)] hover:bg-[var(--color-surface-2)]"
                  }`}
                >
                  <span className="text-lg">{a.emoji}</span>
                  <span className="min-w-0 flex-1">
                    <span className="block text-sm font-medium">{a.name}</span>
                    <span className="block truncate text-xs text-[var(--color-muted)]">
                      {a.tagline}
                    </span>
                  </span>
                </button>
              ))}
            </div>

            <label className="mt-6 block">
              <span className="text-sm font-medium">
                A cosa ti servirà?{" "}
                <span className="font-normal text-[var(--color-muted)]">
                  (facoltativo)
                </span>
              </span>
              <textarea
                value={useCase}
                onChange={(e) => setUseCase(e.target.value)}
                rows={3}
                maxLength={500}
                placeholder="Es. preparare esami, scrivere email di lavoro, fare debug…"
                className="mt-2 w-full resize-none rounded-lg border border-[var(--color-line)] bg-[var(--color-ink)] px-3 py-2 text-sm outline-none placeholder:text-[var(--color-muted)]/60 focus:border-[var(--color-accent)]"
              />
            </label>
          </>
        )}

        {error && (
          <p className="mt-4 text-sm text-red-400" role="alert">
            {error}
          </p>
        )}

        <div className="mt-7 flex items-center justify-between">
          <button
            type="button"
            onClick={() => setStep(Math.max(0, step - 1))}
            disabled={step === 0 || pending}
            className="text-sm text-[var(--color-muted)] transition hover:text-[var(--color-text)] disabled:invisible"
          >
            Indietro
          </button>
          <button
            type="button"
            onClick={next}
            disabled={!canContinue || pending}
            className="rounded-lg bg-[var(--color-accent)] px-6 py-2.5 text-sm font-medium text-white transition hover:opacity-90 disabled:cursor-not-allowed disabled:opacity-40"
          >
            {pending
              ? "Un attimo…"
              : step === STEPS - 1
                ? "Inizia a chattare"
                : "Avanti"}
          </button>
        </div>
      </div>
    </div>
  );
}
