---
title: 'Story 3.2: 270° Circular Radial Utilization Gauge Widget'
type: 'feature'
created: '2026-10-19'
status: 'draft'
route: 'dispatch'
review_loop_iteration: 0
baseline_commit: 'ee51fc453e6a8f322b86b64292cbca802e05ded7'
context:
  - _bmad-output/planning-artifacts/epics.md
  - _bmad-output/planning-artifacts/ux-designs/ux-creditbillsytems-2026-10-13/DESIGN.md
  - _bmad-output/planning-artifacts/ux-designs/ux-creditbillsytems-2026-10-13/EXPERIENCE.md
  - _bmad-output/planning-artifacts/architecture/architecture-creditbillsytems-2026-10-13/ARCHITECTURE-SPINE.md
---

<frozen-after-approval reason="human-owned intent — do not modify unless human renegotiates">

## Intent

**Problem:** Story 3.1 implemented pure domain functions (`CreditCalculator`, `CreditHealthTier`) for utilization and tier categorization, but users cannot see the result visualized in the Dashboard.

**Approach:** Create a standalone `UtilizationGaugeWidget` presentation component that renders a 270° circular radial progress arc, animates from 0% to the current utilization on entry, colors the arc and status pill by health tier, displays the percentage and tier label, and opens an informational dialog when tapped. The widget is pure presentation — it accepts utilization data as inputs and performs no Firestore, Firebase, AuthProvider, or repository access.

## Boundaries & Constraints

