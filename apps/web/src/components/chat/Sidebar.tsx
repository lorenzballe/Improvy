"use client";

import Link from "next/link";
import { usePathname, useRouter } from "next/navigation";
import { useState } from "react";
import type { Conversation } from "@/types/db";

export function Sidebar({
  conversations,
  userName,
}: {
  conversations: Conversation[];
  userName: string;
}) {
  const router = useRouter();
  const pathname = usePathname();
  const [open, setOpen] = useState(false);
  const [deleting, setDeleting] = useState<string | null>(null);

  async function remove(id: string) {
    setDeleting(id);
    const response = await fetch(`/api/conversations/${id}`, {
      method: "DELETE",
    });
    setDeleting(null);

    if (!response.ok) return;
    // Se stavamo guardando quella conversazione, torniamo alla chat vuota.
    if (pathname === `/chat/${id}`) router.push("/chat");
    router.refresh();
  }

  return (
    <>
      {/* Barra mobile */}
      <div className="flex items-center justify-between border-b border-[var(--color-line)] px-4 py-3 md:hidden">
        <button
          type="button"
          onClick={() => setOpen(true)}
          aria-label="Apri le conversazioni"
          className="rounded-lg px-2 py-1 text-lg leading-none transition hover:bg-[var(--color-surface-2)]"
        >
          ☰
        </button>
        <span className="text-sm font-semibold">
          <span className="text-[var(--color-accent-soft)]">✦</span> Improvy
        </span>
        <Link
          href="/chat"
          className="rounded-lg px-2 py-1 text-lg leading-none transition hover:bg-[var(--color-surface-2)]"
          aria-label="Nuova chat"
        >
          +
        </Link>
      </div>

      {open && (
        <div
          className="fixed inset-0 z-30 bg-black/60 md:hidden"
          onClick={() => setOpen(false)}
          aria-hidden="true"
        />
      )}

      <aside
        className={`fixed inset-y-0 left-0 z-40 flex w-72 shrink-0 flex-col border-r border-[var(--color-line)] bg-[var(--color-surface)] transition-transform md:static md:z-auto md:translate-x-0 ${
          open ? "translate-x-0" : "-translate-x-full"
        }`}
      >
        <div className="flex items-center justify-between px-4 py-4">
          <Link href="/" className="text-sm font-semibold tracking-tight">
            <span className="text-[var(--color-accent-soft)]">✦</span> Improvy
          </Link>
          <button
            type="button"
            onClick={() => setOpen(false)}
            aria-label="Chiudi"
            className="rounded-lg px-2 py-1 text-sm transition hover:bg-[var(--color-surface-2)] md:hidden"
          >
            ✕
          </button>
        </div>

        <div className="px-3">
          <Link
            href="/chat"
            onClick={() => setOpen(false)}
            className="flex items-center gap-2 rounded-lg border border-[var(--color-line)] px-3 py-2 text-sm font-medium transition hover:bg-[var(--color-surface-2)]"
          >
            <span className="text-base leading-none">+</span> Nuova chat
          </Link>
        </div>

        <nav className="mt-4 min-h-0 flex-1 overflow-y-auto px-3 pb-4">
          {conversations.length === 0 ? (
            <p className="px-2 py-3 text-xs text-[var(--color-muted)]">
              Nessuna conversazione.
            </p>
          ) : (
            <ul className="space-y-0.5">
              {conversations.map((c) => {
                const active = pathname === `/chat/${c.id}`;
                return (
                  <li key={c.id} className="group relative">
                    <Link
                      href={`/chat/${c.id}`}
                      onClick={() => setOpen(false)}
                      className={`block truncate rounded-lg py-2 pl-3 pr-9 text-sm transition ${
                        active
                          ? "bg-[var(--color-surface-2)]"
                          : "text-[var(--color-muted)] hover:bg-[var(--color-surface-2)] hover:text-[var(--color-text)]"
                      }`}
                    >
                      {c.title}
                    </Link>
                    <button
                      type="button"
                      onClick={() => remove(c.id)}
                      disabled={deleting === c.id}
                      aria-label={`Elimina "${c.title}"`}
                      className="absolute right-1.5 top-1/2 -translate-y-1/2 rounded px-1.5 py-1 text-xs text-[var(--color-muted)] opacity-0 transition hover:text-red-400 focus:opacity-100 group-hover:opacity-100 disabled:opacity-40"
                    >
                      {deleting === c.id ? "…" : "✕"}
                    </button>
                  </li>
                );
              })}
            </ul>
          )}
        </nav>

        <div className="border-t border-[var(--color-line)] px-4 py-3 text-xs text-[var(--color-muted)]">
          {userName || "Account"}
        </div>
      </aside>
    </>
  );
}
