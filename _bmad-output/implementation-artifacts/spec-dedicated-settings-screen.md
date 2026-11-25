---
title: 'Dedicated Settings Screen'
type: 'feature'
created: '2026-11-25'
status: 'done'
route: 'dispatch'
baseline_commit: '86f88dda44a0cb300b47dd780e6fae000c53c891'
review_loop_iteration: 0
context: []
---

<frozen-after-approval reason="human-owned intent — do not modify unless human renegotiates">

## Intent

**Problem:** Account and information actions are buried in the top-right profile popup, while the bottom-nav Settings tab opens the admin logo/help page directly. Users have no single settings destination.

**Approach:** Replace the Settings tab body with a dedicated Settings screen that lists Admin, Help & Settings, About, Contact Details, App Version, and Log Out, each opening its corresponding page. Move these actions out of the profile popup and keep existing pages and persistence intact.

## Boundaries & Constraints

**Always:** Reuse the existing pages and their public keys/constructors; keep Dashboard/Bills/Calendar at indices 0–2; keep `SettingsRepository?` injection, the logout confirmation flow, and its error SnackBar/redirect behavior; add widget coverage for the new hub and updated navigation.

**Never:** Rewrite the existing About/Contact/Version/History/logo screens, change stored settings data or auth contracts, add remote services, or alter bill/card/calendar flows.

**Decisions (user-approved):**
- Admin entry opens the existing `AdminLogoInputPage` (logo upload/replace); Help & Settings entry opens the existing `AdminHelpSettingsScreen`.
- History is not exposed from the Settings screen; the existing page remains untouched but unnavigated.
- The top-right profile button and its popup are removed; the Settings tab is the sole account/information destination.
- Admin and Help & Settings entries are visible to every signed-in user. This supersedes the earlier admin-only visibility constraint for navigation only; logo storage behavior is unchanged.

## I/O & Edge-Case Matrix

| Scenario | Input / State | Expected Output / Behavior | Error Handling |
|----------|--------------|---------------------------|----------------|
| Open Settings | Signed-in user taps Settings destination | Settings screen lists the requested entries | N/A |
| Open entry | User taps a listed entry | Corresponding page is pushed; hub remains underneath | N/A |
| Repository missing | `SettingsRepository?` is null when admin/help entry is tapped | Entry does not crash; user is told settings are unavailable | SnackBar/inline message |
| Log out | User taps Log Out, then confirms | `AuthProvider.logout()` runs and app redirects to `/login` | Error SnackBar; no redirect if logout fails |
| Cancel log out | User taps Cancel on confirmation | Returns to Settings without logging out | N/A |

</frozen-after-approval>

## Code Map

- `lib/features/dashboard/presentation/dashboard_shell_screen.dart:31-369` -- shell state, account popup (`:101-291`), `IndexedStack` tab 3 (`:318-334`), `NavigationBar` destination 3 (`:336-366`); replace tab body and strip action tiles.
- `lib/features/settings/presentation/admin_help_settings_screen.dart:16-390` -- existing help/branding page; keys `uploadButtonKey`, `fallbackIconKey`, `admin-logo-input-link`; reuse, do not rewrite.
- `lib/features/settings/presentation/admin_logo_input_page.dart:8-43` -- existing logo upload page with injectable I/O callbacks; Admin entry target.
- `lib/features/settings/presentation/about_page.dart:5`, `contact_details_page.dart:5`, `app_version_page.dart:7`, `logout_confirmation_page.dart:5` -- ready-made destination pages with stable keys; `history_page.dart:11` exists but is not navigated from the hub.
- `lib/core/constants/app_version.dart:4,7` -- version constants; `app_version_page.dart` already consumes them.
- `lib/core/auth/admin_initializer.dart:7`, `lib/features/auth/presentation/auth_provider.dart:56-58,160-174` -- seeded admin email (not used to gate settings entries by user decision) and logout behavior.
- `lib/main.dart:29-66` -- `SettingsRepository?` DI; dashboard already watches it as nullable.
- `test/features/dashboard/dashboard_shell_screen_test.dart:200-221,552-636` -- asserts Settings destination and popup tiles; must be updated for the hub.
- `test/features/auth/secure_logout_test.dart:147-153` -- taps profile icon; remove that interaction and assert no profile icon remains.
- `test/features/settings/presentation/account_pages_test.dart:168-255` -- existing page-level coverage; extend for hub navigation rather than duplicating page bodies.

