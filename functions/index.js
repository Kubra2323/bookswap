"use strict";

const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { setGlobalOptions } = require("firebase-functions/v2");
const { defineSecret } = require("firebase-functions/params");
const admin = require("firebase-admin");

const { normalizeIsbn } = require("./src/isbn");
const { computeRange } = require("./src/priceRange");
const { buildPrompt, parseExplanation, callGemini } = require("./src/gemini");
const { isStudentEmail } = require("./src/students");
const { fetchBookInfo } = require("./src/books");

admin.initializeApp();
setGlobalOptions({ region: "europe-west1", maxInstances: 5 });

// Stored as a Secret Manager secret on deploy, or in functions/.secret.local for the emulator.
// It never reaches the Flutter app and never goes into git.
const geminiKey = defineSecret("GEMINI_API_KEY");
const db = admin.firestore();

const CACHE_TTL_MS = 7 * 24 * 60 * 60 * 1000; // TODO(P2): confirm Google Books caching terms.

function requireStudent(request) {
  const token = request.auth && request.auth.token;
  if (!token) throw new HttpsError("unauthenticated", "Sign in first.");
  if (!isStudentEmail(token.email) || token.email_verified !== true) {
    throw new HttpsError("permission-denied", "A verified university email is required.");
  }
}

function readIsbn(data) {
  const isbn = normalizeIsbn(data && data.isbn);
  if (!isbn) throw new HttpsError("invalid-argument", "Invalid ISBN.");
  return isbn;
}

async function cachedBookInfo(isbn) {
  const ref = db.collection("books").doc(isbn);
  const snap = await ref.get();
  if (snap.exists) {
    const d = snap.data();
    const age = Date.now() - (d.fetchedAt ? d.fetchedAt.toMillis() : 0);
    if (age < CACHE_TTL_MS) return d;
  }
  const info = await fetchBookInfo(isbn);
  if (!info) return null;
  await ref.set({ ...info, fetchedAt: admin.firestore.FieldValue.serverTimestamp() });
  return info;
}

exports.getBookInfo = onCall(async (request) => {
  requireStudent(request);
  const isbn = readIsbn(request.data);
  const info = await cachedBookInfo(isbn);
  if (!info) throw new HttpsError("not-found", "Book not found. Enter the details by hand.");
  const { fetchedAt, ...publicInfo } = info; // eslint-disable-line no-unused-vars
  return publicInfo;
});

exports.getPriceGuide = onCall({ secrets: [geminiKey] }, async (request) => {
  requireStudent(request);
  const isbn = readIsbn(request.data);
  const edition = String((request.data && request.data.edition) || "").trim().slice(0, 40);
  const condition = String((request.data && request.data.condition) || "").trim().slice(0, 20);

  // Real, non-demo, active listings only. Demo data never feeds prices (P0 plan B, risk 2).
  const snap = await db
    .collection("listings")
    .where("isbn", "==", isbn)
    .where("status", "==", "active")
    .where("isDemo", "==", false)
    .limit(50)
    .get();

  const offers = snap.docs.map((doc) => {
    const x = doc.data();
    return {
      id: doc.id,
      priceTry: x.priceTry,
      edition: x.edition,
      condition: x.condition,
      currency: "TRY",
      createdAt: x.createdAt && x.createdAt.toDate ? x.createdAt.toDate().toISOString() : null,
    };
  });

  const range = computeRange(offers, { edition });
  if (!range.ok) {
    // Fewer than 3 matching offers: no estimate, no invented range.
    return { estimate: null, reason: range.reason, offersFound: range.count, sources: [] };
  }

  let book = null;
  try {
    book = await cachedBookInfo(isbn);
  } catch (err) {
    console.warn("book info unavailable", err.message);
  }

  let explanation = null;
  try {
    const text = await callGemini({
      apiKey: geminiKey.value(),
      prompt: buildPrompt({ book, edition, condition, range }),
    });
    explanation = parseExplanation(text, { edition, range });
  } catch (err) {
    // Plan B: still return the calculated range if Gemini fails or says something unsupported.
    console.warn("gemini explanation skipped", err.message);
  }

  return {
    estimate: { low: range.low, high: range.high, median: range.median, currency: "TRY" },
    offersUsed: range.count,
    explanation,
    sources: range.offers.map((o) => ({ listingId: o.id, priceTry: o.priceTry, date: o.createdAt })),
    bookSource: book && book.infoLink ? { title: book.title, url: book.infoLink } : null,
  };
});
