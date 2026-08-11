import { redirect } from "next/navigation";
import { listAgentsForClient } from "@/lib/ai/agents";
import { getProfile } from "@/lib/db/queries";
import { createClient } from "@/lib/supabase/server";
import { OnboardingForm } from "./OnboardingForm";

export default async function OnboardingPage() {
  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();

  if (!user) redirect("/login");

  const profile = await getProfile(user.id);
  if (profile?.onboarding_completed) redirect("/chat");

  const fullName =
    profile?.full_name ??
    (user.user_metadata?.full_name as string | undefined) ??
    "";
  const firstName = fullName.split(" ")[0] ?? "";

  return (
    <main className="flex min-h-screen items-center justify-center px-6 py-12">
      <OnboardingForm agents={listAgentsForClient()} firstName={firstName} />
    </main>
  );
}
