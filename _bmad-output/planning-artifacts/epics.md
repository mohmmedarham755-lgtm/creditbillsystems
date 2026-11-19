---
status: final
stepsCompleted:
  - step-01-validate-prerequisites
  - step-02-design-epics
  - step-03-create-stories
  - step-04-final-validation
inputDocuments:
  - _bmad-output/planning-artifacts/prds/prd-creditbillsytems-2026-10-13/prd.md
  - _bmad-output/planning-artifacts/architecture/architecture-creditbillsytems-2026-10-13/ARCHITECTURE-SPINE.md
  - _bmad-output/planning-artifacts/ux-designs/ux-creditbillsytems-2026-10-13/DESIGN.md
  - _bmad-output/planning-artifacts/ux-designs/ux-creditbillsytems-2026-10-13/EXPERIENCE.md
---

# creditbillsytems - Epic Breakdown

## Overview

This document provides the complete epic and story breakdown for creditbillsytems, decomposing the requirements from the PRD, UX Design contract (DESIGN.md and EXPERIENCE.md), and Architecture requirements into implementable, beginner-friendly user stories.

## Requirements Inventory

### Functional Requirements

* **FR-1**: A user can register a new account using a valid email format and minimum 6-character password, creating a root profile document in Cloud Firestore.
* **FR-2**: A registered user can log in with their credentials and maintain session persistence across app launches via Firebase Authentication.
* **FR-3**: A user can trigger a password reset recovery email or securely log out, clearing active session state.
* **FR-4**: A user can create a new credit card with bank name, nickname, last 4 digits, positive credit limit, billing cycle day (1-31), and grace period days.
* **FR-5**: A user can view all added cards in a visual carousel or list displaying bank, nickname, last 4 digits, limit, and current active balance.
* **FR-6**: A user can modify card details or delete a card with confirmation, dynamically recalculating dashboard totals.
* **FR-7**: The system automatically computes aggregate and per-card credit utilization rates in real time ($(\frac{\text{Balances}}{\text{Limits}}) \times 100$).
* **FR-8**: The UI visually displays credit health tiers via a gauge and badges: Healthy ($<30\%$, Green), Moderate ($30\%-50\%$, Amber), and High Risk ($>50\%$, Red).
* **FR-9**: A user can record a monthly bill statement by selecting a card, entering total statement amount due, statement date, and due date.
* **FR-10**: The system continuously resolves and reflects bill statuses: `unpaid`, `partially_paid`, `paid`, and `overdue`.
* **FR-11**: A user can filter bills by status (`All`, `Pending`, `Paid`, `Overdue`) and inspect bill details and payment logs.
* **FR-12**: A user can record single or multiple installment payments towards an active bill with amount, date, and optional note.
* **FR-13**: Upon recording a payment, the system dynamically recalculates remaining balance and updates card and dashboard utilization metrics.
* **FR-14**: A user can view a chronological payment history ledger with support for deleting individual payments (restoring bill balance).
* **FR-15**: A user can view an interactive monthly calendar with status indicators for dates with due bills or statement cuts.
* **FR-16**: The app schedules local notifications on the user's Android device at 3 days before, 1 day before, and morning of due date.
* **FR-17**: When a bill is paid in full, all scheduled pending notifications for that bill are cancelled.

### NonFunctional Requirements

* **NFR-1**: Full 16-digit card numbers and CVVs are never stored or requested; only user-provided card nicknames and masked last 4 digits are stored.
* **NFR-2**: Cloud Firestore rules strictly enforce that `/users/{userId}/{document=**}` is accessible only when `request.auth.uid == userId`.
* **NFR-3**: Cloud Firestore offline persistence is enabled so users can access cached financial data without internet connectivity.
* **NFR-4**: Notifications are scheduled locally on-device using `flutter_local_notifications` and fire autonomously without network connection.
* **NFR-5**: Dashboard metric calculations (aggregate limit, balance, utilization percentage) complete in $< 100\text{ms}$ upon document load.
* **NFR-6**: Clean Material 3 styling with responsive layouts tested on standard Android screen resolutions.

