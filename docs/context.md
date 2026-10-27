# Project Context

## One-liner
A mobile-first, subscription-based tenant management app for small landowners and family property managers (including mothers/parents who run a few rental units), built to work **offline and online**.

## Problem
Small landlords typically manage tenants with notebooks, chat threads, and memory. This causes:
- Missed or disputed rent payments (no reliable record)
- No clear view of who owes what, and since when
- Lost lease details, deposits, and utility readings
- Awkward reminder conversations
- Poor connectivity in many rental areas, so cloud-only tools fail

## Target Users
| Persona | Description | Key need |
|---|---|---|
| **Landowner (primary)** | Owns 1–30 units (apartments, rooms, boarding houses, small compounds) | See income, arrears, and occupancy at a glance |
| **Family manager (primary)** | Parent/relative who handles collection and tenant concerns day to day | Dead-simple UI, large text, minimal steps |
| **Tenant (secondary, phase 2)** | Rents a unit | See balance, receipts, send requests |
| **Helper/caretaker (phase 2)** | Collects rent or handles repairs on behalf of owner | Limited-permission access |

## Core Value Proposition
1. **Works without internet**: record payments, readings, and notes anywhere, sync later.
2. **Clear ledger per tenant**: always know who has paid and who hasn't.
3. **Simple enough for non-technical users**: designed for low digital literacy.
4. **Affordable subscription**: priced by number of units.

## Business Model
- Subscription tiers by unit count (e.g., Free trial → Starter → Standard → Pro). *Pricing to be validated with the client.*
- Optional later add-ons: tenant portal, SMS reminders, multi-user access, reports export.

## Assumptions (to validate)
- Users primarily on mid-range Android devices; iOS secondary
- Rent is mostly collected in cash or via transfer/e-wallet, then **recorded manually** (no payment processing in MVP)
- Reminders via push notification and shareable messages (SMS/chat) in MVP
- Primary language needs: English + local language option

## Out of Scope (MVP)
- In-app payment processing
- Tenant-facing app
- Accounting/tax features
- Property listing / tenant marketing

## Risks
| Risk | Mitigation |
|---|---|
| Sync conflicts from offline edits | Append-only ledger design, deterministic conflict rules (see Architecture.md) |
| Low willingness to pay | Free tier + clear ROI demo (arrears recovered) |
| Data loss on device | Automatic cloud backup when online, export option |
| Low digital literacy | Guided onboarding, big touch targets, icons + text |

## Success Metrics
- Time to first tenant added < 3 minutes
- % of active users recording ≥ 1 payment/week
- Free → paid conversion rate
- 30/60/90-day retention
- Sync failure rate < 1%

## Glossary
- **Unit**: a rentable space (room, apartment, house)
- **Lease**: agreement linking a tenant to a unit with terms
- **Ledger**: chronological record of charges and payments for a lease
- **Arrears**: unpaid amount past due date
