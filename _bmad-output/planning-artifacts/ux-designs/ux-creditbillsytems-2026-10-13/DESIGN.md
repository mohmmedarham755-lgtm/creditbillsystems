---
name: Credit Bill System
description: Clean, modern fintech personal credit manager. Material 3 native, calm, trustworthy, debt-aware.
status: final
updated: 2026-10-13
colors:
  # Light Mode Palette
  surface-base: '#F8FAFC'
  surface-card: '#FFFFFF'
  surface-raised: '#F1F5F9'
  text-primary: '#0F172A'
  text-secondary: '#475569'
  text-muted: '#94A3B8'
  brand-primary: '#2563EB'
  brand-primary-light: '#EFF6FF'
  border-subtle: '#E2E8F0'
  
  # Status & Utilization Health Tiers
  health-healthy: '#10B981'        # <30% Utilization (Emerald)
  health-healthy-bg: '#ECFDF5'
  health-moderate: '#F59E0B'       # 30-50% Utilization (Amber)
  health-moderate-bg: '#FFFBEB'
  health-risk: '#EF4444'           # >50% Utilization (Crimson)
  health-risk-bg: '#FEF2F2'
  
  # Dark Mode Palette
  surface-base-dark: '#0B0F19'
  surface-card-dark: '#151D2C'
  surface-raised-dark: '#1E293B'
  text-primary-dark: '#F8FAFC'
  text-secondary-dark: '#94A3B8'
  text-muted-dark: '#64748B'
  brand-primary-dark: '#3B82F6'
  border-subtle-dark: '#1E293B'
  health-healthy-dark: '#34D399'
  health-moderate-dark: '#FBBF24'
  health-risk-dark: '#F87171'

typography:
  display:
    size: '32px'
    weight: 700
    line-height: '40px'
    note: 'Material 3 Headline Medium — Total limits and utilization percentage'
  title:
    size: '20px'
    weight: 600
    line-height: '28px'
    note: 'Material 3 Title Large — Screen headers and card nicknames'
  body:
    size: '15px'
    weight: 400
    line-height: '22px'
    note: 'Material 3 Body Medium — Transaction rows and descriptions'
  meta:
    size: '12px'
    weight: 500
    line-height: '16px'
    note: 'Material 3 Label Small — Badges, dates, masked card numbers'

rounded:
  sm: '8px'      # Buttons, tags, text fields
  md: '16px'     # Cards, list tiles, dialogs
  lg: '24px'     # Bottom sheets, utilization gauge cards
  full: '9999px' # Status pill badges, circular action buttons

spacing:
  '1': '4px'
  '2': '8px'
  '3': '12px'
  '4': '16px'
  '5': '20px'
  '6': '24px'
  '8': '32px'
---

# Credit Bill System — Visual Design System (DESIGN.md)

## Brand & Style

The **Credit Bill System** visual language is engineered for financial clarity and psychological calm. Personal finance apps too often trigger anxiety through cluttered data grids, neon gradients, or alarming popups. This design adopts a quiet, structured fintech aesthetic: high-contrast typography, generous negative space, soft tactile surfaces, and purposeful semantic color. 

Rather than treating color as decoration, color is reserved strictly for financial state signals:
* **Slate Navy (`#2563EB`)**: Signals navigation and primary user intent (adding cards, recording payments).
* **Emerald Green (`#10B981`)**: Reassures safe utilization ($<30\%$) and fully settled bills.
* **Amber Gold (`#F59E0B`)**: Cautions that spending is approaching credit score risk thresholds ($30\%-50\%$) or due dates are near.
* **Crimson Red (`#EF4444`)**: Alerts the user to high-risk utilization ($>50\%$) or overdue payments.

---

## Colors

### Canvas & Surfaces
* **Canvas (`surface-base` / `#F8FAFC`)**: A cool, glare-free light slate canvas that prevents eye fatigue.
* **Card Surface (`surface-card` / `#FFFFFF`)**: Pure white containers elevated slightly above the canvas to establish clear visual hierarchy.
* **Raised Surface (`surface-raised` / `#F1F5F9`)**: Subtle background tint used for text input fields, inactive tabs, and segmented controls.

### Health & Utilization Semantics
* **Healthy (< 30%)**: Background `{colors.health-healthy-bg}`, foreground `{colors.health-healthy}`. Indicates optimal credit health that improves credit scores.
* **Moderate (30% - 50%)**: Background `{colors.health-moderate-bg}`, foreground `{colors.health-moderate}`. Warns the user before heavy credit impact occurs.
* **High Risk (> 50%)**: Background `{colors.health-risk-bg}`, foreground `{colors.health-risk}`. Prominently highlights debt concentration that damages credit ratings.

---

## Typography

The typography follows Android **Material 3 Typography Scale**, implemented cleanly using Flutter's default platform sans-serif (`Roboto` on Android).

