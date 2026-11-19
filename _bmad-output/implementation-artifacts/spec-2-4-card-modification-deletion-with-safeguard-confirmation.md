-I am continuing my existing Flutter project, Credit Bill System.

Project path: `D:\credit bill system\creditbillsytems`

First, inspect the project structure and existing Git changes. Read the approved BMAD Story 2.4 specification.

My previous GitHub Copilot session stopped because its monthly quota was exhausted.

Continue from the existing code. Do not start a new project.

Rules:
- Only access files inside `D:\credit bill system\creditbillsytems`.
- Preserve all existing changes.
- Do not run git reset, git checkout to discard changes, or git clean.
- Do not create Git commits.
- First report which parts of Story 2.4 are completed and which are incomplete.
- Do not edit files until you report the current state.-
title: 'Story 2.4: Card Modification & Deletion with Safeguard Confirmation'
type: 'feature'
created: '2026-10-19'
status: 'in-progress'
route: 'dispatch'
review_loop_iteration: 0
baseline_commit: 'ee51fc453e6a8f322b86b64292cbca802e05ded7'
context:
  - _bmad-output/implementation-artifacts/epic-2-context.md
  - _bmad-output/implementation-artifacts/spec-2-3-credit-card-carousel-portfolio-display.md
---

<frozen-after-approval reason="human-owned intent — do not modify unless human renegotiates">

## Intent

**Problem:** Cardholders can add and view cards but cannot correct card details or remove a closed account from their portfolio.

**Approach:** Add per-card Edit and Delete actions. Edit reuses the existing card form in edit mode; Delete requires an explicit confirmation that identifies the selected card.

## Boundaries & Constraints

**Always:** Edit only nickname, bank name, last four digits, credit limit, billing-cycle day, and grace period. Keep `currentBalance` read-only and preserve the latest persisted balance when an edit saves, including a balance change made while the form is open. Validate fields using the existing Add Card rules: required trimmed nickname and bank name, exactly four numeric last digits, positive locale-aware credit limit, cycle day 1–31, and non-negative whole-number grace period. Never request or store a full card number, CVV, PIN, or magnetic-stripe data. Use the authenticated UID from `AuthProvider`, the existing `CardRepository` methods, Provider `ChangeNotifier`, typed application exceptions, and `/users/{uid}/cards/{cardId}` ownership.

**Deletion decision:** Deletion is permitted even when `currentBalance` is nonzero, but the confirmation must explicitly identify the card and disclose that it will be removed from the portfolio. Cancel must leave the record unchanged.

**Never:** Edit `currentBalance`; delete without explicit confirmation; add fields to `CardModel`; access Firestore from widgets; change Firestore rules, unrelated dashboard surfaces, or other card/bill workflows.

## I/O & Edge-Case Matrix

| Scenario | Input / State | Expected Output / Behavior | Error Handling |
|----------|--------------|---------------------------|----------------|
| Open card actions | Authenticated portfolio contains a card | Per-card action menu exposes Edit and Delete with accessible labels | No action for unauthenticated state |
| Valid edit | User changes one or more editable fields and submits valid values | Reuse the existing form pattern prefilled with current values; persist changes for the selected card and refresh its portfolio item/totals | Show saving state; prevent duplicate submission |
| Invalid edit | Required names are blank; last four is not exactly four digits; limit is not positive; cycle day is outside 1–31; or grace period is not a non-negative integer | Keep form open, show inline validation, and do not call the repository | No persistence call |
| Balance changes during edit | The persisted current balance changes after edit form opened | Save editable fields while preserving the latest persisted `currentBalance`; do not write the stale balance captured when the form opened | Transaction/repository failure is surfaced; user can retry |
| Edit persistence failure | Repository rejects the update or card no longer exists | Keep form open with entered values, clear loading, and show a user-facing error; do not report success | Translate Firebase failures through existing typed exceptions |
| Missing authentication | User signs out or UID changes while an edit/delete is open or pending | Do not perform an operation for a missing or previous UID; clear prior-user state and ignore stale completions | Surface an appropriate signed-in requirement when submission is attempted |
| Delete with zero balance | User selects Delete | Confirmation names the selected card and offers explicit Cancel and Delete actions | Cancel closes the dialog and makes no repository call |
| Delete with nonzero balance | Selected card has a positive `currentBalance` | Confirmation still permits deletion after explicit confirmation and identifies the card; confirmed delete removes that user's card | Cancel leaves card unchanged |
| Delete persistence failure | User confirms, repository rejects deletion | Keep the card visible, clear loading, and show a user-facing error with a retry path | Do not show success or remove local card optimistically |
| Last card deleted | Repository/stream confirms deletion | Portfolio transitions to its existing empty state and Add Your First Card action | Stream/repository failure follows the error behavior above |

</frozen-after-approval>

## Code Map