### Additional Requirements (Architecture)

* **ARCH-1**: Layered Feature-Driven Architecture (`presentation`, `domain`, `data` within `auth`, `cards`, `dashboard`, `bills`, `payments`, `calendar`).
* **ARCH-2**: Dependency Inversion Rule: UI widgets interact strictly with Domain repository interfaces; no direct `FirebaseFirestore.instance` in widgets.
* **ARCH-3**: Hierarchical user-scoped Firestore subcollections: `/users/{uid}/cards`, `/users/{uid}/bills`, `/users/{uid}/payments`.
* **ARCH-4**: Pure Domain calculations (`CreditCalculator`, `BillStatusEvaluator`) with zero UI or Firebase dependencies for easy unit testing.
* **ARCH-5**: Provider state management (`ChangeNotifierProvider`) for beginner-friendly, reactive state without code generation.
* **ARCH-6**: Deterministic notification ID hashing from bill ID hash to manage cancellation on settlement.
* **ARCH-7**: Standardized application failure envelope (`AppException` hierarchy) surfaced via `ScaffoldMessenger` SnackBar alerts.

### UX Design Requirements

* **UX-DR1**: Material 3 Theme setup with custom palette (Deep Slate canvas `#F8FAFC`, Brand Primary `#2563EB`, Surface Card `#FFFFFF`) and dark mode support (`#0B0F19`).
* **UX-DR2**: Semantic Credit Health Color Tokens (Emerald `#10B981` for $<30\%$, Amber `#F59E0B` for $30\%-50\%$, Crimson `#EF4444` for $>50\%$).
* **UX-DR3**: Credit Card Carousel Widget with embossed payment card styling, horizontal scroll, and page snapping.
* **UX-DR4**: 270° Circular Radial Credit Utilization Gauge Widget with animated progress fill and inner text.
* **UX-DR5**: Flat 3-tab Bottom Navigation Bar (`Dashboard`, `Bills`, `Calendar`) plus Top App Bar Profile/Settings button.
* **UX-DR6**: Segmented Bill Filter Chips (`All`, `Pending`, `Paid`, `Overdue`) with instant client-side filtering.
* **UX-DR7**: Slide-Up Bottom Sheet Modal for Payment Logging with quick-fill amount chips (`Pay Full`, `Pay Half`).
* **UX-DR8**: Interactive Monthly Calendar View (`table_calendar`) with semantic colored due date indicator dots.
* **UX-DR9**: Accessibility and state handling compliance (48x48dp minimum touch targets, empty state illustrations with action buttons, and shimmer loading skeletons).

### FR Coverage Map

* **FR-1**: Epic 1 - Account Registration & Password Validation (Firebase Auth)
* **FR-2**: Epic 1 - User Authentication & Session Persistence
* **FR-3**: Epic 1 - Password Reset Recovery & Secure Logout
* **FR-4**: Epic 2 - Credit Card Creation with Cycle Rules and Validation
* **FR-5**: Epic 2 - Credit Card Portfolio Overview & Carousel Display
* **FR-6**: Epic 2 - Card Details Modification & Deletion Safeguards
* **FR-7**: Epic 3 - Real-Time Credit Utilization Rate Calculation
* **FR-8**: Epic 3 - Color-Coded Health Threshold Indicators (3 Tiers)
* **FR-9**: Epic 4 - Monthly Bill Statement Entry & Due Date Calculation
* **FR-10**: Epic 4 - Automated 4-Stage Bill Lifecycle Progression
* **FR-11**: Epic 4 - Segmented Bill Filtering & Detail Inspection
* **FR-12**: Epic 5 - Recording Installment & Full Payments
* **FR-13**: Epic 5 - Dynamic Remaining Balance & Utilization Recalculation
* **FR-14**: Epic 5 - Payment History Ledger with Delete / Restore
* **FR-15**: Epic 6 - Interactive Due Date Monthly Calendar View
* **FR-16**: Epic 6 - Scheduled Local Due Date Reminders (3d, 1d, same-day)
* **FR-17**: Epic 6 - Notification Cancellation upon Bill Settlement

