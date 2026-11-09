---
title: 'Make Bills status filters usable on mobile'
type: 'bugfix'
created: '2026-11-09'
status: 'done'
route: 'oneshot'
review_loop_iteration: 0
context: []
---

<frozen-after-approval reason="human-owned intent — do not modify unless human renegotiates">

## Intent

**Problem:** On mobile, the Bills status segments wrap their labels and are difficult to tap. Selecting Pending should show unpaid and partially paid bills, and users must be able to open each result to inspect its details.

**Approach:** Keep the existing segmented filter, make all four labels readable and touch targets at least 48 dp high, include partial bills in Pending, and preserve bill-to-detail navigation.

</frozen-after-approval>

## Implementation Notes

- `lib/features/bills/presentation/bills_tab_screen.dart`: The four `SegmentedButton` labels currently compete for width with icons; bill rows already navigate to `BillDetailScreen`.
- `lib/features/bills/presentation/bill_provider.dart`: `filteredBills` currently treats Pending as `unpaid` only, while `EXPERIENCE.md` defines it as unpaid plus partially paid.
- `test/features/bills/presentation/bills_tab_screen_test.dart`: Existing tests cover filter taps and details; add compact mobile assertions for readable labels/touch height and verify a partially paid bill appears in Pending and opens its full details.
- Keep changes limited to the status filter presentation/filtering and focused tests. Do not modify the dashboard navigation, bill persistence, or existing worktree changes.
- Removed space-consuming segment icons, kept labels on one line with scale-down behavior, and set a 48 dp minimum segment height.
- Pending now includes both unpaid and partially paid bills; each result continues to open the existing full bill-detail view.
- `flutter test test\features\bills\presentation\bills_tab_screen_test.dart test\features\bills\presentation\bill_provider_test.dart test\features\bills\presentation\bill_detail_screen_test.dart` passed all 32 tests.
- `dart analyze` on the changed Bills implementation and test files reported no issues; `git diff --check` passed.
- No unrelated worktree changes were modified and no commit was created.