## Tasks & Acceptance

**Execution:**
- [x] `lib/features/settings/presentation/settings_screen.dart` (new) -- build the dedicated hub with keyed entries: Admin to `AdminLogoInputPage`, Help & Settings to `AdminHelpSettingsScreen`, About, Contact Details, App Version, Log Out; include repository-unavailable handling.
- [x] `lib/features/dashboard/presentation/dashboard_shell_screen.dart` -- render the hub as tab 3; remove the profile button and popup entirely; wire hub entries to their existing pages and preserve logout behavior.
- [x] `test/features/settings/presentation/settings_screen_test.dart` (new) -- cover entry rendering, navigation to each page, missing-repository path, and logout confirm/cancel wiring.
- [x] `test/features/dashboard/dashboard_shell_screen_test.dart` -- replace popup-tile assertions with hub-tab assertions; keep coverage that primary tabs are unchanged.
- [x] `test/features/auth/secure_logout_test.dart` -- remove the profile-icon tap and assert the profile button is absent.

**Acceptance Criteria:**
- Given a signed-in user, when the Settings destination is selected, then the dedicated Settings screen is visible and Dashboard/Bills/Calendar remain the first three destinations.
- Given the Settings screen, when each listed entry is tapped, then its corresponding existing page is shown without rewriting that page.
- Given any signed-in user, including a non-admin, when Settings is opened, then all six requested entries are visible.
- Given the dashboard app bar, then no top-right profile button or account popup is present.
- Given logout confirmation, when the user confirms, then session state is cleared and the app returns to Login; when cancelled, the user stays signed in.

## Review Triage Log

Review round 1 (blind hunter, edge-case hunter, verification-gap). All layers reported against the staged diff.

