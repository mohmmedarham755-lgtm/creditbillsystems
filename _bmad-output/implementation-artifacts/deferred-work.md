- source_spec: `_bmad-output/implementation-artifacts/spec-2-1-credit-card-data-model-subcollection-repository.md`
  summary: Surface Firebase initialization failures instead of starting the app after initialization fails.
  evidence: `lib/main.dart` catches initialization errors and continues to `runApp`, leaving Firebase-dependent features unavailable.
- source_spec: `_bmad-output/implementation-artifacts/spec-2-1-credit-card-data-model-subcollection-repository.md`
  summary: Show an authentication loading state until persisted-session initialization completes.
  evidence: `AuthProvider` tracks `isInitialized`, but `AuthGate` does not consult it before rendering the login screen.
  status: done — `AuthGate` now renders `_AuthLoadingState` while `!authProvider.isInitialized`

- source_spec: `_bmad-output/implementation-artifacts/spec-2-1-credit-card-data-model-subcollection-repository.md`
  summary: Preserve authenticated state and report logout failures when Firebase sign-out fails.
  evidence: `AuthProvider.logout` catches sign-out failures, clears local state, and the dashboard navigates to login regardless.
  status: done — `logout()` preserves state + sets `errorMessage` on failure; dashboard shows error SnackBar and skips redirect
- source_spec: `_bmad-output/implementation-artifacts/spec-2-1-credit-card-data-model-subcollection-repository.md`
  summary: Make account creation recoverable if writing the Firestore profile fails after Firebase Auth registration succeeds.
  evidence: `AuthRepositoryImpl.registerWithEmailAndPassword` creates the auth account before writing the user document and does not roll it back on write failure.
- source_spec: `_bmad-output/implementation-artifacts/spec-2-1-credit-card-data-model-subcollection-repository.md`
  summary: Add exact 30% and 50% boundary tests for credit utilization health tiers.
  evidence: `test/core/credit_calculator_test.dart` tests representative values but not either defined tier boundary.
  status: done — boundary tests already present (exactly 30%, exactly 50%, rounding-to-30%, rounding-to-50%, just-below-30%)
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
- source_spec: `_bmad-output/implementation-artifacts/spec-admin-logo-upload-setting.md`
  summary: Make the admin logo settings screen compile for Flutter web or explicitly exclude web as a target.
  evidence: The settings screen imports `dart:io` unconditionally while the project has a web directory and web-specific SQLite setup; a web build would settle whether this is a real failure, but web is not part of the approved local-storage intent or CI.
- source_spec: `_bmad-output/implementation-artifacts/spec-admin-logo-upload-setting.md`
  summary: Decide whether to keep or revert toolchain-generated `pubspec.lock` and `.metadata` revisions.
  evidence: Transitive dependency versions and the local Flutter revision changed without a `pubspec.yaml` edit; no feature logic depends on them, and a toolchain policy decision would settle whether these belong in the change.

- source_spec: `_bmad-output/implementation-artifacts/spec-dedicated-settings-screen.md`
  summary: Reconcile the dashboard app-bar logo preview with the earlier frozen "Settings page only" branding placement.
  evidence: The staged settings work renders `_buildBrandLogo` in the dashboard AppBar for all signed-in users, while `spec-admin-logo-upload-setting.md` froze logo placement to the Settings page; the earlier logo story introduced it, not this navigation change.

- source_spec: `_bmad-output/implementation-artifacts/spec-dedicated-settings-screen.md`
  summary: Remove or actually use the unreferenced `assets/images/setting.jpg` and correct the earlier spec's "untouched" claim.
  evidence: The asset and its `pubspec.yaml` entry are staged but no Dart code references them; `spec-admin-logo-upload-setting.md` still describes the asset as unrelated/uncommitted, so the spec claim is stale.

- source_spec: `_bmad-output/implementation-artifacts/spec-dedicated-settings-screen.md`
  summary: Decide whether to keep or revert toolchain-generated `.metadata` and `pubspec.lock` revisions.
  evidence: Root/channel revisions and several transitive dependency versions changed without a `pubspec.yaml` constraint edit; no feature logic in this navigation change depends on them, and a toolchain policy decision would settle whether they belong in the change.

- source_spec: `_bmad-output/implementation-artifacts/spec-dedicated-settings-screen.md`
  summary: Make the App Version page read from one source of truth or add a drift test against `pubspec.yaml`.
  evidence: `lib/core/constants/app_version.dart` duplicates the package version with only a "keep in sync" comment; a build could display a stale version without any test failing.

- source_spec: `_bmad-output/implementation-artifacts/spec-dedicated-settings-screen.md`
  summary: Make legacy `app_settings` repair preserve or explicitly migrate rows with unrecognized columns instead of rebuilding the table destructively.
  evidence: `DatabaseHelper._ensureSettingsTable` drops and recreates `app_settings` when no recognized key/value column is present, silently discarding rows in an unknown legacy schema; the migration predates this navigation change.

- source_spec: `_bmad-output/implementation-artifacts/spec-dedicated-settings-screen.md`
  summary: Restrict lost-image recovery to picker-cancel flows and serialize it with uploads.
  evidence: `AdminHelpSettingsScreen._loadSettings` awaits `_recoverLostImage()` on every settings load, and recovery does not set `_isSaving`, so startup can persist a lost image over the current logo and a concurrent upload can race; the behavior predates this navigation change.

- source_spec: `_bmad-output/implementation-artifacts/spec-dedicated-settings-screen.md`
  summary: Verify lost-image retrieval failure handling on non-Android platforms.
  evidence: `retrieveLostData` may throw `UnimplementedError` outside Android; a real iOS/desktop picker-cancel run would settle whether the current catch shows a false error. The behavior predates this navigation change.

- source_spec: `_bmad-output/implementation-artifacts/spec-dedicated-settings-screen.md`
  summary: Add widget coverage for dashboard AppBar brand logo loading and fallback.
  evidence: Dashboard tests never provide a repository with a real logo path and never assert `dashboard-brand-logo` or `dashboard-brand-logo-fallback`, so the AppBar preview could regress with a green suite; the branding predates this navigation change.

- source_spec: `_bmad-output/implementation-artifacts/spec-dedicated-settings-screen.md`
  summary: Re-evaluate the `dart:io` web compilation risk for dashboard and settings screens.
  evidence: Both files import `dart:io` unconditionally while the project has web-specific SQLite setup; a `flutter build web` run would settle whether web is a real target, and web is outside the approved local-storage intent. Already logged from the earlier logo spec; re-flagged by this review.
