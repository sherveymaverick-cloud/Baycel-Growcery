# Activity 4 - Final System Development Checking & Evaluation

**System:** Baycel Growcery — Grocery Store Management System  
**Date:** September 20, 2026  
**Platform:** Flutter + Firebase (Firestore, Auth, FCM)

---

## Score Summary

| # | Criterion | Verdict |
|---|---|---|
| 1 | Input & Field Validation | **PARTIAL** |
| 2 | Security | **FAIL (CRITICAL)** |
| 3 | Database & Performance | **PARTIAL** |
| 4 | Search, Sort, Filter | **PARTIAL** |
| 5 | Edit & Delete Confirmation | **PASS** (minor gaps) |
| 6 | Proper Info in Each Field | **PASS** |
| 7 | UI/UX & Design | **PASS** |
| 8 | Error Handling | **PASS** |
| 9 | Pagination & Large Data | **FAIL** |
| 10 | Application Stability | **PASS** |
| 11 | T&C & App Permissions | **FAIL** |
| 12 | Payment & QR Integration | **FAIL** |

**Final: 5 PASS / 3 PARTIAL / 4 FAIL (1 CRITICAL)**

---

## 1. INPUT AND FIELD VALIDATION — PARTIAL

### 1.1 Required fields cannot be left blank
- **PARTIAL** — Register Screen and main floor staff forms (cash advance, absence, sales, delivery, stock out) enforce this well with validators and SnackBar errors.
- **FAIL** — Employee Edit Dialog (`employee_screen.dart`), Inventory Add Product (non-name fields), Profile Name Edit, and Payroll Deduction have no validators. Blank values are silently saved.

### 1.2 Text fields have appropriate min/max character limits
- **FAIL** — No `maxLength` is set on ANY text field in the entire codebase. Only password fields have a minimum (6 chars). Name, email, SKU, barcode, reason, supplier, and all other text fields accept arbitrarily long input.

### 1.3 Name fields should not accept only 1 character
- **FAIL** — Every name field only checks `isEmpty`. Single-character names like "A" or "X" pass validation everywhere — Register Screen, Employee Edit, Profile Edit, Product Name, Supplier Name, etc.

### 1.4 Number fields accept only appropriate numbers
- **PARTIAL**
- **PASS:** Register Screen and Employee Edit hourly rates validate numeric check, non-negative, and max ₱1,000. Cash Advance validates > 0 and ≤ ₱10,000.
- **FAIL:** Inventory price/stock/reorder fields and Payroll deduction amounts accept negatives and arbitrary values with no validators.

### 1.5 Email fields have proper email validation
- **PARTIAL**
- **PASS:** Register Screen and Login Screen use regex `r'^[^\s@]+@[^\s@]+\.[^\s@]+$'`.
- **FAIL:** Employee Edit Dialog and Forgot Password dialog have no email format validator.

### 1.6 Contact numbers have proper length and format
- **N/A** — No contact number fields exist in the codebase.

### 1.7 Passwords have appropriate validation
- **PARTIAL**
- **PASS:** Register + Change Password enforce min 6 chars and confirm-password match. Visual strength indicator provided.
- **FAIL:** No max length, no complexity requirements (strength bar is informational only). Login Screen has no client-side password validation.

### 1.8 Dates are properly validated
- **PARTIAL**
- **PASS:** Absence Form uses `showDateRangePicker` with `firstDate: now` and `lastDate: now + 365 days`.
- **FAIL:** Time pickers in Register Schedule and Cashier Sales have no validation that end time > start time.

### 1.9 Invalid inputs show clear error messages
- **PARTIAL**
- **PASS:** Register, Login, Change Password, and main floor staff forms show clear inline errors or SnackBars.
- **FAIL:** Employee Edit, Inventory (non-name fields), Profile Name Edit, Delivery Discrepancy, and Payroll Deduction show no errors because they have no validation.

---

## 2. SECURITY — CRITICAL GAPS

### 2.1 Exposed API keys or secret keys
- **PARTIAL** — `.gitignore` covers `firebase_options.dart`, `google-services.json`, `GoogleService-Info.plist`. No hardcoded secrets in source code. However, no verification that these were never committed to version control.

### 2.2 Database security rules
- **FAIL (CRITICAL)** — **No `firestore.rules` file exists.** Firestore is completely open with no server-side access control.

### 2.3 User access permissions
- **PARTIAL** — UI-level role checks exist in dashboards (owner sees all, manager sees employees, floor staff see limited data). But no backend enforcement — any authenticated user could theoretically read/write any collection.

