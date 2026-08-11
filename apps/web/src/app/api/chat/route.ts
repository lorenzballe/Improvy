import { NextResponse } from "next/server";
import { getAgent, streamAgentReply } from "@/lib/ai";
import type { ChatMessage } from "@/lib/ai/types";
import { titleFromMessage } from "@/lib/db/queries";
import { createClient } from "@/lib/supabase/server";

export const runtime = "nodejs";
// Le risposte lunghe possono superare il limite di default su Vercel.
export const maxDuration = 300;

/** Quanti messaggi passati mandare al modello. Tiene sotto controllo il costo. */
const HISTORY_LIMIT = 40;
const MAX_MESSAGE_CHARS = 32_000;

interface ChatRequestBody {
  message?: unknown;
  agentId?: unknown;
  conversationId?: unknown;
}

export async function POST(request: Request) {
  const supabase = await createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();

  if (!user) {
    return NextResponse.json({ error: "Non autenticato." }, { status: 401 });
  }

  let body: ChatRequestBody;
  try {
    body = (await request.json()) as ChatRequestBody;
  } catch {
    return NextResponse.json({ error: "Body non valido." }, { status: 400 });
  }

  const text = typeof body.message === "string" ? body.message.trim() : "";
  if (!text) {
    return NextResponse.json(
      { error: "Il messaggio è vuoto." },
      { status: 400 },
    );
  }
  if (text.length > MAX_MESSAGE_CHARS) {
    return NextResponse.json(
      { error: "Messaggio troppo lungo." },
      { status: 413 },
    );
  }

  const agent = getAgent(
    typeof body.agentId === "string" ? body.agentId : undefined,
  );
  let conversationId =
    typeof body.conversationId === "string" ? body.conversationId : null;
  let createdNewConversation = false;
  let title = "";

  // --- conversazione ------------------------------------------------------
  if (conversationId) {
    // RLS impedisce di leggere conversazioni altrui: se non torna nulla,
    // o non esiste o non è di questo utente. In entrambi i casi: 404.
    const { data: existing } = await supabase
      .from("conversations")
      .select("id, title")
      .eq("id", conversationId)
      .maybeSingle();

    if (!existing) {
      return NextResponse.json(
        { error: "Conversazione non trovata." },
        { status: 404 },
      );
    }
    title = existing.title as string;
  } else {
    title = titleFromMessage(text);
    const { data: created, error } = await supabase
      .from("conversations")
      .insert({ user_id: user.id, agent_id: agent.id, title })
      .select("id, title")
      .single();

    if (error || !created) {
      return NextResponse.json(
        { error: "Impossibile creare la conversazione." },
        { status: 500 },
      );
    }
    conversationId = created.id as string;
    createdNewConversation = true;
  }

  // --- salva il messaggio dell'utente -------------------------------------
  const { error: insertError } = await supabase.from("messages").insert({
    conversation_id: conversationId,
    user_id: user.id,
    role: "user",
    content: text,
  });

  if (insertError) {
    return NextResponse.json(
      { error: "Impossibile salvare il messaggio." },
      { status: 500 },
    );
  }

  // --- storico da passare al modello --------------------------------------
  const { data: history } = await supabase
    .from("messages")
    .select("role, content")
    .eq("conversation_id", conversationId)
    .order("created_at", { ascending: true })
    .limit(HISTORY_LIMIT);

  const messages: ChatMessage[] = (history ?? []).map((m) => ({
    role: m.role as "user" | "assistant",
    content: m.content as string,
  }));

  // --- stream verso il browser (Server-Sent Events) -----------------------
  const encoder = new TextEncoder();
  const finalConversationId = conversationId;

  const stream = new ReadableStream<Uint8Array>({
    async start(controller) {
      const send = (payload: Record<string, unknown>) => {
        controller.enqueue(
          encoder.encode(`data: ${JSON.stringify(payload)}\n\n`),
        );
      };

      send({
        type: "meta",
        conversationId: finalConversationId,
        title,
        isNew: createdNewConversation,
        agentId: agent.id,
      });

      let answer = "";
      let model: string | null = null;
      let inputTokens: number | null = null;
      let outputTokens: number | null = null;
      let failed = false;

      try {
        for await (const chunk of streamAgentReply(
          agent.id,
          messages,
          request.signal,
        )) {
          switch (chunk.type) {
            case "thinking":
              send({ type: "thinking", text: chunk.text });
              break;
            case "text":
              answer += chunk.text;
              send({ type: "text", text: chunk.text });
              break;
            case "usage":
              model = chunk.model;
              inputTokens = chunk.inputTokens;
              outputTokens = chunk.outputTokens;
              send({
                type: "usage",
                model: chunk.model,
                inputTokens: chunk.inputTokens,
                outputTokens: chunk.outputTokens,
              });
              break;
            case "refusal":
              send({ type: "refusal", message: chunk.message });
              break;
            case "error":
              failed = true;
              send({ type: "error", message: chunk.message });
              break;
          }
        }
      } catch (error) {
        failed = true;
        send({
          type: "error",
          message:
            error instanceof Error ? error.message : "Errore imprevisto.",
        });
      }

      // Salviamo la risposta solo se c'è del testo. Un errore a metà stream
      // lascia comunque in memoria quanto è già stato generato.
      if (answer.trim()) {
        await supabase.from("messages").insert({
          conversation_id: finalConversationId,
          user_id: user.id,
          role: "assistant",
          content: answer,
          agent_id: agent.id,
          model,
          input_tokens: inputTokens,
          output_tokens: outputTokens,
        });

        // Forza l'aggiornamento di updated_at per l'ordinamento in sidebar.
        await supabase
          .from("conversations")
          .update({ agent_id: agent.id })
          .eq("id", finalConversationId);
      }

      send({ type: "done", saved: Boolean(answer.trim()), failed });
      controller.close();
    },
  });

  return new Response(stream, {
    headers: {
      "Content-Type": "text/event-stream; charset=utf-8",
      "Cache-Control": "no-cache, no-transform",
      Connection: "keep-alive",
      // Disattiva il buffering del proxy, altrimenti lo stream arriva tutto insieme.
      "X-Accel-Buffering": "no",
    },
  });
}
