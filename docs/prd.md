# Product Requirements (System Requirements): Tenera

**Version:** 0.2 (replaces 0.1)
**Product:** Tenera, a landlord-only rental management app
**Platform:** Flutter mobile app, local SQLite database, **no login**, subscription via app store billing
**Status:** Draft for client review

## 1. Product Scope in One Paragraph
Tenera replaces the notebook, spreadsheet, paper receipts and chat threads a small landlord uses to run rentals. It answers three daily questions: **who paid, who owes what, and what do I need to follow up on today.** It works fully offline, stores data on the device, and protects it with backup/restore and an optional app lock. Tenants never use the app.

## 2. Module Verdicts (from the landlord feature list)
| Module | Verdict | Release |
|---|---|---|
| 1. Dashboard | Build, simplified (numbers + lists, no charts) | MVP |
| 2. Properties & Units | Build; property → unit, optional occupant count. No floors/beds tracking | MVP |
| 3. Tenants | Build; profile, notes, archive. Occupant names as simple optional list | MVP |
| 4. Leases | Build, simplified: active / ended only, expiry reminders, rent change with effective date | MVP (+ rent change in v1.1) |
| 5. Rent & Payments | Build; the core of the product | MVP |
| 6. Expenses | Defer; simple expense log | v2.0 |
| 7. Maintenance & Repairs | Defer; simple repair log per unit | v2.0 |
| 8. Move-in / Move-out | Build the **deposit settlement** only (deductions + refund). Inspection checklists deferred | MVP (settlement), v2.0 (checklists) |
| 9. Reminders | Build; local notifications, treated as a must-have | MVP |
| 10. Reports & Data | Build tenant statement + arrears + monthly summary; exports | MVP (statement), v1.1 (rest) |
| Utilities (provider bill + meter readings) | Build in two steps | MVP: manual charge, v1.1: full flow |
| Backup, restore, integrity check, app lock | Build | MVP |
| Subscription | Build | MVP |

**Not building:** tenant app/login, cloud sync, online payments, e-signatures, IoT, utility provider APIs, lease version history, bed-level tracking, per-property cash-flow charts. These stay out unless validated with landlords.

## 3. Business Rules
| ID | Rule |
|---|---|
| BR-1 | Money is stored as **transactions** (ledger entries). Balances are always calculated, never typed in. |
| BR-2 | Recorded entries are never edited or deleted. A mistake is fixed with a **void** or **adjustment** entry that points to the original. |
| BR-3 | A unit cannot have two overlapping active leases, unless the unit is marked **shared** (e.g., a boarding room with multiple tenants). |
| BR-4 | **Security deposits are tracked separately** from rent and are never counted as income or collected rent. |
| BR-5 | A payment entered by the landlord is considered received and verified. No separate "verification" step in the MVP. |
| BR-6 | Partial and advance payments are allowed. Payments apply to the oldest unpaid charge first. |
| BR-7 | Ending a lease or archiving a tenant never deletes financial history. |
| BR-8 | Recurring rent charges are generated automatically for every due period, including missed periods if the app wasn't opened. |
| BR-9 | Receipt numbers are sequential and unique per landlord (e.g., RC-0001). |
| BR-10 | Utility shares must sum **exactly** to the billed amount; rounding leftovers go to the last unit. |
| BR-11 | All strings, dates and currency formats are locale-aware. |

## 4. Functional Requirements

### A. Setup and Settings
| ID | Requirement | Priority |
|---|---|---|
| FR-A1 | First-run welcome, language and currency selection | P0 |
| FR-A2 | Guided first setup: add property → unit → tenant → lease in under 3 minutes | P0 |
| FR-A3 | Optional app lock (PIN or biometric) | P0 |
| FR-A4 | Settings: reminder times, grace days, receipt header (landlord name, contact) | P0 |

### B. Properties and Units
| ID | Requirement | Priority |
|---|---|---|
| FR-B1 | Create/edit/archive properties (name, address, notes, photos) | P0 |
| FR-B2 | Create/edit/archive units (name/number, default rent, deposit, notes, photos, shared flag, occupant capacity) | P0 |
| FR-B3 | Unit status derived automatically: vacant / occupied / overdue | P0 |
| FR-B4 | Search and filter units by property, status, price | P0 |
| FR-B5 | Unit history: past tenants and leases | P1 |

