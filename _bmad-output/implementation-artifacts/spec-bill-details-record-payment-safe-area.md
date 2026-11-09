---
title: 'Keep Bill Details payment action above system navigation'
type: 'bugfix'
created: '2026-11-09'
status: 'in-progress'
route: 'oneshot'
review_loop_iteration: 0
context: []
---

<frozen-after-approval reason="human-owned intent — do not modify unless human renegotiates">

## Intent

**Problem:** On Android, the Bill Details screen's Record Payment button is obscured by the system navigation area at the bottom of the display.

**Approach:** Respect the bottom safe area for the scrollable details content so the payment action can be fully brought into view and tapped.

</frozen-after-approval>

## Implementation Notes

- `lib/features/bills/presentation/bill_detail_screen.dart`: The details page is a `SingleChildScrollView` without bottom safe-area handling.
- `test/features/bills/presentation/bill_detail_screen_test.dart`: Add a compact-device regression test with a simulated Android bottom inset and assert the Record Payment button can be scrolled fully above it.
- Keep the change limited to Bill Details layout and its widget test; preserve existing worktree changes and payment behavior.
