---
name: Retail Modern Tactile
colors:
  surface: '#faf8ff'
  surface-dim: '#d2d9f4'
  surface-bright: '#faf8ff'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#f2f3ff'
  surface-container: '#eaedff'
  surface-container-high: '#e2e7ff'
  surface-container-highest: '#dae2fd'
  on-surface: '#131b2e'
  on-surface-variant: '#434655'
  inverse-surface: '#283044'
  inverse-on-surface: '#eef0ff'
  outline: '#747686'
  outline-variant: '#c4c5d7'
  surface-tint: '#2151da'
  primary: '#0037b0'
  on-primary: '#ffffff'
  primary-container: '#1d4ed8'
  on-primary-container: '#cad3ff'
  inverse-primary: '#b7c4ff'
  secondary: '#006c4a'
  on-secondary: '#ffffff'
  secondary-container: '#82f5c1'
  on-secondary-container: '#00714e'
  tertiary: '#8f000b'
  on-tertiary: '#ffffff'
  tertiary-container: '#bb0112'
  on-tertiary-container: '#ffc7c1'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#dce1ff'
  primary-fixed-dim: '#b7c4ff'
  on-primary-fixed: '#001551'
  on-primary-fixed-variant: '#0039b5'
  secondary-fixed: '#85f8c4'
  secondary-fixed-dim: '#68dba9'
  on-secondary-fixed: '#002114'
  on-secondary-fixed-variant: '#005137'
  tertiary-fixed: '#ffdad6'
  tertiary-fixed-dim: '#ffb4ab'
  on-tertiary-fixed: '#410002'
  on-tertiary-fixed-variant: '#93000b'
  background: '#faf8ff'
  on-background: '#131b2e'
  surface-variant: '#dae2fd'
typography:
  headline-xl:
    fontFamily: Space Grotesk
    fontSize: 40px
    fontWeight: '700'
    lineHeight: 48px
    letterSpacing: -0.03em
  headline-xl-mobile:
    fontFamily: Space Grotesk
    fontSize: 30px
    fontWeight: '700'
    lineHeight: 36px
    letterSpacing: -0.02em
  headline-lg:
    fontFamily: Space Grotesk
    fontSize: 32px
    fontWeight: '700'
    lineHeight: 40px
    letterSpacing: -0.02em
  headline-lg-mobile:
    fontFamily: Space Grotesk
    fontSize: 24px
    fontWeight: '700'
    lineHeight: 32px
    letterSpacing: -0.01em
  headline-md:
    fontFamily: Space Grotesk
    fontSize: 22px
    fontWeight: '600'
    lineHeight: 28px
    letterSpacing: -0.01em
  title-lg:
    fontFamily: Plus Jakarta Sans
    fontSize: 18px
    fontWeight: '700'
    lineHeight: 26px
    letterSpacing: 0em
  title-md:
    fontFamily: Plus Jakarta Sans
    fontSize: 16px
    fontWeight: '600'
    lineHeight: 24px
    letterSpacing: 0em
  body-lg:
    fontFamily: Plus Jakarta Sans
    fontSize: 16px
    fontWeight: '500'
    lineHeight: 24px
    letterSpacing: 0em
  body-md:
    fontFamily: Plus Jakarta Sans
    fontSize: 14px
    fontWeight: '400'
    lineHeight: 20px
    letterSpacing: 0em
  body-sm:
    fontFamily: Plus Jakarta Sans
    fontSize: 12px
    fontWeight: '500'
    lineHeight: 16px
    letterSpacing: 0.01em
  currency-display:
    fontFamily: Space Grotesk
    fontSize: 36px
    fontWeight: '700'
    lineHeight: 44px
    letterSpacing: -0.02em
  currency-table:
    fontFamily: JetBrains Mono
    fontSize: 15px
    fontWeight: '600'
    lineHeight: 20px
    letterSpacing: -0.01em
  label-code:
    fontFamily: JetBrains Mono
    fontSize: 12px
    fontWeight: '500'
    lineHeight: 16px
    letterSpacing: 0.02em
  label-caps:
    fontFamily: Plus Jakarta Sans
    fontSize: 11px
    fontWeight: '700'
    lineHeight: 14px
    letterSpacing: 0.06em
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  gutter: 1rem
  gutter-sm: 0.75rem
  margin: 1rem
  margin-desktop: 2rem
  space-xs: 0.25rem
  space-sm: 0.5rem
  space-md: 0.75rem
  space-lg: 1rem
  space-xl: 1.5rem
---

## Brand & Style

This design system is engineered for the high-velocity, high-stress reality of neighborhood retail counters, dukans, and busy storefronts. The interface prioritizes tactile confidence, instantaneous readability from arm's length, and rapid tap accuracy under bright ambient store lighting or harsh daylight conditions.