### C. Tenants
| ID | Requirement | Priority |
|---|---|---|
| FR-C1 | Create/edit tenants (name, phone, optional email, emergency contact, notes) | P0 |
| FR-C2 | Optional ID/contract photo attachment, stored locally and included in backups | P1 |
| FR-C3 | Optional list of household members/co-occupants | P1 |
| FR-C4 | Search tenants by name, unit, status | P0 |
| FR-C5 | Archive former tenants (history kept) | P0 |
| FR-C6 | Private landlord notes per tenant | P0 |

### D. Leases
| ID | Requirement | Priority |
|---|---|---|
| FR-D1 | Create lease: tenant, unit, start date, optional end date, monthly rent, due day, deposit, billing notes | P0 |
| FR-D2 | Lease status: active / ended | P0 |
| FR-D3 | Expiry reminder before lease end date | P0 |
| FR-D4 | Change rent with an effective date (future charges only) | P1 |
| FR-D5 | Optional late-fee rule per lease (grace days, flat amount or %); landlord can waive | P1 |
| FR-D6 | Lease summary view that can be shared/printed as PDF | P1 |
| FR-D7 | Move-out: end lease, record deposit deductions with notes/photos, compute refund, mark settled | P0 |

### E. Rent and Payments
| ID | Requirement | Priority |
|---|---|---|
| FR-E1 | Auto-generate monthly rent charges per lease (BR-8) | P0 |
| FR-E2 | Record payment: tenant, amount, date, method (cash, bank transfer, e-wallet, other), reference number, note | P0 |
| FR-E3 | Partial and advance payments (BR-6) | P0 |
| FR-E4 | Tenant ledger and statement of account (charges, payments, running balance) | P0 |
| FR-E5 | Receipt generation (PDF/image) with sequential number, shareable to any chat/SMS app | P0 |
| FR-E6 | Void/adjust an entry with a reason (BR-2) | P0 |
| FR-E7 | One-off charges (utilities, repair, penalty, other) | P0 |
| FR-E8 | Deposit tracking: received, held, deducted, refunded | P0 |
| FR-E9 | Payments tab: all payments, filter by date, property, tenant, method | P0 |
| FR-E10 | Credits and refunds | P1 |

### F. Reminders
| ID | Requirement | Priority |
|---|---|---|
| FR-F1 | Local notification before rent due date and when overdue | P0 |
| FR-F2 | Lease expiry reminders | P0 |
| FR-F3 | Pre-filled reminder message to the tenant, shared via the phone's share sheet | P0 |
| FR-F4 | Notification list with done/snooze | P1 |
| FR-F5 | Utility reading and billing reminders | P1 |

### G. Utilities (see section 5)
| ID | Requirement | Priority |
|---|---|---|
| FR-G1 | Manual utility charge on a tenant (one-off charge, type = electricity/water/internet/other) | P0 |
| FR-G2 | Utility bill entry: type, property, billing period, total, statement photo/PDF | P1 |
| FR-G3 | Meter readings per unit: previous/current reading, date, optional photo | P1 |
| FR-G4 | Automatic share calculation and per-tenant charge creation | P1 |
| FR-G5 | Equal or fixed-amount split for shared bills (e.g., internet) | P1 |

### H. Dashboard and Reports
| ID | Requirement | Priority |
|---|---|---|
| FR-H1 | Dashboard: total/occupied/vacant units, collected this month, unpaid balance, overdue list, due soon, expiring leases | P0 |
| FR-H2 | Quick actions: Record payment, Add tenant, Add unit | P0 |
| FR-H3 | Arrears (aging) report | P1 |
| FR-H4 | Monthly expected vs collected summary | P1 |
| FR-H5 | Occupancy report, tenant directory | P1 |
| FR-H6 | Export reports to PDF and CSV | P1 |
| FR-H7 | Deposit liability report | P1 |

### I. Backup and Data Safety
| ID | Requirement | Priority |
|---|---|---|
| FR-I1 | Export backup file (database + attachments) the user can save or share | P0 |
| FR-I2 | Import/restore from a backup file with validation | P0 |
| FR-I3 | Monthly "back up your records" reminder; show last backup date on Home and More | P0 |
| FR-I4 | Database integrity check on demand and after restore | P1 |
| FR-I5 | Android Auto Backup enabled as a safety net | P1 |

### J. Subscription
| ID | Requirement | Priority |
|---|---|---|
| FR-J1 | Free trial; plans limited by unit count | P0 |
| FR-J2 | Purchase and **Restore purchases** via store billing | P0 |
| FR-J3 | Over-limit behavior: existing data stays viewable and exportable, adding is blocked | P0 |
| FR-J4 | Cached entitlement works offline with a grace period | P0 |

