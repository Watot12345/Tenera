# Tenera Landing Page & Docs Site Redesign

**Date:** 2026-11-27
**Status:** Draft — awaiting approval

## Intent & Why
Tenera's GitHub Pages site ([docs/index.html](file:///home/your/Tenera/docs/index.html), [docs/releases.html](file:///home/your/Tenera/docs/releases.html), [docs/privacy-policy.html](file:///home/your/Tenera/docs/privacy-policy.html)) currently uses a navy-blue palette that doesn't match the app's Roof Ledger teal/amber identity, relies on emoji icons and static walls of text, and offers no light/dark mode for eye comfort. The goal is a classy, calm, editorial product pitch tailored to serious Filipino landlords that builds trust and makes downloading the APK effortless.

## Goals, Non-Goals & Anti-Goals
- **Goals:**
  - Unify all 3 public pages under a shared Roof Ledger design system (`docs/styles.css` + `docs/site.js`): warm alabaster light mode (`#F6F8F7`), gentle slate dark mode (`#0F171A`), deep teal primary (`#0E6B63`), warm amber accent (`#F2A33A`), crisp inline SVG icons, and generous whitespace.
  - Pitch the app cleanly with refined, purposeful interactions: hero screenshot switcher + native `<dialog>` full-size lightbox, tabbed landlord workflows, Monthly/Annual pricing toggle with savings badge, collapsible Android install steps & landlord FAQ, and an accessible Light/Dark theme toggle persisted in `localStorage`.
  - Keep the dynamic GitHub Releases latest-version sync working for the release badge and APK download links.
- **Non-Goals:** No backend, no build bundler/framework (stays zero-dependency static HTML/CSS/JS for GitHub Pages), no changes to the Flutter app or markdown spec files.
- **Anti-Goals:** No gamification, flashy neon effects, bouncy animations, or emoji clutter; no hiding the APK download CTA behind multiple clicks; no developer PRD wall above the fold.

## Constraints
- Served directly by GitHub Pages from `docs/` (`.nojekyll`).
- Must look crisp on mobile phones (where most landlords open the link to download the APK) as well as desktop, with WCAG AA contrast in both light and dark modes and `prefers-reduced-motion` respected.

## Approaches Considered
1. **Approach A — Landing Page Only (`docs/index.html`):** Fast single-file redesign, but leaves `releases.html` and `privacy-policy.html` in the older navy-blue style.
2. **Approach B — Full Cohesive Site Refresh (`docs/styles.css` + `docs/site.js` + `index.html`, `releases.html`, `privacy-policy.html`) *(Selected)*:** Extracts shared tokens, typography, header/footer, and theme toggle so every public page feels like one trustworthy product.

## Page Architecture (`docs/index.html`)
1. **Sticky Glass Header:** Tenera squircle icon + wordmark, clean nav links, Light/Dark eye-comfort toggle, compact *Download APK* CTA.
2. **Hero Pitch (2-column):** Release badge (auto-synced with GitHub Releases), confident landlord-focused headline & subcopy, primary *Download APK* + secondary *What's New* buttons, calm trust strip (14-Day Free Trial · 100% Offline SQLite · Play Protect Safe · GCash/Maya Ready). Right column: interactive phone showcase with segmented toggle (*Home Ledger* / *Room Grid*) + click-to-zoom native `<dialog>` lightbox.
3. **Interactive Landlord Workflow Tabs (`#features`):** 4 clean tabs (*Rent & SOA*, *Rooms & Tenants*, *Utilities & Expenses*, *Offline & Security*), each pairing concise landlord benefits with clean visual highlights — replacing the 9-card emoji wall.
4. **Transparent Pricing (`#pricing`):** Monthly / Annual pill toggle that smoothly updates Starter (`₱49/mo` ↔ `₱399/yr`), Tenera Pro (`₱199/mo` ↔ `₱1,499/yr`, featured), and Business (`₱499/mo` ↔ `₱3,999/yr`) with savings callouts.
5. **Android Install Guide & Landlord FAQ (`#install`):** Clean 4-step numbered guide plus collapsible `<details>` FAQ answering common landlord questions (offline safety, Play Protect, backups, upgrading).
6. **Footer & Compact Docs Strip:** Clean footer with subtle links to PRD, Architecture, Theme, Releases, and Privacy Policy.