1. **Display Large (`display`)**: Bold, high-visibility numeric display used for the aggregate credit limit and utilization gauge percentage (e.g., `24.5%`).
2. **Title (`title`)**: Semi-bold, grounding header font used for Card Titles, Bill Section titles, and App Bar headers.
3. **Body (`body`)**: Highly legible neutral font for form labels, transaction notes, and breakdown rows.
4. **Meta / Label (`meta`)**: Monospaced-leaning small label for masked card digits (`•••• 4128`), dates (`Due 28 Oct`), and status badges.

---

## Layout & Spacing

* **8-Point Grid System**: All margins, paddings, and component heights adhere to multiples of 4dp and 8dp.
* **Screen Padding**: Standard outer horizontal padding of `16px` (`spacing.4`) on mobile screens, expanding to `24px` on tablets.
* **Component Rhythm**:
  * Intra-card spacing: `8px` (`spacing.2`) between related labels and values.
  * Card-to-card separation: `16px` (`spacing.4`) vertically in lists.
  * Section separation: `24px` (`spacing.6`) between Dashboard summary widgets and lists.

---

## Elevation & Depth

Material 3 tonal elevation is utilized rather than heavy skeuomorphic drop shadows:
* **Level 0 (Flat)**: Background canvas and full-screen containers.
* **Level 1 (Card Elevation)**: Subtle 1dp shadow (`color: rgba(15, 23, 42, 0.05)`, `blur: 4px`, `offset: (0, 2)`) for credit card widgets and bill list tiles.
* **Level 2 (Active/Floating)**: 3dp elevation for the primary Floating Action Button (`Add Card` / `Log Bill`).
* **Level 3 (Modal/Sheet)**: 8dp elevation with a 40% dim barrier for the Bottom Sheet Payment Logger.

---

## Shapes

* **Buttons & Inputs**: `rounded.sm` (`8px`) for sharp, professional form controls.
* **Cards & Containers**: `rounded.md` (`16px`) providing modern, friendly corners without looking cartoonish.
* **Bottom Sheets & Dialogs**: `rounded.lg` (`24px`) top corners for smooth slide-up drawer animations.
* **Status Badges**: `rounded.full` (`9999px`) pill shape ensuring status badges look distinct from actionable buttons.

---

## Components

### 1. Credit Card Carousel Widget
* **Visual Representation**: Styled like an embossed payment card with subtle linear gradient (Deep Navy to Slate, or bank-themed accents).
* **Content**: Bank name, card nickname, chip icon, masked digits (`•••• 4812`), available balance, and credit limit.
* **Dimensions**: Fixed aspect ratio `1.586 : 1` (standard credit card ratio), horizontal scroll with page snapping.

### 2. Utilization Radial Gauge
* **Visual Representation**: Thick circular progress arc ($270^\circ$ sweep) centered on the dashboard.
* **Inner Display**: Large display percentage in center (e.g., `28%`), accompanied by a sub-caption: `Healthy Utilization` or `Alert: High Risk`.
* **Track Color**: Subtle grey `{colors.border-subtle}` with animated fill using the semantic tier color (`health-healthy`, `health-moderate`, or `health-risk`).

### 3. Bill Status List Tile
* **Visual Representation**: Clean horizontal row with bank logo / card icon on the left, bill metadata in the center (due date, remaining balance), and a pill badge on the right.
* **Status Badges**:
  * `Unpaid`: Amber pill with clock icon.
  * `Partially Paid`: Blue pill with fraction icon (e.g., `$350 left`).
  * `Paid`: Green pill with checkmark icon.
  * `Overdue`: Red pill with exclamation badge.

### 4. Slide-Up Payment Logger Sheet
* **Visual Representation**: Half-height modal sheet sliding from the bottom.
* **Fields**: Prominent currency input field, quick-select chips (`Pay Full Balance`, `Pay Minimum Due`, `Custom Amount`), date picker, and full-width "Record Payment" button.

---

## Do's and Don'ts

| Do | Don't |
| :--- | :--- |
| **Do** use green exclusively for healthy financial states (paid, $<30\%$ utilization). | **Don't** use green as decorative button backgrounds where users might confuse it for status. |
| **Do** mask credit card numbers to show only the last 4 digits (`•••• 1234`). | **Don't** ever display or prompt for 16-digit PANs or CVVs. |
| **Do** show explicit remaining balances on partially paid bills (e.g., *"$200 of $500 paid — $300 remaining"*). | **Don't** hide payment math behind complex dropdowns. |
| **Do** maintain a strict 48x48dp minimum touch target for all buttons and interactive chips. | **Don't** place tiny icon buttons close together without touch padding. |
| **Do** provide instant visual feedback on text inputs (currency symbol prefix, decimal formatting). | **Don't** allow free-form raw text input in currency amount fields. |
