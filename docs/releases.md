---
layout: default
title: Release Notes & Changelog
---

# 📋 Tenera Release Notes & Changelog

All official releases of Tenera are published to the [GitHub Releases](https://github.com/Watot12345/Tenera/releases) repository.

---

## 🏷️ Version v1.0.1 (Latest Release)

*Release Date: November 2026*  
*Target: Android 7.0 (API 24) to Android 15+*

### 🚀 What's New in v1.0.1
- **Partial & Advance Payments + Tenant SOA**: Record partial or advance payments with running balances, sequential receipts, and void/adjustment audit trails (BR-2, FR-E3, FR-E4, FR-E6).
- **Move-Out Security Deposit Settlement & Escrow Reports**: Track security deposits strictly as liabilities (separate from rent income) and calculate move-out deductions and refunds (BR-4, FR-D7, FR-H7).
- **Government ID Attachment & Late-Fee Rules**: Attach tenant ID photos offline and configure optional grace days and late fees with 1-tap waiver support (FR-C2, FR-D5).
- **Expense Tracker, Maintenance Tickets & Arrears Aging Report**: Track property expenses, unit repair tickets, 30/60/90+ day arrears aging buckets, and on-demand SQLite `PRAGMA integrity_check` diagnostics.
- **Play Protect Safe SMS Reminders**: Uses the device's default SMS app via `sms:` intent without invasive `SEND_SMS` permissions.

---

## 🏷️ Version v1.0

*Release Date: October 2026*  
*Target: Android 7.0 (API 24) to Android 14+*

### 🚀 What's New

#### Core Architecture
- **SQLite Single Source of Truth**: Removed all mock data. Properties, rooms, tenants, and payment records are saved and queried directly from local SQLite (`tenera.db`).
- **Dynamic Ledger Math**: Real-time computation of `_collectedAmount`, `_expectedAmount`, `_vacantUnits`, and `_totalUnits`.
- **Hybrid Cloud Sync**: Introduced `SyncService` and `FirebaseService` allowing optional cloud backup to Firebase Cloud Firestore without requiring upfront user login.
- **In-App Update Engine**: Integrated `UpdateService` which queries the GitHub Releases API and prompts users when new APK releases are published.

#### User Interface & Experience
- **Concept C Roof Ledger Theme**: Modern, clean aesthetic with high-contrast palette tokens (`#1D3557` Deep Navy, `#E9C46A` Warm Gold, `#2A9D8F` Paid Emerald, `#E76F51` Overdue Terracotta).
- **Payment Dialog Enhancements**:
  - Live tenant candidate search by name, unit, or initials.
  - Cash photo proof attachment.
  - Digital payment reference number logging for GCash and Bank Transfer.
- **Room Grid & Tenant Assignment**:
  - Visual room matrix per property.
  - Room status filters (All, Occupied, Overdue, Vacant).
  - Long-press to remove or vacate tenants with confirmation modal.
  - Dedicated "Add Room" flow.
- **Welcome & App Guide**: Comprehensive onboarding and in-app instructions accessible anytime via the **More** tab.

### 📦 Assets & Downloads
- `app-release.apk` (Production APK for ARM64, ARMv7, and x86_64)
- Source code (zip & tar.gz)

---

## 🗺️ Roadmap & Upcoming Releases

- [ ] Automatic SMS & Messenger reminder generation via direct intent hooks.
- [ ] Automated background periodic sync to Firebase when Wi-Fi is connected.
- [ ] Utility bills split calculator (Water & Electricity submeter math).
- [ ] Export payment history to PDF and CSV receipts.