### Design Movement
**Tactile Functional Modernism:** A synthesis of utility-first retail ergonomics and modern digital tactile feedback. The aesthetic eschews decorative fluff in favor of physical button affordances, crisp 1px structural dividing lines, micro-embossed interactive planes, and hyper-legible numerals. The system bridges physical registers and mobile-first agility with an uncompromising dedication to contrast, semantic speed, and thumb-driven ergonomics.

### Personality & Tone
- **Unyielding Reliability:** Solid, grounded, and dependable. Transactions feel definitive and safe.
- **Velocity & Clutter-Free Clarity:** Every millimeter of screen real estate is optimized for rapid checkout, swift stock updates, and friction-free ledger (Khata) reconciliation.
- **Empowering Familiarity:** Professional and modern without feeling overly corporate or alien to independent shop owners.

## Colors

The palette is engineered with extreme semantic clarity, optimized for rapid scanning across inventory counts, credit balances, and register totals.

### Color Palette Architecture
- **Primary (`#1D4ED8` - Retail Cobalt):** Commands primary actions, payment confirmations, navigation anchors, and focal state triggers. Conveys banking-grade security and institutional trust.
- **Secondary (`#059669` - Ledger Emerald):** Dedicated strictly to positive transactional flow: full payment received, cash inflow, healthy stock, settled balance, and completed orders.
- **Tertiary (`#DC2626` - Alert Crimson):** Expresses urgency: outstanding store credit (Baki/Udhar), depleted stock, deficit balances, and destructive actions.
- **Warning Accent (`#D97706` - Due Amber):** Denotes partial payments, impending due dates, and minimum reorder thresholds.
- **Neutral Surface & Ink (`#0F172A` - Slate Charcoal):** Delivers WCAG AAA-compliant visual hierarchy against pure white (`#FFFFFF`) and slate canvas layers (`#F8FAFC`). In dark mode, it inverts into deep obsidian (`#090D16`) with high-luminance slate text (`#F1F5F9`).

### Palette Tokens & Roles
- **Surface Canvas (Light):** `#F8FAFC`
- **Surface Card / Container:** `#FFFFFF`
- **Border / Divider Rule:** `#E2E8F0` (Dark: `#1E293B`)
- **Text Primary:** `#0F172A` (Dark: `#F8FAFC`)
- **Text Secondary / Muted:** `#475569` (Dark: `#94A3B8`)
- **Text Interactive / Link:** `#1D4ED8` (Dark: `#3B82F6`)

## Typography

Typography balances bold, industrial structure with rapid readability across noisy visual environments.

### Font Family System
- **Space Grotesk (Headlines & Currency Keynotes):** Offers geometric authority and distinctive character. Numerals are balanced, crisp, and unambiguous—making transaction totals, grand sums, and daily revenue metrics readable even at a glance or angle.
- **Plus Jakarta Sans (Interface & Ergonomic Body):** Provides rounded, humanist warmth combined with clean modern grotesque clarity. Open apertures preserve legibility at smaller text sizes on compact mobile screens.
- **JetBrains Mono (Receipts, Invoices, Barcodes, & Currency Line-Items):** Strictly monospaced for columnar alignment in checkout slips, bill manifests, itemized calculations, and SKU identification.

### Currency Formatting Rules
Currency glyphs (e.g., `৳`, `₹`, `$`) inherit their scale directly from the parent numeral style, retaining identical stroke weight to avoid visually disjointed totals. Large balance indicators use `currency-display`, whereas transaction receipts use `currency-table` to enforce crisp tabular alignment across decimal points.

## Layout & Spacing

The layout is built upon an 8-point base spatial grid (with a 4-point micro-scale for compact table density and badges).

### Viewport Adaptation & Breakpoints
- **Mobile Handheld (360px – 599px):** 4-column fluid layout with `1rem` outer canvas margin and `0.75rem` gutters. All primary transaction controls are pinned to a dedicated bottom action bar (persistent thumb zone).
- **Tablet / Countertop POS Dock (600px – 1023px):** 8-column layout. Split-pane default: left pane (60%) handles item selection/catalog matrix; right pane (40%) maintains real-time cart summary and payment controls.
- **Desktop / Back-Office Management (1024px+):** 12-column layout with max container width of 1440px and `2rem` outer padding. Allows multi-column analytics, inventory spreadsheets, and vendor reconciliation sidebars.

### Touch Ergonomics
All primary interactive elements (buttons, quantity steppers, category tabs, drawer triggers) enforce a strict minimum boundary of 48px × 48px to prevent missed taps during rapid checkout transactions.

