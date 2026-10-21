---
title: 'Story 2.2: Add New Credit Card with Input Validation'
type: 'feature'
created: '2026-10-15'
status: 'in-review'
route: 'dispatch'
review_loop_iteration: 0
baseline_commit: 'ee51fc453e6a8f322b86b64292cbca802e05ded7'
context:
  - _bmad-output/implementation-artifacts/epic-2-context.md
---

<frozen-after-approval reason="human-owned intent — do not modify unless human renegotiates">

## Intent

**Problem:** Authenticated cardholders cannot enter a credit card through the app, so the card model and user-scoped repository implemented in Story 2.1 are not reachable through a user workflow.

**Approach:** Provide an Add Card modal form from the Dashboard, validate privacy-safe card details before saving, and create the card through the domain repository for the authenticated user. A successful save adds the persisted card to `CardProvider`.

## Boundaries & Constraints

**Always:** Persist only nickname, bank name, last four digits, credit limit, billing cycle day, grace period, and current balance. Require an authenticated UID and use the existing `/users/{uid}/cards` repository path. Keep widgets independent of Firestore, use Provider state and typed application errors, and never request or persist a full card number, CVV, PIN, or magnetic-stripe data. Initialize a newly entered card's current balance to `0.0`.

**Never:** Implement card portfolio display, card editing/deletion, bill entry, or unrelated dashboard/auth changes. Do not alter Firebase emulator configuration or Firestore rules unless investigation proves the Story 2.2 behavior requires it.

**Approved validation decisions:** Card nickname and bank name are both required. Grace period days must be a non-negative integer; no maximum is imposed because no upper limit is defined by the story.

## I/O & Edge-Case Matrix

| Scenario | Input / State | Expected Output / Behavior | Error Handling |
|----------|--------------|---------------------------|----------------|
| Valid card | All approved fields valid; authenticated user | Save through repository; include returned ID in provider state; close form and confirm success | N/A |
| Invalid fields | Non-positive/invalid limit, cycle day outside 1–31, or last-four value not exactly four digits | Keep form open and do not call repository | Inline validation errors |
| Sensitive value | Full card number or CVV entered into the last-four field | Reject unless it is exactly four numeric characters; provide no full-number/CVV field | Inline validation error |
| Persistence failure | Valid form; repository returns an application error | Keep form open and preserve entered values | Show a user-facing error; clear loading state |

</frozen-after-approval>

## Code Map

- `_bmad-output/planning-artifacts/epics.md:209-221` — Story 2.2 acceptance criteria: modal entry, limit > 0, cycle day 1–31, exactly four numeric last digits, no PAN/CVV, Firestore save and provider update.
- `_bmad-output/planning-artifacts/prds/prd-creditbillsytems-2026-10-13/prd.md:137-143` — FR-4 repeats the input constraints, user-scoped document creation, and dashboard-limit update.
- `_bmad-output/planning-artifacts/ux-designs/ux-creditbillsytems-2026-10-13/EXPERIENCE.md:100-105,146-150` — Dashboard Add Card CTA and onboarding form flow.
- `_bmad-output/implementation-artifacts/spec-2-1-credit-card-data-model-subcollection-repository.md` — completed prerequisite; model, repository, rules, and test conventions. No separate Design Notes section exists.
- `lib/features/cards/domain/card_model.dart` — eight fields, map serialization, and exact four-digit validation; use current balance `0.0` for new cards.
- `lib/features/cards/domain/card_repository.dart` and `lib/features/cards/data/card_repository_impl.dart` — inject the repository contract; `createCard` returns the generated ID and writes under the authenticated user's cards subcollection.
- `lib/features/cards/presentation/card_provider.dart` — currently contains totals/loading/error only; extend it to own newly created cards and add state.
- `lib/features/auth/presentation/auth_provider.dart` — exposes nullable authenticated `userId`; do not accept a user ID from form input.
- `lib/main.dart` — global provider registration/composition root; keep any concrete repository wiring here rather than in widgets.
- `lib/features/dashboard/presentation/dashboard_shell_screen.dart` — Dashboard tab is a placeholder and has no Add Card action; add the entry point here without building the later portfolio UI.
- `lib/features/auth/presentation/register_screen.dart` and `lib/core/theme/app_theme.dart` — existing `Form`/`TextFormField` and Material 3 styling patterns.
- `test/features/cards/data/card_repository_impl_test.dart`, `test/features/cards/card_model_test.dart`, and `test/features/auth/register_screen_test.dart` — persistence, model, and widget-test patterns to extend or follow.
- `firestore.rules` — already allowlists safe card fields and enforces four numeric last digits; preserve these rules and user ownership.

## Tasks & Acceptance

