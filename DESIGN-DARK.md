---
name: Tactical Slate Retail POS
colors:
  surface: '#0f131d'
  surface-dim: '#0f131d'
  surface-bright: '#353944'
  surface-container-lowest: '#0a0e18'
  surface-container-low: '#171b26'
  surface-container: '#1c1f2a'
  surface-container-high: '#262a35'
  surface-container-highest: '#313540'
  on-surface: '#dfe2f1'
  on-surface-variant: '#c2c6d6'
  inverse-surface: '#dfe2f1'
  inverse-on-surface: '#2c303b'
  outline: '#8c909f'
  outline-variant: '#424754'
  surface-tint: '#adc6ff'
  primary: '#adc6ff'
  on-primary: '#002e6a'
  primary-container: '#4d8eff'
  on-primary-container: '#00285d'
  inverse-primary: '#005ac2'
  secondary: '#4edea3'
  on-secondary: '#003824'
  secondary-container: '#00a572'
  on-secondary-container: '#00311f'
  tertiary: '#ffb95f'
  on-tertiary: '#472a00'
  tertiary-container: '#ca8100'
  on-tertiary-container: '#3e2400'
  error: '#ffb4ab'
  on-error: '#690005'
  error-container: '#93000a'
  on-error-container: '#ffdad6'
  primary-fixed: '#d8e2ff'
  primary-fixed-dim: '#adc6ff'
  on-primary-fixed: '#001a42'
  on-primary-fixed-variant: '#004395'
  secondary-fixed: '#6ffbbe'
  secondary-fixed-dim: '#4edea3'
  on-secondary-fixed: '#002113'
  on-secondary-fixed-variant: '#005236'
  tertiary-fixed: '#ffddb8'
  tertiary-fixed-dim: '#ffb95f'
  on-tertiary-fixed: '#2a1700'
  on-tertiary-fixed-variant: '#653e00'
  background: '#0f131d'
  on-background: '#dfe2f1'
  surface-variant: '#313540'
typography:
  display-lg:
    fontFamily: Space Grotesk
    fontSize: 36px
    fontWeight: '700'
    lineHeight: 44px
    letterSpacing: -0.03em
  headline-lg:
    fontFamily: Space Grotesk
    fontSize: 28px
    fontWeight: '700'
    lineHeight: 36px
    letterSpacing: -0.02em
  headline-md:
    fontFamily: Space Grotesk
    fontSize: 22px
    fontWeight: '600'
    lineHeight: 28px
    letterSpacing: -0.01em
  headline-sm:
    fontFamily: Space Grotesk
    fontSize: 18px
    fontWeight: '600'
    lineHeight: 24px
  body-lg:
    fontFamily: Space Grotesk
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 24px
  body-md:
    fontFamily: Space Grotesk
    fontSize: 14px
    fontWeight: '400'
    lineHeight: 20px
  body-sm:
    fontFamily: Space Grotesk
    fontSize: 12px
    fontWeight: '400'
    lineHeight: 16px
  label-lg:
    fontFamily: Space Grotesk
    fontSize: 14px
    fontWeight: '600'
    lineHeight: 20px
    letterSpacing: 0.02em
  label-md:
    fontFamily: Space Grotesk
    fontSize: 12px
    fontWeight: '600'
    lineHeight: 16px
    letterSpacing: 0.04em
  label-sm:
    fontFamily: Space Grotesk
    fontSize: 10px
    fontWeight: '700'
    lineHeight: 14px
    letterSpacing: 0.06em
  stat-currency:
    fontFamily: Space Grotesk
    fontSize: 30px
    fontWeight: '700'
    lineHeight: 36px
    letterSpacing: -0.02em
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  gutter: 0.75rem
  margin: 1rem
  space-xs: 0.25rem
  space-sm: 0.5rem
  space-md: 0.75rem
  space-lg: 1rem
  space-xl: 1.5rem
---

## Brand & Style

