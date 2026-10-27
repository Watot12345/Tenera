# Architecture (Local-first, no backend)

Flutter app + SQLite on the device. No login, no server in the MVP. See `infrastructure.md` for packages and tools, `prd.md` for requirements.

## 1. Principles
1. **Local database is the system of record.** The app works fully offline because there is nothing else to depend on.
2. **Append-only money.** Charges and payments are never edited in place; corrections are void/adjustment entries (BR-2).
3. **Protect against device loss.** Backup/restore is a core feature, not an extra.
4. **Sync-ready, not sync-built.** Every record has a stable UUID, `created_at`, `updated_at` and `deleted_at`, so cloud sync can be added later without replacing the data model.
5. **Simple first.** Few layers, few moving parts, one developer can hold it in their head.

## 2. Layer Diagram
```
┌──────────────────────── Flutter App ────────────────────────┐
│  UI (screens, widgets, theme.md tokens)                     │
│    ↓                                                        │
│  State (Riverpod providers / view models)                   │
│    ↓                                                        │
│  Domain services (ledger, charge generation, utilities,     │
│                   deposits, reminders, receipts)            │
│    ↓                                                        │
│  Repositories (one per aggregate)                           │
│    ↓                                                        │
│  Drift (type-safe SQL) ──→ SQLite file (optionally encrypted)│
│                                                             │
│  Platform services: local notifications · file storage ·    │
│  share sheet · PDF · biometrics · store billing             │
└─────────────────────────────────────────────────────────────┘
      only external contact: Google Play / App Store billing
```

## 3. Data Model

**Common columns on every table:** `id` (UUID), `created_at`, `updated_at`, `deleted_at` (nullable, soft delete).

| Table | Key columns |
|---|---|
| `settings` | key, value (currency, language, grace days, receipt header, next receipt number) |
| `properties` | name, address, notes |
| `units` | property_id, name, default_rent, default_deposit, is_shared, capacity, notes |
| `tenants` | name, phone, email, emergency_contact, notes, archived_at |
| `occupants` | tenant_id, name, relation (optional) |
| `leases` | tenant_id, unit_id, start_date, end_date, rent_amount, due_day, deposit_amount, status (active/ended), late_fee_rule (grace_days, type, value), ended_at |
| `rent_changes` | lease_id, effective_from, new_amount |
| `ledger_entries` | lease_id, kind, amount (signed), entry_date, period (YYYY-MM, for charges), method, reference, receipt_no, description, voids_entry_id, related_bill_id |
| `deposit_entries` | lease_id, kind (received/deduction/refund), amount, note |
| `utility_bills` | property_id, type, period_start, period_end, total_amount, split_method, status |
| `meter_readings` | unit_id, utility_type, reading_date, value, is_estimated, is_reset, photo_id |
| `utility_allocations` | bill_id, unit_id, lease_id, consumption, amount, ledger_entry_id |
| `attachments` | owner_type, owner_id, kind (photo/pdf), file_path, mime, size, checksum |
| `reminders` | kind, target_type, target_id, due_at, status (pending/done/snoozed) |
| `entitlement_cache` | plan, expires_at, last_verified_at |
| `schema_meta` | schema_version, last_backup_at |

`ledger_entries.kind`: `rent_charge`, `utility_charge`, `late_fee`, `other_charge`, `payment`, `credit`, `adjustment`, `void`.
Charges are positive, payments/credits negative (or the reverse; pick one convention and keep it in one place).

### Rules enforced in code and constraints
- `PRAGMA foreign_keys = ON`; `journal_mode = WAL`.
- Unique index on `(lease_id, kind, period)` for `rent_charge` so a period can't be billed twice (BR-8).
- Unique index on `receipt_no`.
- Overlapping active leases per unit rejected unless `units.is_shared` (BR-3).
- Ledger rows are insert-only. Update/delete is blocked in the repository layer and by a SQLite trigger.
- Deposit entries live in their own table and are excluded from rent income calculations (BR-4).

