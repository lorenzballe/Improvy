/**
 * Which creator sent a buyer, as a name safe to store and to show.
 *
 * It arrives from a link (improvy.app/?ref=marco) that anyone can edit, so it
 * is treated as untrusted text: lower-cased, and refused unless it is a short
 * slug. A refused ref is simply absent — a sale is never lost over it.
 */
const SHAPE = /^[a-z0-9][a-z0-9_-]{1,31}$/;

export function cleanRef(value) {
  if (typeof value !== "string") return null;
  const v = value.trim().toLowerCase();
  return SHAPE.test(v) ? v : null;
}