## Epic List

### Epic 1: User Authentication & Profile Security
Users can register with email and password, log in, maintain persistent sessions across app restarts, and log out securely, ensuring their personal financial data is isolated in Cloud Firestore.
**FRs covered:** FR-1, FR-2, FR-3
**NFRs / Arch / UX covered:** NFR-2, ARCH-1, ARCH-2, ARCH-7

### Epic 2: Credit Card Portfolio Management
Users can add and manage multiple credit cards with nicknames, masked last 4 digits, credit limits, and billing cycle days, browsing their card inventory in a visual carousel.
**FRs covered:** FR-4, FR-5, FR-6
**NFRs / Arch / UX covered:** NFR-1, ARCH-3, ARCH-6, UX-DR3

### Epic 3: Credit Utilization Dashboard & Health Monitoring
Users can view a real-time financial health dashboard featuring an animated 270° radial utilization gauge, total credit limit versus balance summaries, and color-coded threshold warnings (<30% healthy).
**FRs covered:** FR-7, FR-8
**NFRs / Arch / UX covered:** NFR-5, UX-DR1, UX-DR2, UX-DR4, UX-DR5, ARCH-4

### Epic 4: Monthly Statement & Bill Lifecycle Management
Users can record monthly statement bills against specific cards, track payment deadlines, and view bills categorized across four lifecycle states: Unpaid, Partially Paid, Paid, and Overdue.
**FRs covered:** FR-9, FR-10, FR-11
**NFRs / Arch / UX covered:** NFR-3, UX-DR6, ARCH-3, ARCH-4

### Epic 5: Split & Partial Payment Logging
Users can record single or multiple installment payments toward active bills via a slide-up logger sheet, track dynamic balance reductions in real time, and view a payment ledger history.
**FRs covered:** FR-12, FR-13, FR-14
**NFRs / Arch / UX covered:** UX-DR7, ARCH-4, ARCH-5

### Epic 6: Smart Calendar & Automated Due Date Reminders
Users can view upcoming deadlines on an interactive monthly calendar and receive automated on-device push notifications (3 days, 1 day, and on due date) to prevent late fees, with automatic alert cancellation upon bill settlement.
**FRs covered:** FR-15, FR-16, FR-17
**NFRs / Arch / UX covered:** NFR-4, UX-DR8, ARCH-5, ARCH-6

---

## Epic 1: User Authentication & Profile Security

Users can register with email and password, log in, maintain persistent sessions across app restarts, and log out securely, ensuring their personal financial data is isolated in Cloud Firestore.

### Story 1.1: Core Architecture Scaffolding & Material 3 Theme Setup

As a developer,
I want to establish the Feature-First directory structure, Material 3 theme palette, and base routing,
So that all upcoming feature stories build upon a solid, consistent architectural foundation.

**Acceptance Criteria:**

**Given** a clean Flutter 3.41 project
**When** the app initializes in `lib/main.dart`
**Then** the folder structure matches `lib/core/` (constants, errors, theme, utils) and `lib/features/`
**And** the Material 3 `ThemeData` implements the approved Deep Slate canvas (`#F8FAFC`), Surface Card (`#FFFFFF`), Brand Primary (`#2563EB`), and dark mode tokens from `DESIGN.md`
**And** the root `MultiProvider` is configured with placeholder providers without throwing build errors.

### Story 1.2: User Registration with Email and Password

As a new user,
I want to register an account using my email and a secure password,
So that my financial cards and bills are securely saved to my personal cloud profile.

