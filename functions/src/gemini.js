"use strict";

// The prompt contains only book facts and the range our code already calculated.
// Never add names, emails, chats or interview notes here (P0: nothing personal goes to Gemini).
function buildPrompt({ book, edition, condition, range }) {
  const facts = {
    title: (book && book.title) || null,
    authors: (book && book.authors) || [],
    edition,
    condition: condition || null,
    currency: "TRY",
    range: { low: range.low, high: range.high, median: range.median },
    offerCount: range.count,
    offerPrices: range.offers.map((o) => o.priceTry),
  };
  return [
    "You explain a used-textbook price range to a student.",
    "Use ONLY the facts in the JSON below. Do not add any other number, price, book or website.",
    "Do not change the range. Do not say the price is guaranteed.",
    'Reply as JSON: {"summary": string (max 60 words), "caveats": string[] (max 3 short items)}.',
    "FACTS:",
    JSON.stringify(facts),
  ].join("\n");
}

function numbersIn(text) {
  return (String(text).match(/\d+(?:[.,]\d+)?/g) || []).map((n) => Number(n.replace(",", ".")));
}

function allowedNumbers({ edition, range }) {
  const set = new Set([range.low, range.high, range.median, range.count]);
  for (const o of range.offers) set.add(o.priceTry);
  for (const n of numbersIn(edition)) set.add(n);
  return set;
}

// Parses Gemini's JSON and rejects answers that contain numbers we did not give it.
// Returns { summary, caveats } or throws. The caller then falls back to "range only" (plan B).
function parseExplanation(text, { edition, range }) {
  let obj;
  try {
    obj = JSON.parse(text);
  } catch (e) {
    throw new Error("Gemini did not return valid JSON");
  }
  if (!obj || typeof obj.summary !== "string" || !Array.isArray(obj.caveats)) {
    throw new Error("Gemini JSON has the wrong shape");
  }
  const caveats = obj.caveats.filter((c) => typeof c === "string").slice(0, 3);
  const allowed = allowedNumbers({ edition, range });
  const bad = numbersIn([obj.summary, ...caveats].join(" ")).filter((n) => !allowed.has(n));
  if (bad.length > 0) throw new Error(`Unsupported numbers in answer: ${bad.join(", ")}`);
  return { summary: obj.summary.trim(), caveats };
}

async function callGemini({ apiKey, prompt, model, fetchImpl = fetch }) {
  const name = model || process.env.GEMINI_MODEL || "gemini-2.5-flash";
  const res = await fetchImpl(
    `https://generativelanguage.googleapis.com/v1beta/models/${name}:generateContent`,
    {
      method: "POST",
      headers: { "Content-Type": "application/json", "x-goog-api-key": apiKey },
      body: JSON.stringify({
        contents: [{ role: "user", parts: [{ text: prompt }] }],
        generationConfig: { responseMimeType: "application/json", temperature: 0.2 },
      }),
    },
  );
  if (!res.ok) throw new Error(`Gemini HTTP ${res.status}`);
  const body = await res.json();
  const text = body.candidates && body.candidates[0] && body.candidates[0].content &&
    body.candidates[0].content.parts && body.candidates[0].content.parts[0] &&
    body.candidates[0].content.parts[0].text;
  if (!text) throw new Error("Gemini returned no text");
  return text;
}

module.exports = { buildPrompt, parseExplanation, callGemini, numbersIn };
