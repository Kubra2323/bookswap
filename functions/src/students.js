"use strict";

// Same rule as lib/core/validators.dart and firestore.rules. Keep all three in sync.
const STUDENT_EMAIL = /^[a-z0-9._%+-]+@(ogr\.)?agu\.edu\.tr$/i;

function isStudentEmail(email) {
  return typeof email === "string" && STUDENT_EMAIL.test(email);
}

module.exports = { isStudentEmail };