| ID | Finding | Verdict | Evidence | Route |
|----|---------|---------|----------|-------|
| B1 | Provider generic mismatch (`SettingsRepository` vs `SettingsRepository?`) | false | `Provider<SettingsRepository>` is read covariantly as `SettingsRepository?`; production and test trees both resolve it, and the full 470-test suite passes. | reject |
| B2 | Admin route does not fire `onLogoChanged`, leaving dashboard logo stale | medium | `_openAdmin` is `void`, awaits nothing, and skips the callback that `_openHelpSettings` calls after pop. | patch |
| B3 | App-bar logo preview conflicts with frozen "Settings page only" placement | defer | Real conflict, but the app-bar branding was introduced by the earlier logo-upload story, not by this navigation change. | defer |
| B4 | Frozen admin-only upload broken by exposing entries to all users | false | The human explicitly approved "All signed-in users" for Admin and Help & Settings; the Admin entry *is* the upload page. | reject |
| B5 | `assets/images/setting.jpg` is unreferenced and spec claim is stale | defer | Asset and `pubspec.yaml` entry predate this story; earlier spec already records it as unrelated/uncommitted. | defer |
| B6 | `HistoryPage` exists but is unreachable | false | Intended by the human decision to omit History; the spec explicitly says it remains untouched but unnavigated. | reject |
| B7 | Mojibake in UI strings and spec files | false | Repo-wide grep for mojibake sequences in `*.dart` found no matches; strings and spec punctuation are correct on disk. | reject |
| B8 | `.metadata` revisions inconsistent | defer | Pre-existing toolchain churn already logged in `deferred-work.md`; not caused by this change. | defer |
| B9 | `pubspec.lock` transitive upgrades unexplained | defer | Pre-existing toolchain churn already logged in `deferred-work.md`; no dependency constraint changed here. | defer |
| B10 | `app_version.dart` can drift from `pubspec.yaml` | defer | Constant predates this story; App Version page only consumes it. | defer |
| B11 | Legacy `app_settings` rebuild drops rows with unknown columns | medium | True at `database_helper.dart:188-209`, but this migration was added by the earlier settings story. | defer |
| B12 | `_ensureSettingsTable` runs DDL on every read/write | false | `database_helper.dart:174` returns early when the recognized `key` column exists; no repeated DDL in normal use. | reject |
| B13 | `_recoverLostImage()` runs on every settings load | medium | True at `admin_help_settings_screen.dart:74-80`; pre-existing behavior from the earlier logo story. | defer |
| B14 | `LogoutConfirmationPage._confirm` throws and leaves button disabled | false | `AuthProvider.logout()` catches sign-out errors and sets `errorMessage`; the wired callback does not throw. | reject |
| B15 | Spec boxes/status/verification claim stale | false | Status is now `in-review` and verification results were recorded before review; the staged diff predated those edits. | reject |
| B16 | `seededAdminEmail` comment still claims UI gating | low | Comment at `admin_initializer.dart:6` is inaccurate after the user's all-users decision; direct comment correction. | patch |
| E1 | Admin route leaves dashboard logo stale after pop | medium | Same root cause as B2 at `settings_screen.dart:101-112`. | patch |
| E2 | `retrieveLostData` error on non-Android shows false failure | maybe-false | Plugin behavior on non-Android was not established; would need a real iOS/desktop cancellation run. Pre-existing. | defer |
| E3 | Concurrent upload races with lost-image recovery | maybe-false | `_recoverLostImage` does not set `_isSaving`; a targeted concurrency test would settle it. Pre-existing. | defer |
| E4 | Legacy settings table rebuild destroys unknown rows | medium | Same root cause as B11 at `database_helper.dart:188-209`. | defer |
| E5 | Account identity no longer visible after popup removal | medium | The popup showed `displayName`/`email`; the hub shows neither, though the user approved removing the popup. | patch |
| V1 | Dashboard AppBar logo/fallback have no test | medium | Real gap, but the AppBar branding predates this story; no test supplies a logo path. | defer |
| V2 | Admin tile callback is untested | medium | Same root cause as B2; no test supplies `onLogoChanged`. | patch |
| V3 | `dart:io` prevents web compilation | maybe-false | Already deferred in `deferred-work.md`; a web build target would settle it. | defer |

Grouping & cascade: B2+E1+V2 route to patch (stale dashboard logo through Admin route and missing callback coverage). E5 routes to patch (preserve account identity in the new hub). B16 routes to patch (stale comment). B3, B5, B8-B11, B13, E2-E4, V1, V3 are pre-existing or maybe-false and route to defer. B1, B4, B6, B7, B12, B14, B15 are rejected. No `intent_gap` or `bad_spec` entries exist, so no loopback.

## Implementation Notes

- `SettingsScreen` intentionally owns no `Scaffold`/`AppBar`; it is a `ListView` body inside the dashboard shell to avoid duplicate title bars.
- Hub keys: `settings-screen`, `settings-account-header`, `admin-page-tile`, `help-settings-tile`, `about-page-tile`, `contact-details-tile`, `app-version-page-tile`, `logout-confirmation-tile`. Existing page keys were reused instead of inventing parallel ones.
- The non-interactive account header preserves the display name/email previously shown in the removed profile popup; it is not a seventh action tile.
- Missing `SettingsRepository?` is handled with the same non-blocking SnackBar message used by the previous account menu; Admin and Help & Settings entries remain visible.
- Verification run 2026-11-25: `flutter analyze` clean; targeted suite 36/36 passed; full suite 470/470 passed.
- Post-review patches applied: async Admin-route `onLogoChanged`, account identity header, focused tests, and corrected `seededAdminEmail` comment.
- Post-patch verification 2026-11-25: `flutter analyze` clean; targeted suite 38/38 passed; full suite 472/472 passed.
- Deferred findings were appended to `_bmad-output/implementation-artifacts/deferred-work.md`.

## Verification

**Commands and results:**
- `flutter analyze` -- no issues
- `flutter test test/features/settings test/features/dashboard/dashboard_shell_screen_test.dart test/features/auth/secure_logout_test.dart` -- 38/38 passed
- `flutter test` -- 472/472 passed
