---
title: 'Admin Logo Upload Setting'
type: 'feature'
created: '2026-11-23'
status: 'approved'
route: 'dispatch'
review_loop_iteration: 1
context: []
baseline_commit: '86f88dda44a0cb300b47dd780e6fae000c53c891'
---

<frozen-after-approval reason="human-owned intent — do not modify unless human renegotiates">

## Intent

**Problem:** The app has no admin-facing place for basic help and branding; the seeded admin cannot upload a logo image through the UI.

**Approach:** Add a small Admin Help & Settings page, reachable from the dashboard account menu for the seeded admin only. The page includes short help/about text and an image-picker control that copies the selected logo to app-managed storage, persists its local path in SQLite, and shows the logo preview on that settings page only.

## Boundaries & Constraints

**Always:** Reuse existing `image_picker` and `path_provider` dependencies; keep auth/dashboard/bill/card flows unchanged except the additive account-menu entry; store logo path in SQLite via existing `DatabaseHelper` patterns; follow Material 3 and existing widget/key conventions; add widget tests for access, picker success/cancel/failure, and missing-file fallback.

**Never:** Add remote upload/cloud storage, change auth contracts, redesign existing screens beyond the additive menu entry and the new settings page, show the upload setting to non-admin users, or introduce a full role-management system.

**Decisions (user-approved):**
- **Access scope:** Admin-only. Only the seeded admin account (`admin@gmail.com`, seeded by `ensureAdminAccount`) can see and use the logo upload setting.
- **Logo placement:** Settings page only. The uploaded logo preview appears on the new Help & Settings page; do not add it to welcome/login/register/app bar branding surfaces.
- **Page type:** Help + setting page. Include short help/about text plus the logo upload control on one small page.

## I/O & Edge-Case Matrix

| Scenario | Input / State | Expected Output / Behavior | Error Handling |
|----------|--------------|---------------------------|----------------|
| Admin opens page | Seeded admin taps account-menu entry | Help & Settings page shows help text, logo preview/fallback, and upload action | N/A |
| Non-admin access | Authenticated non-admin user opens account menu | Logo/help setting entry is not shown | N/A |
| Pick image | Admin picks an image | Image copied to app storage, path persisted in SQLite, preview updates | N/A |
| Picker cancelled | Admin dismisses picker | Existing logo/path unchanged | No error shown |
| Missing file | Persisted path no longer exists | Page shows default fallback and allows re-upload | No crash |
| Copy/persist failure | File copy or DB write fails | Existing setting unchanged; user sees non-blocking error | SnackBar/inline error |

</frozen-after-approval>

## Code Map

- `lib/features/dashboard/presentation/dashboard_shell_screen.dart:31-136` — account bottom sheet/profile action; add additive "Admin Help & Settings" `ListTile` only for seeded admin; keep logout behavior unchanged.
- `lib/app.dart:31-36` — named routes; add settings route only if needed, keep existing routes unchanged.
- `lib/main.dart:28-103,121-129` — DI composition uses shared `DatabaseHelper`; wire settings repository/provider here. Admin is seeded at startup.
- `lib/core/database/database_helper.dart:7,40-148` — DB v1, no `onUpgrade`, duplicate users/cards CREATEs in `_onCreate`. Add durable logo setting storage safely (new settings table or equivalent) with initialization/migration that works for existing installs; do not refactor existing duplicate CREATEs.
- `lib/core/auth/admin_initializer.dart:7-40` — seeded admin identity (`admin@gmail.com`).
- `lib/features/auth/presentation/auth_provider.dart:52-59` — `currentUser/userEmail`; admin check can compare normalized email to seeded admin.
- `lib/features/settings/domain/*` (new) — small model/contract for logo path setting.
- `lib/features/settings/data/*` (new) — SQLite settings repository using `DatabaseHelper`.
- `lib/features/settings/presentation/admin_help_settings_screen.dart` (new) — Help & Settings page: short help/about text, logo preview/fallback, pick-image button, loading/error states.
- `pubspec.yaml:39-40` — `image_picker` and `path_provider` already available.
- `test/features/dashboard/dashboard_shell_screen_test.dart` — account sheet/app-bar patterns and fake providers/repos.
- `test/widget_test.dart:58-128` — FFI in-memory DB setup pattern; open DB outside `testWidgets`.
- `test/features/settings/presentation/admin_help_settings_screen_test.dart` (new) — widget tests for access, pick/cancel/failure, missing-file fallback.

## Tasks & Acceptance

