---
name: Baycel Grocery Store
description: A precise, efficient grocery store management system built for operators
colors:
  primary: "#C62828"
  primary-light: "#EF5350"
  primary-dark: "#8E0000"
  secondary: "#FEB300"
  secondary-dark: "#F57F17"
  tertiary: "#006AB8"
  error: "#BA1A1A"
  surface: "#F8F9FA"
  card: "#FFFFFF"
  text-primary: "#1C1B1F"
  text-secondary: "#5B403D"
  text-muted: "#616161"
  text-disabled: "#9E9E9E"
  divider: "#E0E0E0"
  info: "#006AB8"
  success: "#2E7D32"
  skeleton-base: "#E0E0E0"
  skeleton-shimmer: "#F5F5F5"
  dark-surface: "#1C1B1F"
  dark-card: "#2C2C2C"
  dark-border: "#3C3C3C"
typography:
  display:
    fontFamily: "Inter, system-ui, sans-serif"
    fontSize: "26px"
    fontWeight: 700
    lineHeight: 1.2
    letterSpacing: "-0.02em"
  headline:
    fontFamily: "Inter, system-ui, sans-serif"
    fontSize: "20px"
    fontWeight: 700
    lineHeight: 1.3
    letterSpacing: "-0.01em"
  title:
    fontFamily: "Inter, system-ui, sans-serif"
    fontSize: "14px"
    fontWeight: 600
    lineHeight: 1.4
    letterSpacing: "normal"
  body:
    fontFamily: "Inter, system-ui, sans-serif"
    fontSize: "13px"
    fontWeight: 400
    lineHeight: 1.4
    letterSpacing: "normal"
  label:
    fontFamily: "Inter, system-ui, sans-serif"
    fontSize: "12px"
    fontWeight: 600
    lineHeight: 1.3
    letterSpacing: "0.02em"
  caption:
    fontFamily: "Inter, system-ui, sans-serif"
    fontSize: "11px"
    fontWeight: 500
    lineHeight: 1.3
    letterSpacing: "0.03em"
rounded:
  sm: "2px"
  md: "4px"
  lg: "8px"
  xl: "12px"
spacing:
  xxs: "2px"
  xs: "4px"
  sm: "8px"
  md: "12px"
  base: "16px"
  lg: "24px"
  xl: "32px"
  "2xl": "48px"
components:
  button-primary:
    backgroundColor: "{colors.primary}"
    textColor: "#FFFFFF"
    rounded: "{rounded.md}"
    padding: "14px 24px"
    typography: "{typography.label}"
  button-primary-hover:
    backgroundColor: "{colors.primary-dark}"
    textColor: "#FFFFFF"
  button-outlined:
    backgroundColor: "transparent"
    textColor: "{colors.text-primary}"
    rounded: "{rounded.md}"
    padding: "14px 24px"
  card:
    backgroundColor: "{colors.card}"
    textColor: "{colors.text-primary}"
    rounded: "{rounded.lg}"
    padding: "16px"
  input:
    backgroundColor: "{colors.card}"
    textColor: "{colors.text-primary}"
    rounded: "{rounded.md}"
    padding: "14px 16px"
  chip:
    backgroundColor: "{colors.primary}1A"
    textColor: "{colors.primary}"
    rounded: "{rounded.sm}"
    padding: "8px 14px"
  snackbar:
    backgroundColor: "{colors.text-primary}"
    textColor: "#FFFFFF"
    rounded: "{rounded.md}"
  topbar:
    backgroundColor: "{colors.card}"
    textColor: "{colors.text-primary}"
    rounded: "{rounded.md}"
    padding: "12px 16px"
  stat-card-icon:
    backgroundColor: "{colors.primary}10"
    textColor: "{colors.primary}"
    rounded: "{rounded.lg}"
    padding: "10px"
  leaderboard-item:
    backgroundColor: "transparent"
    textColor: "{colors.text-primary}"
    rounded: "{rounded.md}"
    padding: "8px 0"
---

# Design System: Baycel Grocery Store

## Overview

**Creative North Star: "The Operational Grid"**

Baycel's visual identity is precision and structure — a system built for operators who think in rows, columns, and status indicators. Every element earns its space through function, not decoration. The grid is the organizing principle: stat cards snap to a 2-column mobile / 4-column desktop grid, inventory tables lock to column headers, and navigation splits cleanly between sidebar (tablet/desktop) and bottom bar (mobile) with no overlap.

