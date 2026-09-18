import { test } from "node:test";
import assert from "node:assert/strict";

import { PRO_AMOUNT, PRO_CURRENCY, proLineItem } from "../lib/catalog.js";

test("with no price id, the product describes itself — icon and all", () => {
  const item = proLineItem({ image: "https://example.com/improvy-pro.png" });
  assert.equal(item.price, undefined);
  assert.equal(item.quantity, 1);
  assert.equal(item.price_data.unit_amount, PRO_AMOUNT);
  assert.equal(item.price_data.currency, PRO_CURRENCY);
  assert.deepEqual(item.price_data.product_data.images, ["https://example.com/improvy-pro.png"]);
  assert.match(item.price_data.product_data.name, /Improvy Pro/);
});

test("the price is 19,99 € and nothing else", () => {
  assert.equal(PRO_AMOUNT, 1999);
  assert.equal(PRO_CURRENCY, "eur");
});

test("a price id from the catalogue wins, and carries nothing else", () => {
  const item = proLineItem({ priceId: "price_123", image: "https://example.com/x.png" });
  assert.deepEqual(item, { price: "price_123", quantity: 1 });
});

test("without an image the field is left out, not sent empty", () => {
  const item = proLineItem({});
  assert.equal("images" in item.price_data.product_data, false);
});

test("Stripe Tax needs the price to say tax is already in it", () => {
  assert.equal(proLineItem({ tax: true }).price_data.tax_behavior, "inclusive");
  assert.equal("tax_behavior" in proLineItem({ tax: false }).price_data, false);
});
