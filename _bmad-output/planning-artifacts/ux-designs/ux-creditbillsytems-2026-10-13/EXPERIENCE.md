---
name: Credit Bill System
status: final
sources:
  - _bmad-output/planning-artifacts/prds/prd-creditbillsytems-2026-10-13/prd.md
updated: 2026-10-13
---

# Credit Bill System — Experience Spine (EXPERIENCE.md)

## Foundation

* **Platform Target**: Single-surface mobile application built with Flutter, optimized first for Android (API 26+) and structurally ready for iOS without architectural refactoring.
* **UI Framework**: Google Material 3 (M3) utilizing Flutter's native widget tree (`Scaffold`, `NavigationBar`, `Card`, `showModalBottomSheet`).
* **Visual Reference**: All visual styling, tokens, and color values are bound to [`DESIGN.md`](./DESIGN.md) via `{colors.*}`, `{typography.*}`, and `{spacing.*}` syntax.
* **Theme Modes**: Full light mode and dark mode support with automatic device preference detection.

---

## Information Architecture

The app uses a flat 3-tab bottom navigation hierarchy with a dedicated top app bar profile/settings action:

| Surface | Reached From | Purpose & Primary Controls |
| :--- | :--- | :--- |
| **Auth Screen** | App Open (unauthenticated) | Email/Password login, new user registration, and password recovery. |
| **Dashboard (Home Tab)** | Bottom Navigation (Tab 1) | High-level command center: Aggregate Credit Utilization Gauge, Card Carousel, Quick Stats (Total Limit, Total Debt), and upcoming 3 urgent bills. |
| **Bills Tab** | Bottom Navigation (Tab 2) | Master bill ledger with status segmented tabs (`All`, `Pending`, `Paid`, `Overdue`), bill cards, and "Log Bill" FAB. |
| **Calendar Tab** | Bottom Navigation (Tab 3) | Interactive monthly calendar displaying due dates, statement generation dates, and date-filtered bill bottom sheets. |
| **Card Detail / Editor** | Tapping any Card in Carousel | View full card parameters, edit credit limits, cycle days, or delete card with confirmation. |
| **Bill Detail View** | Tapping any Bill row | Inspect statement totals, breakdown of remaining balance, payment history log, and "Record Payment" button. |
| **Payment Logger (Modal)** | "Record Payment" button | Half-screen bottom sheet to record installment or full payments with date picker and quick-fill presets. |
| **Settings / Profile** | Top App Bar (Right Icon) | Account information, currency preference display, notification permission status, and secure logout. |

### Navigation & Modal Hierarchy
* **Bottom Navigation Bar**: Always visible on top-level tabs (Dashboard, Bills, Calendar).
* **Modal Stack Rule**: Modals never stack more than one level deep. A bottom sheet dismisses before opening a sub-dialog.
* **Android Back Button / System Gesture**: 
  * On modal: Dismisses the sheet.
  * On detail screens: Returns to parent tab.
  * On top-level tabs: If not on Dashboard, switches to Dashboard; if on Dashboard, standard Android double-tap or minimize app.

---

## Voice and Tone (Microcopy)

The application communicates with directness, financial precision, and zero judgmental fluff:

| Context | Do (Clean, Reassuring) | Don't (Vague, Alarming, or Preachy) |
| :--- | :--- | :--- |
| **Utilization Status** | "Utilization: 24.5% — Healthy usage below 30%." | "Great job spending responsibly! Keep it up! 🎉" |
| **High Utilization** | "Utilization: 54.2% — High balance may impact credit rating." | "WARNING! Dangerous debt level detected!" |
| **Payment Confirmation** | "Payment of $250.00 recorded. Remaining balance: $150.00." | "Payment successful! Congratulations!" |
| **Bill Settlement** | "Bill paid in full." | "You conquered this bill! Zero debt remaining!" |
| **Due Date Reminder** | "Citi Card bill ($420.00) is due in 3 days." | "Hey buddy, don't forget you owe money!" |
| **Empty State** | "No active bills. Tap '+' to record your statement." | "Nothing here yet. Go add some bills." |

---

## Component Patterns

### 1. Credit Card Carousel Widget
* **Location**: Dashboard top section.
* **Behavior**:
  * Horizontally scrollable with page snapping (one card prominent, next card peeking at `{spacing.4}`).
  * Includes an "Add Card" tile at the tail of the list.
  * Tapping a card opens the Card Detail sheet with full cycle information.

### 2. Utilization Radial Gauge Widget
* **Location**: Dashboard center.
* **Behavior**:
  * Smooth entry animation on load ($0\% \to \text{target}\%$ over 600ms).
  * Color dynamically transitions between `{colors.health-healthy}`, `{colors.health-moderate}`, and `{colors.health-risk}` based on PRD formulas.
  * Tapping the gauge expands an informational dialog explaining the 30% credit score rule.

### 3. Segmented Bill Filter Bar
* **Location**: Bills tab header.
* **Behavior**:
  * Filter chips: `All`, `Pending` (unpaid + partial), `Paid`, `Overdue`.
  * Instant client-side filtering without reloading the screen.
  * Active chip styled with `{colors.brand-primary}`, inactive with `{colors.surface-raised}`.

