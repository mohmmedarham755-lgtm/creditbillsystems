# Product Brief Addendum: Credit Bill System

This addendum preserves technical constraints, downstream design decisions, and evaluated alternatives captured during product brief discovery. These details feed directly into the PRD (`bmad-prd`) and Architecture (`bmad-architecture`) phases.

---

## 1. Technical Architecture & Constraints

* **Frontend**: Flutter (Dart), targeting Android first, structured cleanly for seamless iOS compilation in later releases.
* **Backend & Authentication**: 
  * Firebase Authentication (Email/Password login and registration).
  * Cloud Firestore as the primary NoSQL datastore with per-user data isolation via Firestore Security Rules.
* **Notification System**:
  * Local notifications (`flutter_local_notifications`) scheduled on device for payment due date alerts (e.g., 3 days before, 1 day before, and on due date).
* **State Management & UI**:
  * Clean modern Flutter UI (Material 3).
  * Data visualization using chart packages (e.g., `fl_chart`) for the Credit Utilization Gauge.

---

## 2. Options Considered & Alternatives Deferred

| Feature Concept | Decision | Rationale |
| :--- | :--- | :--- |
| **Direct Bank / Plaid Integration** | **Rejected / Out of Scope** | Requires enterprise banking API agreements, high subscription costs, and complex OAuth compliance that is out of scope for an academic project. |
| **Android SMS Transaction Parsing** | **Deferred to Future Roadmap** | Requires sensitive Google Play permissions (`READ_SMS`), is fragile across different bank SMS formats, and does not work on iOS. Manual entry guarantees 100% control and cross-platform consistency. |
| **Local-Only vs. Cloud Storage** | **Cloud Selected (Firebase)** | Cloud Firestore enables multi-device sync, secure authentication, and prevents data loss if the user uninstalls the app or changes devices. |

---

## 3. Core Domain Models & Business Logic

### A. Credit Utilization Logic
* Formula: $\text{Utilization \%} = \frac{\sum \text{Outstanding Balances}}{\sum \text{Credit Limits}} \times 100$
* Indicator Thresholds:
  * Healthy: $< 30\%$ (Green)
  * Moderate: $30\% - 50\%$ (Amber/Yellow)
  * High Risk: $> 50\%$ (Red / Alert)

### B. Bill Lifecycle States
1. **Unpaid**: Bill statement generated, full amount pending.
2. **Partially Paid**: Partial payment recorded; remaining balance tracked.
3. **Paid**: Balance cleared ($0 remaining).
4. **Overdue**: Due date passed with balance $> 0$.

---

## 4. Downstream Handoff Notes

* **For John (Product Manager - PRD)**: Formalize functional requirements for Card CRUD, Bill generation, Payment logging, and Notification triggers.
* **For Sally (UX Designer)**: Focus on a dashboard with Card Carousel, Utilization Radial Gauge, Upcoming Bills timeline, and a simple 3-step Payment Logger modal.
* **For Winston (Architect)**: Design Firestore data schema (`users`, `cards`, `bills`, `payments`) with indexes and security rules ensuring users can only read/write their own records.
