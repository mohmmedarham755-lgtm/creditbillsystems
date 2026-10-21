---
title: 'Story 2.3: Credit Card Carousel & Portfolio Display'
type: 'feature'
created: '2026-10-19'
status: 'done'
route: 'dispatch'
review_loop_iteration: 0
baseline_commit: 'ee51fc453e6a8f322b86b64292cbca802e05ded7'
context:
  - _bmad-output/implementation-artifacts/epic-2-context.md
---

<frozen-after-approval reason="human-owned intent — do not modify unless human renegotiates">

## Intent

**Problem:** Authenticated users can add credit cards but cannot review their saved portfolio in the Dashboard.

**Approach:** Show the authenticated user's saved cards in a horizontally snapping, privacy-safe carousel, with an empty-state action that reuses the existing Add Card flow.

## Boundaries & Constraints

**Always:** Load and display only the signed-in user's cards through the existing repository contract and `CardProvider`; keep Firestore access out of widgets. Respect the existing user-scoped Firestore rules, Material 3 theme, cached/offline data behavior, and privacy restriction against full card numbers, CVVs, PINs, or magnetic-stripe data. Calculate available credit as `creditLimit - currentBalance` and format monetary amounts with the shared currency formatter. Support theme text scaling and provide meaningful card semantics without implying unsupported edit behavior.

**Never:** Add or change card data fields, collect sensitive card data, implement card editing/deletion or a card-detail screen, modify Firestore security rules, or expand into other Dashboard features.

## I/O & Edge-Case Matrix

| Scenario | Input / State | Expected Output / Behavior | Error Handling |
|----------|--------------|---------------------------|----------------|
| Saved portfolio | Authenticated user has one or more cards | Render the user's cards in a snapping carousel; show the next-card preview and an Add Card tile | N/A |
| Empty portfolio | Authenticated user's card stream emits no cards | Show a minimal card illustration and “+ Add Your First Card”; action opens the existing Add Card modal | N/A |
| Loading or failure | User's card stream has not emitted or fails | Show card-shaped loading placeholders; on failure show a retry action | Surface the provider error; retry resubscribes for the current UID |
| Account changes | Authenticated UID changes or becomes null | Cancel/ignore the old user's stream and clear old-user cards before showing the new user's state | Do not render prior-user data |
| No authenticated user | Auth provider has no UID | Do not open a card stream or expose an Add Card action | Clear any previously visible portfolio |

</frozen-after-approval>

## Code Map

- `lib/features/cards/domain/card_model.dart` -- reuse the existing eight-field model; derive available credit from its limit and current balance without changing the schema or storing derived values.
- `lib/features/cards/domain/card_repository.dart` and `lib/features/cards/data/card_repository_impl.dart` -- existing user-scoped repository exposes `getCards`; add `watchCards({required String userId})` and its Firestore implementation for cached live updates.
- `lib/features/cards/presentation/card_provider.dart` -- owns cards added during Story 2.2 and clears state on auth changes; extend it with an authenticated-user stream subscription, loading/error/retry state, and subscription cleanup.
- `lib/features/dashboard/presentation/dashboard_shell_screen.dart` -- Dashboard's private `_DashboardTab` currently contains the placeholder and Add Card entry point; replace its card placeholder without changing Bills/Calendar tabs or account navigation.
- `lib/features/cards/presentation/add_card_bottom_sheet.dart` -- reuse `showAddCardBottomSheet` for the empty-state and carousel Add Card actions.
- `lib/core/theme/app_theme.dart`, `lib/core/constants/app_colors.dart`, and `lib/core/utils/currency_formatter.dart` -- use existing Material 3 surfaces, palette, and monetary formatting.
- `lib/features/auth/presentation/auth_provider.dart` -- source authenticated UID; never accept a UID from the UI.
- `test/features/cards/card_provider_test.dart` and `test/features/cards/add_card_bottom_sheet_test.dart` -- follow existing fake-repository and widget-test conventions; extend the fake repository to emit controlled card streams.
- `_bmad-output/planning-artifacts/epics.md` Story 2.3, `_bmad-output/planning-artifacts/ux-designs/ux-creditbillsytems-2026-10-13/DESIGN.md`, `_bmad-output/planning-artifacts/ux-designs/ux-creditbillsytems-2026-10-13/EXPERIENCE.md`, and `_bmad-output/planning-artifacts/architecture/architecture-creditbillsytems-2026-10-13/ARCHITECTURE-SPINE.md` -- source acceptance, carousel/empty-state design, and layer/offline invariants.

