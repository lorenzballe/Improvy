import Link from "next/link";
import { listAgentsForClient } from "@/lib/ai/agents";
import { createClient } from "@/lib/supabase/server";

export default async function LandingPage() {
  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();

  const agents = listAgentsForClient();

  return (
    <main className="min-h-screen">
      <header className="mx-auto flex max-w-5xl items-center justify-between px-6 py-6">
        <span className="text-lg font-semibold tracking-tight">
          <span className="text-[var(--color-accent-soft)]">✦</span> Improvy
        </span>
        <Link
          href={user ? "/chat" : "/login"}
          className="rounded-lg border border-[var(--color-line)] px-4 py-2 text-sm font-medium transition hover:bg-[var(--color-surface-2)]"
        >
          {user ? "Apri la chat" : "Accedi"}
        </Link>
      </header>

      <section className="mx-auto max-w-3xl px-6 pt-16 pb-20 text-center sm:pt-24">
        <h1 className="text-4xl font-semibold leading-tight tracking-tight sm:text-6xl">
          Un assistente.
          <br />
          <span className="text-[var(--color-muted)]">Più cervelli.</span>
        </h1>
        <p className="mx-auto mt-6 max-w-xl text-base leading-relaxed text-[var(--color-muted)] sm:text-lg">
          Scrivi una domanda e scegli chi risponde: risposte istantanee,
          ragionamento profondo, codice o scrittura. Ogni agente usa il modello
          giusto per il suo compito.
        </p>

        <div className="mt-10 flex items-center justify-center gap-3">
          <Link
            href={user ? "/chat" : "/login"}
            className="rounded-lg bg-[var(--color-accent)] px-6 py-3 text-sm font-medium text-white transition hover:opacity-90"
          >
            {user ? "Continua" : "Inizia con Google"}
          </Link>
        </div>
      </section>

      <section className="mx-auto max-w-5xl px-6 pb-24">
        <div className="grid gap-3 sm:grid-cols-2 lg:grid-cols-3">
          {agents.map((agent) => (
            <div
              key={agent.id}
              className="rounded-xl border border-[var(--color-line)] bg-[var(--color-surface)] p-5"
            >
              <div className="text-xl">{agent.emoji}</div>
              <h3 className="mt-3 font-medium">{agent.name}</h3>
              <p className="mt-1 text-sm text-[var(--color-muted)]">
                {agent.tagline}
              </p>
              <p className="mt-3 font-mono text-xs text-[var(--color-muted)]/70">
                {agent.modelLabel}
              </p>
            </div>
          ))}
        </div>
      </section>

      <footer className="border-t border-[var(--color-line)] px-6 py-8 text-center text-xs text-[var(--color-muted)]">
        Improvy — versione iniziale
      </footer>
    </main>
  );
}
