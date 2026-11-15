# BookSwap

Second-hand textbooks for AGÜ students. The app helps students find the right edition and
gives a sourced price guide: ML Kit reads the book on the phone, Cloud Functions calculate
a price range from real listings, and Gemini only explains that range.

Course project for COMP 205. This repository is the **P1 skeleton + back-end + CI**.

## What works in P1

| Area | State |
| --- | --- |
| Email/password sign-in, university-email check, email verification | Code written and view-model unit tested; not yet run against a real Firebase project |
| Firestore listings: create, live list, search, mark as sold | Code written and view-model unit tested; not yet run against Firestore |
| Firestore security rules (users, books, listings, chats) | Written; not yet tested in the emulator |
| Cloud Function `getBookInfo` (Google Books + cache) | Implemented, unit tested with fakes |
| Cloud Function `getPriceGuide` (range from >= 3 offers + Gemini explanation) | Price logic and Gemini answer check unit tested; not run end to end |
| GitHub Actions CI (Flutter analyze/test, functions tests) | Working, green on GitHub |
| ISBN scan / OCR (ML Kit), chat, photos | Not started (Week 8+) |

Update this table with the real state before you submit.

## Architecture

```
lib/
  core/        validators (email, ISBN, price)
  models/      Listing, PriceGuide (plain Dart, no Firebase)
  data/        repositories: abstract interface + Firebase implementation
  viewmodels/  ChangeNotifier view models (Provider), tested with fake repositories
  views/       pages (login, home, sell)
functions/     Cloud Functions (Node 22): isbn, priceRange, gemini, books + index.js
firestore.rules, firestore.indexes.json, firebase.json
```

Rule of thumb: views know view models, view models know repository interfaces,
only repositories know Firebase. Provider keys never reach the app; Gemini is called from
Cloud Functions only. See `docs/adr/0001-backend-on-free-plan.md`.

## Setup (each team member)

1. Install Flutter, Node 22 and the Firebase CLI (`npm i -g firebase-tools`).
2. Create **your own** Firebase project on the free Spark plan. Never add a billing account.
   Enable Email/Password sign-in and Firestore (production mode).
3. `dart pub global activate flutterfire_cli` then `flutterfire configure`.
   This creates `lib/firebase_options.dart` and `google-services.json`. Both are git-ignored.
4. `flutter pub get`
5. Create an Android emulator **with Google Play**.

## Run against the local emulators (no billing)

```bash
cd functions && npm install && cd ..
echo "GEMINI_API_KEY=your-key" > functions/.secret.local    # git-ignored, optional
firebase emulators:start
flutter run --dart-define=USE_EMULATOR=true
```

The Auth emulator does not send real emails. Open the Emulator UI at http://localhost:4000,
find the user under Authentication and mark the email as verified there.

## Tests

```bash
flutter analyze && flutter test
cd functions && npm test
```

CI runs the same commands on every push and pull request.

## Security rules for the team

- `lib/firebase_options.dart`, `google-services.json`, `.secret.local` and API keys stay out of git.
- Never paste them or keys into an AI chat.
- Student names, emails, chats and interview notes are never sent to Gemini. 
