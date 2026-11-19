---
foundation:
  platform: "Flutter (mobile)"
  uiSystem: "Material Design 3"
  designSpec: "../DESIGN.md"
informationArchitecture:
  screens:
    - name: "WelcomeScreen"
      purpose: "Introduce the app and invite the user to start the authentication flow"
      components:
        - AppBar
        - Text (title)
        - FloatingActionButton (extended)
voiceAndTone:
  brandVoice: "Friendly, approachable, trustworthy"
  microcopy:
    title: "Welcome"
    button: "Get Started"
componentPatterns:
  appBar:
    behavior: "Static, no back navigation"
  fabExtended:
    behavior: "Navigates to AuthGate when pressed"
statePatterns:
  fab:
    default: "Enabled"
    pressed: "Ripple effect"
    disabled: "Greyed out (not used in this screen)"
interactionPrimitives:
  tap:
    description: "Navigate to AuthGate"
    analyticsEvent: "welcome_get_started_tapped"
accessibilityFloor:
  contrast:
    textVsBackground: "4.5:1 minimum"
  labels:
    fab: "Get Started button"
keyFlows:
  welcomeJourney:
    protagonist: "Alex"
    device: "Android phone"
    steps:
      - description: "Opens the app and sees the Welcome screen"
        action: "Read title and description"
      - description: "Taps the Get Started button"
        action: "Navigates to AuthGate"
        climax: "Enters authentication flow"
responsiveAndPlatform:
  tablet: "Same layout, centered with larger padding"
  web: "Not currently targeted"
---

## Foundation
- **Platform:** Flutter mobile app (Android & iOS) using Material Design 3.
- **Design reference:** All visual tokens are defined in [`DESIGN.md`](../DESIGN.md).

## Information Architecture
- **Screen:** `WelcomeScreen`
- **Purpose:** Provide a brief, friendly introduction and a clear entry point to the authentication flow.
- **Core components:** `AppBar`, `Text` (title), `FloatingActionButton.extended`.

## Voice and Tone
- **Brand voice:** Friendly, approachable, trustworthy.
- **Microcopy:**
  - Title: **“Welcome”**
  - Button label: **“Get Started”**

## Component Patterns
- **AppBar:** Static, no back navigation, displays the title.
- **FAB (extended):** Primary call‑to‑action; on tap it pushes a replacement route to `AuthGate`.

## State Patterns
- **FAB:**
  - **Default:** Enabled, primary colour.
  - **Pressed:** Material ripple effect.
  - **Disabled:** Not applicable on this screen.

## Interaction Primitives
- **Tap on Get Started:**
  - Triggers navigation to `AuthGate`.
  - Emits analytics event `welcome_get_started_tapped`.

## Accessibility Floor
- **Contrast:** Text (`#000000`) vs. background (`#E3F2FD`) meets ≥ 4.5:1.
- **Screen‑reader label:** FAB labelled “Get Started button”.

## Key Flows
### Welcome Journey (Alex, Android phone)
1. **Open app** – sees the Welcome screen with title and button.
2. **Read title** – understands the app’s purpose.
3. **Tap Get Started** – navigates to the authentication gate (climax). 

## Responsive & Platform
- **Tablet:** Same layout, centered; increase page padding to 32 dp.
- **Web:** Currently not targeted; if later needed, layout will remain centered with responsive breakpoints.

## Do's and Don'ts
- **Do** keep the screen minimal – only title and primary action.
- **Do** ensure the button is reachable via keyboard navigation on accessibility tools.
- **Don't** add extra navigation elements (back button, menu) on this introductory screen.
- **Don't** use text that violates the brand voice; stay friendly and concise.
