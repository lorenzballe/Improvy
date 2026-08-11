import { createBrowserClient } from "@supabase/ssr";

/** Client Supabase per i Client Component (gira nel browser). */
export function createClient() {
  return createBrowserClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
  );
}
