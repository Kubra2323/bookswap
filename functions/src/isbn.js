"use strict";

// Returns a valid 13-digit ISBN string, or null if the input is not a valid ISBN-10/13.
function normalizeIsbn(input) {
  if (typeof input !== "string") return null;
  const cleaned = input.replace(/[\s-]/g, "").toUpperCase();
  if (/^\d{13}$/.test(cleaned)) return isValidIsbn13(cleaned) ? cleaned : null;
  if (/^\d{9}[\dX]$/.test(cleaned)) return isValidIsbn10(cleaned) ? isbn10To13(cleaned) : null;
  return null;
}

function isValidIsbn13(s) {
  if (!/^97[89]\d{10}$/.test(s)) return false;
  let sum = 0;
  for (let i = 0; i < 12; i++) sum += Number(s[i]) * (i % 2 === 0 ? 1 : 3);
  return (10 - (sum % 10)) % 10 === Number(s[12]);
}

function isValidIsbn10(s) {
  let sum = 0;
  for (let i = 0; i < 10; i++) {
    const v = s[i] === "X" ? 10 : Number(s[i]);
    if (s[i] === "X" && i !== 9) return false;
    sum += v * (10 - i);
  }
  return sum % 11 === 0;
}

function isbn10To13(s10) {
  const body = "978" + s10.slice(0, 9);
  let sum = 0;
  for (let i = 0; i < 12; i++) sum += Number(body[i]) * (i % 2 === 0 ? 1 : 3);
  return body + String((10 - (sum % 10)) % 10);
}

module.exports = { normalizeIsbn, isValidIsbn13, isValidIsbn10, isbn10To13 };