### 2.4 Admin protection
- **FAIL** — Owner can be created via Registration Screen (role dropdown includes "Owner"). The fallback role heuristic in `home_screen.dart` derives role from email address containing "owner", granting owner access to anyone with such an email.

### 2.5 Authentication
- **PASS** — Firebase Auth properly integrated with `authStateChanges()` listener, comprehensive error handling for 8 error codes, re-authentication before password changes, proper session management.

### 2.6 User roles and permissions
- **FAIL (CRITICAL)** — No Firestore rules enforce role-based access. All 7 roles (owner, manager, cashier, bagger, bodegero, delivery_checker, merchandiser) are only differentiated at the UI level.

### 2.7 API security
- **PARTIAL** — Firebase SDK handles API security. No custom API endpoints exist. No exposed third-party API keys.

### 2.8 Rate limits
- **FAIL** — No client-side login attempt throttling. Firebase has built-in `too-many-requests` handling but no custom rate limiting.

### 2.9 Protection of sensitive information
- **FAIL** — Session data (uid, role, name, email) stored in plain SharedPreferences. Debug `print()` calls in `notification_service.dart` (8 instances). No encryption of sensitive data at rest.

### 2.10 Unnecessary database permissions
- **FAIL (CRITICAL)** — No Firestore rules = all permissions are wide open. No restrictions on any collection for any authenticated user.

---

## 3. DATABASE AND PERFORMANCE — PARTIAL

### 3.1 Local database + Cloud database
- **PARTIAL**
- **Cloud:** Firebase Firestore used as primary data store with 9 collections (users, products, stock_movements, deliveries, attendance, absence_forms, payrolls, settings, cash_advances).
- **Local:** SharedPreferences used only for 4 session strings (uid, role, name, email). **No local database** (SQLite, Hive, Drift, etc.) for business data caching.

### 3.2 Data synchronization
- **FAIL** — No sync mechanism between local storage and cloud. No upload queue, no offline write queue, no `connectivity_plus` for network detection.

### 3.3 Caching
- **PARTIAL**
- **UI-level:** HomeScreen caches floor staff dashboard widgets in `_pageCache` to avoid rebuilding on tab switches.
- **Data-level:** No Firestore cache configuration, no application-level data cache. Every StreamBuilder re-subscribes to Firestore snapshots.

### 3.4 Offline handling
- **FAIL** — No `connectivity_plus` package, no network state detection, no offline banners, no retry logic. All StreamBuilders use `.snapshots()` which silently stop emitting when offline.

### 3.5 Database structure
- **PARTIAL**
- Clean 9-collection structure with proper `toMap()`/`fromMap()` serialization.
- 1 composite index defined in `firestore.indexes.json` (attendance by employeeId + date).
- **Missing indexes:** products by barcode, products by sku, stock_movements by performedBy, cash_advances by employeeId, notifications by userId + read.

### 3.6 Efficient queries
- **PARTIAL**
- **PASS:** `getProductByBarcode()`, `getProductBySku()`, `getTodaysAttendance()` use `.where().limit(1)`.
- **FAIL:** `getStockMovementsByUser()` and `getCashAdvancesByUser()` fetch all records then sort client-side. Owner dashboard nests 5–9 simultaneous Firestore StreamBuilders. Dashboard re-subscribes to same collections multiple times.

### 3.7 Pagination
- **FAIL** — Zero pagination anywhere. Every `.snapshots()` call fetches entire collections. No `.limit()`, no cursors, no "Load More", no infinite scroll. Will degrade significantly as data grows.

### 3.8 Loading indicators
- **PASS** — Excellent skeleton screen system (Dashboard, Table, Profile, Settings, ListTile, Card) with shimmer animations. `CircularProgressIndicator` for button loading states. `ConnectionState.waiting` checks throughout.

### 3.9 Error handling
- **PARTIAL**
- Try-catch on all Firestore writes with user-friendly messages.
- `mounted` checks before `setState` throughout.
- **Some silent error swallowing:** `catch (_) {}` blocks in `owner_dashboard.dart`, `manager_dashboard.dart`, `delivery_screen.dart`. Missing `snapshot.hasError` checks in some StreamBuilders.

### 3.10 Avoiding unnecessary requests
- **FAIL** — Owner dashboard opens 9+ simultaneous Firestore live listeners. Duplicate stream subscriptions in `employee_screen.dart` (2 StreamBuilders for same stream). No debouncing. Full collection fetches for dashboard summaries.

---

## 4. SEARCH, SORT, AND FILTER — PARTIAL

