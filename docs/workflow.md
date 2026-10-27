# Workflow

Covers both **product workflows** (how the app behaves) and **development workflow** (how you build it).

## Part A: Product Workflows

### A1. Tenant lifecycle
```
Add tenant → Assign to unit (create lease) → Monthly charges auto-generate
   → Payments recorded → Receipt shared → (Overdue → Reminder)
   → Lease ends → Deposit settled → Unit becomes vacant → Tenant archived
```

### A2. Monthly rent cycle
1. Day before due date: local notification "Rent due tomorrow: N tenants."
2. Due date: charge becomes "due"; unit status updates.
3. Owner records payments as collected (cash/transfer/e-wallet).
4. Past due: status turns overdue; appears on Home overdue list.
5. Owner sends reminder via share sheet.
6. Month-end: report shows collected vs expected.

### A3. Local write (no sync in MVP)
```
User action → validate → single SQLite transaction (ledger entry + related rows)
   → UI updates instantly → reminders rescheduled if needed
Failure → transaction rolls back → plain-language error → nothing half-saved
```
Data safety comes from backups (A6), not from a server.

### A4. Subscription
```
Trial → paywall at unit limit/expiry → store purchase (no Tenera account)
→ entitlement read from the store and cached on device → offline grace period
→ "Restore purchases" on a new phone → blocked from adding units if lapsed (data never locked)
```

### A5. New phone / restore
Install app → Restore from backup → pick `.tenera` file → checksums and integrity check → confirm counts → data swapped in (old copy kept until confirmed).

### A6. Backup cycle
Monthly reminder → Export backup → user saves to Drive/chat/USB → "last backup" date updates on Home and More.

### A7. Utility billing (v1.1)
Enter provider bill → enter unit meter readings → review proposed shares → confirm → charges added to each tenant ledger.

---

## Part B: Development Workflow

### B1. Phases
| Phase | Duration (est.) | Deliverables |
|---|---|---|
| 0. Discovery | 1 wk | Client interviews with 5–10 landlords, validate pricing, finalize PRD |
| 1. Design | 2 wks | Wireframes → clickable prototype, brand basics |
| 2. Foundations | 2 wks | Repo, CI/CD, local DB schema and migrations, ledger engine, theme |
| 3. MVP build | 6–8 wks | Properties, tenants, leases, charges, payments, receipts, dashboard |
| 4. Data safety | 2 wks | Backup/restore, migration tests, app lock, offline QA |
| 5. Billing | 1–2 wks | Subscription, paywall, entitlements |
| 6. Pilot | 3–4 wks | 10–20 real landlords, feedback loop |
| 7. Launch prep | 2 wks | Store listings, privacy policy, support flow |

*Estimates assume 1–2 developers; adjust once team and stack are fixed.*

### B2. Git & release flow
- `main` (always releasable) ← `feature/*` via pull request
- PR needs: passing CI, lint, tests, 1 review (or self-review checklist if solo)
- Conventional commits; semantic versioning
- Tags trigger staging builds; manual promotion to production

### B3. Definition of Done
- [ ] Works offline (airplane-mode test)
- [ ] Unit/widget tests for logic
- [ ] Accessible (font scale, labels)
- [ ] Analytics event added where relevant
- [ ] Strings translatable
- [ ] No new crashes in Sentry on staging

### B4. Testing strategy
| Level | Focus |
|---|---|
| Unit | Charge generation, balance math, utility share rounding, late fees |
| Integration | Backup/restore round trip, upgrading databases from older versions |
| E2E | Add tenant → record payment → receipt |
| Manual | Low-end device, flaky network, battery saver |
| Beta | TestFlight / Play internal track |

### B5. Feedback loop
Weekly pilot check-ins → issues triaged (bug / UX friction / feature) → prioritized in a simple board (Now / Next / Later).

### B6. Pitch-to-client workflow
1. Show problem and persona (context.md)
2. Demo clickable prototype (ui-ux-structure.md)
3. Walk through scope and phases (prd.md, this file)
4. Explain differentiator: offline-first (Architecture.md)
5. Agree on pilot scope, pricing hypothesis, and timeline