**Acceptance Criteria:**

**Given** the user is on the Register Screen
**When** the user inputs an email and a password of at least 6 characters and taps "Sign Up"
**Then** Firebase Authentication creates the account with a unique `uid`
**And** a root user profile document is initialized at `/users/{uid}` in Cloud Firestore
**And** if the email is invalid or already in use, an inline error message informs the user without an app crash.

### Story 1.3: User Login and Session Persistence

As a returning user,
I want to log in with my registered credentials and stay logged in across app launches,
So that I don't have to re-authenticate every time I open the app.

**Acceptance Criteria:**

**Given** the user has previously created an account
**When** the user submits valid email and password credentials on the Login Screen
**Then** Firebase Auth authenticates the user and navigates directly to the Main Navigation Shell
**And** on subsequent cold app starts, the auth state listener detects `currentUser` and bypasses the Login Screen
**And** invalid credentials trigger a clear error SnackBar alert: *"Invalid email or password"*.

### Story 1.4: Password Reset Recovery & Secure Logout

As an authenticated user,
I want to reset my forgotten password or log out securely,
So that I can recover my account access or protect my data when sharing my device.

**Acceptance Criteria:**

**Given** a user forgotten their password on the Login screen
**When** the user enters their email and taps "Forgot Password"
**Then** Firebase triggers a password reset email to their address
**Given** an authenticated user is on the Profile/Settings screen
**When** the user taps "Log Out"
**Then** the active Firebase session is terminated, local provider state is cleared, and the app redirects to Login.

---

## Epic 2: Credit Card Portfolio Management

Users can add and manage multiple credit cards with nicknames, masked last 4 digits, credit limits, and billing cycle days, browsing their card inventory in a visual carousel.

### Story 2.1: Credit Card Data Model & Subcollection Repository

As a developer,
I want to create the `CardModel` entity and Firestore repository adhering to Dependency Inversion,
So that card data is cleanly isolated under `/users/{uid}/cards` without exposing raw database queries to the UI.

**Acceptance Criteria:**

**Given** the domain layer for credit cards
**When** `CardModel` is instantiated
**Then** it contains fields for `id`, `cardName`, `bankName`, `last4Digits`, `creditLimit`, `billingCycleDay`, `gracePeriodDays`, and `currentBalance`
**And** `CardRepositoryImpl` implements all CRUD operations strictly targeting `/users/{userId}/cards/{cardId}`
**And** unit tests verify `CardModel.toMap()` and `fromMap()` preserve monetary values as doubles, and a separate Firestore timestamp mapper round-trips Firestore timestamps to Dart `DateTime` values without adding timestamp fields to `CardModel`.

### Story 2.2: Add New Credit Card with Input Validation

As an authenticated cardholder,
I want to add a new credit card with its credit limit, cycle day, and masked number,
So that the system can track its available balance and payment due dates.

**Acceptance Criteria:**

**Given** the user opens the "Add Card" modal form
**When** the user enters card nickname, bank name, last 4 digits (`"4812"`), limit (`$2500`), cycle day (`15`), and grace period (`20 days`) and taps "Save"
**Then** form validation verifies credit limit is $> 0$, cycle day is between 1 and 31, and last 4 digits are exactly 4 numeric characters
**And** full card numbers and CVVs are strictly disallowed (NFR-1)
**And** the card is written to Cloud Firestore and added to `CardProvider`.

### Story 2.3: Credit Card Carousel & Portfolio Display

As an authenticated user,
I want to view my credit cards in an interactive horizontal carousel with page snapping,
So that I can see each card's limit, balance, and masked number at a glance.

**Acceptance Criteria:**

**Given** the user has one or more cards saved in Firestore
**When** viewing the Dashboard or Cards surface
**Then** cards render inside a horizontal `PageView` with aspect ratio `1.586:1` styled per `DESIGN.md`
**And** each card displays the bank name, nickname, masked digits (`•••• 4812`), available limit, and cycle day
**And** if no cards exist, an empty state displays an illustration and an "+ Add Your First Card" action button.

