---
target: lib (full app)
total_score: 25
max_score: 40
na_heuristics: 
p0_count: 2
p1_count: 3
p2_count: 4
p3_count: 2
target_identity: "file:C:\\Users\\Shervey Quiap\\Desktop\\finalproject-baycel\\lib\\screens\\owner_dashboard.dart"
target_fingerprint: "sha256:8b9da97d2479e79640d0c784bdbbdf765bdec2c55cf979105741a6fb2bcfa814"
target_path: "C:\\Users\\Shervey Quiap\\Desktop\\finalproject-baycel\\lib\\screens\\owner_dashboard.dart"
timestamp: 2026-09-17T07-19-21Z
slug: lib-screens-owner-dashboard-dart
---
Method: dual-agent (A: ses_f51d2d129ffeh0S5P1yvrPsJvk · B: ses_f51d2906effePKT7jKEd8naGum)

---

## Design Health Score

| # | Heuristic | Score | Key Issue |
|---|-----------|-------|-----------|
| 1 | Visibility of System Status | 3 | Bulk approve shows spinner then snackbar — no per-item progress |
| 2 | Match Between System and Real World | 2 | "Bodegero", "SKUs", "Stock-Out", "Bale" — unexplained jargon everywhere |
| 3 | User Control and Freedom | 4 | Confirmation dialogs on all destructive actions. Cancel always available. |
| 4 | Consistency and Standards | 3 | Status pill reimplemented 4 times across different files |
| 5 | Error Prevention | 2 | Sales counter submits with empty fields defaulting to 0. No input validation. |
| 6 | Recognition Rather Than Recall | 2 | Notifications sheet shows 3 hardcoded fake items. Users expect real data. |
| 7 | Flexibility and Efficiency of Use | 3 | "Approve All" bulk action is good. But no keyboard shortcuts or quick-add. |
| 8 | Aesthetic and Minimalist Design | 2 | Owner dashboard is a wall of 7+ sections. Donut chart is a fake circle. |
| 9 | Error Recovery | 3 | Snackbars on failures. Payroll undo. But no retry buttons. |
| 10 | Help and Documentation | 1 | Zero tooltips, zero help text, zero onboarding. First-timers are lost. |
| **Total** | | **25/40** | **Acceptable** |

---

## Design Specificity Verdict

**LLM assessment:** The token foundation is strong and product-specific — the crimson palette, Filipino peso context, and role-based access feel intentional. But the **screen layouts are structurally interchangeable**. Every screen follows `Header → Stats Grid → Card with List`. Owner dashboard, inventory, payroll, and delivery screens are visually indistinguishable in structure — swap the text and icons and this could be a CRM or HR tool. The floor staff dashboards are the exception: the crimson gradient ClockCard and sales counter with cash short/over detection feel authored for this exact product.

**Deterministic scan:** Detector returned empty results. Manual review found 49 issues: 2 hardcoded colors, 35+ magic numbers for padding/font sizes, 5 inconsistent spacing patterns, 4 accessibility issues (missing tooltips/semantics), 1 duplicated dialog, 1 shadow token non-usage, and 1 abstraction leak (home screen bypasses FirestoreService).

---

## Overall Impression

The bones are grocery-specific; the layouts are SaaS-generic. The biggest opportunity is **authoring each screen for its specific workflow** rather than using the same card-stack recipe everywhere. The second biggest is **killing the jargon barrier** — half the users won't know what "Bodegero" or "Bale" means without a glossary.

---

## What's Working

1. **Design token architecture** (`theme.dart`) — Three-layer system with semantic naming is production-grade. `BaycelComponents.card` and `.input` reuse eliminates drift across every screen. Best decision in the codebase.

2. **Floor staff ClockCard** (`floor_staff_shared_widgets.dart:10-150`) — Gradient card with 3-state FSM (clocked in / on break / not clocked in) with context-aware buttons. The semi-transparent shopping cart watermark at 8% opacity is a nice branded touch. Most product-specific UI element.

3. **Skeleton loading system** (`shared_widgets.dart:165-380`) — Six skeleton variants with unified shimmer animation. Better than most production apps. `SkeletonTable` with `FlexColumnWidth` ratios matching real tables is a thoughtful detail.

---

## Priority Issues

### P0 — Fix Now

