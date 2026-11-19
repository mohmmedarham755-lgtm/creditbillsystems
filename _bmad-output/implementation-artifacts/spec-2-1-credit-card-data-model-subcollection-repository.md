---
title: 'Story 2.1: Credit Card Data Model, Subcollection & Repository'
type: 'feature'
created: '2026-10-14'
status: 'done'
route: 'dispatch'
review_loop_iteration: 1
baseline_commit: 'ee51fc453e6a8f322b86b64292cbca802e05ded7'
context:
  - _bmad-output/implementation-artifacts/epic-2-context.md
---

<frozen-after-approval reason="human-owned intent — do not modify unless human renegotiates">

## Intent

**Problem:** The cards feature has no domain model or Firestore repository, so credit card records cannot be represented and persisted according to Story 2.1.

**Approach:** Add the eight-field card model, repository contract and Firestore implementation scoped to `/users/{userId}/cards/{cardId}`. Test monetary double serialization in the card model and timestamp conversion in a separate Firestore timestamp mapper; do not add a timestamp field to `CardModel`.

## Boundaries & Constraints

**Always:** Preserve existing uncommitted work. Keep UI independent of Firestore. Scope card documents to the requested user subcollection. Enforce authenticated UID ownership in Firestore rules. Do not store full card numbers or CVVs. Keep `CardModel` limited to the eight fields specified in Story 2.1; test Firestore `Timestamp` ↔ `DateTime` conversion in a separate mapper, preserving values at Dart `DateTime` precision. Precision finer than `DateTime` supports may be lost.

**Never:** Implement later card-entry, display, editing, or deletion UI stories; add card fields or behaviors not approved for Story 2.1.

</frozen-after-approval>

## Code Map

- `lib/features/auth/domain/user_model.dart` -- existing domain model and map conversion example; it serializes dates as milliseconds, not Firestore timestamps.
- `lib/features/auth/domain/auth_repository.dart` -- repository contract belongs in Domain.
- `lib/features/auth/data/auth_repository_impl.dart` -- Firebase dependency injection and repository implementation example.
- `lib/core/constants/firestore_collections.dart` -- centralized `users` and `cards` collection names.
- `lib/core/errors/app_exceptions.dart` -- typed `DatabaseException` for persistence failures.
- `lib/features/cards/presentation/card_provider.dart` -- existing state placeholder; do not add provider CRUD/UI in this story.
- `test/features/auth/user_model_test.dart` -- current model serialization test style.
- `firebase.json` -- FlutterFire platform config only; no Firestore rules target is configured.
- `_bmad-output/planning-artifacts/architecture/architecture-creditbillsytems-2026-10-13/ARCHITECTURE-SPINE.md` -- requires pure-Dart Domain entities, Firestore mapping in Data, and authenticated user-scoped persistence.

## Tasks & Acceptance

**Execution:**
- [x] `lib/features/cards/domain/card_model.dart` -- define exactly the eight card fields listed in Story 2.1 as a Domain model.
- [x] `lib/features/cards/domain/card_model.dart` -- reject serialization of values that are not exactly four digits in `last4Digits`.
- [x] `lib/features/cards/domain/card_repository.dart` -- define CRUD contract scoped to a user ID.
- [x] `lib/features/cards/data/card_repository_impl.dart` -- implement CRUD under `/users/{userId}/cards/{cardId}` using injected Firestore and typed database errors.
- [x] `lib/features/cards/data/firestore_timestamp_mapper.dart` -- convert Firestore `Timestamp` to `DateTime` and `DateTime` to Firestore `Timestamp` independently of `CardModel`.
- [x] `test/features/cards/card_model_test.dart` -- verify the eight-field model serializes and deserializes monetary values as doubles.
- [x] `test/features/cards/data/firestore_timestamp_mapper_test.dart` -- verify timestamp value round-trip preservation through the separate mapper.
- [x] `firestore.rules` and `firebase.json` -- configure rules requiring authenticated UID ownership for user documents and their subcollections.