## 4. Key Calculations
- **Balance** = sum of ledger entries for the lease (charges − payments − credits ± adjustments), excluding voided pairs.
- **Application of payments:** oldest unpaid charge first (BR-6), computed on read for display; not stored.
- **Overdue** = unpaid charge older than its due date plus grace days.
- **Unit status** = vacant (no active lease) / occupied / overdue (occupied with overdue balance), derived, never stored.

## 5. Recurring Charge Generation
- Runs on app start, on resume, and from a daily background task where the OS allows.
- For each active lease, it creates a charge for **every due period up to today** that doesn't exist (catches up on missed months).
- The `(lease_id, kind, period)` unique index makes it idempotent. Running twice creates nothing new.
- Rent amount for a period is resolved from `rent_changes` (latest effective_from ≤ period start).
- Late fees are created by the same job after the grace period, once per charge.

## 6. Utilities Engine
1. Input: bill total, period, per-unit consumption (readings), split method.
2. Output: proposed allocation per unit, shown for review.
3. On confirm (single DB transaction): insert `utility_allocations` and one `utility_charge` ledger entry per tenant, linked by `related_bill_id`.
4. Rounding: compute in integer minor units (centavos/cents); the last unit absorbs the remainder (BR-10).
5. Corrections: void the generated charges and re-issue; never edit.
6. **Store money as integers (minor units)**, never floating point.

## 7. Reminders
- Scheduled with local notifications (`flutter_local_notifications`).
- The OS limits scheduled notifications (iOS keeps about 64 pending; Android may delay or restrict exact alarms and background work). So the app **schedules only the next N upcoming reminders** and rebuilds the schedule every time it opens.
- The reminders table is the source of truth; notifications are a convenience.
- Tenant messages are prefilled text opened through the share sheet; the app never sends SMS itself.

## 8. Backup and Restore
**Export** creates a single `.tenera` file (zip):
```
manifest.json   (app version, schema_version, created_at, row counts, checksums)
tenera.db       (consistent copy made with SQLite backup API / VACUUM INTO)
attachments/    (photos and PDFs referenced by the DB)
```
**Import:**
1. Read manifest; refuse files from a newer schema version than the app supports.
2. Verify checksums.
3. Restore into a **temporary** database, run `PRAGMA integrity_check` and row count comparison.
4. Only then swap it in; keep the previous database as a rollback copy until the user confirms.
- Backup reminder monthly; last backup date visible on Home and More.
- Android Auto Backup is a safety net, not the plan.

## 9. Subscription and Entitlement
- Store billing (`in_app_purchase`) is the source of truth.
- The app caches the entitlement with an offline grace period (default 7 days).
- "Restore purchases" is a first-class button (no account to fall back on).
- Over-limit: view, export and record payments continue; adding new units is blocked.
- Free trial and product IDs are configured in the store consoles.

## 10. Security and Privacy
- Optional app lock (PIN or biometric) on launch and resume.
- Database encryption with SQLCipher recommended; key in the platform keystore. (Open decision in `infrastructure.md`.)
- Attachments stored in the app's private storage; included in backups only.
- No PII in logs, crash reports or analytics.
- No payment gateway secrets are ever stored in the app. Local records are not tamper-proof, which is why the ledger is append-only and exportable.

## 11. Migrations
- Every schema change has a numbered Drift migration and a test that upgrades a database from each previous version.
- Test fixtures include a realistic database with many leases and ledger entries.
- A backup is automatically taken before a migration runs.

## 12. Future (not built now)
- Optional cloud backup/sync: needs accounts, a server, conflict rules. The UUID/timestamp columns above are the preparation.
- Tenant-facing app, online payments: server-side verification only. Never trust a screenshot or the app's own status.

## 13. Decisions Log
| # | Decision | Status |
|---|---|---|
| 1 | Flutter + SQLite via Drift, local only | Decided |
| 2 | No login, no backend in MVP | Decided |
| 3 | Append-only ledger, integer money | Decided |
| 4 | Backup file + restore is mandatory in MVP | Decided |
| 5 | SQLCipher encryption | Open |
| 6 | `in_app_purchase` vs RevenueCat | Open |
| 7 | iOS at launch or after Android | Open |