**Execution:**
- [x] `lib/core/database/database_helper.dart` — add durable `logo_path` setting storage with safe initialization/migration for existing DBs — persist logo across restarts.
- [x] `lib/features/settings/domain/*` and `lib/features/settings/data/*` — create settings model/repository contract + SQLite implementation — isolate persistence from UI.
- [x] `lib/features/settings/presentation/admin_help_settings_screen.dart` — build Help & Settings page with short help/about text, logo preview/fallback, and upload/replace action using `image_picker` + app-managed file copy — satisfy user flow.
- [x] `lib/features/dashboard/presentation/dashboard_shell_screen.dart` — add admin-only account-menu entry and bottom navigation destination to open the new page — make feature discoverable without changing logout.
- [x] `lib/main.dart` / `lib/app.dart` — wire repository/provider/route as needed with existing `DatabaseHelper` — integrate feature.
- [x] `test/features/settings/presentation/admin_help_settings_screen_test.dart` — cover admin page render, pick success, cancel, copy/persist failure, and missing-file fallback — verify I/O matrix.
- [x] `test/features/dashboard/dashboard_shell_screen_test.dart` (or nearby dashboard test) — assert admin sees entry and non-admin does not — enforce access scope.

**Acceptance Criteria:**

| AC | Status | Evidence |
|----|--------|----------|
| Given the seeded admin user, when they open the account menu, then they see an Admin Help & Settings entry and can open the page. | **Met** | `dashboard_shell_screen.dart` admin-only account-menu entry + Settings tab; dashboard tests cover admin visibility and account-menu tile tap/navigation. |
| Given the seeded admin user, when they pick a logo image, then the image is copied to app-managed storage, its path is persisted in SQLite, and the settings-page preview updates. | **Met** | `admin_help_settings_screen.dart` copies to app-managed `branding/`, saves via `SettingsRepository`; widget test verifies copy/persist/preview; SQLite repository round-trip test verifies persistence. |
| Given no logo or a missing persisted logo file, when the admin opens the settings page, then default fallback branding is shown and no crash occurs. | **Met** | Widget tests cover no-logo fallback and missing persisted file fallback; `Image.file` has `errorBuilder` fallback for decode failures. |
| Given a non-admin authenticated user, when they open the account menu, then the Admin Help & Settings entry is not available. | **Met** | Admin check in dashboard shell; dashboard test asserts non-admin does not see entry. |
| Given picker cancel or copy/persist failure, when the admin attempts upload, then the previous setting remains unchanged and failures show a non-blocking error. | **Met** | Widget tests cover cancelled picker and copy/persist failure with SnackBar and unchanged previous setting. |

**Accepted recovery improvement (outside frozen ACs, user-requested):**
- Given settings loading fails, when the admin sees the error, then a Retry action is available and successfully reloads settings when the repository recovers. **Met (UI/recovery behavior)** — widget test passes. **Underlying root cause unverified** — not reproduced.

## Implementation Notes

- Admin logo upload/help setting is implemented via `AdminHelpSettingsScreen`, `SettingsRepository`/`SqliteSettingsRepository`, `DatabaseHelper` app-settings storage, and admin-only dashboard entry points (account menu + Settings tab).
- **2026-11-23 recovery improvement (accepted):** Added a `Retry` action to the settings load-failure state in `AdminHelpSettingsScreen`. When `getSettings()` fails, the screen shows `Unable to load settings.` with an `admin-settings-retry` button that re-runs `_loadSettings()`.
- **Root-cause status (unverified):** The reported underlying “unable to load setting” failure has **not** been reproduced. The Retry UI provides recovery, but this does **not** prove the underlying DB/storage/provider/root cause is fixed.

## Spec Change Log

- **2026-11-23 — Additive navigation entry (user-driven, outside frozen intent):** The human requested "add setting logo option navigation bar" after approval. Added a 4th admin-only bottom-navigation destination labeled `Settings` (index 3) wired to the same `AdminHelpSettingsScreen`. The frozen account-menu entry is preserved. Dashboard/Bills/Calendar indices are unchanged. This is an additive entry point only; no frozen intent was modified.
- **2026-11-23 — Load-failure recovery improvement (accepted, outside frozen intent):** User reported "unable to load setting". Added a Retry action on the settings load-error state. This is an additive recovery UX improvement; frozen intent and I/O matrix were not modified. Underlying load-failure root cause remains unverified.

## Review Triage Log

Review round 1 (blind hunter, edge-case hunter, verification-gap). Verdicts rendered against the current working tree. Gap findings V1–V3 were pre-verified by their layer and judged from filed evidence.

