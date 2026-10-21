# Epic 2 Context: Credit Card Portfolio Management

<!-- Compiled from planning artifacts. Edit freely. Regenerate with compile-epic-context if planning docs change. -->

## Goal

Let authenticated users maintain their own credit-card portfolio with manually entered, privacy-conscious card details, then use the portfolio to track limits, balances, and billing cycles. Never collect full payment-card numbers or CVVs; Firestore access must isolate every user's records. Portfolio views should show each user's cards and remain usable with Firestore's local cache when offline.

## Stories

- Story 2.1: Credit Card Data Model & Subcollection Repository
- Story 2.2: Add New Credit Card with Input Validation
- Story 2.3: Credit Card Carousel & Portfolio Display
- Story 2.4: Card Modification & Deletion with Safeguard Confirmation

## Requirements & Constraints

- Card records capture a nickname, bank name, last four digits, credit limit, billing-cycle day, grace period, and current balance.
- Support card create/read/update/delete under the owning user's cards subcollection. Users may read or mutate only records within their authenticated UID.
- Persist only masked card identifiers; do not request or store full PAN, CVV, PIN, or magnetic-stripe data.
- Monetary values use doubles; card dates map between Dart date values and Firestore timestamps. Available credit is the credit limit less current balance.
- Portfolio empty state offers an Add Your First Card action; card details include bank, nickname, masked digits, limit/current balance, and cycle information.

## Technical Decisions

- Keep card feature code in `lib/features/cards/` and respect Presentation / Domain / Data boundaries. Widgets depend on domain contracts, not Firestore.
- Firestore business documents belong beneath `/users/{userId}/cards/{cardId}`; server-side rules must require authenticated UID ownership.
- Follow established repository constructor injection for Firebase dependencies and the project's typed application exception conventions.
- Manage feature state with Provider `ChangeNotifier`; widgets consume state and invoke actions through Provider.

## UX & Interaction Patterns

- The Dashboard hosts a horizontally snapping credit-card carousel, with the next card peeking into view and an Add Card tile at the end; use the 1.586:1 card ratio.
- Card surfaces show nickname, bank, masked last four digits, available balance, limit, and billing-cycle information; never expose full card credentials.
- Follow the existing Material 3 theme, 16dp card spacing/radii, and approved card styling. Show a minimal credit-card illustration and Add Your First Card action for an empty portfolio.
- Honor loading, error, accessibility, and offline-cache behavior established for app content.

## Cross-Story Dependencies

- The card model and repository provide the persistence foundation for card entry, portfolio display, and editing/deletion stories.