- `_bmad-output/planning-artifacts/epics.md:237-250` — Story 2.4 intent and acceptance criteria for updating a card and confirming deletion.
- `_bmad-output/implementation-artifacts/epic-2-context.md` — user-scoped card ownership, privacy rules, layered architecture, and portfolio behavior.
- `_bmad-output/implementation-artifacts/spec-2-2-add-new-credit-card-with-input-validation.md` — existing Add Card validation and form conventions to reuse.
- `_bmad-output/implementation-artifacts/spec-2-3-credit-card-carousel-portfolio-display.md` — portfolio display, stream state, accessibility, and user-isolation contract.
- `_bmad-output/planning-artifacts/architecture/architecture-creditbillsytems-2026-10-13/ARCHITECTURE-SPINE.md` and `architecture-guide.md` — presentation/domain/data boundaries, UID ownership, Provider state, offline cache, and typed failures.
- `lib/features/cards/domain/card_model.dart` — existing eight-field model; no schema change. `currentBalance` remains part of the entity but is not editable.
- `lib/features/cards/domain/card_repository.dart` and `lib/features/cards/data/card_repository_impl.dart` — reuse `updateCard({userId, card})` and `deleteCard({userId, cardId})`; update persistence must preserve the latest stored `currentBalance` rather than overwrite it from a stale edit form.
- `lib/features/cards/presentation/card_provider.dart` — add authenticated update/delete actions and operation-specific loading/error handling; keep portfolio stream as the source of refreshed card data and totals, and ignore stale completions after account change/dispose.
- `lib/features/cards/presentation/add_card_bottom_sheet.dart` — reuse the existing form structure and validators in create/edit mode; edit mode prepopulates the six editable fields and has no editable balance input.
- `lib/features/cards/presentation/card_carousel.dart` and `credit_card_tile.dart` — add an accessible per-card Edit/Delete menu without implying card-detail navigation; retain the existing visual card content and carousel behavior.
- `test/features/cards/data/card_repository_impl_test.dart` — cover user-scoped update/delete, preservation of the latest persisted balance when the edit model contains an older balance, and update/delete failures.
- `test/features/cards/card_provider_test.dart` — cover update/delete success, user UID scoping, total recalculation from portfolio snapshots, operation loading/errors, and stale completion isolation.
- `test/features/cards/add_card_bottom_sheet_test.dart` or a focused edit-form test — cover prefilled edit values, field validation, read-only balance, successful update, and visible failures.
- `test/features/cards/card_carousel_test.dart`, `credit_card_tile_test.dart`, or a focused card-action test — cover accessible action menu, named confirmation, cancel/no-op, confirmation with nonzero balance, delete failure, and empty-state transition.

## Tasks & Acceptance

**Execution:**
- [ ] Reuse repository update/delete contracts under the authenticated user's `/users/{uid}/cards/{cardId}` path; make update persistence preserve the latest stored `currentBalance` atomically.
- [ ] Extend `CardProvider` with update/delete operations, loading and typed user-visible error state, and account-change/disposal guards.
- [ ] Extend the existing Add Card form for edit mode: prefill editable fields, reuse validators, keep balance read-only, and preserve entered values on failure.
- [ ] Add per-card Edit/Delete actions and accessible named deletion confirmation; allow confirmed deletion regardless of balance.
- [ ] Add repository, provider, form, and widget tests for the specified success, validation, confirmation, error, race, ownership, and accessibility cases.

**Acceptance Criteria:**
- Given an authenticated user selects Edit on a portfolio card, when the edit form opens, then nickname, bank name, last four digits, credit limit, billing-cycle day, and grace period are prefilled and editable, while `currentBalance` is not an editable field.
- Given a valid edit, when the user submits it, then only the selected card under the authenticated user's collection is updated through the existing repository contract and the portfolio reflects the persisted values.
- Given `currentBalance` changes in Firestore after the edit form opens, when the user saves edits, then the latest persisted balance remains unchanged by the edit and is reflected in the portfolio.
- Given invalid edit values, when the user submits, then inline validation prevents persistence and the form retains the user's input.
- Given an edit fails to persist, when the operation completes, then loading clears, the form remains open with values intact, and a user-facing error is shown without a success indication.
- Given an authenticated user selects Delete, when the confirmation dialog appears, then it identifies the selected card by nickname, bank, and masked last four digits and presents explicit Cancel and Delete actions.
- Given a card has a nonzero balance, when deletion is requested, then deletion remains allowed only after the same explicit named confirmation; canceling never calls the repository.
- Given deletion is confirmed, when the user remains authenticated and the repository succeeds, then only that user's selected card is removed and the portfolio stream updates; deleting the last card displays the existing empty-portfolio state.
- Given update/delete fails, when the operation completes, then loading clears, the card is not removed optimistically, and a user-visible retryable error is available.
- Given the user signs out or changes accounts while an operation is pending, when its completion arrives, then it cannot mutate or expose the prior user's state.
- Given assistive technology or enlarged text is used, when card actions/forms/confirmation are presented, then each action, field, validation message, busy state, and selected-card confirmation has meaningful accessible semantics and remains usable.

## Implementation Notes

- To prevent a stale edit form from overwriting a concurrent balance update, the repository update must preserve `currentBalance` from the latest document state at commit time. A transaction should re-read/retry on conflict and write the edited fields with that latest balance; do not pass the form's balance snapshot through as authoritative.
- Firestore access remains in `CardRepositoryImpl`; widgets use `CardProvider` and the domain repository contract only. Keep all card operations user-scoped and rely on existing Firestore ownership rules.
- Existing totals are derived from the card stream. Do not update totals from the stale edit form's balance; allow the resulting snapshot to recalculate totals.

## Verification

**Commands:**
- `flutter analyze` — expected: no analyzer issues.
- `flutter test test/features/cards/data/card_repository_impl_test.dart test/features/cards/card_provider_test.dart test/features/cards/add_card_bottom_sheet_test.dart test/features/cards/card_carousel_test.dart test/features/cards/credit_card_tile_test.dart` — expected: focused repository, provider, form, action, and portfolio tests pass.
- `flutter test` — expected: full Flutter test suite passes.
- `git diff --check` — expected: no whitespace errors.