## 5. Utilities Specification

**Goal:** turn a provider bill and meter readings into fair per-tenant charges without manual math.

### Flow (v1.1)
1. Landlord adds a **utility bill**: type, property, period start/end, total amount, optional photo/PDF.
2. Landlord enters each unit's **meter reading** for the period (previous is prefilled from last time), optionally with a meter photo.
3. App calculates **consumption** per unit, then **effective rate** = bill total ÷ total consumption (or a landlord-set fixed rate).
4. App proposes each unit's share. Landlord can review and adjust.
5. On confirm, a utility **charge** is added to each tenant's ledger, linked to the bill.

### Split methods
| Method | Use |
|---|---|
| By meter readings, allocate actual bill | Electricity, water with sub-meters |
| By meter readings, fixed rate per unit | Landlord charges a set price per kWh / m³ |
| Equal split | Shared internet, common-area bills |
| Fixed amount | Flat monthly utility fee |

### Edge cases to handle
- Tenant moves in/out mid-period (prorate by days or by reading at move date).
- Meter replaced or reset (allow "meter reset" flag; compute from the new starting value).
- Negative or zero consumption (block with a clear message).
- Missing reading (mark "estimated", allow later correction through an adjustment).
- Shares rounded to cents; leftover goes to the last unit (BR-10).
- Vacant units: landlord absorbs their share; excluded from tenant charges.
- Editing after confirmation: void and re-issue, never edit (BR-2).

## 6. Non-Functional Requirements
- **Offline:** every P0 feature works with no internet. The app has no required network calls except store billing.
- **Performance:** cold start < 3 s on a mid-range Android phone; lists respond < 300 ms with 500 tenants and 5,000 ledger entries.
- **Reliability:** no data loss on crash or force-close (SQLite transactions, WAL mode); migrations are tested with real backup files.
- **Security and privacy:** optional app lock; encrypted database recommended; tenant data never leaves the device except through user-chosen exports and shares; no PII in logs or analytics.
- **Accessibility:** 48 dp touch targets, support up to 200% text scale, never rely on color alone (see `theme.md`).
- **Localization:** English first; all strings in ARB files; currency and date formats from locale.
- **App size:** under 40 MB download.
- **Compatibility:** minimum Android version to be decided; iOS after Android (open question).

## 7. Release Plan
| Release | Contents | Outcome |
|---|---|---|
| **v1.0 MVP** | Sections A–E, FR-F1–F3, FR-G1, FR-H1–H2, FR-I1–I3, FR-J | Pilot with 10–20 landlords |
| **v1.1** | FR-B5, FR-C2–C3, FR-D4–D6, FR-E10, FR-F4–F5, FR-G2–G5, FR-H3–H7, FR-I4–I5 | Utilities, reports, polish; public launch |
| **v2.0** | Expenses, maintenance log, move-in/out inspection checklists | Operations features |
| **Later** | Optional cloud backup/sync with accounts, multi-user, tenant-facing features, online payments | Only if demand is proven |

## 8. Out of Scope
Tenant accounts or login, cloud sync, online payments or gateway integrations, e-signatures, IoT, utility provider APIs, accounting/tax filing, lease document generation beyond a summary.

## 9. Open Questions
1. Pricing and unit-count tiers; free trial length?
2. Launch country: currency, languages, tax or receipt requirements?
3. Android first, or both platforms at launch?
4. Do most target landlords have sub-meters, or one shared meter per building?
5. Is database encryption (SQLCipher) required at launch?
6. Minimum Android version?

## 10. Acceptance Criteria (samples)
**Record payment offline**
- Given no internet, when the landlord records a partial payment, then the ledger updates immediately, the balance reduces, a receipt number is assigned, and a receipt can be shared.

**Auto-generated rent**
- Given an active lease with due day 5, when the app is first opened on the 12th after being closed since the 2nd, then the charge for the 5th exists exactly once.

**Void a mistake**
- Given a payment entered with the wrong amount, when the landlord voids it with a reason and records a correct one, then both entries remain visible in the ledger and the balance is correct.

**Backup and restore**
- Given a backup file exported from phone A, when imported on phone B, then all properties, tenants, leases, ledger entries and photos match, and the integrity check passes.

**Utility share rounding**
- Given a ₱1,000.00 bill split across 3 units, then the shares sum to exactly ₱1,000.00.

**Over plan limit**
- Given a plan limited to 10 units and the landlord has 10, when they try to add an 11th, then they see an upgrade prompt and can still view, record payments for, and export existing data.