**Acceptance Criteria:**
- Given a card model, when instantiated, then it exposes `id`, `cardName`, `bankName`, `last4Digits`, `creditLimit`, `billingCycleDay`, `gracePeriodDays`, and `currentBalance`.
- Given a user ID and card operation, when repository CRUD executes, then every document read or written is confined to `/users/{userId}/cards/{cardId}`.
- Given card data with double monetary values, when serialized and deserialized, then values round-trip as doubles without adding timestamp fields to `CardModel`.
- Given a Firestore `Timestamp`, when converted to `DateTime` and back by the separate mapper, then its value is preserved at Dart `DateTime` precision; any sub-microsecond precision not representable by `DateTime` may be lost.
- Given a Firestore request for a user document or descendant, when the caller is unauthenticated or has a different UID, then the security rules deny access.

## Implementation Notes

- `CardModel.id` is supplied by the Firestore document path; only the other seven fields are stored in document data. Monetary values deserialize from Firestore numeric values as doubles.
- `CardRepositoryImpl` accepts an injected `FirebaseFirestore` instance and builds every operation from `/users/{userId}/cards`. Firebase and unexpected persistence failures are surfaced as `DatabaseException`.
- Firestore timestamp conversion lives in `FirestoreTimestampMapper`, not in `CardModel`.
- `CardModel.toMap` rejects `last4Digits` values that are not exactly four digits, preventing serialization of a full card number in that field.
- `firestore.rules` protects user documents and every descendant with authenticated UID ownership, and `firebase.json` points the Firebase CLI to those rules.

## Spec Change Log

- Resolved the Story 2.1 timestamp contract: keep timestamps out of `CardModel` and test Firestore `Timestamp` ↔ `DateTime` conversion in the separate mapper; update the epic acceptance criterion to match.
- Resolved the review's timestamp precision question: round-trip preservation is required at Dart `DateTime` precision; sub-microsecond precision loss is expected because `DateTime` cannot represent it.

## Review Triage Log

- `patch` — `firebase.json` had an extra closing brace, making the Firebase CLI configuration invalid; removed the extra brace and verified the JSON parses and points to `firestore.rules`.
- `medium` — `intent_gap` — `FirestoreTimestampMapper.toDateTime` converts nanosecond-precision Firestore timestamps to Dart `DateTime`, which only retains microsecond precision; converting back changes timestamps whose nanoseconds are not divisible by 1,000. The approved acceptance criterion does not define whether “value preserved” means exact Firestore precision or the precision representable by `DateTime`.
- `medium` — `patch` — `CardModel.toMap` persists `last4Digits` without checking that it contains only four digits, so a caller can pass and persist a full card number in that field despite the no-full-number constraint.
- `false` — The `.story21-review.diff` file was generated only as a temporary review artifact and is removed after review; it is not part of the product change.
- `medium` — `patch` — `CardModel.toMap` accepted arbitrary `last4Digits` values, allowing a full card number to be serialized; serialization now rejects anything other than exactly four digits.
- `medium` — `defer` — No tests exercise repository CRUD path selection or returned values; add these with the repository test harness.
- `medium` — `defer` — Firestore ownership rules have no emulator tests; add owner, unauthenticated, and cross-user cases when emulator test support is configured.
- `false` — Web configuration is not an approved platform in this story; the generated options explicitly report web unsupported, so the finding does not establish a Story 2.1 regression.
- `medium` — `defer` — Firebase initialization failures are logged and app startup continues, leaving Firebase-dependent features unavailable; this is outside Story 2.1.
- `medium` — `defer` — `AuthGate` does not use `AuthProvider.isInitialized`, so it can render login before the auth-state stream resolves; this is outside Story 2.1.
- `medium` — `defer` — Logout failures are caught and local auth state is cleared regardless, while the dashboard navigates to login; this is outside Story 2.1.
- `medium` — `defer` — Registration can leave a Firebase Auth account without its Firestore profile if profile creation fails; this is outside Story 2.1.
- `medium` — `defer` — Credit health tier tests omit the exact 30% and 50% boundaries defined for the calculator; this is outside Story 2.1.
- `false` — The approved Story 2.1 requirements do not define monetary or billing-cycle range validation; the cited entry-form constraints are specified for Story 2.2, not this repository/model story.
- `false` — The earlier timestamp precision finding is resolved: the approved criterion now explicitly permits precision finer than Dart `DateTime` to be lost.
- `medium` — `defer` — Repository CRUD path selection and behavior remain untested; no current repository test harness exists.
- `medium` — `defer` — The Firestore access-control acceptance has no automated emulator verification; the project currently has no rules test setup.
- `false` — The full-number finding is resolved by rejecting non-four-digit values during serialization. At the time this review note was recorded, the spec remained `in-review`; it was subsequently marked `done` after review and verification were complete.
- `resolved` — `test/features/cards/data/card_repository_impl_test.dart` now covers repository create, get (including absent and wrong-user documents), list scoping, update, delete, and Firestore error translation; all six tests pass using `fake_cloud_firestore`.
- `resolved` — `test/firestore.rules.test.cjs` exercises owner read/write success and unauthenticated/cross-UID read/write denial against the configured Firestore emulator; all three tests pass under `firebase emulators:exec`.

