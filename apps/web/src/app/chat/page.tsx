import { redirect } from "next/navigation";
import { ChatView } from "@/components/chat/ChatView";
import { DEFAULT_AGENT_ID, listAgentsForClient } from "@/lib/ai/agents";
import { getProfile } from "@/lib/db/queries";
import { createClient } from "@/lib/supabase/server";

export default async function NewChatPage() {
  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();

  if (!user) redirect("/login");

  const profile = await getProfile(user.id);
  const firstName = (profile?.full_name ?? "").split(" ")[0] ?? "";

  return (
    <ChatView
      agents={listAgentsForClient()}
      initialAgentId={profile?.preferred_agent ?? DEFAULT_AGENT_ID}
      conversationId={null}
      initialMessages={[]}
      userName={firstName}
    />
  );
}
