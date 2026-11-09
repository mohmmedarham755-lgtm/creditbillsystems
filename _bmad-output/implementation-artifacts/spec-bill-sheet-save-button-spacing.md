---
title: 'Adjust bill sheet Save Bill button spacing'
type: 'bugfix'
created: '2026-11-09'
status: 'done'
route: 'oneshot'
review_loop_iteration: 0
context: []
---

<frozen-after-approval reason="human-owned intent — do not modify unless human renegotiates">

## Intent

**Problem:** On Android, the Save Bill button in the Log New Bill bottom sheet is too close to or obscured by the system navigation bar.

**Approach:** Increase only the bottom spacing below the button so it sits fully above the navigation area, retaining current field layout, scrolling, and keyboard avoidance.

</frozen-after-approval>

## Implementation Notes

- Increased the form's bottom content padding from 24 dp to 48 dp, preserving the existing system-inset and keyboard-inset handling.
- Updated the modal widget test to require at least 16 dp of clearance above the simulated bottom navigation inset while still submitting the bill.

## Review Triage Log

- false — The one-shot spec intentionally omits separate acceptance criteria; the widget regression test verifies the button's clearance and successful bill submission.
- false — The widget test measured the button at y=592 on a 640 px viewport with a 24 px bottom inset, leaving 24 px above the inset; the 72 px estimate did not match the rendered layout.
- low (rejected) — The blank line in `lib/main.dart` predates this task, has no runtime impact, and is unrelated; changing it would touch existing user work.
