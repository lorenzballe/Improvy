import { createClient } from "@/lib/supabase/server";
import type { Conversation, Message, Profile } from "@/types/db";

/**
 * Query lato server. Le policy RLS del database filtrano già per utente
 * loggato, quindi qui non serve (e non basterebbe) aggiungere `where user_id`.
 */

export async function getProfile(userId: string): Promise<Profile | null> {
  const supabase = await createClient();
  const { data } = await supabase
    .from("profiles")
    .select("*")
    .eq("id", userId)
    .maybeSingle();
  return data as Profile | null;
}

export async function listConversations(): Promise<Conversation[]> {
  const supabase = await createClient();
  const { data } = await supabase
    .from("conversations")
    .select("*")
    .order("updated_at", { ascending: false })
    .limit(100);
  return (data ?? []) as Conversation[];
}

export async function getConversation(
  id: string,
): Promise<Conversation | null> {
  const supabase = await createClient();
  const { data } = await supabase
    .from("conversations")
    .select("*")
    .eq("id", id)
    .maybeSingle();
  return data as Conversation | null;
}

export async function listMessages(
  conversationId: string,
): Promise<Message[]> {
  const supabase = await createClient();
  const { data } = await supabase
    .from("messages")
    .select("*")
    .eq("conversation_id", conversationId)
    .order("created_at", { ascending: true });
  return (data ?? []) as Message[];
}

export async function createConversation(
  userId: string,
  agentId: string,
  title: string,
): Promise<Conversation | null> {
  const supabase = await createClient();
  const { data } = await supabase
    .from("conversations")
    .insert({ user_id: userId, agent_id: agentId, title })
    .select()
    .single();
  return data as Conversation | null;
}

export async function deleteConversation(id: string): Promise<void> {
  const supabase = await createClient();
  await supabase.from("conversations").delete().eq("id", id);
}

/** Titolo provvisorio ricavato dal primo messaggio dell'utente. */
export function titleFromMessage(text: string): string {
  const clean = text.trim().replace(/\s+/g, " ");
  if (clean.length <= 60) return clean || "Nuova conversazione";
  return `${clean.slice(0, 57)}...`;
}
