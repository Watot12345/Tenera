# Agents

Guidance for AI coding/planning agents (Claude Code or similar) working on this repository. Place this at the repo root so agents load it automatically.

## Project Summary
Offline-first, subscription-based mobile app for small landlords to manage tenants, rent, and receipts. See `context.md`, `prd.md`, `Architecture.md`, `ui-ux-structure.md`, `workflow.md`.

## Non-Negotiable Rules
1. **Offline-first**: every P0 feature must work with no network. Reads/writes hit the local DB first.
2. **Append-only money**: never update or delete payments/charges in place; use void/adjustment entries. Store money as integers in minor units, never floating point.
3. **UUIDs and timestamps on every record** (`id`, `created_at`, `updated_at`, `deleted_at`) so sync can be added later. Recurring charge generation must be idempotent.
4. **Local-only MVP**: no backend, no login, no network calls except store billing. Do not add a server without an approved PRD change.
5. **No PII in logs** (names, phone numbers, ID photos).
6. **Plain-language UI copy**; all strings go through localization.
7. **Accessibility**: ≥ 48dp touch targets, support dynamic font scaling.
8. Do not add payment processing, tenant app, or accounting features without an approved PRD change.

## Agent Roles

| Agent | Responsibility | Reads | Writes |
|---|---|---|---|
| **Planner** | Break PRD items into tasks with acceptance criteria | prd.md, workflow.md | task list, PRD updates |
| **Architect** | Schema, sync design, API contracts, ADRs | Architecture.md | Architecture.md, migrations |
| **Mobile Dev** | Screens, state, local DB, sync client | ui-ux-structure.md, Architecture.md | `/app` |
| **Backend Dev** | Phase 3 only (optional cloud backup/sync); not needed for MVP | Architecture.md | `/server` (future) |
| **UX Agent** | Screen specs, flows, empty/error states, copy | ui-ux-structure.md | specs, strings |
| **QA Agent** | Test plans, offline/failure-mode tests, regression | prd.md acceptance criteria | `/tests` |
| **Reviewer** | PR review against rules above | all | review comments |

## Working Agreement
- Start each task by stating which PRD item (FR-#) it implements.
- Prefer small PRs (< 400 lines), each with tests.
- When a rule conflicts with a request, stop and ask, don't silently bend the rule.
- Record significant decisions in the Architecture.md decisions log.
- If requirements are ambiguous, list assumptions in the PR description.

## Suggested Repo Layout
```
/app            mobile client
/server         (Phase 3, not part of the MVP)
/docs           context.md, prd.md, Architecture.md, infrastructure.md, theme.md, ui-ux-structure.md, workflow.md, skills.md
/tests
agents.md
```

## Commands (fill in once stack is chosen)
```
# install:   
# run app:   
# run tests: 
# lint:      
# migrate:   
```

## Definition of Done (agent checklist)
- [ ] Implements a referenced FR-#
- [ ] Works in airplane mode
- [ ] Tests added/updated and passing
- [ ] No hardcoded strings
- [ ] No PII in logs
- [ ] Docs updated if behavior changed
