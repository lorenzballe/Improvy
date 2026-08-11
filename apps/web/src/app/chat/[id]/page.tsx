import { notFound, redirect } from "next/navigation";
import { ChatView, type UiMessage } from "@/components/chat/ChatView";
import { DEFAULT_AGENT_ID, listAgentsForClient } from "@/lib/ai/agents";
import { getConversation, getProfile, listMessages } from "@/lib/db/queries";
import { createClient } from "@/lib/supabase/server";

export default async function ConversationPage({
  params,
}: {
  params: Promise<{ id: string }>;
}) {
  const { id } = await params;

  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();

  if (!user) redirect("/login");

  // RLS filtra già per utente: se non esiste (o è di un altro), è un 404.
  const conversation = await getConversation(id);
  if (!conversation) notFound();

  const [rows, profile] = await Promise.all([
    listMessages(id),
    getProfile(user.id),
  ]);

  const initialMessages: UiMessage[] = rows.map((m) => ({
    id: m.id,
    role: m.role,
    content: m.content,
    agentId: m.agent_id ?? conversation.agent_id,
  }));

  const firstName = (profile?.full_name ?? "").split(" ")[0] ?? "";

  return (
    <ChatView
      agents={listAgentsForClient()}
      initialAgentId={conversation.agent_id || DEFAULT_AGENT_ID}
      conversationId={conversation.id}
      initialMessages={initialMessages}
      userName={firstName}
    />
  );
}
