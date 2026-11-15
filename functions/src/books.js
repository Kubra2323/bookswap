"use strict";

// Looks up basic book metadata from Google Books by 13-digit ISBN.
// Returns null when the book is not found. Only metadata is kept, never book contents.
async function fetchBookInfo(isbn, fetchImpl = fetch) {
  const url = `https://www.googleapis.com/books/v1/volumes?q=isbn:${encodeURIComponent(isbn)}&maxResults=1`;
  const res = await fetchImpl(url);
  if (!res.ok) throw new Error(`Google Books HTTP ${res.status}`);
  const body = await res.json();
  const item = body.items && body.items[0];
  if (!item) return null;
  const v = item.volumeInfo || {};
  return {
    isbn,
    title: v.title || "",
    authors: Array.isArray(v.authors) ? v.authors : [],
    publisher: v.publisher || "",
    publishedDate: v.publishedDate || "",
    infoLink: v.infoLink || null,
    source: "Google Books",
  };
}

module.exports = { fetchBookInfo };