## Tasks & Acceptance

**Execution:**
- [x] `lib/features/cards/domain/card_repository.dart` and `lib/features/cards/data/card_repository_impl.dart` -- expose `watchCards({required String userId})` so cached and subsequent user-scoped Firestore snapshots reach presentation state.
- [x] `lib/features/cards/presentation/card_provider.dart` -- subscribe for the authenticated UID, publish loading/cards/errors, support retry, and cancel or ignore stale subscriptions on account changes/dispose.
- [x] `lib/features/cards/presentation/card_carousel.dart` -- render card-shaped loading placeholders, retryable error, empty, and populated states; use a snapping `PageView`, 1.586:1 card ratio, readable card details, and Add Card actions.
- [x] `lib/features/cards/presentation/credit_card_tile.dart` -- implement the responsive, accessible Material 3 card surface with approved styling, chip motif, bank, nickname, masked digits, available credit, total limit, and cycle day.
- [x] `lib/features/dashboard/presentation/dashboard_shell_screen.dart` -- replace the Dashboard card placeholder with the portfolio carousel and preserve the existing Add Card behavior through the carousel.
- [x] `test/features/cards/card_provider_test.dart` -- cover stream snapshots, failures/retry, loading, and account-switch isolation.
- [x] `test/features/cards/card_carousel_test.dart`, `test/features/cards/credit_card_tile_test.dart`, and `test/features/dashboard/dashboard_shell_screen_test.dart` -- verify card content, ratio/preview, responsive semantics, empty CTA opening the existing form, unauthenticated state, and error/loading/retry behavior.

**Acceptance Criteria:**
- Given an authenticated user with saved cards, when the Dashboard loads or Firestore emits a cached/updated snapshot, then only that user's cards appear in a horizontally snapping `PageView` with a 1.586:1 aspect ratio and a 16dp next-card preview.
- Given a displayed card, when its portfolio item renders, then it shows bank name, nickname, `••••` plus the last four digits, available credit (`creditLimit - currentBalance`), total credit limit, and billing cycle day, using the approved card styling, existing theme, and currency formatter.
- Given a displayed card, when its portfolio item renders, then it also shows the current balance using the shared currency formatter.
- Given an authenticated user with no saved cards, when the card stream is empty, then an illustration and “+ Add Your First Card” action appear and open the existing Add Card modal.
- Given the stream is loading or fails, when the Dashboard displays portfolio content, then card-shaped loading placeholders or a user-visible error with retry are shown; retry subscribes for the current authenticated user.
- Given the authenticated UID changes or signs out, when the provider updates, then the prior user's cards are cleared and no stale stream result is displayed.
- Given the card text is enlarged or read with assistive technology, when a portfolio item renders, then its content remains readable and semantics announce card identity, masked digits, and credit values without advertising editing.
- Given a displayed card is read with assistive technology, when its semantics are announced, then the current balance is included.

## Implementation Notes

## Verification

**Commands:**
- `flutter analyze` -- expected: no analyzer issues.
- `flutter test test/features/cards/card_provider_test.dart test/features/cards/card_carousel_test.dart test/features/cards/credit_card_tile_test.dart test/features/dashboard/dashboard_shell_screen_test.dart` -- expected: all targeted provider and portfolio widget tests pass.
- `flutter test` -- expected: full Flutter test suite passes.

## Review Triage Log