### Story 2.4: Card Modification & Deletion with Safeguard Confirmation

As an authenticated cardholder,
I want to edit my card parameters or delete a closed credit card,
So that my card portfolio accurately reflects my active bank accounts.

**Acceptance Criteria:**

**Given** the user selects an existing card in the portfolio
**When** the user updates the credit limit from $2,500 to $3,000 and taps "Update"
**Then** the document is updated in Firestore and dashboard totals dynamically adjust
**Given** the user taps "Delete Card"
**When** the delete confirmation dialog is shown
**Then** the user must confirm the action before the card document is removed from `/users/{uid}/cards/{cardId}`.

---

## Epic 3: Credit Utilization Dashboard & Health Monitoring

Users can view a real-time financial health dashboard featuring an animated 270° radial utilization gauge, total credit limit versus balance summaries, and color-coded threshold warnings (<30% healthy).

### Story 3.1: Pure Domain Credit Utilization Calculator & Health Tiers

As a developer,
I want to implement pure domain functions for credit utilization and health tier categorization,
So that calculation logic remains consistent, reliable, and 100% unit-tested.

**Acceptance Criteria:**

**Given** a list of credit cards with limits and balances
**When** `CreditCalculator.calculateUtilization(balances, limits)` is executed
**Then** it returns $(\frac{\sum Balances}{\sum Limits}) \times 100$ rounded to 1 decimal place
**And** if total limit is 0, it returns `0.0%` without dividing by zero
**And** `CreditCalculator.getHealthTier(percentage)` returns:
  - `CreditHealthTier.healthy` if percentage $< 30\%$
  - `CreditHealthTier.moderate` if $30\% \le \text{percentage} \le 50\%$
  - `CreditHealthTier.highRisk` if percentage $> 50\%$.

### Story 3.2: 270° Circular Radial Utilization Gauge Widget

As a user,
I want to see my aggregate credit utilization rendered in an animated circular gauge,
So that I immediately understand whether my current debt usage is safe for my credit score.

**Acceptance Criteria:**

**Given** the Dashboard screen loads with card data
**When** the `UtilizationGaugeWidget` renders
**Then** it animates a $270^\circ$ circular progress arc from 0% to current utilization
**And** the arc color and status pill dynamically reflect:
  - Emerald Green (`#10B981`) with badge *"Healthy Usage (<30%)"*
  - Amber Gold (`#F59E0B`) with badge *"Moderate Usage (30-50%)"*
  - Crimson Red (`#EF4444`) with badge *"High Risk Usage (>50%)"*
**And** tapping the gauge opens an informative dialog explaining credit utilization score impacts.

### Story 3.3: Dashboard Command Center Screen Integration

As an authenticated user,
I want a consolidated Dashboard screen displaying my gauge, card carousel, and quick stats,
So that I have a single command center for my personal credit status.

**Acceptance Criteria:**

**Given** the user opens the app on the Dashboard tab
**When** the screen renders
**Then** it displays:
  1. Top App Bar with app title and Profile icon
  2. The Utilization Radial Gauge card with Total Limit and Total Unpaid metrics
  3. The Credit Card Carousel with "+ Add Card" trailing tile
  4. The Upcoming Bills list showing the top 3 closest deadlines
**And** pull-to-refresh triggers a smooth Firestore re-sync in $< 100\text{ms}$.

---

## Epic 4: Monthly Statement & Bill Lifecycle Management

Users can record monthly statement bills against specific cards, track payment deadlines, and view bills categorized across four lifecycle states: Unpaid, Partially Paid, Paid, and Overdue.

### Story 4.1: Bill Domain Model & PHP Repository

As a developer,
I want to define the `BillModel` entity and PHP repository for bill statements,
So that billing records are securely managed under user-scoped PHP API endpoints with complete status metadata.

