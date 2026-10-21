- source_spec: `_bmad-output/implementation-artifacts/spec-2-1-credit-card-data-model-subcollection-repository.md`
  summary: Surface Firebase initialization failures instead of starting the app after initialization fails.
  evidence: `lib/main.dart` catches initialization errors and continues to `runApp`, leaving Firebase-dependent features unavailable.
- source_spec: `_bmad-output/implementation-artifacts/spec-2-1-credit-card-data-model-subcollection-repository.md`
  summary: Show an authentication loading state until persisted-session initialization completes.
  evidence: `AuthProvider` tracks `isInitialized`, but `AuthGate` does not consult it before rendering the login screen.
- source_spec: `_bmad-output/implementation-artifacts/spec-2-1-credit-card-data-model-subcollection-repository.md`
  summary: Preserve authenticated state and report logout failures when Firebase sign-out fails.
  evidence: `AuthProvider.logout` catches sign-out failures, clears local state, and the dashboard navigates to login regardless.
- source_spec: `_bmad-output/implementation-artifacts/spec-2-1-credit-card-data-model-subcollection-repository.md`
  summary: Make account creation recoverable if writing the Firestore profile fails after Firebase Auth registration succeeds.
  evidence: `AuthRepositoryImpl.registerWithEmailAndPassword` creates the auth account before writing the user document and does not roll it back on write failure.
- source_spec: `_bmad-output/implementation-artifacts/spec-2-1-credit-card-data-model-subcollection-repository.md`
  summary: Add exact 30% and 50% boundary tests for credit utilization health tiers.
  evidence: `test/core/credit_calculator_test.dart` tests representative values but not either defined tier boundary.
- source_spec: `_bmad-output/implementation-artifacts/spec-2-1-credit-card-data-model-subcollection-repository.md`
  summary: Validate card financial and billing-cycle ranges as part of card-entry validation.
  evidence: Those constraints belong to Story 2.2; Story 2.1 defines the model fields but no value ranges.

## Deferred from: code review of spec-2-1-credit-card-data-model-subcollection-repository (2026-10-15)

- Defer server-side card-field allowlisting in Firestore rules: the approved Story 2.1 rules define UID ownership, not card document schema validation. Revisit if rules are approved to enforce card fields and reject unapproved data.

- source_spec: `_bmad-output/implementation-artifacts/spec-2-2-add-new-credit-card-with-input-validation.md`
  summary: Configure Firebase options for supported web deployments.
  evidence: `DefaultFirebaseOptions.currentPlatform` throws for web, and startup catches that error and continues; Story 2.2 changes provider composition but does not define platform configuration.
- source_spec: `_bmad-output/implementation-artifacts/spec-2-2-add-new-credit-card-with-input-validation.md`
  summary: Handle Firebase initialization failures before exposing Firebase-backed features.
  evidence: `main()` logs Firebase initialization failures and still starts providers whose repositories use Firebase; this startup behavior predates the Add Card flow.
- source_spec: `_bmad-output/implementation-artifacts/spec-2-2-add-new-credit-card-with-input-validation.md`
  summary: Add automated coverage for Firebase startup initialization.
  evidence: Existing tests do not run the `main()` initialization path; Story 2.2 now covers card-provider composition, while startup initialization verification is broader existing coverage.

## Deferred from: code review of spec-2-3-credit-card-carousel-portfolio-display (2026-10-19)

- source_spec: `_bmad-output/implementation-artifacts/spec-2-3-credit-card-carousel-portfolio-display.md`
  summary: Prevent Firebase-dependent providers from starting after Firebase initialization fails.
  evidence: `main()` logs initialization errors and still calls `runApp`; this general startup behavior predates Story 2.3.
- source_spec: `_bmad-output/implementation-artifacts/spec-2-3-credit-card-carousel-portfolio-display.md`
  summary: Configure Firebase options for all intended deployment platforms.
  evidence: The generated options throw for web and Linux; platform configuration is outside Story 2.3.
- source_spec: `_bmad-output/implementation-artifacts/spec-2-3-credit-card-carousel-portfolio-display.md`
  summary: Initialize the default Firebase app even when a named app is already registered.
  evidence: `Firebase.apps.isEmpty` can be false while no default app exists, leaving default Firebase service access unavailable.
- source_spec: `_bmad-output/implementation-artifacts/spec-2-3-credit-card-carousel-portfolio-display.md`
  summary: Surface Firestore persistence-configuration failures instead of continuing without a user-facing notice.
  evidence: The startup catch logs settings errors and continues, so a failed persistence configuration can remain unapplied.
- source_spec: `_bmad-output/implementation-artifacts/spec-2-3-credit-card-carousel-portfolio-display.md`
  summary: Preserve caller ownership of injected `AuthProvider` instances in `buildAppWithProviders`.
  evidence: `ChangeNotifierProvider(create: ...)` takes ownership of an injected notifier and disposes it with the provider tree.
- source_spec: `_bmad-output/implementation-artifacts/spec-2-3-credit-card-carousel-portfolio-display.md`
  summary: Add automated coverage for Firebase startup initialization and Firestore configuration.
  evidence: The current test suite does not exercise `main()` initialization; this is broader startup verification rather than Story 2.3 behavior.
