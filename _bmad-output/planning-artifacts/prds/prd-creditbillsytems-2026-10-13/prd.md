---
title: "PRD: Credit Bill System"
status: final
created: 2026-10-13
updated: 2026-10-13
---

# PRD: Credit Bill System

## 0. Document Purpose

This Product Requirements Document (PRD) defines the complete functional and non-functional requirements for the **Credit Bill System**, a personal credit card and bill tracking application built with Flutter (Android first) and Firebase. It serves as the single source of truth for academic project reviewers, UX design (`bmad-ux`), technical architecture (`bmad-architecture`), and test-driven implementation (`bmad-build`). All requirements are scoped to ensure high academic rigor and reliable software engineering practices while remaining beginner-friendly and feasible to construct.

---

## 1. Vision

The **Credit Bill System** is a clean, focused, mobile-first personal finance application that frees users from the cognitive chaos of managing multiple credit cards. In modern banking, consumers frequently hold several cards across various financial institutions—each with separate credit limits, distinct statement cut-off dates, varying payment grace periods, and steep penalties for late payments. Missing a payment deadline incurs substantial late fees and directly damages credit ratings, while exceeding healthy credit utilization limits quietly suppresses credit scores.

The application serves as a personal credit command center. By pairing deliberate, privacy-respecting manual data entry with secure cloud synchronization via Firebase, users gain a real-time visual gauge of their aggregate credit utilization, an interactive calendar of upcoming payment deadlines, and flexible support for partial or split payments across paychecks.

As an academic and portfolio project, the app demonstrates disciplined software engineering: rigorous client-server authentication, isolated NoSQL data persistence in Cloud Firestore, scheduled on-device background notifications, and a responsive Material 3 design, establishing a dependable baseline for future multi-platform expansion.

---

## 2. Target User

### 2.1 Jobs To Be Done (JTBD)
* **Functional (Core)**: "When my credit card statements are generated, I want to record my statement balance and due date in one central place, so that I never miss a payment deadline or incur late fees."
* **Financial Health**: "When I spend on my cards, I want to see my total credit utilization percentage against my combined credit limits, so that I keep my utilization under 30% to protect my credit score."
* **Budget Flexibility**: "When I cannot pay a lump sum at once, I want to make and log partial payments over the month, so that I know exactly how much balance remains on each bill before the due date."
* **Cognitive Relief**: "When I am busy with everyday life, I want my phone to proactively alert me 3 days and 1 day before payments are due, so that I don't have to constantly check banking portals."
* **Portfolio / Academic**: "When evaluating this project, evaluators and recruiters must see clean separation of concerns, secure data handling, and robust real-world error handling."

### 2.2 Non-Users (v1)
* **High-Frequency Corporate Treasuries**: The app is not designed for business accounting, corporate payroll, or multi-user expense auditing.
* **Hands-Off Aggregator Users**: Users who insist on zero manual effort and demand automated direct bank screen-scraping (e.g., Plaid/Yodlee) are explicitly excluded from v1.0.

### 2.3 Key User Journeys

#### UJ-1. Daniel registers and adds his credit cards
* **Persona & Context**: Daniel, a university graduate with two credit cards (HDFC and ICICI), wants to organize his cards for the upcoming semester.
* **Entry State**: Unauthenticated; opens app on Android.
* **Path**:
  1. Daniel taps "Sign Up", enters email and password, and registers instantly via Firebase Auth.
  2. Directed to the Empty Dashboard; taps the "Add Card" action button.
  3. Enters card nickname ("HDFC Millennia"), last 4 digits ("4812"), credit limit ($2,500), billing cycle day (15th), and payment due day (5th).
  4. Saves card; enters a second card ("ICICI Amazon Pay", limit $1,500).
* **Climax**: The dashboard populates with a total credit limit of $4,000 and 0% utilization with both cards displayed in a horizontal carousel.
* **Resolution**: Ready to log statements as bills arrive.
* **Edge Case**: If Daniel accidentally enters a negative credit limit or non-numeric digits, input validation immediately flags the error inline before submission.

#### UJ-2. Maya logs a new statement and checks credit utilization
* **Persona & Context**: Maya receives an email stating her monthly card bill is $900.
* **Entry State**: Authenticated, existing cardholder with a total credit limit of $3,000.
* **Path**:
  1. Maya opens the app and navigates to the "Bills" tab.
  2. Taps "New Bill", selects her card, sets statement amount ($900), and confirms the due date.
  3. Taps "Save Bill".