This design system is tailored for fast-paced FMCG and retail environments, balancing immediate tactical legibility with a high-end, modern dark interface. The target audience consists of busy shop owners, store managers, and retail cashiers who operate handheld terminals or mobile phones in fluctuating retail lighting—from brightly lit storefront aisles to dim stockrooms. 

The aesthetic is precision-driven, tactical, and utilitarian. It merges Modern Corporate ergonomics with high-contrast, data-dense efficiency. It evokes speed, complete inventory control, and financial clarity. By rejecting murky low-contrast dark grays in favor of crisp midnight slate foundations paired with electric visual cues, interactions feel instant, authoritative, and reliable under intense operational pressure.

## Colors

The palette is engineered for rapid visual parsing during active transactions, inventory counts, and ledger management:

- **Canvas & Backgrounds:** The base canvas starts at `#0B0F19` (Obsidian Slate), stepping up to `#111827` (Charcoal) for secondary areas. Elevated surfaces and interactive containers live at `#182234` and `#1E293B`, creating defined operational layers without washing out contrast.
- **Accents & Operational Signals:**
  - **Electric Blue (`#3B82F6`):** The primary interaction color, reserved strictly for primary actions, current scan highlights, and active navigation nodes.
  - **Luminous Emerald (`#10B981`):** Represents positive cash flow, settled invoices, successful barcode captures, and healthy inventory.
  - **Bright Amber (`#F59E0B`):** Warns of low-stock thresholds, pending syncs, and credit ledger dues.
  - **Signal Rose (`#F43F5E`):** Denotes critical alerts, out-of-stock items, cancelled orders, and voided bills.
- **Typographic Neutral Hierarchy:** High-clarity white `#F8FAFC` for headline metrics, prices, and primary labels; `#94A3B8` (Light Slate) for secondary metadata and table headers; `#64748B` (Muted Slate) for placeholders, inactive units, and structural timestamps.
- **Structural Outlines:** Subtle, functional borders use `#1E293B` on lower layers and `#334155` on interactive cards and inputs to define boundaries cleanly in ambient glare.

## Typography

Space Grotesk delivers an industrial, technical aesthetic while preserving numerical distinction, critical for FMCG barcode reading, SKU searching, and daily sales tallies.

- **Numerics & Currencies:** Space Grotesk features open geometric counters and distinct glyph forms that prevent misinterpretation between similar numbers (such as `8`, `0`, and `3`) at high-speed checkout lanes.
- **Hierarchy Rules:** All monetary sums, SKU counts, and totals must use medium to bold weights (`600` or `700`). Secondary descriptive information, such as unit packs (e.g., "12 x 500ml") or tax brackets, strictly uses regular weights with secondary slate colors (`#94A3B8`).
- **Letter Spacing:** Tighter letter spacing on display and headline metrics maximizes horizontal efficiency on compact mobile displays, while micro labels receive positive tracking to maintain legibility at sub-12px sizes.

## Layout & Spacing

The layout is optimized for single-thumb mobile ergonomics and compact POS hand terminal screens.

- **Grid Architecture:** A 4-column fluid mobile grid anchored by `1rem` (16px) outer canvas margins and `0.75rem` (12px) gutters between items. This maximizes touch targets while preventing accidental taps between dense SKU rows.
- **Vertical Rhythm:** Information is organized into distinct, modular functional slabs. Dense line items (cart entries, inventory rows) utilize `0.5rem` internal vertical padding, whereas major operational blocks (total tender sum, barcode scanner triggers) use `1rem` to `1.5rem` structural separation.
- **Safe Zone & Bottom-Weighting:** Primary execution controls (e.g., "Charge Cash", "Add Item", "Print Receipt") are permanently anchored inside a high-contrast sticky bottom action area with elevated z-indexing and reinforced padding above operating system navigation bars.

## Elevation & Depth

Visual hierarchy does not rely on heavy, blurry drop shadows, which can muddy dark interfaces and degrade screen contrast in retail lighting. Instead, depth is constructed through structural tonal layering and precise hairline borders:

