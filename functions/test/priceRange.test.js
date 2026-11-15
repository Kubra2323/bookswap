"use strict";
const test = require("node:test");
const assert = require("node:assert/strict");
const { computeRange } = require("../src/priceRange");

const offer = (id, priceTry, edition = "4th") => ({ id, priceTry, edition, currency: "TRY" });

test("returns no estimate with fewer than 3 matching offers", () => {
  const r = computeRange([offer("a", 150), offer("b", 180)], { edition: "4th" });
  assert.equal(r.ok, false);
  assert.equal(r.reason, "not_enough_offers");
  assert.equal(r.count, 2);
});

test("ignores offers of another edition", () => {
  const offers = [offer("a", 150), offer("b", 180), offer("c", 200, "3rd")];
  const r = computeRange(offers, { edition: "4th" });
  assert.equal(r.ok, false);
  assert.equal(r.count, 2);
});

test("edition is required", () => {
  const r = computeRange([offer("a", 1), offer("b", 2), offer("c", 3)], { edition: "  " });
  assert.equal(r.ok, false);
  assert.equal(r.reason, "edition_required");
});

test("calculates low, median and high from 5 offers", () => {
  const offers = [120, 150, 170, 190, 250].map((p, i) => offer(String(i), p));
  const r = computeRange(offers, { edition: "4th" });
  assert.equal(r.ok, true);
  assert.equal(r.count, 5);
  assert.equal(r.low, 150);
  assert.equal(r.median, 170);
  assert.equal(r.high, 190);
});

test("edition matching ignores case and spaces", () => {
  const offers = [offer("a", 100, " 4TH "), offer("b", 110, "4th"), offer("c", 120, "4Th")];
  assert.equal(computeRange(offers, { edition: "4th" }).ok, true);
});

test("skips invalid prices and other currencies", () => {
  const offers = [
    offer("a", 100),
    offer("b", 110),
    offer("c", 120),
    offer("d", -5),
    offer("e", NaN),
    { ...offer("f", 9), currency: "USD" },
  ];
  const r = computeRange(offers, { edition: "4th" });
  assert.equal(r.ok, true);
  assert.equal(r.count, 3);
});
