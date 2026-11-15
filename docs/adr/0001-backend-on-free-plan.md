# ADR 0001: Back-end on the free Firebase plan

**Status:** Proposed (the team must confirm this before P1 is submitted)

## Context

The course rule is to use the free Spark plan and never add a billing account.
Our P0 architecture uses Firebase Auth, Firestore, Cloud Storage for book photos and
Cloud Functions to call Gemini. As far as I know, deploying Cloud Functions and creating
a new default Cloud Storage bucket need the paid Blaze plan, so these two parts may not
be deployable on Spark. Check this in the Firebase console of our own project.

## Decision (proposed)

1. Auth and Firestore (with security rules) run on Spark. They are deployed for real.
2. Cloud Functions run on the Firebase Emulator Suite for P1 and for the demo
   (`firebase emulators:start`, app started with `--dart-define=USE_EMULATOR=true`).
   The code is deploy-ready; deploying needs a billing account, which we do not add.
3. Book photos are stored as small compressed images in Firestore, as taught in Week 7,
   instead of Cloud Storage. Not part of the P1 skeleton.

## Consequences

- No billing risk, and every team member can run the full back-end locally.
- The Gemini call works only while the emulator runs with a local `GEMINI_API_KEY`
  (`functions/.secret.local`, git-ignored). Plan B from P0 stays: if the call fails, the
  app still shows the calculated range or lets the student type a price.
- If the instructor allows a deployed back-end, only step 2 changes.