- **Layer 0 (Canvas):** `#0B0F19` — Base background for the overall app wrapper.
- **Layer 1 (Card & Section Surfaces):** `#111827` with a 1px perimeter border of `#1E293B` — Used for standard product cards, SKU lists, and passive data blocks.
- **Layer 2 (Elevated & Active Containers):** `#182234` with a 1px border of `#334155` — Applied to focused search inputs, active transaction items, and summary tally modules.
- **Layer 3 (Overlays & Drawers):** `#1E293B` with a subtle top edge highlight (`rgba(255, 255, 255, 0.08)`) and an ultra-diffused shadow (`box-shadow: 0 16px 32px -8px rgba(0, 0, 0, 0.6)`) — Used for quick-add item sheets, cash calculators, and payment modals.

## Shapes

The interface balances tactical utility with modern software refinement using roundedness level 2:

- **Standard Elements (`rounded-md` / 0.5rem / 8px):** Form inputs, inline tags, quantity steppers, and list badges use 8px corners to keep UI edges crisp and space-efficient.
- **Containers & Cards (`rounded-lg` / 1rem / 16px):** Primary product cards, operational dashboard widgets, and grouped item clusters use 16px rounded corners, distinguishing content groups cleanly against the midnight slate canvas.
- **Overlays & Floating Actions (`rounded-xl` / 1.5rem / 24px):** Bottom action sheets, modal dialogs, and large primary checkout triggers adopt 24px rounding to signal interactivity and tactile friendliness under thumb reach.

## Components

### Buttons
- **Primary (Checkout / Charge):** Background `#3B82F6`, label `#F8FAFC`, font weight `600`. Full width on mobile bottom bars with minimum height of `48px` for instant tap accuracy. Active state dips to `#2563EB`.
- **Secondary (Add Discount / Hold Cart):** Background `#182234`, border 1px solid `#334155`, label `#F8FAFC`.
- **Destructive / Void:** Background `rgba(244, 63, 94, 0.12)`, border 1px solid `#F43F5E`, text `#F43F5E`.

### Product & Cart Cards
- Surface `#111827`, border 1px solid `#1E293B`, rounded `1rem`. Active or selected card shifts background to `#182234` and border to `#3B82F6`.
- Product pricing is prominently displayed in bold Space Grotesk (`headline-sm`, `#F8FAFC`), with inventory status chips positioned at top right.

### Chips & Badges
- **In Stock:** Background `rgba(16, 185, 129, 0.12)`, border 1px solid `rgba(16, 185, 129, 0.3)`, text `#10B981`.
- **Low Stock:** Background `rgba(245, 158, 11, 0.12)`, border 1px solid `rgba(245, 158, 11, 0.3)`, text `#F59E0B`.
- **Critical / Out:** Background `rgba(244, 63, 94, 0.12)`, border 1px solid `rgba(244, 63, 94, 0.3)`, text `#F43F5E`.
- Corners use `rounded-md` (`0.5rem`) with `label-sm` tracking.

### Form Inputs & Barcode Fields
- Background `#111827`, border 1px solid `#334155`, text `#F8FAFC`, placeholder `#64748B`.
- Focus state: Border transitions to `#3B82F6` with an outer glow ring (`box-shadow: 0 0 0 2px rgba(59, 130, 246, 0.2)`).
- Dedicated barcode scan inputs feature an integrated scan icon on the right trailing edge in `#3B82F6`.

### Lists & Inventory Rows
- Separated by hairline borders (`1px solid #1E293B`), eliminating unnecessary whitespace.
- Trailing actions (quantity adjusters: `-` and `+`) use elevated dark slate buttons (`#1E293B`) with high-contrast glyphs (`#F8FAFC`) to minimize fat-finger errors during rush hours.

### Checkboxes & Radios
- Square rounded checkbox (`4px` radius) with `#1E293B` background and `#334155` border. When checked: `#3B82F6` solid fill with a crisp white tick mark.