The verification-gap reviewer could not read its assigned temporary diff and produced no review findings; this layer is not treated as a clean review. The implementation was manually checked against the tests, and the full analyzer and test suite were run directly.

| Finding | Verdict | Evidence |
|---------|---------|----------|
| Blind Hunter 1: Firebase initialization failures are caught and startup continues. | medium — defer | `main()` logs the exception and still calls `runApp(buildAppWithProviders())`; this startup behavior predates Story 2.3. |
| Blind Hunter 2: Firebase options are unsupported on web and Linux. | medium — defer | `DefaultFirebaseOptions.currentPlatform` throws for these platforms; platform configuration is outside this story and startup handling predates it. |
| Blind Hunter 3: `Firebase.apps.isEmpty` can skip default-app initialization when only a named app exists. | medium — defer | The condition checks whether any app exists, not whether `[DEFAULT]` exists; default Firebase services may then be unavailable. |
| Blind Hunter 4: Firestore persistence-setting failures are not surfaced. | medium — defer | The shared catch only writes to `debugPrint` and continues; a failed persistence configuration can remain unapplied without a user-facing notice. This startup behavior predates this story. |
| Blind Hunter 5: An injected `AuthProvider` is disposed by the provider wrapper. | low — defer | `ChangeNotifierProvider(create: ...)` owns and disposes the supplied instance; this helper behavior is outside Story 2.3. |
| Blind Hunter 6: Injecting auth without a repository unexpectedly constructs Firebase storage. | false | `buildAppWithProviders` intentionally defaults to the Firebase-backed repository when none is supplied; the app initializes Firebase before using that production default. |
| Blind Hunter 7: The test suite does not verify the production provider wiring. | false | `add_card_bottom_sheet_test.dart` exercises `buildAppWithProviders` with injected dependencies and verifies auth changes clear the composed card provider. |
| Blind Hunter 8: The unauthenticated startup path is untested. | false | `auth_gate_test.dart` covers unauthenticated rendering and transitions between login and dashboard. |
| Blind Hunter 9: Firebase startup initialization has no automated coverage. | medium — defer | No test exercises `main()` initialization; this broader startup verification gap predates Story 2.3. |
| Blind Hunter 10: Navigation destination changes are not verified after tab selection. | false | `widget_test.dart` taps Bills and Calendar and asserts each destination's distinct body content. |
| Edge Case Hunter 1: Firebase initialization failure leaves Firebase-backed features unavailable. | medium — defer | This duplicates Blind Hunter 1: the catch logs and continues to provider startup; the underlying startup behavior predates Story 2.3. |
| Edge Case Hunter 2: A named app can exist without the default app being initialized. | medium — defer | This duplicates Blind Hunter 3: `Firebase.apps.isEmpty` does not establish that the default app is present. |

### Review Findings

- [x] [Review][Decision] Display current balance on card tiles — Resolved per user direction and the original Epic 2.3 requirement; the tile and its accessibility label now include the formatted current balance.
- [x] [Review][Patch] Guard pending `addCard` completions after provider disposal [lib/features/cards/presentation/card_provider.dart:198-228] — Disposal invalidates outstanding requests, and completions no longer update state or notify listeners.
- [x] [Review][Patch] Test Firestore subscription error translation [lib/features/cards/data/card_repository_impl.dart:55-73] — Added repository coverage asserting a `FirebaseException` is surfaced as a `DatabaseException` with its message and code preserved.

