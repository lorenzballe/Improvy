import { Fragment, type ReactNode } from "react";

/**
 * Renderer markdown minimale.
 *
 * Costruisce nodi React, non HTML: niente `dangerouslySetInnerHTML`, quindi
 * nessun rischio di injection da quello che scrive il modello.
 * Copre ciò che l'AI usa davvero: blocchi di codice, code inline, grassetto,
 * corsivo, titoli, elenchi. Se in futuro serve markdown completo, si sostituisce
 * questo file con `react-markdown` senza toccare il resto.
 */

const FENCE = /```(\w+)?\n([\s\S]*?)```/g;

export function Markdown({ text }: { text: string }) {
  const blocks: ReactNode[] = [];
  let cursor = 0;
  let key = 0;

  for (const match of text.matchAll(FENCE)) {
    const start = match.index ?? 0;
    if (start > cursor) {
      blocks.push(
        <Fragment key={key++}>{renderText(text.slice(cursor, start))}</Fragment>,
      );
    }
    blocks.push(
      <pre key={key++}>
        <code>{match[2].replace(/\n$/, "")}</code>
      </pre>,
    );
    cursor = start + match[0].length;
  }

  if (cursor < text.length) {
    blocks.push(
      <Fragment key={key++}>{renderText(text.slice(cursor))}</Fragment>,
    );
  }

  return <>{blocks}</>;
}

/** Righe normali: titoli, elenchi, paragrafi. */
function renderText(chunk: string): ReactNode[] {
  const out: ReactNode[] = [];
  const lines = chunk.split("\n");

  let listItems: ReactNode[] = [];
  let listOrdered = false;
  let key = 0;

  const flushList = () => {
    if (listItems.length === 0) return;
    const items = listItems;
    listItems = [];
    out.push(
      listOrdered ? (
        <ol key={key++} className="my-2 list-decimal space-y-1 pl-5">
          {items}
        </ol>
      ) : (
        <ul key={key++} className="my-2 list-disc space-y-1 pl-5">
          {items}
        </ul>
      ),
    );
  };

  for (const line of lines) {
    const bullet = /^\s*[-*]\s+(.*)$/.exec(line);
    const numbered = /^\s*\d+[.)]\s+(.*)$/.exec(line);
    const heading = /^(#{1,4})\s+(.*)$/.exec(line);

    if (bullet) {
      if (listOrdered) flushList();
      listOrdered = false;
      listItems.push(<li key={key++}>{inline(bullet[1])}</li>);
      continue;
    }

    if (numbered) {
      if (!listOrdered) flushList();
      listOrdered = true;
      listItems.push(<li key={key++}>{inline(numbered[1])}</li>);
      continue;
    }

    flushList();

    if (heading) {
      const size =
        heading[1].length === 1
          ? "text-lg"
          : heading[1].length === 2
            ? "text-base"
            : "text-sm";
      out.push(
        <p key={key++} className={`mt-3 mb-1 font-semibold ${size}`}>
          {inline(heading[2])}
        </p>,
      );
      continue;
    }

    if (line.trim() === "") {
      out.push(<div key={key++} className="h-2" />);
      continue;
    }

    out.push(
      <p key={key++} className="my-1 leading-relaxed">
        {inline(line)}
      </p>,
    );
  }

  flushList();
  return out;
}

/** Formattazione dentro una riga: `code`, **grassetto**, *corsivo*. */
const INLINE = /(`[^`]+`|\*\*[^*]+\*\*|\*[^*\n]+\*)/g;

function inline(line: string): ReactNode[] {
  const parts = line.split(INLINE).filter((p) => p !== "");

  return parts.map((part, i) => {
    if (part.startsWith("`") && part.endsWith("`") && part.length > 2) {
      return <code key={i}>{part.slice(1, -1)}</code>;
    }
    if (part.startsWith("**") && part.endsWith("**") && part.length > 4) {
      return (
        <strong key={i} className="font-semibold">
          {part.slice(2, -2)}
        </strong>
      );
    }
    if (part.startsWith("*") && part.endsWith("*") && part.length > 2) {
      return <em key={i}>{part.slice(1, -1)}</em>;
    }
    return <Fragment key={i}>{part}</Fragment>;
  });
}