### 4. Slide-Up Payment Logger Sheet
* **Location**: Triggered from Bill Detail.
* **Behavior**:
  * Slides up from bottom taking 60% of screen height; automatically focuses the numeric amount field.
  * Quick-fill chips:
    * `Pay Full ($XXX)`: Pre-fills exact `remainingBalance`.
    * `Pay Half ($XXX)`: Pre-fills 50% of `remainingBalance`.
  * Submitting triggers a gentle haptic buzz, updates the parent screen in real time, and dismisses the sheet.

---

## State Patterns

### 1. Cold Open & Authentication
* **Behavior**: App displays a clean branding splash while Firebase checks `currentUser`.
* If authenticated: Navigates immediately to Dashboard with cached offline data.
* If unauthenticated: Smooth cross-fade to Login screen.

### 2. Empty States
* **Empty Dashboard (No Cards)**:
  * Illustration: Minimal line-art credit card.
  * Copy: *"Track your first credit card. Add your credit limit and billing cycle to get started."*
  * Call to Action: Prominent `+ Add Card` button.
* **Empty Bills List**:
  * Copy: *"No bills logged yet. When your statement arrives, record it here to track due dates."*
  * Call to Action: `+ Record Bill` button.
* **Empty Calendar Date**:
  * Copy: *"No payments due on this date."*

### 3. Loading & Shimmer States
* Network requests use subtle grey shimmer skeletons matching the exact shape of card and list tiles (no generic center spinning spinners on content pages).

### 4. Error Handling
* Form input validation triggers inline red text below the field (e.g., *"Credit limit must be greater than $0"*).
* Firebase network errors display a non-intrusive floating `SnackBar` at the bottom with a retry action (e.g., *"Unable to sync with cloud. Displaying offline data."*).

---

## Interaction Primitives

* **Gestures**:
  * **Swipe to Delete**: Swiping left on a bill or payment reveals a red delete action with confirmation modal.
  * **Pull-to-Refresh**: Available on Dashboard and Bills tab to manually re-sync Cloud Firestore.
* **Haptics**:
  * Light impact haptic on successful payment submission and bill status change.
  * Warning haptic if user enters an amount greater than the remaining balance.
* **Touch Targets**: Strictly enforced minimum of `48 x 48 dp` for all interactive elements, icons, and filter chips.

---

## Accessibility Floor

1. **Screen Reader Semantics (`Semantics` in Flutter)**:
   * Credit card widgets announce: *"Card [Nickname], ending in [last 4 digits], limit [limit], current balance [balance]. Double tap to edit."*
   * Utilization gauge announces: *"Credit utilization is [X] percent, categorized as [Healthy/Moderate/High Risk]."*
   * Status badges announce: *"Status: [Unpaid/Partially Paid/Paid/Overdue]."*
2. **Dynamic Font Scaling**: All text styles honor the system font scale without layout clipping or text truncation on large display sizes.
3. **Contrast Compliance**: All text and semantic state badges exceed WCAG 2.1 AA ratio ($> 4.5:1$ against their respective backgrounds).

---

## Key Flows (Screen Journeys)

### Flow 1: New User Onboarding & Card Setup (Realizes UJ-1)
1. **Screen 1 (Login/Register)**: User enters email/password $\to$ Taps "Sign Up".
2. **Screen 2 (Dashboard - Empty)**: Welcome header appears with empty card placeholder $\to$ User taps `+ Add Card`.
3. **Screen 3 (Add Card Form)**: User enters Card Name, Bank, Last 4 digits, Limit ($2,500), Billing Cycle Day (15), Grace Period (20 days) $\to$ Taps "Save Card".
4. **Resolution**: Card appears with smooth slide animation into the carousel; aggregate limit reflects $2,500.

### Flow 2: Statement Logging & Utilization Impact (Realizes UJ-2)
1. **Screen 1 (Bills Tab)**: User taps Floating Action Button `+ New Bill`.
2. **Screen 2 (New Bill Modal)**: User selects Card from dropdown $\to$ enters Statement Amount ($900) $\to$ due date auto-calculates from card rules $\to$ Taps "Save Bill".
3. **Screen 3 (Dashboard)**: User switches to Dashboard; radial gauge animates from 0% to 36.0% (turning amber with warning badge).

### Flow 3: Split Payment Installments (Realizes UJ-3)
1. **Screen 1 (Bill Detail)**: User selects active $600 bill due in 12 days $\to$ Taps "Record Payment".
2. **Screen 2 (Payment Logger Sheet)**: User enters $350 $\to$ taps "Confirm Payment".
3. **Feedback**: Haptic buzz; bill status transitions to `Partially Paid`; remaining balance updates to $250.
4. **Follow-up**: User logs second payment of $250 $\to$ status transitions to `Paid` with green badge; notifications cancelled.

### Flow 4: Responding to Due Date Notification (Realizes UJ-4)
1. **System Alert**: Local Android notification appears at 09:00 AM: *"Citi Card bill of $420 is due in 3 days."*
2. **Screen 1 (App Launch)**: Tapping alert deep-links directly to the Smart Calendar view focused on the due date.
3. **Screen 2 (Action)**: Bottom sheet displays the Citi Card bill with a 1-tap "Record Payment" button.
