import { createServerClient } from "@supabase/ssr";
import { cookies } from "next/headers";

/**
 * Client Supabase per Server Component, Route Handler e Server Action.
 * Legge la sessione dai cookie, quindi conosce l'utente loggato.
 */
export async function createClient() {
  const cookieStore = await cookies();

  return createServerClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
    {
      cookies: {
        getAll() {
          return cookieStore.getAll();
        },
        setAll(cookiesToSet) {
          try {
            for (const { name, value, options } of cookiesToSet) {
              cookieStore.set(name, value, options);
            }
          } catch {
            // I Server Component non possono scrivere cookie. Il refresh della
            // sessione avviene nel middleware, quindi qui si può ignorare.
          }
        },
      },
    },
  );
}