* **Climax**: The app recalculates her utilization gauge from 0% to 30.0%, turning the indicator amber to alert her that she is touching the healthy threshold limit.
* **Resolution**: The bill appears on her dashboard with status `Unpaid`.
* **Edge Case**: If Maya attempts to create a duplicate bill for the same card in the same billing period, the system prompts her with a warning dialog.

#### UJ-3. Alex makes two partial payments across paychecks
* **Persona & Context**: Alex has an active bill of $600 due on the 28th. On the 15th (payday), he pays $350.
* **Entry State**: Authenticated; bill shows $600 with status `Unpaid`.
* **Path**:
  1. Alex opens the bill details and taps "Record Payment".
  2. Enters $350 and selects today's date.
  3. The bill status updates immediately to `Partially Paid` with a remaining balance of $250.
  4. On the 25th, Alex records the remaining $250 payment.
* **Climax**: The bill balance updates to $0.00 and status automatically transitions to `Paid` with a green checkmark.
* **Resolution**: Pending push notifications for this bill are cancelled automatically.
* **Edge Case**: If Alex attempts to enter a payment of $300 when only $250 is remaining, the system displays an overpayment confirmation modal before accepting the payment.

#### UJ-4. Sarah receives a due-date reminder and checks the calendar
* **Persona & Context**: Sarah is working and forgets that a card payment is due in 3 days.
* **Entry State**: App is running in background or closed; device is connected to local system clock.
* **Path**:
  1. At 09:00 AM, Sarah receives a local Android notification: *"Payment Reminder: Your Citi Card bill of $420 is due in 3 days."*
  2. Taps the notification; app opens directly to the Smart Calendar view.
  3. Sees the 20th marked with an amber deadline pin and views the bill breakdown.
* **Climax**: Sarah pays the bill on her bank portal and marks the bill paid in the app.
* **Resolution**: The calendar badge updates from pending to settled.

---

## 3. Glossary

* **Credit Card**: A credit account managed by the user, characterized by a card label, issuing bank name, masked last 4 digits, credit limit, and cycle dates.
* **Credit Limit**: The maximum credit line authorized by the bank for a card.
* **Outstanding Balance**: The current unpaid balance owed on a card or active bill.
* **Billing Cycle Day**: The calendar day of the month on which the card statement is generated.
* **Payment Due Date**: The calendar deadline by which at least the minimum or total statement balance must be paid to avoid penalties.
* **Bill**: An individual monthly statement record tied to a specific Credit Card, containing statement date, due date, total amount due, and remaining balance.
* **Bill Status**: The lifecycle state of a Bill:
  * `Unpaid`: Total statement balance is fully pending ($RemainingBalance == TotalAmountDue$).
  * `Partially Paid`: One or more payments recorded, but $0 < RemainingBalance < TotalAmountDue$.
  * `Paid`: Bill balance is completely settled ($RemainingBalance == 0$).
  * `Overdue`: Current date is past the Payment Due Date and $RemainingBalance > 0$.
* **Credit Utilization Rate**: The ratio of total outstanding balances to total combined credit limits, expressed as a percentage: $(\frac{\sum Balances}{\sum Limits}) \times 100$.
* **Partial Payment**: An installment payment made toward an active Bill that is less than the total outstanding balance.
* **Local Reminder Notification**: An on-device notification scheduled via `flutter_local_notifications` triggered prior to or on the Payment Due Date.

---

## 4. Features

### 4.1 User Authentication & Profile Security
**Description**: Provides individual account security using Firebase Authentication. Each user’s cards, bills, and payments are strictly segregated to their authenticated user identifier (`uid`). Realizes UJ-1.

#### FR-1: Account Registration & Password Validation
* **Capability**: A user can register a new account using a valid email address and password.
* **Consequences (testable)**:
  - System requires a valid email format (`user@domain.com`) and minimum 6-character password.
  - Returns user-friendly error messages on duplicates (`email-already-in-use`) or weak passwords (`weak-password`).
  - Creates a corresponding root user profile record in Cloud Firestore (`/users/{uid}`).

#### FR-2: User Authentication & Session Persistence
* **Capability**: A registered user can log in with their credentials and maintain session state across app restarts.
* **Consequences (testable)**:
  - Valid credentials transition user directly to the Home Dashboard.
  - Invalid credentials present an explicit error notification without crashing.
  - App launch automatically checks Firebase Auth state; if authenticated, bypasses Login screen.