### 4.1 Search bar (by name or ID)
- **FAIL** — **No screen has a data search.** The global search bar in `home_screen.dart` only searches navigation tab labels, not actual data records. No screen (Employee, Inventory, Delivery, Payroll, Attendance) has a search field.

### 4.2 Alphabetical sorting
- **FAIL** — No screen offers alphabetical sort toggles. All lists render in Firestore's default order (insertion/document ID). Table headers are static text, not clickable sort headers.

### 4.3 Date sorting
- **PARTIAL**
- **PASS:** Reports screen has Daily/Weekly/Monthly/Yearly time period dropdown.
- **PARTIAL:** Other screens use implicit Firestore `orderBy` (deliveries, payrolls, attendance, stock movements, absence forms all ordered by date descending) but no user-facing toggle to switch order.

### 4.4 Filters/categories
- **PASS**
- Employee Screen: Role-based `ChoiceChip` filters (All, Manager, Cashier, Bagger, Bodegero, Delivery Checker, Merchandiser).
- Inventory Screen: Category-based `ChoiceChip` filters (All, Groceries & Canned, Beverages, Frozen & Dairy, Snacks, Household).
- Delivery Screen: Status-based `ChoiceChip` filters with counts (All, Verified, Pending, Discrepancy).
- Reports Screen: Sales graph time-period dropdown (Daily, Weekly, Monthly, Yearly).

---

## 5. EDIT AND DELETE CONFIRMATION — PASS (minor gaps)

### Operations with proper confirmation (PASS)
| Operation | Location | Confirmation |
|---|---|---|
| Delete employee | `employee_screen.dart:592-626` | AlertDialog with Cancel/Delete + warning text |
| Edit employee | `employee_screen.dart:364-665` | Form dialog with Cancel/Save |
| Accept delivery | `delivery_screen.dart:292-330` | AlertDialog with Cancel/Accept |
| Report discrepancy | `delivery_screen.dart:332-380` | Dialog with note + Cancel/Report |
| Bulk approve absences | `owner_dashboard.dart:692-738` | AlertDialog with Cancel/Approve All |
| Bulk approve cash advances | `owner_dashboard.dart:1105-1143` | AlertDialog with Cancel/Approve All |
| Single absence approve/reject | `owner_dashboard.dart:531-690` | Dialog with explicit Approve/Reject buttons |
| Single cash advance approve/reject | `owner_dashboard.dart:939-1103` | Dialog with explicit Approve/Reject buttons |
| Change password | `profile_settings_screen.dart:208-291` | Dialog with Cancel/Update |
| Log out | `home_screen.dart:272-308` | AlertDialog with Cancel/Log out |
| Confirm cash shortage | `floor_staff_dashboard.dart:197-212` | AlertDialog with Cancel/Confirm |
| Mark received (verify delivery) | `floor_staff_shared_widgets.dart:1391-1406` | Dialog with Cancel/Confirm |

### Operations missing confirmation (FAIL)
| Operation | Location | Issue |
|---|---|---|
| Run payroll | `payroll_screen.dart:48-145` | No confirmation — generates records for ALL employees immediately |
| Mark payroll as paid | `payroll_screen.dart:175-192` | No confirmation — irreversible financial action |
| Confirm delivery (Bodegero) | `floor_staff_dashboard.dart:317-331` | `_handleConfirmDelivery()` changes status with no prompt |

### Minor failures (low-risk, within form contexts)
- Remove individual deduction in Payroll (inside unsaved edit dialog)
- Remove item from delivery form (within unsubmitted form)
- Remove scanned item in Bodegero (within active form)
- Remove parsed item in Delivery Scanner (within active form)

---

## 6. PROPER INFORMATION IN EACH FIELD — PASS

All fields correctly match their purpose:
- Login: Email (email keyboard, `name@baycel.com` hint) + Password (obscured)
- Register: Full Name (text, `TextCapitalization.words`), Email (email keyboard), Password (obscured), Confirm Password, Hourly Rate (number), Payday (dropdown), Schedule (time pickers)
- Inventory Add Product: Product Name, SKU, Barcode, Price (`₱` prefix, number), Stock Qty, Reorder Level, Category (dropdown), Unit (dropdown)
- Employee Edit: Name, Email, Role (dropdown), Hourly Rate, Payday, Schedule — Merchandiser shows product assignment instead of rate/payday
- Cash Advance: Amount (`₱` prefix, decimal number), Reason (text)
- Absence: Date range picker, Reason (text)
- Deduction Editor: Description (text), Amount (decimal number)
- No unnecessary fields exist — every field maps to the underlying Firestore document schema.

