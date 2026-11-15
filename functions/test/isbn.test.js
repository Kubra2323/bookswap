"use strict";
const test = require("node:test");
const assert = require("node:assert/strict");
const { normalizeIsbn, isbn10To13 } = require("../src/isbn");

test("accepts a valid ISBN-13 with hyphens", () => {
  assert.equal(normalizeIsbn("978-0-262-04630-5"), "9780262046305");
});

test("converts a valid ISBN-10 to ISBN-13", () => {
  assert.equal(normalizeIsbn("0306406152"), "9780306406157");
  assert.equal(isbn10To13("0306406152"), "9780306406157");
});

test("accepts ISBN-10 ending with X", () => {
  assert.equal(normalizeIsbn("080442957X"), "9780804429573");
});

test("rejects a wrong checksum", () => {
  assert.equal(normalizeIsbn("9780262046306"), null);
  assert.equal(normalizeIsbn("0306406153"), null);
});

test("rejects non-ISBN input", () => {
  assert.equal(normalizeIsbn(""), null);
  assert.equal(normalizeIsbn("hello"), null);
  assert.equal(normalizeIsbn(null), null);
  assert.equal(normalizeIsbn(12345), null);
});