| ID | Finding | Verdict | Evidence | Route |
|----|---------|---------|----------|-------|
| B1 | Blind #1 — nested Scaffold/AppBar gives two title bars on the Settings tab | low | `AdminHelpSettingsScreen` owns a `Scaffold`+`AppBar` and is mounted as an `IndexedStack` child beneath the shell's own `AppBar`. Real, visible duplication. | patch |
| B2 | Blind #2 — RangeError when admin access is lost while Settings is selected | false | Current tree clamps with `selectedIndex = isAdmin ? _currentIndex : (_currentIndex <= 2 ? _currentIndex : 0)` at `dashboard_shell_screen.dart:157-160`, used by both the stack and the bar. The guard landed after the reviewed diff. | reject |
| B3 | Blind #3 — admin email duplicated; uid ignored | low | Literal `'admin@gmail.com'` in `dashboard_shell_screen.dart:33` and `admin_initializer.dart:8` can drift; normalized-email comparison is the approved mechanism, so one shared constant is the direct fix. | patch |
| B4 | Blind #4 — no human approval recorded for the nav-bar entry | false | Human requested "add setting logo option navigation bar"; recorded in Spec Change Log. Fix would edit this spec, which is disallowed. | reject |
| B5 | Blind #5 — unconditional `dart:io` breaks web builds | maybe-false | `dart:io` occurs only in the settings screen while `web/`, `kIsWeb`, and `sqflite_common_ffi_web` exist. A web build would fail, but CI runs analyze only and the approved intent is local app-managed storage; settling it requires a web build target in scope. | defer |
| B6 | Blind #6 — synchronous filesystem calls on the UI thread | low | `existsSync`/`copySync` run on small logo files; no jank demonstrated. The fix requires an async rewrite of the picker flow, more than a direct correction. | reject |
| B7 | Blind #7 — no image validation or size cap | low | Intent asks for a small logo upload, not validation; adding MIME/size guards adds new branches for an undemonstrated harm. | reject |
| B8 | Blind #8 — corrupt logo file renders a broken image | medium | `_hasValidLogo` checks only `existsSync()`; `Image.file` has no `errorBuilder`, so decode failure has no fallback. | patch |
| B9 | Blind #9 — failed save leaves an orphaned copied file | low | `copySync` precedes `saveLogoPath`; failure leaves one unreferenced file. Disk clutter only, and cleanup adds a new failure branch. | reject |
| B10 | Blind #10 — settings load error has no retry affordance | low | `_loadError` is already shown inline; adding retry UI exceeds the captured error-handling intent. | reject |
| B11 | Blind #11 — no SQLite settings persistence round-trip test | high | No test constructs `SqliteSettingsRepository` or calls `getAppSetting`/`saveAppSetting`; widget tests inject fakes, so a wrong persistence key ships undetected. | patch |
| B12 | Blind #12 — extra picker/copy/email-normalization test cases missing | low | Double-tap guard and `trim().toLowerCase()` exist; copy failure shares the tested save-failure catch. Extra cases are hardening, not defect fixes. | reject |
| B13 | Blind #13 — account-menu tile presence asserted but never tapped | medium | Dashboard test checks only the tile key/label; a dead tile would keep the suite green. | patch |
| B14 | Blind #14 — verification records suppressed analyze commands only | low | `## Verification` lists commands but no captured outputs; plain `flutter analyze` was run clean after the deprecation infos were fixed. | patch |
| B15 | Blind #15 — pubspec.lock and .metadata churn | low | Transitive version bumps and local Flutter revision are toolchain-generated; `pubspec.yaml` is unchanged and no feature logic depends on them. | defer |
| B16 | Blind #16 — unused `copyWith` and file-wide ignore | false | No caller needs `copyWith`, but its presence has no bad outcome; the ignore matches the repo's dashboard shell convention. Rejected as harmless. | reject |
| E1 | Edge #1 — stale index RangeError when admin access is lost | false | Same guard as B2 at `dashboard_shell_screen.dart:157-160` covers `IndexedStack` and `NavigationBar`; guard postdates the reviewed diff. | reject |
| E2 | Edge #2 — account sheet stays open if auth flips to non-admin | low | Requires an auth change during an open modal; the sheet closes on tap and no normal flow triggers this. Fix adds auth-listener state. | reject |
| E3 | Edge #3 — stale preview after uploading through the pushed route | low | Pushed route and tab are separate instances; adding `didPopNext` reload is extra lifecycle surface for a low-traffic path. | reject |
| E4 | Edge #4 — `setState` after awaits without a `mounted` recheck | false | Every post-await `setState` is guarded: null-picker branch at `:103`, success at `:125`, error at `:131`; load path guards at `:64` and `:70`. | reject |
| E5 | Edge #5 — orphaned logo files on replace or DB failure | low | Same root cause/outcome as B9. | reject |
| E6 | Edge #6 — unreadable/corrupt persisted file is never exercised and shows no fallback | medium | Same root cause as B8: no `errorBuilder` and only missing-file test coverage. | patch |
| E7 | Edge #7 — `dart:io` import prevents web compilation | maybe-false | Same root cause as B5; settle only if web becomes a supported build target. | defer |
| V1 | Gap #1 — account-menu tile not tapped in any test | medium | Filed evidence: dashboard test at `:585-590` asserts presence only, and no repo test taps `admin-help-settings-tile`. | patch |
| V2 | Gap #2 — no SQLite persistence across restarts test | high | Filed evidence: only fake repositories are injected in tests; a wrong key or missing round-trip would not fail any test. | patch |
| V3 | Gap #3 — v1→v2 DB upgrade path untested | medium | Filed evidence: all DB tests inject pre-opened databases, so `_onUpgrade` never runs; a broken migration would fail existing installs at startup. | patch |