**A. Status pill triple-implemented (now quadruple)**
- `owner_dashboard.dart:1010-1053` — `_buildStatusPill`
- `shared_widgets.dart:94-117` — `BaycelPill`
- `shared_widgets.dart:119-136` — `BaycelStatusPill`
- `delivery_screen.dart:267-310` — `_buildStatusPill`
- `payroll_screen.dart:402-429` — `_StatusPill`

**Why it matters:** Visual drift is already happening — each implementation has slightly different padding, colors, and border radius. Future changes to status styling require editing 4+ files.

**Fix:** Delete all private `_buildStatusPill` / `_StatusPill`. Standardize on `BaycelPill` from `shared_widgets.dart`. ~80 lines of duplicated code eliminated.

**Suggested command:** `/impeccable distill`

**B. Notifications are hardcoded mocks**
- `home_screen.dart:436-457` — Three static `_NotificationItem` widgets with hardcoded text ("5 products need reordering", "2 employees clocked in late"). The bell icon shows a badge dot (`hasBadge: true` at line 353) suggesting unread notifications. Users will tap and see the same 3 fake items every time.

**Why it matters:** Shipping fake badges actively erodes trust. Users learn to ignore the bell within 2 sessions.

**Fix:** Either wire to a real Firestore notifications collection, or remove the badge dot and notification sheet entirely until real data exists.

**Suggested command:** `/impeccable distill`

### P1 — Fix Soon

**C. Owner dashboard is a wall of competing sections**
- `owner_dashboard.dart` — 4 stat cards + absence approvals + cash advance approvals + revenue trend chart + category donut + top products + recent deliveries — all on one scroll. That's 7+ competing attention zones with no progressive disclosure.

**Why it matters:** Cognitive load is 5/8 failures. Users can't find what they need. The owner who wants to approve absences must scroll past charts and product lists to find the approval section.

**Fix:** Extract absence approvals and cash advance approvals into dedicated screens accessible from the sidebar. Keep the dashboard focused on at-a-glance stats and charts.

**Suggested command:** `/impeccable distill`

**D. Reports screen 5-deep StreamBuilder nesting**
- `reports_screen.dart:219-369` — Products → Deliveries → Users → Attendance → Stock Movements. All 5 must resolve before any report card renders. On slow connections, the reports page is blank for 3-5 seconds.

**Why it matters:** The waterfall load means a single slow stream blocks the entire reports experience. Users see nothing instead of partial data.

**Fix:** Merge streams with `StreamGroup` / `combineLatest`, or decouple each report card to load independently.

**Suggested command:** `/impeccable optimize`

**E. Delivery checker: two workflows competing on one page**
- `delivery_checker_dashboard.dart:26-41` — "Create Delivery Record" and "Verify Deliveries" are both full-featured forms on the same scroll. Creating a delivery requires scrolling past the verification section.

**Why it matters:** Two distinct workflows with different goals share the same space. Users doing one task see irrelevant UI for the other.

**Fix:** Use a `TabBar` or segmented control: "Create" | "Verify". Each task gets its own focused context.

**Suggested command:** `/impeccable layout`

### P2 — Improvement

**F. Magic numbers throughout (35+ instances)**
Padding values like `9`, `5`, `6`, `10`, `16` and font sizes like `10.5`, `11.5`, `12.5` appear everywhere instead of using `BaycelSpacing` and `BaycelTypography` tokens.

**Why it matters:** Inconsistent spacing creates visual noise. The 9px vertical padding used across all list rows doesn't match any token (BaycelSpacing.sm is 8px).

**Fix:** Add missing tokens (`BaycelSpacing.row = 9` or standardize to `sm`), then replace all magic numbers.

**Suggested command:** `/impeccable layout`

**G. Crimson exceeds 15% coverage on owner dashboard**
Crimson appears in: sidebar gradient, sidebar active tile, revenue card icon, chart bars, nav indicator, all primary buttons, all ChoiceChip selections, notification badge, floor staff gradient header, ClockCard gradient, "Approve All" button. That's 30-40% of visual weight.

**Why it matters:** When everything is crimson, nothing is important. The accent scarcity rule exists to make primary actions pop.

**Fix:** Reserve crimson for: (a) primary action buttons, (b) the brand header, (c) the most important stat on each screen. Use `BaycelColors.textSecondary` or `BaycelColors.blue` for secondary actions.

**Suggested command:** `/impeccable quieter`

