---
title: 'Fix bill form submit button visibility'
type: 'bugfix'
created: '2026-11-05'
status: 'done'
route: 'oneshot'
review_loop_iteration: 0
context: []
---

<frozen-after-approval reason="human-owned intent — do not modify unless human renegotiates">

## Intent

**Problem:** On Android, the bill-entry sheet's Save Bill button is partially obscured by the bottom system navigation area, making submission difficult or impossible.

**Approach:** Respect the device's bottom safe-area inset while retaining scrolling and keyboard avoidance so the submit button can be brought fully into view and tapped.

</frozen-after-approval>

## Implementation Notes

- Wrapped the bill-entry sheet in `SafeArea(top: false)` while retaining the existing scroll view and keyboard-inset padding.
- Added a widget regression test that opens the real bill-entry modal with a simulated 24 px bottom system inset, verifies the Save Bill button remains above the inset, and confirms bill submission still succeeds.
- Verified with `flutter test test\\features\\bills\\presentation\\bill_entry_form_test.dart` and targeted `flutter analyze`.

## Review Triage Log

- low — Added the implementation details and verification result to this section; the original draft had not yet been finalized when reviewed.
- false — The one-shot spec intentionally omits the full tasks/acceptance sections; the test verifies the button boundary and successful submit behavior.
- medium — Updated the regression test to open `showBillEntryForm`, exercising the actual bottom-sheet route.
- low — Rejected separate keyboard-interaction coverage as outside the reported bottom-system-inset issue; existing `viewInsets` keyboard avoidance was preserved unchanged.
