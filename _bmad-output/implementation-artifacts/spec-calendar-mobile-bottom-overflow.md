---
title: 'Fix Calendar mobile empty-state overflow'
type: 'bugfix'
created: '2026-11-09'
status: 'done'
route: 'oneshot'
review_loop_iteration: 0
context: []
---

<frozen-after-approval reason="human-owned intent — do not modify unless human renegotiates">

## Intent

**Problem:** On a compact Android screen, the Calendar tab's no-bills empty state overflows the bottom of its available panel by 28 pixels.

**Approach:** Adjust only the empty state's vertical layout so it fits the available mobile panel while preserving its existing content, calendar behavior, and navigation.

</frozen-after-approval>

## Implementation Notes

- Both `_SelectDayState` and `_NoBillsDayState` could exceed the height available in the calendar's `Expanded` day panel.
- Added a shared centered, scrollable day-panel layout that keeps content centered when it fits and allows scrolling when it does not. Its vertical padding is 16 dp; the horizontal spacing and content are unchanged.
- Added a regression test with dashboard app bar/navigation at a 360 x 780 dp viewport; it checks both empty states for render overflows.
- `flutter test test\features\calendar` passed all 15 tests.
- `dart analyze lib\features\calendar\presentation\calendar_screen.dart test\features\calendar\calendar_screen_test.dart` reported no issues.
- `git diff --check` passed for both changed Dart files.
- Existing worktree changes were preserved; no unrelated files were modified.
