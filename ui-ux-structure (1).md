# UI/UX Structure

Colors, type, spacing and component styling live in `theme.md`. Requirements are in `prd.md`.

## 1. Design Principles
1. **Big and clear.** Large text, 48 dp touch targets, high contrast. Many users aren't tech-savvy.
2. **Money first.** Home answers "who owes me and how much?"
3. **Three taps or fewer** for frequent actions (record payment, add tenant, add a charge).
4. **Offline is normal.** There is no sync status to worry about; instead show a calm "last backup" reminder.
5. **Icons plus words.** Never icons alone.
6. **Forgiving.** Void instead of delete, confirmations for risky actions, plain language.
7. **Start small.** Hide advanced options (late fees, utilities by meter) until the user opens them.

## 2. Navigation: five tabs
```
[ Home ]  [ Properties ]  [ Tenants ]  [ Payments ]  [ More ]
```
| Tab | Purpose |
|---|---|
| **Home** | Dashboard: collected, unpaid, overdue list, due soon, expiring leases, last backup |
| **Properties** | Properties → units, with status (vacant / occupied / overdue) |
| **Tenants** | Tenant list with balance chips; tenant detail with ledger |
| **Payments** | All payments received; filters; record payment |
| **More** | Reports, Utilities, Backup & restore, Subscription, Security, Settings, Help |

A persistent **"Record payment"** button (label + icon) on Home, Tenants and Payments.

## 3. Screen Map
```
First run
 ├─ Welcome → language & currency
 ├─ Choose: Start fresh / Restore from backup
 └─ Guided setup: property → unit → tenant → lease

Home
 ├─ Summary cards: Collected this month · Unpaid balance · Vacant units
 ├─ Overdue list → Tenant detail
 ├─ Due soon list
 ├─ Leases ending soon
 ├─ Backup banner ("Last backup 12 days ago · Back up now")
 └─ Quick actions: Record payment · Add tenant · Add unit

Properties
 ├─ Property list → Add/Edit property
 └─ Property detail
     ├─ Unit list (status chips) → Add unit
     └─ Unit detail: current tenant, rent, history, photos, meter readings

Tenants
 ├─ Search + filter (All / Overdue / Paid / Archived)
 ├─ Add/Edit tenant
 └─ Tenant detail
     ├─ Lease card (rent, due day, deposit, dates)
     ├─ Ledger / statement of account
     ├─ Record payment → Receipt (share)
     ├─ Add charge (utility, repair, penalty, other)
     ├─ Send reminder (share sheet)
     ├─ Notes, attachments
     └─ Move out → Deposit settlement

Payments
 ├─ Payment list (date, tenant, unit, amount, method)
 ├─ Filters: date range, property, tenant, method
 └─ Payment detail → Receipt / Void with reason

More
 ├─ Reports: Arrears · Monthly summary · Occupancy · Deposits · Export
 ├─ Utilities: Bills · Meter readings · Split & create charges   (v1.1)
 ├─ Backup & restore · Integrity check
 ├─ Subscription & plan · Restore purchases
 ├─ Security (app lock)
 ├─ Settings (language, currency, reminders, grace days, receipt header)
 └─ Help / contact
```

## 4. Key Flows

### A. Record a payment (most important)
`Record payment → pick tenant (search) → amount (prefilled with balance, editable) → date (today) → method → optional reference → Save → Receipt screen (Share / Done)`
Partial and advance payments need no extra steps; the receipt shows the remaining balance.

### B. Add tenant and lease
`Tenants → + → name & phone → choose vacant unit → rent (prefilled from unit), due day, start date, deposit → Review → Save`
Optional sections (co-occupants, late fees, attachments) are collapsed under "More details".

### C. Month-end follow-up
`Home → Overdue list → tenant → Send reminder → prefilled message → share sheet`

### D. Add a utility charge (MVP)
`Tenant detail → Add charge → type: Electricity / Water / Internet / Other → amount → note → Save`

### E. Utility bill with meter readings (v1.1)
`More → Utilities → New bill → type, property, period, total, photo → enter each unit's reading (previous prefilled) → review proposed shares → Confirm → charges added to tenant ledgers`

### F. Move out and deposit
`Tenant detail → Move out → move-out date → record deductions (amount, note, photo) → see refund amount → mark refunded → lease ends, unit becomes vacant`

### G. Backup and restore
`More → Backup & restore → Export backup → choose where to save/share`
`First run or More → Restore → pick .tenera file → validation summary ("12 tenants, 340 entries") → Confirm`

## 5. Status Language
Defined with colors in `theme.md`: Paid ✓ · Due in N days · Overdue N days · Vacant. Always icon + label + color.

## 6. Component Inventory
Summary card · Tenant row · Unit tile · Ledger row · Amount input (numeric keypad) · Date picker · Status chip · Backup banner · Empty state · Paywall sheet · Confirmation dialog · Receipt template · Reading input row (previous / current / consumption).

## 7. Empty, Error and Edge States
- No properties/tenants yet → one sentence + one button.
- Over plan limit → friendly upgrade sheet; existing data stays viewable and exportable.
- Backup overdue → gentle banner, never a blocking popup.
- Restore failure → plain message, current data untouched.
- Subscription lapsed → read-only banner for adding new units, never data lockout.
- Voiding a payment → asks for a reason; both entries stay visible.
- Utility reading lower than previous → ask: "Meter reset?" or fix the number.

## 8. Accessibility and Localization
Dynamic font scaling to 200%, screen-reader labels, locale-aware dates and currency, translatable strings from day one, numbers in tabular figures.

## 9. Wireframe / Prototype Checklist (next)
- [ ] Home dashboard
- [ ] Properties → unit list → unit detail
- [ ] Tenants list and tenant detail with ledger
- [ ] Record payment and receipt
- [ ] Add tenant + lease
- [ ] Payments tab
- [ ] Move-out and deposit settlement
- [ ] Backup & restore
- [ ] Paywall
- [ ] Utility bill and readings (v1.1)