**Execution:**
- [x] `lib/features/cards/presentation/add_card_bottom_sheet.dart` — implement the modal form and client validation, without PAN/CVV inputs.
- [x] `lib/features/cards/presentation/card_provider.dart` and `lib/main.dart` — inject the repository contract, persist for the authenticated user, track the returned card, and expose loading/error/success state.
- [x] `lib/features/dashboard/presentation/dashboard_shell_screen.dart` — expose the Add Card modal entry point from Dashboard.
- [x] `test/features/cards/add_card_bottom_sheet_test.dart` — cover form validation, privacy constraints, successful save, and visible save failure.
- [x] `test/features/cards/card_provider_test.dart` — cover repository success, returned ID/provider state, authenticated user scoping, loading, and error cleanup.

**Acceptance Criteria:**
- Given an authenticated user opens Add Card, when valid nickname, bank, last four digits, positive credit limit, cycle day 1–31, and grace period are entered and Save is tapped, then the card is stored through the repository under that user's cards subcollection and appears in `CardProvider`.
- Given invalid credit limit, cycle day, or last four digits, when Save is tapped, then inline validation prevents the repository call.
- Given the Add Card form, when the user supplies a full card number or CVV, then no such value is requested or persisted and invalid last-four input is rejected.
- Given a repository failure during save, when the operation completes, then the form remains usable, loading clears, and a user-facing error is shown.

## Implementation Notes

## Verification

**Commands:**
- `flutter analyze` — passed; no analyzer issues.
- `flutter test test/features/cards/add_card_bottom_sheet_test.dart test/features/cards/card_provider_test.dart` — passed; all focused Add Card tests pass.
- `flutter test` — passed; all 75 tests passed after the review fixes.
- `git diff --check` — no whitespace errors in tracked changes; Git emitted only existing LF-to-CRLF working-tree warnings.

## Review Triage Log

| Finding | Verdict | Evidence and route |
|---|---|---|
| Blind Hunter 1: Previously saved cards are not loaded into provider state. | false | Story 2.2 requires the newly saved card to enter `CardProvider`; listing/restoring the portfolio belongs to Story 2.3 and is not part of this form flow. |
| Blind Hunter 2: App-scoped provider retained cards after account changes or an in-flight prior-user save. | medium — patched | `CardProvider` now clears user-scoped state on auth changes/sign-out and ignores stale create completions by generation; account-switch and pending-create tests pass. |
| Blind Hunter 3: `addCard` discarded totals established by `updateTotals`. | medium — patched | It now applies saved-card limit/balance deltas to existing totals; regression coverage verifies add and replacement behavior. |
| Blind Hunter 4: A previous save error remained visible after reopening the form. | low — patched | The modal entry point clears provider error state; widget coverage verifies the reopened sheet has no stale error. |
| Blind Hunter 5: Dashboard still shows placeholder content after saving instead of a card portfolio. | false | Story 2.2 requires provider state, while card portfolio display is explicitly reserved for Story 2.3. |
| Blind Hunter 6: Bills and Calendar tabs remain placeholders. | false | These pre-existing surfaces are unrelated to the Add Card acceptance criteria and were not changed for this story. |
| Blind Hunter 7: Firebase initialization failures are logged and startup continues. | medium — defer | The behavior predates Story 2.2 and affects general startup rather than card entry; recorded in `deferred-work.md`. |
| Blind Hunter 8: Firebase/Firestore startup configuration failures are not surfaced to the user. | medium — defer | This pre-existing startup failure-handling issue is not caused by the card-entry flow; recorded in `deferred-work.md`. |
| Blind Hunter 9: Nickname and bank fields have no maximum length. | false | The story and approved decisions specify required fields but no length cap; an unrequested arbitrary bound is not justified by this review. |
| Blind Hunter 10: Locale decimal separators may be rejected by `double.tryParse`. | medium — patched | Credit-limit parsing now uses the active locale; a German comma-decimal widget test passes. |
| Edge Case Hunter 1: Account/logout behavior was added beyond card-entry scope. | false | The account menu/logout code was present before the Story 2.2 implementation; this change adds the Add Card entry point only. |
| Verification Gap Reviewer 1: Firebase startup initialization is not tested. | medium — defer | Existing widget tests do not execute `main()`; startup initialization is broader, pre-existing behavior and is recorded in `deferred-work.md`. |
| Verification Gap Reviewer 2: Production card repository binding was unverified. | medium | The initial test exercised the provider directly. Added `buildAppWithProviders()` and an Add Card success test through that composition root; fixed and verified. |

## Final Review Acceptance (2026-10-19)

Review accepted: all Story 2.2 findings are resolved, rejected as out of scope/unsupported by the approved criteria, or explicitly deferred as pre-existing Firebase startup work in `deferred-work.md`. The production repository-binding gap was closed with a composition-root widget test. Verification evidence is sufficient: `flutter analyze`, focused Add Card tests, the full 75-test suite, and `git diff --check` passed after review fixes. Story acceptance criteria and review fixes have no outstanding blockers. Sprint status remains `review` pending the separately approved status transition.