---

## 7. UI/UX AND DESIGN — PASS

### Design System
- **Colors:** `BaycelColors` with crimson primary, marigold warning, blue info, semantic success/error colors, dark theme tokens.
- **Typography:** `BaycelTypography` with 12 text styles based on Inter font family (10px–26px).
- **Spacing:** `BaycelSpacing` with 11 tokens from 2px to 48px plus component-specific tokens.
- **Radius:** `BaycelRadius` with 5 border radius tokens.
- **Shadows:** `BaycelShadows` with 3-level shadow system.
- **Components:** `BaycelComponents` with shared button styles, card decorations, input decorations.

### Responsive Layouts
- Login: Split-panel desktop vs stacked mobile (860px breakpoint)
- Home: Bottom NavigationBar vs sidebar (600px breakpoint)
- Employee grid: 3 breakpoints at 1024/600 for 1/2/3 columns
- Reports grid: 3 breakpoints at 900/600 for 1/2/3 columns
- Attendance stats: 500px breakpoint for 2x2 grid

### Animations
- Staggered entrance animations via `StaggeredItem` (fade + slide)
- Press-scale feedback via `PressScale`
- Fade-through page transitions
- Reduce-motion respect via `MediaQuery.of(context).disableAnimations`

### Empty States
Every data list includes proper empty states with icons and descriptive text:
- Inventory: "No products found"
- Employees: "No employees found"
- Deliveries: "No deliveries found"
- Absence: "No absence requests"
- Cash Advances: "No cash advance requests"
- Attendance: "No attendance records for this date"
- Payroll: "No payroll records found"
- Reports: "No sales data yet"
- Notifications: "No notifications" + "You're all caught up!"

### Skeleton Loaders
Full set: `SkeletonDashboard`, `SkeletonTable`, `SkeletonListTile`, `SkeletonCard`, `SkeletonProfile`, `SkeletonSettings` — all with shimmer animation.

### Consistent Components
- Status pills/badges: `BaycelPill`, `BaycelStatusPill`, `DeliveryStatusPill`
- Password strength indicator with visual bar
- Consistent button styles (primary crimson, outlined)

---

## 8. ERROR HANDLING — PASS

### Authentication Errors
`AuthService` maps 8 Firebase Auth error codes to user-friendly messages:
- `user-not-found` → "No account found with this email."
- `wrong-password` → "Incorrect password."
- `invalid-email` → "Invalid email format."
- `user-disabled` → "This account has been disabled."
- `too-many-requests` → "Too many attempts. Please try again later."
- `email-already-in-use` → "An account already exists with this email."
- `weak-password` → "Password is too weak."
- `operation-not-allowed` → "This sign-in method is not enabled."

### Firestore Service Errors
Every write method has try-catch with user-friendly messages:
- `saveUser` → "Failed to save user profile. Please try again."
- `updateUser` → "Failed to update employee. Please try again."
- `deleteUser` → "Failed to delete employee. Please try again."
- `addProduct` → "Failed to add product. Please try again."
- `addDelivery` → "Failed to add delivery. Please try again."
- `addAttendance` → "Failed to record attendance. Please try again."
- `addAbsenceForm` → "Failed to submit absence form. Please try again."
- `addPayroll` → "Failed to add payroll record. Please try again."
- `addCashAdvance` → "Failed to submit cash advance. Please try again."
- (and more for every write operation)

### Input Validation Errors
- Register Screen: Inline `TextFormField` validators with clear messages
- Login Screen: Manual validation with inline red error text
- Cash Advance: 3 separate SnackBar messages for different error types
- Sales Submission: SnackBar for missing receipt, missing shift times, invalid amount

### StreamBuilder Safety
All StreamBuilders use `snapshot.data ?? []` to prevent null-reference crashes.

### Mounted Checks
`if (mounted)` before `setState` throughout the codebase after async operations.

---

## 9. PAGINATION AND LARGE DATA — FAIL

### Current State
- **Zero pagination** in the entire codebase.
- Every `.snapshots()` call fetches entire collections:
  - `getUsers()` — ALL users
  - `getProducts()` — ALL products
  - `getStockMovements()` — ALL stock movements (unbounded growth)
  - `getDeliveries()` — ALL deliveries
  - `getAttendance()` — ALL attendance records
  - `getAbsenceForms()` — ALL absence forms
  - `getPayrolls()` — ALL payrolls
  - `getCashAdvances()` — ALL cash advances
