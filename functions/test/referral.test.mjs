import { test } from "node:test";
import assert from "node:assert/strict";
import { cleanRef } from "../lib/referral.js";

test("a creator slug is kept, lower-cased", () => {
  assert.equal(cleanRef("Marco_Jazz"), "marco_jazz");
  assert.equal(cleanRef("  pianotips-2 "), "pianotips-2");
});

test("anything that is not a short slug is dropped, never stored", () => {
  for (const bad of [undefined, null, 42, "", "a", "x".repeat(33), "has space", "<script>", "a/b", "-lead"]) {
    assert.equal(cleanRef(bad), null, String(bad));
  }
});