## Elevation & Depth

This system avoids floating, amorphous drop shadows in favor of structured tactile planes, micro-bevels, and distinct surface boundaries.

### Tactile Elevation Hierarchy
- **Level 0 (Flat / Canvas):** Surface color `#F8FAFC`. Used for window backdrop, non-clickable layout groupings, and empty ledger regions.
- **Level 1 (Card / Resting Tile):** `#FFFFFF` surface framed by a crisp `1px solid #E2E8F0` border and a delicate tactile anchor shadow: `0 1px 3px 0 rgba(15, 23, 42, 0.06), 0 1px 2px -1px rgba(15, 23, 42, 0.04)`.
- **Level 2 (Interactive Floating / Active State):** Raised cards, bottom transaction bar, and dropdown flyouts. `0 4px 6px -1px rgba(15, 23, 42, 0.08), 0 2px 4px -2px rgba(15, 23, 42, 0.06)`. Border color subtly adjusts to `#CBD5E1`.
- **Level 3 (Modals, Slide-over Drawers, Keypad Sheets):** `0 20px 25px -5px rgba(15, 23, 42, 0.12), 0 8px 10px -6px rgba(15, 23, 42, 0.08)`. Overlay dimming uses `#0F172A` at 45% opacity.

### Interactive Press States
Buttons and tactile cards utilize an active press effect: transforming downward by `1px` (`translateY(1px)`) while shedding shadow blur. This provides immediate, physical feedback on mobile touchscreens without relying solely on sound cues.

## Shapes

The interface embraces a balanced, sturdy corner treatment (Level 2: `0.5rem` / `8px` baseline) designed to feel durable, clean, and structurally sound without looking excessively bubbly or toy-like.

### Shape Hierarchy
- **Micro Radii (`4px` / `space-xs`):** Status indicators, inline category tags, ledger badges, table row indicators.
- **Component Radii (`8px` / `0.5rem`):** Inputs, buttons, card enclosures, numeric keypad keys, dropdown trigger selectors.
- **Container Radii (`12px` – `16px` / `rounded-lg`):** Bottom sheets, modal overlays, invoice detail blocks, and full-width checkout carts.
- **Full Radius (Pill / 9999px):** Quick-filter chips, counter badges, barcode scan triggers.

## Components

### Buttons
- **Primary Transactional:** Solid `#1D4ED8`, white bold text, minimum 52px height for primary mobile triggers (e.g., "Charge Cash", "Confirm Order"). Active state dims to `#1E40AF` with a `1px` inner inset shadow.
- **Secondary (Credit / Split Actions):** `#F1F5F9` background, `#0F172A` text, `1px solid #CBD5E1`.
- **Destructive / Due:** Crimson `#DC2626` background or light red tint `#FEF2F2` with `#991B1B` text for credit removal or cancellation.

### Semantic Status Badges & Chips
- **Paid / In Stock / Positive Revenue:** Emerald container `#ECFDF5`, text `#065F46`, border `#A7F3D0`.
- **Due / Outstanding Credit / Low Stock:** Amber container `#FFFBEB`, text `#92400E`, border `#FDE68A`.
- **Overdue / Out of Stock / Loss:** Crimson container `#FEF2F2`, text `#991B1B`, border `#FECACA`.
- **Badge Anatomy:** Rendered with `label-caps` typography, `4px` padding inline, height fixed at 24px, vertical center-aligned.

### Cart & Catalog Cards
- Constructed with `#FFFFFF` background, `1px solid #E2E8F0`, and `roundedness: 2` (8px). 
- Products feature high-contrast title typography (`title-md`), highlighted price in `currency-table`, and an integrated tactile `+` stepper button positioned right at the bottom corner for rapid one-handed basket building.

### Input Fields & Numeric Keypads
- **Form Inputs:** 48px height, `1px solid #CBD5E1` border, `#FFFFFF` background, active focus ring `2px solid #1D4ED8` with zero blur offset.
- **POS Touch Keypad:** Large numeric grid with 64px height keys, `Space Grotesk` bold digits, tactile borders, dedicated quick-add currency presets (`+৳100`, `+৳500`, `+৳1000`).

### Persistent Bottom Action Bar (Checkout Bar)
- Pinned to the screen bottom with `safe-area-inset-bottom`.
- Elevated at Level 2 depth. Features split hierarchy: left side displays total item count and bold `currency-display` sum; right side houses the primary, full-width checkout trigger.

### Digital Receipt Line
- Monospaced typography (`JetBrains Mono`), paper-white background, subtle dashed dividing rules (`1px dashed #CBD5E1`), strictly aligned right-hand figures for fast human verification.