**H. Empty states use wrong icons**
- `bagger_dashboard.dart:226` — `Icons.shopping_cart_outlined` for "No absence requests" (should be `Icons.event_busy`)
- `bodegero_dashboard.dart:131,187,275` — `Icons.shopping_cart_outlined` for "No pending deliveries" (should be `Icons.local_shipping_outlined`)
- `merchandiser_dashboard.dart:167,210` — `Icons.shopping_cart_outlined` for "No products assigned" (should be `Icons.inventory_2_outlined`)

**Why it matters:** Wrong icons confuse the reading. A shopping cart for "no absence requests" makes no semantic sense.

**Fix:** Match icons to context. Shopping cart only for empty product lists.

**Suggested command:** `/impeccable clarify`

### P3 — Polish

**I. Donut chart is not a donut chart**
- `owner_dashboard.dart:791-806` — "Sales by Category" renders a `Container` with a circular border and text inside. It's a circle with a number, not a proportional chart.

**Fix:** Either implement a real donut with `CustomPainter` or rename to "Category Breakdown" and remove the decorative circle.

**J. Employee "Active" status is always hardcoded green**
- `employee_screen.dart:318-327` — Every employee card shows green dot + "Active" regardless of actual status.

**Fix:** Remove the status indicator until real status data exists.

**K. DropdownButtonFormField uses invalid `initialValue` parameter**
- `floor_staff_shared_widgets.dart:518` — `DropdownButtonFormField` uses `initialValue` which is not a valid parameter (should be `value`). This would cause a runtime error if the product list is non-empty.

**Fix:** Change `initialValue:` to `value:`.

---

## Persona Red Flags

### Alex (Power User)
- 8 nav items in owner sidebar — too many top-level destinations
- No keyboard shortcuts or command palette — search only navigates to screen tabs, not specific records
- Bulk approve has no selective mode (approve all except specific items)
- Owner dashboard forces scrolling through 7 sections to find approvals

### Jordan (First-Timer)
- Jargon everywhere: "Bodegero" (untranslated Filipino), "SKUs", "Stock-Out to Shelves", "Deductions", "Bale" — no tooltips, no help icons, no glossary
- No onboarding flow — Jordan lands on owner dashboard with 7 sections and zero guidance
- Cashier sales counter has 5 fields with no explanation of what "Expected Cash" vs "Actual Cash" means

### Casey (Distracted Mobile User)
- Floor staff scroll has no section anchors — must scroll past sales form to reach attendance
- Cashier form fields clear on tab switch — state not preserved
- Attendance table has 8 columns on mobile — will overflow or require horizontal scroll with no indication

---

## Minor Observations

- `owner_dashboard.dart:685` — Revenue trend hardcodes `dailyRevenue[label] = dayDeliveries.length * 260.0`. The ₱260 multiplier is undocumented. If average order value changes, this breaks silently.
- `settings_screen.dart:36-49` — `_saveSettings()` fires on every toggle change (3 toggles = 3 rapid Firestore writes). No debounce.
- `employee_screen.dart:380-383` — Double-modal pattern (AlertDialog inside AlertDialog) for delete confirmation is unusual in Material Design.
- `home_screen.dart:53` — Home screen bypasses `FirestoreService` and calls `FirebaseFirestore.instance` directly for role detection. Abstraction leak.

---

## Questions to Consider

1. **Should the owner dashboard split approvals into dedicated screens?** The absence and cash-advance approval workflows are full-featured enough to justify their own pages, which would also solve the wall-of-sections problem.

2. **Should floor staff dashboards use card-based navigation (tap to expand) instead of a long scroll?** This would solve mobile scroll depth, Casey's one-handed use, and the missing-anchor problem simultaneously.

3. **Is the ₱260 per-delivery revenue multiplier real or placeholder?** If it's a business assumption, it should come from a settings/config model, not a magic number.

4. **Should the notification system be built before shipping the bell icon?** A badge that always shows fake data harms trust more than having no badge at all.

5. **Is "Bodegero" the right primary label, or should "Stockroom" lead?** The role badge shows "Bodegero · Stockroom" — non-Filipino users may not know the term.

---

**Trend for `lib` (last 3 runs): 22 → 23 → 25 (out of 40)**
Wrote `.impeccable/critique/2026-09-17T06-15-00Z__lib.md`.