**Always:** Accept `utilizationPercentage` (double) and optional `healthTier` (CreditHealthTier) as constructor inputs; derive the tier from the percentage via `CreditCalculator.getHealthTier()` when not supplied; render tier-appropriate arc color and badge label using `CreditCalculator.getHealthTierLabel()`; use `AppColors` health tier tokens (`healthHealthy` #10B981, `healthModerate` #F59E0B, `healthRisk` #EF4444) and background variants; render a 270° sweep arc with a 600ms entry animation from 0% to target; format the percentage to 1 decimal place; open an informational dialog explaining credit utilization score impacts on tap; provide meaningful accessibility semantics ("Credit utilization is X percent, categorized as Healthy/Moderate/High Risk"); remain a pure presentation widget with no Firestore, Firebase, AuthProvider, or repository dependency.

**Utilization clamping rules:**
- The visual arc fill is clamped to the valid range 0%–100%, so it never draws beyond the 270° sweep.
- The center percentage text always shows the actual utilization percentage (including values above 100%), formatted to one decimal place (for example, `125.0%`).
- Tier selection uses the actual utilization percentage, not the clamped arc value. A value above 50% remains high risk even if the arc is clamped at 100%.
- For a negative percentage, clamp the visual arc to 0% and display `0.0%` in the center; the tier is derived from the actual (negative) percentage via `CreditCalculator.getHealthTier()`, which returns `CreditHealthTier.healthy` for values below 30%. Do not modify `lib/core/utils/credit_calculator.dart`.

**Never:** Access Firestore or Firebase from the widget; request or accept an authenticated UID from the UI; implement card editing/deletion, bill entry, calendar, or unrelated Dashboard features; modify `lib/core/utils/credit_calculator.dart`, `lib/core/constants/app_colors.dart`, or `lib/features/dashboard/presentation/dashboard_shell_screen.dart` (gauge integration into the Dashboard shell belongs to Story 3.3); add fields to `CardModel` or change Firestore rules.

## I/O & Edge-Case Matrix

| Scenario | Input / State | Expected Output / Behavior | Error Handling |
|----------|--------------|---------------------------|----------------|
| Healthy utilization | percentage 20.0, no tier supplied | 270° arc animates 0%→20%, Emerald fill, badge "Healthy Usage (<30%)", center shows "20.0%" | N/A |
| Moderate utilization | percentage 40.0, no tier supplied | 270° arc animates 0%→40%, Amber fill, badge "Moderate Usage (30-50%)" | N/A |
| High-risk utilization | percentage 66.7, no tier supplied | 270° arc animates 0%→66.7%, Crimson fill, badge "High Risk Usage (>50%)" | N/A |
| Zero utilization | percentage 0.0 | Arc shows 0% fill, badge "Healthy Usage (<30%)" | N/A |
| Full utilization | percentage 100.0 | Arc shows full 270° fill without overflow | N/A |
| Above 100% utilization | percentage 125.0 | Arc clamped at 100% fill (no overflow beyond 270°), center shows "125.0%", tier high risk with Crimson fill and "High Risk Usage (>50%)" badge | N/A |
| Negative percentage | percentage -10.0 | Arc clamped at 0% fill, center shows "0.0%", tier derived from actual negative value (healthy), badge "Healthy Usage (<30%)" | N/A |
| Explicit tier override | percentage 20.0, tier supplied as moderate | Arc uses supplied tier color and label regardless of percentage | N/A |
| Tap gauge | Any rendered state | Opens informational dialog explaining utilization score impacts; dialog dismisses cleanly | N/A |
| Enlarged text / assistive tech | textScaler 2.0 | Percentage, badge, and label remain readable; semantics announce tier and percentage | N/A |
| Animation control | percentage 50.0 during pump sequence | Initial state 0%, intermediate state after 300ms (~25%), completed state after 600ms (50%) | Animation controller disposed after test; no pending timers |

</frozen-after-approval>

## Code Map

- `_bmad-output/planning-artifacts/epics.md:275-290` — Story 3.2 acceptance criteria: 270° arc animation, tier colors/badges, tap-to-explain dialog.
- `_bmad-output/planning-artifacts/ux-designs/ux-creditbillsytems-2026-10-13/DESIGN.md` — Utilization Radial Gauge component: thick circular progress arc (270° sweep), center percentage display + sub-caption, grey track with semantic tier color fill.
- `_bmad-output/planning-artifacts/ux-designs/ux-creditbillsytems-2026-10-13/EXPERIENCE.md` — Gauge behavior: 600ms entry animation (0% → target%), dynamic tier color transition, tap opens informational dialog, accessibility announcement.
- `_bmad-output/planning-artifacts/architecture/architecture-creditbillsytems-2026-10-13/ARCHITECTURE-SPINE.md` — `fl_chart: ^1.1.1` pinned as the Charts & Gauges package (line 155); `features/dashboard/presentation/UtilizationGaugeWidget` listed as presentation component; AD-3 requires calculations via pure Domain functions, never duplicated in UI widgets; AD-1 prohibits Firestore access from widgets.
- `lib/core/utils/credit_calculator.dart` — `CreditHealthTier` enum, `getHealthTier(double)`, `getHealthTierLabel(CreditHealthTier)` — reuse as-is; no changes.
- `lib/core/constants/app_colors.dart` — `healthHealthy`, `healthModerate`, `healthRisk` and `*Bg` variants (light and dark) — reuse as-is; no changes.
- `lib/features/dashboard/presentation/dashboard_shell_screen.dart` — gauge will be integrated here in Story 3.3; this story creates the standalone widget only — no changes in this story.
- `test/features/dashboard/utilization_gauge_widget_test.dart` — new widget tests covering arc rendering, tier colors, percentage formatting, edge cases (0%, 100%, >100%, negative), tap dialog, accessibility, and deterministic animation.
- `_bmad-output/planning-artifacts/architecture/architecture-creditbillsytems-2026-10-13/ARCHITECTURE-SPINE.md` — presentation boundary: widgets use domain contracts, no Firestore in widgets; file naming lowercase snake_case; class naming UpperCamelCase.

## Tasks & Acceptance

**Execution:**
- [ ] `lib/features/dashboard/presentation/utilization_gauge_widget.dart` — implement the standalone 270° radial gauge widget with entry animation, tier coloring, percentage/badge display, tap-to-dialog, and accessibility semantics.
- [ ] `test/features/dashboard/utilization_gauge_widget_test.dart` — cover arc rendering/sweep, tier color mapping, percentage formatting, edge cases (0%, 100%, >100%, negative), tap dialog, accessibility semantics, and deterministic animation control.

**Acceptance Criteria:**
- Given the Dashboard screen loads with card data, when the `UtilizationGaugeWidget` renders, then it animates a 270° circular progress arc from 0% to current utilization over 600ms.
- Given a utilization percentage below 30%, when the widget renders, then the arc fill is Emerald Green (#10B981) and the status pill reads "Healthy Usage (<30%)".
- Given a utilization percentage between 30% and 50%, when the widget renders, then the arc fill is Amber Gold (#F59E0B) and the status pill reads "Moderate Usage (30-50%)".
- Given a utilization percentage above 50%, when the widget renders, then the arc fill is Crimson Red (#EF4444) and the status pill reads "High Risk Usage (>50%)".
- Given a utilization percentage above 100% (for example 125.0%), when the widget renders, then the arc is clamped at 100% fill (no overflow beyond the 270° sweep), the center percentage text shows the actual value formatted to one decimal place (for example "125.0%"), and the tier remains high risk with Crimson fill and "High Risk Usage (>50%)" badge.
- Given a negative utilization percentage, when the widget renders, then the arc is clamped at 0% fill, the center shows "0.0%", and the tier is derived from the actual negative percentage via `CreditCalculator.getHealthTier()` (healthy).
- Given no health tier is supplied, then the widget derives the tier and label from the percentage using `CreditCalculator.getHealthTier()` and `getHealthTierLabel()`.
- Given an explicit health tier is supplied, then the widget uses the supplied tier color and label regardless of the percentage value.
- Given the widget is tapped, then an informative dialog explaining credit utilization score impacts opens and can be dismissed.
- Given assistive technology or enlarged text is used, then each percentage value, badge, and state has meaningful accessible semantics and remains usable; semantics announce "Credit utilization is X percent, categorized as Healthy/Moderate/High Risk".
- Given the widget is tested with explicit pump durations, then the animation is deterministic: initial state shows 0%, an intermediate pump shows partial progress, and a completed pump shows the target percentage; the animation controller is disposed and no pending timers or ticker exceptions remain.

## Implementation Notes

- Use `CustomPaint` with a 270° sweep arc; the track uses `borderSubtle` grey and the fill animates from 0 to the clamped target percentage (clamped to 0–100 for visual purposes).
- Use an `AnimationController` with a 600ms duration for the entry animation; rebuild via `AnimatedBuilder` or equivalent; dispose the controller in `dispose()`.
- Derive the health tier from `CreditCalculator.getHealthTier(percentage)` when `healthTier` is not explicitly provided; format the percentage to 1 decimal place matching `calculateUtilization` precision.
- Badge text comes from `CreditCalculator.getHealthTierLabel(tier)`; use `AppColors` health tier tokens for arc fill and badge background/foreground, including dark mode variants.
- The center percentage text always shows the actual (unclamped) utilization value formatted to one decimal place, including values above 100%.
- The informational dialog on tap explains the 30% credit score rule using neutral, non-judgmental copy per `EXPERIENCE.md` voice and tone.
- Widget tests must control animation time explicitly using `tester.pump()` with defined durations (for example, pumping 300ms for an intermediate state and 600ms for completion) rather than relying on `pumpAndSettle()` while a ticker is active. Each test must dispose the widget (and thus its animation controller) to avoid pending timers.
- The widget is presentation-only; Story 3.3 wires it into `_DashboardTab` alongside total limit/unpaid metrics and the upcoming-bills list.

## Verification

**Commands:**
- `flutter analyze` — expected: no analyzer issues.
- `flutter test test/features/dashboard/utilization_gauge_widget_test.dart` — expected: all gauge widget tests pass.
- `flutter test` — expected: full Flutter test suite passes.
- `git diff --check` — expected: no whitespace errors.

## Files Allowed to Change (creation only)

- `lib/features/dashboard/presentation/utilization_gauge_widget.dart` (new file)
- `test/features/dashboard/utilization_gauge_widget_test.dart` (new file)

## Explicit Exclusions (do NOT modify)

- `lib/core/utils/credit_calculator.dart` — reuse as-is; do not modify for negative percentage handling
- `lib/core/constants/app_colors.dart` — reuse as-is
- `lib/features/dashboard/presentation/dashboard_shell_screen.dart` — integration is Story 3.3
- `sprint-status.yaml` — no changes
- Story 2.4 specification — no changes
- `_bmad-output/planning-artifacts/epics.md` — no changes
- Any Firestore, authentication, bill, or calendar code
- Any existing specification file
