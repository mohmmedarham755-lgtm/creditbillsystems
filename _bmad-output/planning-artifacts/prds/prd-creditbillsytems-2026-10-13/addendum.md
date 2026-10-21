# PRD Addendum: Technical Specifications & Downstream Handoff

This addendum preserves technical architecture decisions, Firestore data design patterns, and package choices to guide the System Architect (`bmad-architecture`) and Developer (`bmad-build`) without cluttering the capability-focused PRD.

---

## 1. Cloud Firestore Data Schema Recommendation

To ensure beginner-friendly development and bulletproof security rules, data is organized in hierarchical subcollections scoped directly to the authenticated user ID (`uid`):

```text
/users/{userId}
  ├── email: string
  ├── displayName: string
  ├── createdAt: timestamp
  │
  ├── /cards/{cardId}
  │     ├── cardName: string (e.g. "Chase Sapphire")
  │     ├── bankName: string (e.g. "Chase")
  │     ├── last4Digits: string (e.g. "4129")
  │     ├── creditLimit: number (e.g. 5000.00)
  │     ├── billingCycleDay: number (1-31)
  │     ├── gracePeriodDays: number (e.g. 21)
  │     ├── currentBalance: number (e.g. 1250.00)
  │     └── createdAt: timestamp
  │
  ├── /bills/{billId}
  │     ├── cardId: string (foreign key to card)
  │     ├── statementDate: timestamp
  │     ├── dueDate: timestamp
  │     ├── totalAmountDue: number (e.g. 850.00)
  │     ├── remainingBalance: number (e.g. 350.00)
  │     ├── minimumDue: number (optional, e.g. 35.00)
  │     ├── status: string ("unpaid" | "partially_paid" | "paid" | "overdue")
  │     └── updatedAt: timestamp
  │
  └── /payments/{paymentId}
        ├── billId: string (foreign key to bill)
        ├── cardId: string (foreign key to card)
        ├── amountPaid: number (e.g. 500.00)
        ├── paymentDate: timestamp
        ├── paymentNote: string (optional)
        └── createdAt: timestamp
```

### Firestore Security Rules Baseline
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId}/{document=**} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

---

## 2. Notification Mechanics (`flutter_local_notifications`)

* **Channel ID**: `credit_bill_reminders`
* **Channel Name**: `Bill Payment Reminders`
* **Trigger Strategy**:
  * Reminder 1: 3 days prior to `dueDate` at 09:00 AM local time.
  * Reminder 2: 1 day prior to `dueDate` at 09:00 AM local time.
  * Reminder 3: On the morning of `dueDate` at 08:00 AM local time.
* **Cancellation**: When a bill's remaining balance hits $0.00 (status becomes `paid`), the app cancels pending notifications associated with `billId`.

---

## 3. Recommended Flutter Dependencies
* `firebase_core`, `firebase_auth`, `cloud_firestore`: Authentication and database.
* `provider` or `flutter_riverpod`: Lightweight, clean state management suitable for academic evaluation.
* `flutter_local_notifications` & `timezone`: Local scheduled notifications.
* `fl_chart`: For rendering the circular Credit Utilization gauge and payment breakdown charts.
* `intl`: Currency and date formatting (`yyyy-MM-dd`).
* `table_calendar`: Interactive monthly calendar widget for due dates.