Grouping & cascade: B2+E1, B4, B5+E7, B6, B7, B9+E5, B10, B12, B15, B16, E2, E3, E4 are rejected or deferred; B8+E6 and B13+V1, B11+V2, V3, B1, B3, B14 route to patch. No `intent_gap` or `bad_spec` entries exist, so there is no loopback; patch and defer entries are processed normally.

Patch round applied: shared seeded-admin constant; pushed account-menu page owns its AppBar while the tab-body page does not; logo decode failure falls back via `Image.file.errorBuilder`; account-menu tile tap navigation test; SQLite settings round-trip test; v1→v2 migration test; analyze/test outputs recorded below. Deferred findings were logged in `deferred-work.md`.

### Verification addendum (2026-11-23, post-Retry recovery fix)

- User reported: "unable to load setting". Reproduction was **not** achieved in automated tests or static analysis.
- Implemented accepted recovery improvement: `admin-settings-retry` button on load-failure state; retries `_loadSettings()`.
- Widget coverage added: `load failure shows error and retry reloads settings` in `test/features/settings/presentation/admin_help_settings_screen_test.dart` (fake repo failure/recovery; **not** a reproduced SQLite root-cause test).
- SQLite persistence sanity remains covered by `test/features/settings/data/sqlite_settings_repository_test.dart` and DB helper tests.
- **Conclusion:** recovery UX improved and verified; underlying settings-load root cause remains **unverified/unreproduced**.

## Design Notes

Store only a local file path/reference in SQLite; copy picked images into an app-managed directory via `path_provider` so the preview survives temporary picker locations. Keep UI minimal: one page, one preview, one upload/replace action, optional remove action if trivial.

## Outstanding / Deferred

| Item | Status | Notes |
|------|--------|-------|
| Underlying “unable to load setting” root cause | **Unverified / unresolved** | Reported by user; not reproduced. Retry recovery added and verified. Needs runtime repro + stack trace/logs to diagnose DB/storage/provider cause. Do **not** claim fixed. |
| B5/E7 — `dart:io` unconditional import may break Flutter web | **Deferred** | Documented in triage and `deferred-work.md`. Web not in approved local-storage intent/CI. |
| B15 — `pubspec.lock` / `.metadata` toolchain churn | **Deferred** | Documented in triage and `deferred-work.md`; toolchain policy decision needed. |
| `assets/images/setting.jpg` + `pubspec.yaml` asset entry | **Unrelated/uncommitted, untouched** | Present in working tree per user request; not removed/modified by this spec update. |

## Verification

**Commands:**
- `flutter analyze` -- expected: no issues
- `flutter analyze --no-fatal-infos --no-fatal-warnings` -- expected: no issues
- `flutter test test/features/settings test/features/dashboard/dashboard_shell_screen_test.dart test/core/database/database_helper_test.dart` -- expected: targeted feature tests pass
- `flutter test test/features/settings` -- expected: all settings tests pass
- `flutter test` -- expected: full suite passes

**Results (2026-11-23, initial implementation):**
- `flutter analyze` -- `No issues found! (ran in 10.2s)`
- `flutter analyze --no-fatal-infos --no-fatal-warnings` -- `No issues found! (ran in 8.9s)`
- `flutter test test/features/settings` -- `All tests passed!` (7 tests)
- `flutter test` -- `All tests passed!` (454 tests)

**Results (2026-11-23, post-Retry recovery improvement):**
- `flutter analyze` -- `No issues found! (ran in 24.5s)`
- `flutter test test/features/settings test/features/dashboard/dashboard_shell_screen_test.dart test/core/database/database_helper_test.dart` -- `All tests passed!` (24 tests)
- `flutter test` -- `All tests passed!` (455 tests)
- New widget test: `load failure shows error and retry reloads settings` -- **passed** (`test/features/settings/presentation/admin_help_settings_screen_test.dart`).

**Verification limits:**
- The reported “unable to load setting” runtime failure was **not reproduced**. No console/stack trace was provided.
- The Retry test proves UI recovery with a fake failing `SettingsRepository`; it does **not** prove the underlying SQLite/settings-load root cause is fixed.