#### FR-3: Password Reset & Secure Logout
* **Capability**: A user can trigger a password recovery email or securely terminate their active session.
* **Consequences (testable)**:
  - Tapping "Forgot Password" prompts for email and triggers Firebase password reset email.
  - Tapping "Log Out" clears local user state, terminates the auth session, and redirects to the Login screen.

---

### 4.2 Credit Card Portfolio Management
**Description**: Allows users to manage multiple credit cards. Serves as the master portfolio for limit calculations and billing cycles. Realizes UJ-1.

#### FR-4: Credit Card Creation with Validation
* **Capability**: A user can add a new credit card with bank name, nickname, last 4 digits, credit limit, billing cycle day, and grace period days.
* **Consequences (testable)**:
  - Credit limit must be a positive number $> 0$.
  - Billing cycle day must be an integer between 1 and 31.
  - Last 4 digits must be exactly 4 numeric characters.
  - Upon save, creates a document in `/users/{uid}/cards/{cardId}` and recalculates aggregate dashboard limits within $< 500\text{ms}$.

#### FR-5: Credit Card Portfolio Overview
* **Capability**: A user can view all added cards in a visual carousel or list displaying card bank, nickname, last 4 digits, limit, and current active balance.
* **Consequences (testable)**:
  - If no cards exist, displays an engaging empty state with an "Add Your First Card" button.
  - Cards are ordered chronologically by creation or upcoming due date.

#### FR-6: Card Modification & Deletion Safeguards
* **Capability**: A user can edit card parameters or delete a card from their portfolio.
* **Consequences (testable)**:
  - Updating credit limit dynamically triggers dashboard utilization recalculation.
  - Deleting a card displays a confirmation warning: *"Deleting this card will archive its associated bills."*
  - Deleting a card removes the card record and cascades cleanup or soft-deletes associated bills.

---

### 4.3 Dynamic Credit Utilization Dashboard
**Description**: Real-time visual dashboard calculating and displaying aggregate and card-level credit utilization against financial safety thresholds. Realizes UJ-1, UJ-2.

#### FR-7: Real-Time Utilization Rate Calculation
* **Capability**: The system automatically computes the aggregate utilization rate: $\text{Rate} = (\frac{\text{Total Unpaid Balances}}{\text{Total Credit Limits}}) \times 100$.
* **Consequences (testable)**:
  - If total credit limit is $0, utilization rate is displayed as $0.0\%$.
  - If total balance is $600 and total limit is $2,000, rate displays exactly $30.0\%$.
  - Updates in real time whenever a bill is created, modified, or paid.

#### FR-8: Color-Coded Health Threshold Indicators
* **Capability**: The UI visually indicates credit health tier via a circular gauge and badge:
  - **Healthy (Green)**: Utilization $< 30\%$
  - **Moderate (Amber)**: Utilization $30\% - 50\%$
  - **High Risk (Red)**: Utilization $> 50\%$
* **Consequences (testable)**:
  - At $29.9\%$, indicator renders in Theme Success (Green).
  - At $30.0\%$, indicator switches to Warning (Amber) and shows guidance: *"Approaching credit score impact threshold."*
  - At $50.1\%$, indicator switches to Danger (Red) and displays a high utilization warning.

---

### 4.4 Monthly Statement & Bill Lifecycle Management
**Description**: Tracks individual monthly billing cycles, statements, and statuses for each credit card. Realizes UJ-2, UJ-3.

#### FR-9: Monthly Bill Entry & Due Date Calculation
* **Capability**: A user can log a bill statement by selecting a card, entering total statement amount due, statement date, and due date.
* **Consequences (testable)**:
  - System prepopulates estimated due date based on the card’s saved cycle day and grace period.
  - Amount due must be $> 0$.
  - Initial `remainingBalance` is set equal to `totalAmountDue`.
  - Initial `status` is set to `unpaid`.

#### FR-10: Automated Lifecycle State Progression
* **Capability**: The system continuously resolves and reflects the correct bill status: `unpaid`, `partially_paid`, `paid`, or `overdue`.
* **Consequences (testable)**:
  - When $0 < \text{remainingBalance} < \text{totalAmountDue}$, status is `partially_paid`.
  - When $\text{remainingBalance} == 0$, status is `paid`.
  - When current system date $>$ `dueDate` and $\text{remainingBalance} > 0$, status is automatically evaluated as `overdue`.

