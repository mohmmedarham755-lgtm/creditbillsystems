---
title: "Product Brief: Credit Bill System"
status: finalized
created: 2026-10-12
updated: 2026-10-13
---

# Product Brief: Credit Bill System

## Executive Summary

The **Credit Bill System** is a mobile-first personal finance application built with Flutter and powered by Firebase, designed to empower users to manage multiple credit cards effortlessly, stay on top of payment deadlines, and protect their credit scores. Modern consumers frequently juggle several credit cards across different banks, each with distinct statement cycles, payment grace periods, credit limits, and interest rules. Missing a single payment incurs steep penalties and harms credit ratings, while relying on manual spreadsheets or bloated enterprise budgeting tools creates unnecessary friction.

This application provides a focused, streamlined command center for credit card users. By pairing manual, privacy-respecting data entry with real-time cloud synchronization, the Credit Bill System delivers proactive due date reminders, transparent bill lifecycle management, and actionable credit health visualization without requiring access to sensitive bank login credentials.

Conceived as an academic project and portfolio showcase, the app emphasizes software engineering rigor: robust authentication, isolated cloud data persistence, scheduled local notifications, and clean Material 3 design, establishing a dependable foundation for future cross-platform expansion.

---

## The Problem

Managing personal credit cards in today's economy presents distinct everyday frustrations:

* **Cognitive Overload across Multiple Cards**: Users holding 2 to 5 credit cards face staggered statement generation dates and payment deadlines. Keeping mental track of what is due, when, and to which bank frequently leads to missed deadlines and expensive late fees.
* **Credit Score Blindspots**: Many cardholders do not realize that using more than 30% of their total credit limit negatively impacts their credit score, even if they pay bills on time. Existing basic reminder apps do not calculate aggregate utilization.
* **All-or-Nothing Payment Tracking**: Most simple bill trackers treat payments as binary (*Paid* or *Unpaid*). In real life, users often make split or partial payments across paychecks. Without partial balance tracking, tracking outstanding debt becomes messy.
* **Privacy & Complexity Barriers**: Mainstream financial aggregators demand direct bank login credentials via third-party APIs, which many users distrust, while generic spreadsheet apps lack push reminders and mobile convenience.

---

## The Solution

The Credit Bill System solves these pain points through a purpose-built personal credit dashboard:

1. **Centralized Card Registry**: Quick manual setup of cards recording card nickname, bank, last 4 digits, credit limit, statement generation day, and grace period.
2. **Proactive Bill Calendar & Local Alerts**: A dedicated calendar timeline displaying upcoming statement cut-offs and due dates, backed by reliable device notifications before payments are due.
3. **Dynamic Credit Utilization Gauge**: An instant visual indicator of total and per-card credit utilization, highlighting healthy usage ($<30\%$) and warning against high-risk balances.
4. **Flexible Bill Lifecycle & Split Payments**: Tracking bills across four distinct states (*Unpaid*, *Partially Paid*, *Paid*, *Overdue*) with clear logging of partial payments and automatic remaining balance recalculation.

---

## What Makes This Different

* **Zero Bank-Credential Anxiety**: By utilizing streamlined manual entry, users retain total control over their data without linking sensitive bank accounts or granting invasive SMS permissions.
* **Credit Health-Centric**: Unlike generic expense trackers, the app specifically emphasizes credit utilization metrics and billing cycle mechanics that safeguard the user's credit profile.
* **Partial Payment Native**: Designed from the ground up to support staggered payments, accurately calculating remaining liabilities after each installment.
* **Reliable & Cloud-Synchronized**: Combines Firebase Authentication and Cloud Firestore for seamless multi-device persistence with device-native scheduled notifications.

---

## Who This Serves

### Primary User: The Multi-Card Cardholder
* **Profile**: Young professionals, students, and tech-savvy individuals managing 2 or more credit cards.
* **Needs**: A clean, single-screen overview of upcoming dues, automated reminders to avoid fees, and clarity on credit limit utilization.
* **Success State**: Never pays a late fee, stays comfortably below the 30% utilization threshold, and feels completely in control of monthly credit liabilities.

### Secondary Audience: Academic Evaluators & Portfolio Reviewers
* **Profile**: Professors, recruiters, and engineering hiring managers.
* **Needs**: Demonstrable software engineering principles, clean separation of concerns, secure data handling, and an intuitive, polished mobile UX.

---

## Scope

### In-Scope for Version 1.0 (MVP)
* **Secure User Authentication**: Firebase Email/Password signup, login, session persistence, and logout.
* **Credit Card Management**: Full CRUD (Create, Read, Update, Delete) for credit cards including card label, bank name, last 4 digits, credit limit, and cycle dates.
* **Monthly Bill Tracking**: Generate monthly billing statements, track due dates, and update statuses (*Unpaid*, *Partially Paid*, *Paid*, *Overdue*).
* **Split / Partial Payments**: Record single or multiple payments against an active bill with a searchable transaction history log.
* **Credit Utilization Gauge**: Visual dashboard widget calculating total and individual credit utilization with color-coded safety thresholds ($<30\%$ Green, $30\%-50\%$ Amber, $>50\%$ Red).
* **Smart Calendar & Local Notifications**: Interactive calendar view of upcoming deadlines paired with local scheduled reminders (3 days before and on the due date).

### Out-of-Scope (Deferred to Future Roadmap)
* Direct Open Banking / Plaid bank account auto-sync.
* Automatic SMS message parsing.
* Multi-currency conversion rates.
* Shared or joint family credit card accounts.
* Export to external accounting software (QuickBooks/Excel).

---

## Success Criteria

* **Functional Reliability**: 100% crash-free core user flows (authentication, card creation, bill generation, payment logging, and calendar navigation).
* **Data Security & Privacy**: Strict Cloud Firestore security rules guaranteeing complete user data isolation—users can only query and mutate their own financial documents.
* **Notification Dependability**: Local reminders reliably trigger at scheduled intervals ahead of bill due dates on Android devices.
* **Usability & Presentation**: A responsive Material 3 interface that is intuitive for first-time users and visually compelling for academic presentation.

---

## Future Vision

If successfully adopted, future iterations will expand the app into an end-to-end intelligent credit assistant:
* **iOS & Web Deployment**: Leveraging Flutter's cross-platform core to compile natively for iOS and the web.
* **On-Device Statement OCR**: Allowing users to snap photos of physical statements or upload PDFs for automated local parsing without external API exposure.
* **Optimized Payoff Strategies**: Algorithmic recommendations for debt repayment (Avalanche vs. Snowball methods) to minimize interest payments across cards.