Rejected:
- `false` — Dashboard route was not wired: `CreditBillApp` uses `AuthGate`, which renders `DashboardShellScreen` for authenticated users.
- `false` — Provider/repository registration was missing: `buildAppWithProviders` registers `CardProvider` with `CardRepositoryImpl`.
- `false` — Firestore ownership rules were missing: `firestore.rules` checks `request.auth.uid == userId` for card access.
- `false` — UI could supply an arbitrary owner UID: the only application call site passes `AuthProvider.userId`, and Firestore rules enforce ownership.
- `false` — Update/delete operations had no UI: those operations belong to the separately scoped Story 2.4 and are explicitly excluded from Story 2.3.
- `false` — Dashboard totals were not rendered: Story 2.3 acceptance criteria do not require portfolio totals.
- `false` — Concurrent saves could be triggered in the current UI flow: the only UI caller disables its Save button while `CardProvider.isLoading` is true.
- `false` — Raw provider error text should be hidden: the approved failure behavior requires surfacing the provider error with retry.
- `false` — Previously loaded cards must remain displayed after a stream failure: the approved acceptance criteria require a user-visible error and retry, not stale-card rendering.

### Follow-up Review (2026-10-19)

Review layers: Blind Hunter, Edge Case Hunter, Verification Gap Reviewer, and Acceptance Auditor. All four layers completed against the Story 2.3 implementation and test diff.

| Finding | Verdict | Evidence |
|---------|---------|----------|
| Blind Hunter 1: Dashboard screen not wired into routing. | false | `CreditBillApp` defaults to `AuthGate`, which renders `DashboardShellScreen` for authenticated users. |
| Blind Hunter 2: Card provider/repository not registered in app DI. | false | `buildAppWithProviders` registers `CardProvider` with `CardRepositoryImpl`; Story 2.3 adds provider stream binding through `ChangeNotifierProxyProvider`. |
| Blind Hunter 3: Firestore ownership rules/tests missing. | false | `firestore.rules` constrains card reads/writes to the authenticated UID; rules tests cover owner and non-owner access. |
| Blind Hunter 4: `addCard` trusts a caller-supplied UID without an auth provider. | false | The only production call site passes `AuthProvider.userId`; Firestore rules independently enforce ownership. |
| Blind Hunter 5: Repository update/delete have no UI. | false | Card modification/deletion is a separate Story 2.4 goal and explicitly excluded by this story's approved boundaries. |
| Blind Hunter 6: Portfolio totals/current balance are not shown. | false | Current balance was added to the tile in this follow-up; aggregate dashboard totals are not required by Story 2.3 acceptance. |
| Blind Hunter 7: Overlapping submissions prematurely clear loading. | false | The only UI caller disables Save while `CardProvider.isLoading` is true, preventing overlapping user submissions. |
| Blind Hunter 8 / Edge Case Hunter 1: Pending create mutates provider after disposal. | medium — patched | `addCard` now checks `_disposed` before mutation and notification, and `dispose` increments the request generation; a test completes a pending write after disposal and asserts no post-dispose notification or card state update. |
| Blind Hunter 9: Repository errors expose implementation details. | false | The provider surfaces typed `AppException` messages by design; Story 2.3 explicitly requires surfacing the provider error with retry. |
| Blind Hunter 10: Stream error hides the last card snapshot. | false | The approved acceptance criteria require an error state and retry; retaining stale snapshot content after a failed stream is not specified. |
| Verification Gap Reviewer 1: Firestore stream error conversion lacked repository coverage. | medium — patched | The repository test now injects a Firestore `permission-denied` stream error and asserts `DatabaseException` preserves the error message and code. |
| Acceptance Auditor 1: Current balance not displayed, despite Epic 2.3 requesting balance visibility. | medium — patched | The approved implementation spec now requires visible current balance and semantics; the tile formats and displays it, with widget assertions for both visible and accessible output. |

**Follow-up verification:** Targeted Story 2.3 tests passed; `flutter analyze` passed without issues; `flutter test` passed all 90 tests; `git diff --check` reported no whitespace errors.

**Follow-up review outcome:** No unresolved findings. All newly identified actionable findings were fixed; other findings were rejected with evidence above. Sprint status remains `review` pending human approval.

### Human Approval Follow-up (2026-10-19)

The user explicitly confirmed human approval for Story 2.3 on 2026-10-19. This approval supersedes the earlier note that sprint status remained `review` pending human approval. Story 2.3 is approved and its status is `done`; the prior review history and verification evidence above are preserved.
