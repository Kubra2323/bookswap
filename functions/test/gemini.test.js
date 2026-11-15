"use strict";
const test = require("node:test");
const assert = require("node:assert/strict");
const { buildPrompt, parseExplanation, callGemini } = require("../src/gemini");
const { fetchBookInfo } = require("../src/books");
const { isStudentEmail } = require("../src/students");

const range = {
  ok: true,
  low: 150,
  high: 190,
  median: 170,
  count: 5,
  offers: [120, 150, 170, 190, 250].map((p, i) => ({ id: String(i), priceTry: p })),
};
const ctx = { edition: "4th", range };

test("prompt contains only book facts and the calculated range", () => {
  const prompt = buildPrompt({
    book: { title: "Introduction to Algorithms", authors: ["Cormen"], isbn: "9780262046305" },
    edition: "4th",
    condition: "Good",
    range,
  });
  assert.match(prompt, /Introduction to Algorithms/);
  assert.match(prompt, /"low":150/);
  assert.doesNotMatch(prompt, /@/); // no email addresses
});

test("accepts a supported explanation", () => {
  const text = JSON.stringify({
    summary: "Based on 5 offers, copies of the 4th edition sell for about 150-190 TL.",
    caveats: ["Condition changes the price."],
  });
  const out = parseExplanation(text, ctx);
  assert.equal(out.caveats.length, 1);
});

test("rejects an explanation with a number we did not provide", () => {
  const text = JSON.stringify({ summary: "New price is 900 TL.", caveats: [] });
  assert.throws(() => parseExplanation(text, ctx), /Unsupported numbers/);
});

test("rejects invalid JSON and wrong shape", () => {
  assert.throws(() => parseExplanation("not json", ctx), /valid JSON/);
  assert.throws(() => parseExplanation('{"summary":1}', ctx), /wrong shape/);
});

test("callGemini sends the key in a header, not the URL", async () => {
  let seen;
  const fakeFetch = async (url, init) => {
    seen = { url, init };
    return {
      ok: true,
      json: async () => ({ candidates: [{ content: { parts: [{ text: "{}" }] } }] }),
    };
  };
  const out = await callGemini({ apiKey: "SECRET", prompt: "hi", fetchImpl: fakeFetch });
  assert.equal(out, "{}");
  assert.doesNotMatch(seen.url, /SECRET/);
  assert.equal(seen.init.headers["x-goog-api-key"], "SECRET");
});

test("callGemini throws on HTTP errors", async () => {
  const fakeFetch = async () => ({ ok: false, status: 429 });
  await assert.rejects(() => callGemini({ apiKey: "k", prompt: "p", fetchImpl: fakeFetch }), /429/);
});

test("fetchBookInfo maps Google Books metadata and handles not found", async () => {
  const found = async () => ({
    ok: true,
    json: async () => ({
      items: [{ volumeInfo: { title: "T", authors: ["A"], infoLink: "https://books.google.com/x" } }],
    }),
  });
  const info = await fetchBookInfo("9780262046305", found);
  assert.equal(info.title, "T");
  assert.equal(info.source, "Google Books");

  const empty = async () => ({ ok: true, json: async () => ({}) });
  assert.equal(await fetchBookInfo("9780262046305", empty), null);
});

test("student email rule", () => {
  assert.equal(isStudentEmail("a.b@agu.edu.tr"), true);
  assert.equal(isStudentEmail("a@ogr.agu.edu.tr"), true);
  assert.equal(isStudentEmail("a@gmail.com"), false);
  assert.equal(isStudentEmail("a@agu.edu.tr.evil.com"), false);
  assert.equal(isStudentEmail(undefined), false);
});