#### FR-11: Bill Filtering & Detail Inspection
* **Capability**: A user can filter bills by status (`All`, `Pending/Unpaid`, `Paid`, `Overdue`) and tap a bill to inspect payment history.
* **Consequences (testable)**:
  - Filtering by `Pending` excludes all bills with status `paid`.
  - Bill detail view displays card nickname, due date countdown (e.g., "Due in 4 days"), total amount, amount paid, and remaining balance.

---

### 4.5 Split & Partial Payment Logging
**Description**: Supports real-world debt repayment where users make multiple partial payments across paychecks rather than a single lump sum. Realizes UJ-3.

#### FR-12: Recording Installment & Full Payments
* **Capability**: A user can log a payment towards an active bill by entering payment amount, payment date, and optional note (e.g., "Paycheck 1").
* **Consequences (testable)**:
  - Payment amount must be $> 0$.
  - Saves a payment record in `/users/{uid}/payments/{paymentId}`.
  - Updates parent bill document atomically in Firestore.

#### FR-13: Dynamic Balance & State Recalculation
* **Capability**: Upon recording a payment, the system immediately recalculates the bill's `remainingBalance` and updates the card's active balance.
* **Consequences (testable)**:
  - On a $500 bill, recording $200 updates `remainingBalance` to $300 and status to `partially_paid`.
  - Recording the remaining $300 updates `remainingBalance` to $0 and status to `paid`.
  - If a payment equals or clears remaining balance, marks bill paid and updates dashboard utilization accordingly.

#### FR-14: Payment History Ledger
* **Capability**: A user can view a chronological audit log of all payments made toward a specific bill or across all cards.
* **Consequences (testable)**:
  - Displays list of payments with amount, formatted date (`dd MMM yyyy`), and optional note.
  - Individual payments can be deleted, which automatically restores the corresponding balance to the bill.

---

### 4.6 Smart Bill Calendar & Local Reminder Notifications
**Description**: Integrates a visual calendar view of deadlines with automated background notifications. Realizes UJ-4.

#### FR-15: Interactive Due Date Calendar
* **Capability**: A user can view a monthly calendar displaying dot indicators or badges on dates where bills are due or statements are cut.
* **Consequences (testable)**:
  - Days with unpaid bills display an amber or red marker; days with settled bills display a green marker.
  - Tapping a highlighted date reveals a bottom sheet listing all bills due on that day.

#### FR-16: Scheduled Local Due Date Reminders
* **Capability**: When a bill is created, the app schedules local notifications on the user's Android device:
  - 3 days before due date at 09:00 AM local time.
  - 1 day before due date at 09:00 AM local time.
  - On the due date at 08:00 AM local time.
* **Consequences (testable)**:
  - Reminders are registered with unique notification IDs mapped to the bill ID.
  - Notification payload contains card name, amount due, and due date.
  - Tapping notification launches the app directly into the Bill details view.

#### FR-17: Notification Cancellation upon Bill Settlement
* **Capability**: When a bill's remaining balance reaches $0.00 (`paid`), all scheduled pending notifications for that bill are cancelled.
* **Consequences (testable)**:
  - Cancelling notifications prevents ghost alarms after a bill is already paid.

---

## 5. Non-Goals (Explicit)

To protect the academic timeline and ensure reliable completion:
* **No Direct Banking API / Plaid Sync**: The app will not connect to bank APIs or require bank user credentials.
* **No Background SMS Parsing**: The app will not request Android SMS read permissions to automatically extract transaction receipts.
* **No Multi-Currency Exchange Engine**: All monetary values are treated in the user's local primary currency without real-time forex conversions.
* **No Multi-User / Shared Accounts**: The app is designed for individual cardholders; joint family accounts or card sharing are deferred.
* **No External Payment Gateway Integration**: The app records that payments occurred; it does not process actual bank-to-bank money transfers via Stripe/UPI/ACH.

---

## 6. MVP Scope