**Acceptance Criteria:**

**Given** the domain layer for bills
**When** `BillModel` is instantiated
**Then** it includes `id`, `cardId`, `statementDate`, `dueDate`, `totalAmountDue`, `remainingBalance`, `minimumDue`, and `BillStatus`
**And** `PhpBillRepository.watchBills()` yields bills ordered by `dueDate` ascending
**And** User isolation is enforced through the existing Bearer-token PHP API
**And** Existing typed exception handling (`DatabaseException`, `AuthException`, `NetworkException`) is preserved

### Story 4.2: Record Monthly Bill Statement with Due Date Prediction

As a cardholder,
I want to log a new monthly bill statement with auto-calculated due date suggestions,
So that I can easily track upcoming statement balances.

**Acceptance Criteria:**

**Given** the user taps "+ Log Bill" in the Bills tab
**When** the user selects a card from the dropdown
**Then** the system automatically pre-fills the estimated due date based on the card's billing cycle day and grace period
**And** when the user inputs the statement amount ($900) and saves
**Then** `totalAmountDue` and `remainingBalance` are both set to $900.00
**And** initial status is set to `unpaid`.

### Story 4.3: Automated 4-State Bill Lifecycle Progression

As a developer,
I want a domain status evaluator that determines whether a bill is Unpaid, Partially Paid, Paid, or Overdue,
So that the bill lifecycle accurately updates without manual user intervention.

**Acceptance Criteria:**

**Given** an existing bill record and the current system date
**When** `BillStatusEvaluator.evaluate(bill, currentDate)` runs
**Then** it returns:
  - `BillStatus.paid` if `remainingBalance == 0.0`
  - `BillStatus.partiallyPaid` if $0 < \text{remainingBalance} < \text{totalAmountDue}$ and $\text{currentDate} \le \text{dueDate}$
  - `BillStatus.unpaid` if $\text{remainingBalance} == \text{totalAmountDue}$ and $\text{currentDate} \le \text{dueDate}$
  - `BillStatus.overdue` if $\text{currentDate} > \text{dueDate}$ and $\text{remainingBalance} > 0.0$.

### Story 4.4: Segmented Bill List Screen & Bill Detail Inspection

As an authenticated user,
I want to filter my bills by status tabs and inspect full statement details,
So that I can quickly isolate unpaid obligations from settled bills.

**Acceptance Criteria:**

**Given** the user navigates to the Bills tab
**When** the user taps the segmented chips (`All`, `Pending`, `Paid`, `Overdue`)
**Then** the list instantly filters without network delays
**And** tapping a bill tile opens the Bill Detail screen displaying statement breakdown, payment countdown (e.g., *"Due in 4 days"*), and the primary "Record Payment" action.

---

## Epic 5: Split & Partial Payment Logging

Users can record single or multiple installment payments toward active bills via a slide-up logger sheet, track dynamic balance reductions in real time, and view a payment ledger history.

### Story 5.1: Payment Domain Model & Atomic Subcollection Updates

As a developer,
I want to create the `PaymentModel` entity and atomic repository operations,
So that recording a payment writes a payment record and updates the parent bill balance atomically.

**Acceptance Criteria:**

**Given** a payment transaction
**When** `PaymentRepository.recordPayment(payment)` is executed
**Then** it writes a payment document to `/users/{uid}/payments/{paymentId}`
**And** updates `remainingBalance` and `status` on the parent bill document in a Firestore batch or transaction
**And** updates the corresponding credit card's active balance.

### Story 5.2: Slide-Up Payment Logger Modal with Quick Presets

As a user,
I want to open a slide-up payment sheet with quick-fill amount buttons,
So that I can log full or partial payments in seconds without tedious manual typing.

**Acceptance Criteria:**

