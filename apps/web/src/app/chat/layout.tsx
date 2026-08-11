import { redirect } from "next/navigation";
import { Sidebar } from "@/components/chat/Sidebar";
import { getProfile, listConversations } from "@/lib/db/queries";
import { createClient } from "@/lib/supabase/server";

export default async function ChatLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();

  if (!user) redirect("/login");

  const profile = await getProfile(user.id);
  if (!profile?.onboarding_completed) redirect("/onboarding");

  const conversations = await listConversations();
  const userName = profile.full_name ?? profile.email ?? "";

  return (
    <div className="flex h-screen overflow-hidden">
      <Sidebar conversations={conversations} userName={userName} />
      <main className="flex min-w-0 flex-1 flex-col">{children}</main>
    </div>
  );
}