- No `.limit()` on any streaming query.
- No pagination UI (no "Load More", page numbers, or infinite scroll).
- Dashboard sections use `.take(5)` client-side, but the stream still loads ALL documents first.

### Impact
As data grows over months of operation, stock movements, attendance records, payrolls, and deliveries will accumulate. This causes:
- Increased memory consumption
- Higher Firestore read costs
- Slower initial page loads
- Potential performance degradation on mobile devices

---

## 10. APPLICATION STABILITY — PASS

### Auth State Management
`AuthWrapper` in `main.dart` uses `StreamBuilder<User?>` on `authStateChanges()`. Shows skeleton while waiting, HomeScreen when authenticated, LoginScreen when not.

### Session Persistence
`HomeScreen._loadSession()` restores role and name from SharedPreferences on app restart, providing immediate navigation while Firestore fetches fresh data.

### Mounted Checks
Consistent `if (mounted)` before `setState` after async operations across all screens.

### Index Bounds Protection
`home_screen.dart:152`: `if (_currentIndex >= _navItems.length) _currentIndex = 0;` prevents index-out-of-range crashes.

### Role Fallback
If Firestore role fetch fails, falls back to email-based role detection and a default name. Navigation always has items.

### Empty State Handling
Every screen handles empty data states gracefully with icons and descriptive text.

### Loading States
- Skeleton loaders during initial load
- CircularProgressIndicator on buttons during processing
- `_isLoading` flags prevent double-submission on login/register
- `_isRunningPayroll` prevents duplicate payroll generation
- `_isProcessingAbsence` / `_isProcessingCashAdvance` prevent concurrent approvals

### Dialog Safety
Dialogs use `StatefulBuilder` for state updates. `ctx.mounted` checks before `Navigator.pop` after async operations.

### Navigation Stability
`pushAndRemoveUntil` with `(route) => false` for logout and login success, preventing back-stack issues.

### Disposal
Controllers are consistently disposed across all screens.

### Page Caching
`HomeScreen._pageCache` caches floor staff dashboard widgets to avoid rebuilding on tab switches.

---

## 11. TERMS AND CONDITIONS AND APP PERMISSIONS — FAIL

### 11a. Terms and Conditions
- **FAIL** — No Terms and Conditions screen, page, or document exists anywhere in the codebase. No checkbox or agreement prompt in login or registration. No link to any legal documents. Only a copyright notice exists in the login screen footer.

### 11b. App Permissions

#### Camera Permission
- **PARTIAL**
- **iOS:** `NSCameraUsageDescription` = "Camera is used to scan delivery lists and product barcodes." — clear purpose.
- **Android:** `<uses-permission android:name="android.permission.CAMERA"/>` declared but no human-readable description.
- **Timing:** Contextual (on button tap), not at startup.
- **Denial handling:** Basic SnackBar in delivery_scanner. Nothing in cashier/barcode scanners. No `permission_handler` package used.

#### Notification Permission
- **FAIL**
- Requested at app startup before login — not contextual.
- No user-facing explanation before permission request.
- Only `print()` logging on denial — no UI feedback.

#### Other Permissions
- N/A — Location, Storage, Microphone, Contacts are not requested.

---

## 12. PAYMENT AND QR CODE INTEGRATION — FAIL

### 12a. PayMongo QR Ph
- **FAIL** — No PayMongo SDK, API calls, or references exist. No payment-related dependencies in `pubspec.yaml`.

### 12b. Traditional QR Payment
- **FAIL** — No payment processing exists. QR scanning is for product barcodes only (inventory/delivery context). Sales are submitted as manual counter records by cashiers with receipt photos. Payroll is computed and tracked but no actual fund transfer occurs through the app.

---

## Top Priorities to Fix Before Presentation

1. **Create `firestore.rules`** — Most critical security gap. Enforce role-based read/write access per collection.
2. **Add Terms & Conditions** screen with agreement checkbox in registration.
3. **Add search bars** to Employee, Inventory, and Delivery screens.
4. **Add pagination** or `.limit()` to collection queries to prevent loading entire datasets.
5. **Add confirmation dialogs** for Run Payroll and Mark as Paid.
6. **Add `maxLength` validators** and min 2-char name validation to all text fields.
7. **Add email validation** to Employee Edit Dialog and Forgot Password.
8. **Remove "Owner"** from registration role dropdown.
9. **Fix role fallback** in `home_screen.dart` — default to safest role, not email-based detection.
10. **Add end > start time validation** to Register Schedule and Cashier Sales time pickers.