## Verification

**Commands:**
- `flutter analyze` -- passed; no analyzer issues.
- `flutter test` -- passed; all 61 tests passed.
- `flutter test test/features/cards/data/card_repository_impl_test.dart` -- passed; all 6 repository CRUD tests passed using `fake_cloud_firestore`.
- `npm run test:firestore-rules` -- passed; all 3 owner/unauthenticated/cross-UID tests passed using Firestore Emulator v1.22.0 via `firebase emulators:exec`.
- `node --test test/firestore.rules.test.cjs` -- passed; all 9 tests, including card deletion ownership checks, passed against the already-running local Firestore Emulator. `npm run test:firestore-rules` could not start another emulator because port 8080 was occupied.
- `npm run test:firestore-rules` -- passed; all 12 Firestore rules tests, including card field allowlisting and rejection of card subcollection writes, passed using a temporary emulator on port 8084 because the configured port 8081 was occupied. The configured port remains 8081.
- `flutter analyze` -- passed; no analyzer issues after completing the remaining model and rules tests.
- `flutter test` -- passed; all 63 tests passed.
- Firestore rules suite -- passed; all 13 tests passed against a temporary Firestore Emulator on port 8082. Port 8081 was occupied by an existing Firestore Emulator, and the suite clears its emulator database before each test, so it was not reused. The temporary emulator was stopped; persistent Firebase/test configuration remains on port 8081.
- `npm ls --depth=0` and lockfile metadata check -- passed; package-lock v3 root dependencies exactly match `package.json`, all 678 resolved packages with registry URLs have integrity hashes, and installed direct dependencies satisfy the declared ranges.
- Parsed `firebase.json` and confirmed existing FlutterFire configuration is preserved alongside the Firestore emulator and rules configuration.

**Review status:** The sprint still marks Story 2.1 as `review`; this verification pass does not promote it to done.

### Review Findings

- [x] [Review][Patch] Add Firestore rules emulator coverage for card deletion [test/firestore.rules.test.cjs:49-87]
- [x] [Review][Patch] Enforce card-field allowlisting in Firestore rules [firestore.rules:5-31]
- [x] [Review][Patch] Verify owner can create a valid card under Firestore rules [test/firestore.rules.test.cjs:58-66]
- [x] [Review][Patch] Assert exact card map fields and full-field round-trip [test/features/cards/card_model_test.dart:29-59]
- [x] [Review][Patch] Exercise Firestore card schema type rejection for every field [test/firestore.rules.test.cjs:113-129]
- [x] [Review][Patch] Reject non-digit last-four values in model tests [test/features/cards/card_model_test.dart:72-88]
- [x] [Review][Patch] Verify integer Firestore amounts deserialize as doubles [test/features/cards/card_model_test.dart:61-70]
- [x] [Review][Patch] Guard Firestore test cleanup when environment setup fails [test/firestore.rules.test.cjs:52-56]

**Rejected**
- `false` — Replacing monetary doubles with minor units conflicts with the approved double-serialization contract; this chunk implements no monetary arithmetic.
- `false` — Validating financial and billing-cycle ranges is assigned to Story 2.2, not Story 2.1.
- `false` — `FormatException` is surfaced inside a `DatabaseException` with its error text; the spec requires unexpected persistence failures to be surfaced as `DatabaseException`.
- `false` — Updating replaces unknown document fields, but this behavior is explicitly asserted by the repository test and the approved model persists only its defined fields.
- `false` — `npm test` is scoped to the Node Firestore rules suite; Flutter unit tests are run using the distinct `flutter test` command, so the package script does not claim to run both ecosystems.
- `resolved` — The Firestore test cleanup hook now checks that environment initialization completed before cleanup; cleanup failures after successful initialization still propagate.
