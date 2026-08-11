"use server";

import { redirect } from "next/navigation";
import { AGENTS, DEFAULT_AGENT_ID } from "@/lib/ai/agents";
import { createClient } from "@/lib/supabase/server";

export interface OnboardingInput {
  role: string;
  useCase: string;
  experienceLevel: string;
  preferredAgent: string;
}

export async function completeOnboarding(input: OnboardingInput) {
  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();

  if (!user) redirect("/login");

  // Non fidarsi del valore che arriva dal client.
  const preferredAgent = AGENTS.some((a) => a.id === input.preferredAgent)
    ? input.preferredAgent
    : DEFAULT_AGENT_ID;

  const { error } = await supabase
    .from("profiles")
    .update({
      role: input.role.slice(0, 120) || null,
      use_case: input.useCase.slice(0, 500) || null,
      experience_level: input.experienceLevel.slice(0, 40) || null,
      preferred_agent: preferredAgent,
      onboarding_completed: true,
    })
    .eq("id", user.id);

  if (error) {
    return { ok: false as const, error: error.message };
  }

  return { ok: true as const };
}