**Given** a user is on the Bill Detail screen of an unpaid or partially paid bill
**When** the user taps "Record Payment"
**Then** a Material 3 Bottom Sheet slides up taking 60% screen height with focused numeric input
**And** quick-fill chips are available:
  - `Pay Full ($XXX)`: fills exact `remainingBalance`
  - `Pay Half ($XXX)`: fills 50% of `remainingBalance`
**And** tapping "Confirm Payment" emits a subtle haptic feedback, records the payment, and dismisses the sheet.

### Story 5.3: Dynamic Remaining Balance & Metric Recalculation

As a user,
I want the bill balance and dashboard gauge to update immediately after logging an installment,
So that I see the instant impact of my payment on my debt and utilization score.

**Acceptance Criteria:**

**Given** an active bill of $600 with remaining balance $600
**When** the user logs a partial payment of $350
**Then** the bill status updates immediately to `Partially Paid` with remaining balance `$250.00`
**And** the Dashboard utilization gauge drops accordingly
**And** when a subsequent payment of $250 is logged, the bill status transitions to `Paid` with a green checkmark.

### Story 5.4: Payment History Ledger with Revert / Delete Support

As a user,
I want to view a chronological payment ledger and delete mistaken payment entries,
So that I maintain an accurate, auditable history of my credit card transactions.

**Acceptance Criteria:**

**Given** the user views the Payment History tab or Bill Detail section
**When** payment entries exist
**Then** they render in reverse chronological order showing amount, formatted date (`dd MMM yyyy`), and optional note
**And** if a user accidentally logged an incorrect payment, swiping or tapping "Delete" restores the subtracted amount back to the bill's `remainingBalance` with a confirmation dialog.

---

## Epic 6: Smart Calendar & Automated Due Date Reminders

Users can view upcoming deadlines on an interactive monthly calendar and receive automated on-device push notifications (3 days, 1 day, and on due date) to prevent late fees, with automatic alert cancellation upon bill settlement.

### Story 6.1: Interactive Monthly Due Date Calendar Screen

As an authenticated user,
I want to view my bill due dates and statement cycles on an interactive calendar,
So that I can visually map out payment deadlines across the month.

**Acceptance Criteria:**

**Given** the user navigates to the Calendar tab
**When** the screen loads
**Then** a monthly calendar renders using `table_calendar` with custom dot markers:
  - Amber/Red dots on dates with pending unpaid bills
  - Green dots on dates with fully paid bills
**And** tapping any highlighted date displays a bottom modal listing all bills due on that day with direct "Record Payment" shortcuts.

### Story 6.2: Scheduled Local Notifications Engine

As a busy user,
I want to receive local device alerts 3 days before, 1 day before, and on the morning of a bill due date,
So that I never miss a payment deadline or incur costly late fees.

**Acceptance Criteria:**

**Given** a new bill is created with a future due date
**When** `NotificationService.scheduleBillReminders(bill)` executes
**Then** using `flutter_local_notifications` and `timezone`, three local notifications are scheduled:
  1. 3 days prior to due date at 09:00 AM local time
  2. 1 day prior to due date at 09:00 AM local time
  3. On the due date at 08:00 AM local time
**And** notification IDs are generated deterministically using the bill ID hash (AD-5)
**And** tapping a notification launches the app directly into that bill's detail view.

### Story 6.3: Automatic Notification Cancellation upon Bill Settlement

As a user,
I want scheduled notifications to be cancelled as soon as I settle a bill,
So that I am not bothered by phantom alarms after my bill is already paid.

**Acceptance Criteria:**

**Given** a bill with pending scheduled notifications
**When** the bill's remaining balance reaches `$0.00` (status becomes `paid`)
**Then** `NotificationService.cancelBillReminders(billId)` is called
**And** all three scheduled notification IDs mapped to that bill are cancelled from the Android notification manager
**And** if a payment is subsequently deleted (restoring a balance $>0$), reminders are re-scheduled automatically.

