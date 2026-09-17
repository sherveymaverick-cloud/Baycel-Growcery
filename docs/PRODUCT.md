# Product

<!-- impeccable:product-schema 1 -->

## Platform

adaptive

## Users

All staff equally — owner, manager, cashier, bagger, bodegero, delivery checker, and merchandiser. Each role has a dedicated dashboard and permission set; no single role dominates the primary audience.

## Product Purpose

Baycel is a grocery store management system that unifies inventory, delivery receiving, RFID-based attendance, payroll, and sales tracking into one cross-platform application. It replaces fragmented manual processes (paper attendance logs, spreadsheets for stock, separate payroll tools) with a single source of truth for store operations.

## Positioning

A multi-role store management system with integrated RFID attendance hardware (ESP32), purpose-built for small-to-medium grocery stores where the same staff handles multiple operational functions and a unified view matters more than best-of-breed specialization.

## Operating Context

- Daily store workflows: opening stock checks, delivery receiving and verification, cashier sales submission, end-of-day attendance reconciliation, periodic payroll runs
- ESP32 RFID readers on the store network for tap-in/tap-out attendance
- Firebase (Cloud Firestore + Auth) as the cloud backend
- Cross-platform access: web browsers for owner/manager back-office, mobile for floor staff

## Capabilities and Constraints

- **Implemented modules:** Login, dashboards (role-based), inventory CRUD, stock movements, delivery receiving, attendance, absence forms, payroll, employee/HR management, reports, sales, settings
- **Backend:** Firebase — fresh setup required; no existing Firebase project configuration
- **Hardware dependency:** ESP32 RFID reader for attendance (WiFi-connected)
- **Role system:** 7 roles with granular permissions (owner full access; manager inventory/delivery/reports; cashier sales/attendance; bagger attendance/absences; bodegero inventory/delivery; delivery checker inventory/delivery; merchandiser stock-out for assigned products)
- **State management:** Provider pattern
- **Open decision:** Deployment target — web-only initial release or simultaneous mobile? _(not yet decided)_
- **Open decision:** Firebase project ownership — who manages the Firebase console and billing? _(not yet decided)_

## Evidence on Hand

- Detailed system workflow document with Mermaid diagrams: `Workflows/Baycel-System-Workflow.md`
- Full Firestore collection schema and security rules documented in workflow
- Flutter project scaffold with providers, models, screens, and config directories
- Implementation priority and estimated timeline documented

## Product Principles

1. **All roles are primary.** The system serves every staff member's daily workflow, not just the owner's.
2. **One source of truth.** Inventory, attendance, and payroll data flows through a single system — no reconciling separate spreadsheets.
3. **Hardware-software integration.** RFID attendance is a first-class feature, not an afterthought bolted onto a login screen.
4. **Role-enforced access.** Permissions are structural, not advisory — the UI only shows what the role allows.
5. **Prototype-first.** Ship a working MVP before optimizing; correctness and completeness outrank polish at this stage.

## Accessibility & Inclusion

No product-specific accessibility requirements established yet.
