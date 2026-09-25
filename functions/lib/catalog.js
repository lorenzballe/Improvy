/**
 * What is being sold, and how Stripe should be told about it.
 *
 * Kept here, and pure, for two reasons. The obvious one is that it can be
 * tested without Stripe. The other is that the checkout page people see —
 * the name, the line under it, the icon on the right — is part of the
 * product, and a product ought to be described in one place rather than
 * typed into a dashboard where nobody reviews it.
 */

/**
 * Eighteen ninety-nine, in the smallest unit Stripe counts in: a euro under
 * the 19,99 € both stores charge, because here nobody takes 15–30%.
 */
export const PRO_AMOUNT = 1899;
export const PRO_CURRENCY = "eur";

export const PRO_NAME = "Improvy Pro";
export const PRO_DESCRIPTION =
  "Lifetime unlock — Chromatic Mode in all 12 keys, every degree in every mode, Custom Mode, adaptive difficulty and deep analytics. One payment, on your account, on any phone.";

/**
 * The single line of the checkout.
 *
 * A price id from the Stripe catalogue wins when there is one, because then
 * the dashboard is the source of truth and reporting groups by product. With
 * no id — which is the default, and one less thing to set up — the price is
 * described inline, and that is what puts the app's own icon on the checkout
 * page instead of a grey placeholder.
 *
 * [image] must be a public https URL: Stripe fetches it from its own servers,
 * so anything behind a login shows as nothing at all.
 *
 * With Stripe Tax on, a price has to say whether tax is already in it.
 * "inclusive" is the honest answer for 18,99 € — that is the number the site
 * advertises and the number the buyer pays.
 */
export function proLineItem({ priceId, image, tax = false } = {}) {
  if (priceId) return { price: priceId, quantity: 1 };
  return {
    quantity: 1,
    price_data: {
      currency: PRO_CURRENCY,
      unit_amount: PRO_AMOUNT,
      ...(tax ? { tax_behavior: "inclusive" } : {}),
      product_data: {
        name: PRO_NAME,
        description: PRO_DESCRIPTION,
        ...(image ? { images: [image] } : {}),
      },
    },
  };
}

