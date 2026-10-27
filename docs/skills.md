# Skills

Two meanings are covered here: (1) the **skills your team needs** to build this product, and (2) the **reusable Claude skills** you can set up to speed up the work.

## Part 1: Skills Required to Build

| Area | Skill | Level needed | Notes |
|---|---|---|---|
| Mobile | Flutter/Dart *or* React Native/TypeScript | Strong | Pick one |
| Local data | SQLite, migrations, encryption (SQLCipher) | Strong | Core of offline-first |
| Sync | Outbox pattern, idempotency, conflict resolution | Strong | Highest-risk area |
| Backend | REST API, PostgreSQL, auth (OTP, JWT) | Medium–Strong | Or Supabase to reduce load |
| Billing | Play Billing / StoreKit, receipt validation | Medium | RevenueCat can simplify |
| Notifications | Local scheduling + FCM/APNs | Medium | |
| UI/UX | Mobile design, accessibility, low-literacy UX | Medium–Strong | Critical for this audience |
| DevOps | CI/CD, environments, backups | Medium | |
| Security/Privacy | Encryption, data privacy law basics | Medium | PII about tenants |
| QA | Offline/network-failure testing, low-end devices | Medium | |
| Product | User interviews, pricing validation | Medium | Needed before heavy coding |

### Skill gaps checklist
- [ ] Who owns mobile?
- [ ] Who owns backend and sync?
- [ ] Who designs UI?
- [ ] Who handles store submission and legal docs?

## Part 2: Reusable Claude Skills / Prompts to Create

Create these once, reuse throughout the project:

| Skill name | Purpose | Trigger example |
|---|---|---|
| `prd-writer` | Turn feature ideas into PRD sections with acceptance criteria | "Write PRD for utilities feature" |
| `sync-reviewer` | Review code/schema for offline-sync and conflict issues | "Review this repo layer for sync bugs" |
| `schema-designer` | Generate migrations + local/server schema from entities | "Add `Deposit` entity" |
| `ui-spec` | Convert a flow into screen specs, states, and copy | "Spec the move-out flow" |
| `test-generator` | Produce unit tests for charge/balance logic | "Tests for late fee rule" |
| `release-notes` | Draft store listing and changelog from commits | "Release notes for v1.0" |
| `pitch-deck` | Build client pitch slides from these docs | "Make the client pitch" |

### Conventions for any skill
- Always read `context.md`, `prd.md`, and `Architecture.md` first.
- Never break the offline-first and append-only ledger rules.
- Output must include acceptance criteria and edge cases.
- Use plain language for user-facing copy (target: low digital literacy).