### 6.1 In Scope (v1.0)
* Firebase Email/Password Authentication & Session Management.
* Credit Card CRUD with limit, nickname, last 4 digits, and billing cycle days.
* Real-time circular Credit Utilization gauge with 3-tier health thresholds ($<30\%$, $30-50\%$, $>50\%$).
* Monthly Bill generation and 4-stage lifecycle management (`unpaid`, `partially_paid`, `paid`, `overdue`).
* Partial and split payment logging with remaining balance auto-calculation.
* Payment history transaction ledger with delete/undo support.
* Monthly Smart Calendar view with due date markers.
* Local background notifications via `flutter_local_notifications` scheduled 3 days, 1 day, and on due date.

### 6.2 Out of Scope for MVP (Deferred to v2.0+)
* Optical Character Recognition (OCR) for camera statement scanning (`[NON-GOAL for MVP]`).
* Automated debt repayment strategy simulators (Avalanche vs. Snowball payoff calculators) (`[NON-GOAL for MVP]`).
* CSV/PDF statement export or import (`[NON-GOAL for MVP]`).
* Native iOS release and deployment to Apple App Store (planned for v2.0; architecture will remain cross-platform clean).

---

## 7. Success Metrics

### Primary Metrics
* **SM-1 (Flow Completion Stability)**: 100% crash-free sessions across end-to-end user journeys (Sign up $\to$ Add Card $\to$ Create Bill $\to$ Partial Payment $\to$ Full Settlement). Validates FR-1 through FR-14.
* **SM-2 (Data Integrity & Isolation)**: 100% compliance with Firestore user security rules—no user can read or write documents belonging to another `userId`. Validates FR-1, FR-4, FR-9, FR-12.

### Secondary Metrics
* **SM-3 (Notification Reliability)**: 100% of scheduled due date alerts trigger on Android test devices at scheduled local times for active unpaid bills. Validates FR-16, FR-17.

### Counter-Metrics (Do Not Optimize)
* **SM-C1 (Input Speed vs. Data Accuracy)**: Do not optimize card creation by skipping input validation rules (e.g., permitting negative limits or empty card names) to shave 2 seconds off creation time. Accuracy and data integrity supersede entry speed.

---

## 8. Cross-Cutting Non-Functional Requirements (NFRs)

### 8.1 Security & Privacy
* **NFR-1 (Client-Side Masking)**: Full card numbers and CVVs are **never** stored or requested. Only user-provided card nicknames and last 4 digits are recorded.
* **NFR-2 (Cloud Security Rules)**: Cloud Firestore database rules enforce that `/users/{userId}/{document=**}` is strictly accessible only when `request.auth.uid == userId`.

### 8.2 Reliability & Offline Usability
* **NFR-3 (Firestore Local Cache)**: Cloud Firestore offline persistence is enabled, allowing users to view existing cards and bills even when cellular or Wi-Fi connectivity is temporarily lost.
* **NFR-4 (Local Notification Autonomy)**: Reminders are scheduled locally on the device and fire regardless of internet connectivity.

### 8.3 Performance & UI
* **NFR-5 (Response Latency)**: Dashboard metric calculations (aggregate limit, balance, utilization gauge) complete in $< 100\text{ms}$ upon document load.
* **NFR-6 (Design Standard)**: Clean Material 3 styling with responsive layouts tested on standard Android screen resolutions (phone form-factors).

---

## 9. Open Questions

1. **Currency Symbol Configuration**: Should the app include a simple settings toggle to pick currency symbol ($, ₹, €, £) or default to the device's local system locale?  
   * *Resolution recommendation*: Use Flutter's `intl` package to automatically format currency based on device locale with a manual symbol override in settings.
2. **Notification Time Preferences**: Should the reminder trigger time (09:00 AM) be user-configurable in v1.0 or hardcoded for simplicity?  
   * *Resolution recommendation*: Hardcode to 09:00 AM for v1.0 MVP to avoid complex settings UI, deferring custom notification time to v2.0.

---

## 10. Assumptions Index

* `[ASSUMPTION: §4.1]`: Standard Firebase Auth Email/Password provider is sufficient without third-party OAuth (Google Sign-In) for v1.0.
* `[ASSUMPTION: §4.2]`: Storing only the last 4 digits and user nicknames satisfies user identification without PCI-DSS compliance scope.
* `[ASSUMPTION: §4.3]`: Standard 30% credit utilization threshold is universal and aligns with general credit bureau recommendations (Experian, Equifax, TransUnion, CIBIL).
* `[ASSUMPTION: §4.6]`: Android 13+ `POST_NOTIFICATIONS` runtime permission will be requested gracefully on first app launch or when the first bill is scheduled.
