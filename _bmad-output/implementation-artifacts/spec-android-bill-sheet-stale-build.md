---
title: 'Verify and rebuild Android bill sheet layout'
type: 'bugfix'
created: '2026-11-09'
status: 'ready-for-dev'
route: 'oneshot'
review_loop_iteration: 0
context: []
---

<frozen-after-approval reason="human-owned intent — do not modify unless human renegotiates">

## Intent

**Problem:** The Android app shows no visible bill-sheet spacing update even though the Flutter source contains the change. The local debug APK predates the source, and the current widget test forces the button into view before checking its position.

**Approach:** Verify the real Bills-tab-to-form route, assert button clearance in the actual modal without forced scrolling, preserve the current form behavior, and build a fresh debug APK from the current source for installation.

</frozen-after-approval>

## Implementation Notes
