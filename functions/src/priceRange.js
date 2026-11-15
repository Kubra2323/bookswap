"use strict";

const MIN_OFFERS = 3;

function norm(s) {
  return String(s || "").trim().toLowerCase();
}

// Linear-interpolated percentile of an ascending-sorted array.
function percentile(sorted, p) {
  const idx = (sorted.length - 1) * p;
  const lo = Math.floor(idx);
  const hi = Math.ceil(idx);
  return sorted[lo] + (sorted[hi] - sorted[lo]) * (idx - lo);
}

/**
 * Calculates a used-book price range from real offers. Pure code, no AI:
 * the AI only explains this result, it never invents the numbers.
 *
 * offers: [{ id, priceTry, edition, condition, currency, createdAt }]
 * Returns { ok: true, low, high, median, count, offers } or
 *         { ok: false, reason, count } (never an invented range).
 */
function computeRange(offers, { edition, minOffers = MIN_OFFERS } = {}) {
  if (!norm(edition)) return { ok: false, reason: "edition_required", count: 0 };

  const usable = (offers || []).filter(
    (o) =>
      o &&
      Number.isFinite(o.priceTry) &&
      o.priceTry > 0 &&
      (o.currency || "TRY") === "TRY" &&
      norm(o.edition) === norm(edition),
  );

  if (usable.length < minOffers) {
    return { ok: false, reason: "not_enough_offers", count: usable.length };
  }

  const prices = usable.map((o) => o.priceTry).sort((a, b) => a - b);
  return {
    ok: true,
    low: Math.floor(percentile(prices, 0.25)),
    high: Math.ceil(percentile(prices, 0.75)),
    median: Math.round(percentile(prices, 0.5)),
    count: usable.length,
    offers: usable,
  };
}

module.exports = { computeRange, percentile, MIN_OFFERS };
