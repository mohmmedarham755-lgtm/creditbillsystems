---
colors:
  primary: "#2196F3"
  accent: "#1976D2"
  background: "#E3F2FD"
typography:
  fontFamily: "Roboto"
  heading:
    size: 24
    weight: "Bold"
  body:
    size: 14
    weight: "Regular"
rounded:
  default: "8dp"
spacing:
  base: "4dp"
  pagePadding: "24dp"
components:
  appBar:
    backgroundColor: "{colors.primary}"
    elevation: "4dp"
  fab:
    backgroundColor: "{colors.accent}"
    shape: "rounded"
  text:
    color: "#000000"
  icon:
    color: "#000000"
images:
  welcome:
    path: "assets/images/welcome.jpg"
    description: "Welcome‑page illustration"
---

## Brand & Style
The Welcome screen uses the primary brand colour **#2196F3** (Material Blue 500) for the app bar and accent actions. The secondary accent colour **#1976D2** provides a slightly darker shade for the “Get Started” button. A light‑blue background **#E3F2FD** creates a friendly, open feel.

## Colors
- **Primary**: `{colors.primary}` – app bar, FAB background
- **Accent**: `{colors.accent}` – button background, interactive highlights
- **Background**: `{colors.background}` – scaffold background
- **Text**: `#000000` – high‑contrast black for body copy

## Typography
- **Font family**: `{typography.fontFamily}` – Roboto, the default Android material font.
- **Heading**: `{typography.heading.size}` sp, **Bold** – used for the Welcome title.
- **Body**: `{typography.body.size}` sp, **Regular** – used for descriptive text.

## Layout & Spacing
- Base spacing unit: `{spacing.base}` – foundation for margins and paddings.
- Page padding: `{spacing.pagePadding}` – applied to the central column.

## Elevation & Depth
- AppBar elevation: `4dp` – gives a subtle shadow separating it from content.
- FAB elevation: default material elevation (`6dp`).

## Shapes
All rectangular components use a corner radius of `{rounded.default}` for a gentle, modern look.

## Components
- **AppBar** – background colour `{colors.primary}`, title “Welcome”.
- **FloatingActionButton (extended)** – background `{colors.accent}`, icon `arrow_forward`, label “Get Started”.
- **Text** – colour `#000000`, centre‑aligned.
- **Icon** – colour `#000000`.

## Do's and Don'ts
- **Do** maintain at least a 4.5:1 contrast ratio between text (`#000000`) and the background (`#E3F2FD`).
- **Do** keep headings title‑cased, never use all‑caps.
- **Don't** overload the screen with additional decorative elements – the design is intentionally minimal.
- **Don't** use colours outside the defined palette for primary UI elements.
