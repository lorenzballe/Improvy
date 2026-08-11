import { NextResponse } from "next/server";
import { createClient } from "@/lib/supabase/server";

export const runtime = "nodejs";

export async function DELETE(
  _request: Request,
  { params }: { params: Promise<{ id: string }> },
) {
  const { id } = await params;
  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();

  if (!user) {
    return NextResponse.json({ error: "Non autenticato." }, { status: 401 });
  }

  // RLS garantisce che si possa cancellare solo la propria conversazione.
  const { error } = await supabase.from("conversations").delete().eq("id", id);

  if (error) {
    return NextResponse.json(
      { error: "Impossibile eliminare la conversazione." },
      { status: 500 },
    );
  }

  return NextResponse.json({ ok: true });
}
