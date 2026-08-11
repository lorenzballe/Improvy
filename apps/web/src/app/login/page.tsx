import Link from "next/link";
import { GoogleButton } from "@/components/GoogleButton";

export default async function LoginPage({
  searchParams,
}: {
  searchParams: Promise<{ next?: string; error?: string }>;
}) {
  const { next, error } = await searchParams;
  const safeNext = next?.startsWith("/") ? next : undefined;

  return (
    <main className="flex min-h-screen flex-col items-center justify-center px-6">
      <div className="w-full max-w-sm">
        <Link
          href="/"
          className="mb-10 block text-center text-lg font-semibold tracking-tight"
        >
          <span className="text-[var(--color-accent-soft)]">✦</span> Improvy
        </Link>

        <div className="rounded-2xl border border-[var(--color-line)] bg-[var(--color-surface)] p-7">
          <h1 className="text-xl font-semibold tracking-tight">Accedi</h1>
          <p className="mt-2 text-sm leading-relaxed text-[var(--color-muted)]">
            Ti serve un account per salvare le conversazioni. Bastano due
            secondi.
          </p>

          <div className="mt-6">
            <GoogleButton next={safeNext} />
          </div>

          {error && (
            <p
              className="mt-4 rounded-lg border border-red-500/30 bg-red-500/10 px-3 py-2 text-sm text-red-300"
              role="alert"
            >
              {error}
            </p>
          )}
        </div>

        <p className="mt-6 text-center text-xs leading-relaxed text-[var(--color-muted)]">
          Continuando accetti che le tue conversazioni vengano salvate sul tuo
          account.
        </p>
      </div>
    </main>
  );
}