The personality is crisp and confident despite the operational density. Inter carries the entire type system with its neutral, business-like clarity — a single weight-stepped hierarchy that never needs a second font. Crimson primary appears where action or status demands it: buttons, active states, stock badges. The neutral surface palette (`#F8F9FA` to `#FFFFFF`) provides the quiet background that lets data speak. Corners are tightly rounded (2–8px) to feel precise and utilitarian on dense operational tables.

**Key Characteristics:**
- Crisp, confident surfaces with soft ambient shadows for depth
- Crimson primary used surgically — action and status only, never decoration
- Inter type system with clear weight hierarchy (400/500/600/700)
- Responsive layout: sidebar on tablet/desktop, bottom nav on mobile
- Data density that scales from phone screens to desktop dashboards
- Tight 2–8px corner radius across all interactive elements
- Full dark theme support with tonal surface hierarchy

## Colors

The palette is utilitarian: one dominant crimson accent for action and identity, one marigold for warnings, a clean neutral scale for data surfaces.

### Primary — Grocery Crimson
- **Crimson** (#C62828): Primary action color — buttons, active nav indicators, stock status badges, sidebar gradient. The brand color.
- **Crimson Light** (#EF5350): Lighter variant — hover states, icon tinting on active elements, chip backgrounds at 10% opacity. Dark theme primary.
- **Crimson Dark** (#8E0000): Dark variant — gradient endpoints, hover darkening on primary buttons, focus depth.

### Secondary — Market Marigold
- **Marigold** (#FEB300): Warning states, low-stock badges, absence pending indicators. Shares duty with error red for urgency hierarchy.
- **Marigold Dark** (#F57F17): Darker amber for text contrast on light backgrounds.

### Tertiary — Blue
- **Blue** (#006AB8): Links, delivery truck status, cold chain indicators, information states.

### Neutral
- **Clean Surface** (#F8F9FA): Scaffold background, off-white fills for input fields.
- **Pure Card** (#FFFFFF): Card backgrounds, drawer background, modal surfaces.
- **Ink** (#1C1B1F): Primary text — headings, body copy, values. Also dark theme surface.
- **Warm Brown** (#5B403D): Secondary text — labels, descriptions, subtitles. Warm tone.
- **Muted** (#616161): Muted labels, table headers.
- **Edge** (#E0E0E0): Dividers, input borders, card borders.
- **Disabled** (#9E9E9E): Disabled text, placeholder icons, inactive navigation indicators.

### Semantic
- **Error** (#BA1A1A): Red for errors, absences, deduction figures.
- **Error Container** (#FFDAD6): Light pink background for absent/error states.
- **Success** (#2E7D32): Green for verified items, live feeds, balanced lanes.
- **Info Blue** (#006AB8): Information states, in-progress attendance, data visualization accent.
- **Skeleton Base** (#E0E0E0): Loading skeleton base color.
- **Skeleton Shimmer** (#F5F5F5): Loading skeleton shimmer highlight.

### Dark Theme
- **Dark Surface** (#1C1B1F): Dark mode scaffold background.
- **Dark Card** (#2C2C2C): Dark mode card and drawer backgrounds.
- **Dark Border** (#3C3C3C): Dark mode dividers, input borders, card borders.

### Data Visualization
- **Viz 1** (#C62828): Primary data category — products, inventory.
- **Viz 2** (#FEB300): Secondary data category — sales, revenue.
- **Viz 3** (#006AB8): Tertiary data category — stock value, info states.
- **Viz 4** (#7B1FA2): Quaternary data category — deliveries, logistics.
- **Viz 5** (#00838F): Quinary data category — employees, attendance.
- **Viz 6** (#2E7D32): Senary data category — payroll, expenses.

### Role Badge Colors
- **Admin/Store Director** (#EF9A9A): Role badge border.
- **Floor Manager** (#FFE082): Role badge border.

### Named Rules
**The Crimson Accent Rule.** Crimson appears on ≤15% of any given screen surface. Its scarcity signals importance; when everything is crimson, nothing is. Reserve it for primary actions, active navigation, and positive status only.

**The Neutral Surface Rule.** Backgrounds stay between `#F8F9FA` and `#FFFFFF`. No colored backgrounds on content surfaces — color lives in badges, icons, and buttons, never behind text blocks.

**The Semantic Color Rule.** Every color has a role: action (primary), status (success/warning/error/info), or hierarchy (text/disabled). Colors are never decorative; they encode meaning.

## Typography

**Display Font:** Inter (with system-ui fallback)
**Body Font:** Inter (with system-ui fallback)

**Character:** Inter is the workhorse of modern product UI — neutral enough to disappear, sharp enough to scan at 11px. The single-family approach means no font switching overhead; weight and size do all the hierarchical work.

### Hierarchy (9 Tokens)
- **Display LG** (700, 26px, 1.2, -0.02em): Hero KPI numbers, dashboard welcome headers. Appears once per screen maximum.
- **Headline LG** (700, 20px, 1.3, -0.01em): Section page titles, persona names.
- **Headline MD** (600, 16px, 1.4): Card section headings, sidebar links.
- **Title MD** (600, 14px, 1.4): Table product names, item titles.
- **Body MD** (400, 13px, 1.4): Default body text, table cell content.
- **Body SM** (400, 12px, 1.4): Secondary body, descriptions.
- **Label MD** (600, 12px, 1.3, 0.02em): Button labels, navigation items.
- **Label SM** (500, 11px, 1.2, 0.03em): Table column headers, metadata labels, badges.
- **Data Mono** (500, 12px, 1.3, -0.01em): SKU codes, timestamps, numerical data, RFID UIDs.

### Named Rules
**The Weight Step Rule.** Every heading level is exactly one weight step heavier than its body context. No two adjacent text elements share the same weight — this creates hierarchy without size tricks.

**The Tabular Nums Rule.** Data-heavy columns use `font-variant-numeric: tabular-nums` for numerical regularity — UPC/SKU, pricing, stock levels, timestamps.

## Layout

The spatial model is sidebar-anchored on tablet (≥600px) and desktop (≥1024px), switching to bottom-navigation on mobile (<600px). Content sits in a 16–24px-padded scrollable area; stat grids use 12–16px gaps with a 2-column mobile / 4-column desktop layout. Section spacing is consistently 24px vertical. Cards use 16px internal padding with zero outer margin (spacing comes from grid gaps).

The sidebar drawer is 256px (16rem) wide with a crimson header (48px top padding for safe area), followed by a flat white body with 8px-padded menu items. Bottom nav is 65px tall with 24px icons and always-visible labels.

### Spacing Scale
| Token | Value | Pixels |
|-------|-------|--------|
| `xxs` | 0.125rem | 2px |
| `xs` | 0.25rem | 4px |
| `sm` | 0.5rem | 8px |
| `md` | 0.75rem | 12px |
| `base` | 1rem | 16px |
| `lg` | 1.5rem | 24px |
| `xl` | 2rem | 32px |
| `2xl` | 3rem | 48px |

### Named Rules
**The Breakpoint Rule.** Mobile (<600px) gets bottom navigation. Tablet (600–1023px) and desktop (≥1024px) get the sidebar. Never mix navigation patterns on the same breakpoint.

## Elevation & Depth

Baycel uses a 4-level shadow system to create depth hierarchy. Cards rest with a nearly invisible ambient shadow, gaining lift on hover. Modals float above everything with pronounced depth.

### Shadow Vocabulary (4-Level)
- **Level 0 (Scaffold):** No shadow on `#F8F9FA` canvas.
- **Level 1 (Cards):** `shadow-sm` = `0 1px 2px rgba(0, 0, 0, 0.04)` — nearly invisible ambient lift.
- **Level 2 (Hover):** `hover:shadow-md` = `0 4px 12px rgba(28, 27, 31, 0.08)` — interactive feedback.
- **Level 3 (Modals):** `shadow-xl` = `0 12px 32px rgba(0, 0, 0, 0.14)` — pronounced float.
- **Sidebar:** `shadow-[0_1px_8px_rgba(0,0,0,0.04)]` — ultra-subtle left rail.

### Named Rules
**The Ambient-Only Rule.** Shadows are ambient and diffuse — never sharp, never structural. They suggest lift without announcing it. Hard shadows belong to no component in this system.

## Shapes

Corner radius follows a four-tier system: 2px for micro controls (badges, inline buttons, role tags), 4px for interactive elements (inputs, small buttons, chips), 8px for containers (cards, panels, metric containers, modals), and 12px for larger interactive elements (avatars). Status pulse dots and avatar circles use `rounded-full`.

### Border Radius Scale
| Token | Value | Usage |
|-------|-------|-------|
| `sm` | 2px | Micro controls, badges, inline buttons, role tags |
| `md` | 4px | Input fields, small buttons, tag chips |
| `lg` | 8px | Cards, panels, metric containers, modals |
| `xl` | 12px | Rounded avatars, larger interactive elements |
| `full` | 9999px | Status pulse dots, avatar circles, progress bars |

## Components

### Buttons
- **Shape:** Tight rounded (4px radius)
- **Primary:** Filled crimson (#C62828) background, white text, 14px vertical / 24px horizontal padding, Inter 600 weight.
- **Hover / Focus:** Darkens to `#8E0000`. Active scales to 0.98. No shadow shift — color change only.
- **Outlined:** Transparent fill, `#E0E0E0` border, dark text, same padding and radius. Used for secondary actions.
- **Ghost/Text:** `text-primary hover:underline` for navigation links.

### Chips / Filter Chips
- **Style:** 10% opacity crimson background (`primaryColor.withValues(alpha: 0.1)`), crimson text, 2px radius, 8px vertical / 14px horizontal padding. Inter 12px.
- **State:** Selected chips show filled crimson background with white text and crimson checkmark. Unselected chips are outlined with `#E0E0E0` border.

### Cards / Containers
- **Corner Style:** 8px radius
- **Background:** White (#FFFFFF)
- **Shadow Strategy:** Soft ambient shadow (`0 1px 2px rgba(0, 0, 0, 0.04)`) at rest, `hover:shadow-md` on interactive cards
- **Border:** 1px solid `#E0E0E0` at 50% opacity
- **Internal Padding:** 16px (14px on compact product cards)

### Inputs / Fields
- **Style:** Outlined with `#E0E0E0` border, white fill, 4px radius, 14px vertical / 16px horizontal content padding.
- **Focus:** Border shifts to primary crimson (#C62828) with 2px width. No glow or shadow.
- **Error:** Border shifts to error red (#BA1A1A). Error text appears below in caption weight.
- **Disabled:** 50% opacity border, no fill change.

### Navigation
- **Sidebar (tablet/desktop):** Surface background, 256px width. Crimson gradient header with user avatar (CircleAvatar, 28px radius, 20% white background). Menu items: 12px radius container, crimson left-bar indicator on active (4px wide, 20px tall), crimson icon tint and 600 weight on active, grey icon and 500 weight on inactive.
- **Bottom Nav (mobile):** White background, 65px height, subtle top shadow. Crimson indicator color at 10% opacity. Icons 24px, labels always visible.
- **Top App Bar (tablet/desktop):** White card-style bar, 8px radius, ambient shadow, 12px/16px padding, sits above content rather than full-bleed. Contains a search input (`#F8F9FA` fill, 4px radius, magnifier icon, `#9E9E9E` placeholder), a `text-muted` current-date label, and 1–2 circular icon buttons (message/notification) with a small crimson badge dot for unread counts. Never fill the bar itself with crimson — it stays neutral so the badge dot is the only accent.
- **Expandable Menu Items:** Sidebar items with children (e.g. "Orders," "Vendor Management") show a chevron and expand in place with a 200ms height transition; child items indent 16px and drop to Label MD weight. Only one top-level group expands at a time. Active child item gets the same 4px crimson left-bar treatment as a top-level active item — never a filled background, to keep the ≤15% crimson-coverage rule intact even when several rows are expanded.

### Stat Cards
- **Shape:** 8px radius, flat with ambient shadow
- **Layout:** Icon container (10px padding, 12px radius, 10% opacity color fill) top-left, value (24px bold), title (13px secondary), optional subtitle in accent color.
- **Grid:** 2-column mobile, 4-column desktop, 1.5 aspect ratio, 12px gaps.
- **Icon Color-Coding:** Each stat gets a distinct icon tint drawn from the Data Visualization palette (Viz 1–6), not from crimson alone — e.g. Orders → Viz 1 crimson, Balance → Viz 3 blue, Products → Viz 4 purple, Customers → Viz 2 marigold, Riders → Viz 6 green. This lets operators scan by color without reading labels, while keeping crimson itself reserved for the one or two stats that are genuinely primary (e.g. today's revenue) — the coverage stays under the 15% rule because only one tile uses crimson at a time.

### Charts
- **Trend Line/Area Chart:** Single-series line in the primary metric's accent color (crimson for revenue, blue for delivery volume, etc.), with a soft gradient fill beneath the line fading from 20% opacity to transparent. Data points show as small filled circles on hover with a floating tooltip card (white background, 4px radius, `shadow-md`, Body SM value + Label SM date). X-axis labels use Label SM in `text-muted`; grid lines are 1px `#E0E0E0` at 50% opacity, horizontal only.
- **Donut/Breakdown Chart:** Used for category splits (e.g. users by role, orders by status). Center shows the total in Headline LG with a Body SM caption beneath. Segments use sequential Viz palette colors, never crimson-only. Legend sits below or beside the chart as color-dot + Label MD text pairs — never color alone, since dot-only legends are easy to miss at a glance.
- **Card Wrapper:** Charts live inside a standard `card` container with a Headline MD title and an optional `text-muted` period-select dropdown (e.g. "This week") in the top-right corner, matching the card header pattern used elsewhere.

### Leaderboard / Ranked List
- **Use case:** "Top vendors," "top products," "top riders," "top customers by orders" — compact ranked lists that sit 2–4 across in a card grid below the main charts.
- **Row:** 40px avatar or thumbnail (12px radius, or `rounded-full` for people), Title MD name, Body SM secondary line (rating, phone, or order count), and a right-aligned value in Data Mono weight. Rows separated by the standard 1px `#E0E0E0` divider at 50% opacity, 8px vertical padding — no zebra striping.
- **Header:** Card title (Headline MD) with a "View All" text link (Label MD, `text-secondary`, no underline until hover) right-aligned in the same row.
- **Cap:** Show 3–5 rows per card; anything beyond belongs on a dedicated table screen, not scrolled inline.

### Status Badge System
- **Online/Verified:** `bg-hardware-online/15 text-hardware-online` (green tint + green text)
- **Pending/Warning:** `bg-marigold-tint text-marigold-dark` (amber tint + amber text)
- **Critical/Error:** `bg-crimson-tint text-crimson-dark` or `bg-error-container text-error`
- **Syncing:** `bg-tertiary-fixed text-tertiary` (blue tint + blue text)
- **Inactive/Offline:** `bg-surface-container text-text-muted`
- **Shape:** `rounded-full` pills or `rounded` (2px) small tags

### Table Design
- **Header:** `bg-surface-scaffold` + `font-label-sm uppercase tracking-wider` + `text-text-muted`
- **Row height:** 36px (`h-table-row-h` or `py-xs px-md`)
- **Cell dividers:** `divide-y divide-surface-container` (1px `#f1ecf2`)
- **Hover row:** `hover:bg-surface-scaffold` or `hover:bg-surface-container`
- **Active/selected row:** 3px solid `bg-primary-container` left border
- **Discrepancy row:** `bg-marigold-tint/40` or `bg-crimson-tint/40` with matching hover intensification

### Progress Bars
- Track: `bg-surface-container rounded-full h-1.5` or `h-2` or `h-1`
- Fill: Colored (varies by context: `bg-primary`, `bg-hardware-online`, `bg-secondary`, `bg-tertiary-container`)
- Overflow hidden with `rounded-full`

### Snackbar
- **Style:** Floating, 4px radius, dark background (#1C1B1F), white text.
- **Behavior:** Auto-dismiss, not persistent. Error snackbars use error red background.

### Profile Page
- **Identity Card:** Top card holds a large `rounded-full` avatar (64–72px) with a small camera-icon edit badge (24px min tap target, crimson fill, white icon) anchored bottom-right of the avatar — not smaller, so it stays reachable on touch. Beside it: name in Headline LG, role as a small pill badge (10% crimson tint, Label SM), and location in Body SM `text-muted`.
- **Info Cards:** "Personal Information" and "Address" each get their own card with a Headline MD section title and a single outlined "Edit" button (icon + label) right-aligned in the header row — never filled crimson, since it's a secondary action relative to the page's primary flows. Fields lay out in a responsive 2–3 column grid: Label SM caption above, Body MD/Title MD value below, 16–24px column gaps.
- **No duplicate identity blocks:** Show the current user's avatar/name once per screen (in the identity card, or in the sidebar footer — not both in visually different treatments) to avoid the redundant "who is this" read.

### Sidebar Drawer
- **Header:** Full-width gradient (crimson → crimson-dark), 48px top padding, white text. CircleAvatar (28px radius, 20% white), name (18px 600), role badge (12px, 20% white background, 12px radius).
- **Menu:** 8px padding, 2px bottom margin per item, 12px radius on hover/active, animated container (200ms) for selection state.
- **Footer:** Logout in error red with `Icons.logout`.

### Skeleton Loaders
- **Base:** `#E0E0E0` with shimmer pulse animation (1500ms cycle, 0.3→0.7 opacity)
- **Shimmer:** `#F5F5F5` highlight via `Color.lerp` interpolation
- **Variants:** SkeletonLoader (generic), SkeletonCard, SkeletonListTile, SkeletonDashboard

### Decorative Background Elements
- Large absolute-positioned circles (e.g., `w-36 h-36`, `w-44 h-44`) at `-right-8 -top-8` or `-right-10 -bottom-10`
- Using brand tints at 10-20% opacity
- `blur-2xl` or `blur-xl` for soft ambient glow
- `pointer-events-none` to prevent interaction

## Dark Theme

The dark theme mirrors the light theme's structure with tonal inversions. Crimson primary shifts to `#EF5350` (Crimson Light) for contrast against dark surfaces. Text inverts to white (`#FFFFFF`) on dark backgrounds.

### Dark Theme Tokens
- **Dark Surface** (#1C1B1F): Scaffold background — same as Ink from the light palette.
- **Dark Card** (#2C2C2C): Cards, drawers, modals — elevated above the scaffold.
- **Dark Border** (#3C3C3C): Dividers, input borders, card borders — visible against dark surfaces.
- **Primary on Dark** (#EF5350): Buttons, active states — the lighter crimson for contrast.
- **Text on Dark** (#FFFFFF): All primary text on dark surfaces.
- **Text Secondary on Dark** (#FFFFFF70): Secondary text at 70% opacity.

### Dark Theme Behavior
- Sidebar header uses `LinearGradient` from `#EF5350` to `#C62828` (lighter primary start).
- Active nav indicator uses `primaryLight.withValues(alpha: 0.2)` for the tonal fill.
- Cards use `#2C2C2C` background with `#3C3C3C` border — flat with ambient shadow.
- Input fields fill with `#2C2C2C`, focus border shifts to `#EF5350`.
- Snackbar stays dark (#1C1B1F) in both themes.

## Do's and Don'ts

### Do:
- **Do** use crimson (#C62828) only for primary actions, active states, and positive status badges — never for decorative backgrounds.
- **Do** keep cards flat with border separation and soft ambient shadow — the 1px `#E0E0E0` border at 50% opacity plus subtle lift is the consistent surface language.
- **Do** use 24px vertical spacing between major sections and 12–16px between items in a group.
- **Do** apply the four-tier radius system: 2px micro, 4px interactive, 8px containers, 12px avatars.
- **Do** show loading states with skeleton loaders (pulse animation) rather than spinners for content-heavy screens.
- **Do** use `FadeTransition` (300ms, easeInOut) for page navigation and `SlideTransition` (300ms, easeOutCubic) for lateral movement.
- **Do** use semantic color tokens (textSecondary, textDisabled, infoColor, etc.) instead of hardcoded grey values.
- **Do** use the data visualization palette for chart colors, stat-card icon tints, and category differentiation — this is what gives scannable variety without breaking the crimson-scarcity rule.
- **Do** support both light and dark themes using Theme.of(context) to access colors.
- **Do** use `tabular-nums` for data-heavy columns (pricing, stock levels, timestamps).

### Don't:
- **Don't** add sharp or structural box shadows to cards — shadows are ambient and diffuse only.
- **Don't** use gradient text or glass/blur effects — the system is crisp but functional.
- **Don't** exceed 15% crimson surface coverage on any screen — accent scarcity signals importance.
- **Don't** use colored left-border accents on cards or alerts — borders stay neutral grey.
- **Don't** place content under the notch, Dynamic Island, or home indicator — respect safe area insets.
- **Don't** mix bottom navigation with sidebar navigation on the same breakpoint — mobile gets bottom nav, tablet/desktop gets sidebar.
- **Don't** use hardcoded Colors.grey[*] values — always use semantic tokens from AppTheme.