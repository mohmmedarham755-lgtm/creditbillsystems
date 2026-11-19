<!-- bmad:context -->
<!-- Verified 2026-10-14 against ee51fc4. Managed by bmad-project-context; edits inside this block are replaced on refresh. Keep anything you want preserved outside the markers. -->

## creditbillsytems

Flutter/Dart credit-bill app using Firebase Authentication, Cloud Firestore, Provider, feature-first Clean Architecture, and Material 3. `lib/main.dart` initializes Firebase and registers providers; `lib/app.dart` configures the themed app, routes, and auth gate. Features live under `lib/features/` with shared foundations in `lib/core/`. BMAD stories, acceptance criteria, architecture, and sprint state live under `_bmad-output/`.

## Policy

- Before story work, inspect the relevant code and read that story's acceptance criteria in `_bmad-output/planning-artifacts/epics.md`; follow the existing BMAD workflow and work on the next `ready-for-dev` story.
- Preserve pre-existing uncommitted changes; do not reset, delete, or overwrite unrelated work. Ask before destructive changes or scope expansion.
- Keep each user's credit-bill data under `/users/{authenticatedUid}/...`; enforce ownership in Firestore Security Rules (`request.auth.uid == userId`), not only through client-side filtering.
- Never expose Firebase credentials, API keys, or private user data in source, logs, examples, or responses.
- Add or update relevant unit/widget tests; run `flutter analyze` and `flutter test` and fix failures before marking a story complete. Update sprint status only after verifying the acceptance criteria, then continue with the next story marked ready.

## Where things are

- App startup and dependency registration: `lib/main.dart`; app theme, auth gate, and routes: `lib/app.dart`.
- Read `_bmad-output/planning-artifacts/architecture/architecture-creditbillsytems-2026-10-13/ARCHITECTURE-SPINE.md` and `architecture-guide.md` for layer boundaries, data ownership, and cross-feature invariants; check actual files before relying on planned modules.
- Story acceptance criteria: `_bmad-output/planning-artifacts/epics.md`; current readiness: `_bmad-output/implementation-artifacts/sprint-status.yaml`.

## Running and verifying

- Fetch dependencies: `flutter pub get`.
- Analyze: `flutter analyze`; run the complete test suite with `flutter test`.
- While iterating, run one test file, e.g. `flutter test test/core/credit_calculator_test.dart`.
- Build an Android APK with `flutter build apk`.

## Conventions that differ from defaults

- Keep feature code in `lib/features/<feature>/{presentation,domain,data}`: presentation widgets/providers should not access Firebase directly; define repository contracts in `domain` and Firebase-backed implementations in `data`.
- Use Provider `ChangeNotifier` for app/feature state; widgets observe with `context.watch`/`Consumer` and invoke actions with `context.read`.
- Keep shared calculations and formatting in `lib/core/utils/` rather than duplicating business logic in widgets.
- Credit-card data may include only a nickname, bank name, and last four digits; never collect or persist full card numbers, CVVs, or PINs.

<!-- /bmad:context -->
