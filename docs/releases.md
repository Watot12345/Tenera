---
layout: default
title: Release Notes & Changelog
---

# 📋 Tenera Release Notes & Changelog

All official releases of Tenera are published to the [GitHub Releases](https://github.com/Watot12345/Tenera/releases) repository.

---

## 🏷️ Version v1.0 (Latest Release)

*Release Date: October 2026*  
*Target: Android 7.0 (API 24) to Android 14+*

### 🚀 What's New

#### Core Architecture
- **SQLite Single Source of Truth**: Removed all mock data. Properties, rooms, tenants, and payment records are saved and queried directly from local SQLite (`tenera.db`).
- **Dynamic Ledger Math**: Real-time computation of `_collectedAmount`, `_expectedAmount`, `_vacantUnits`, and `_totalUnits`.
- **Hybrid Cloud Sync**: Introduced `SyncService` and `FirebaseService` allowing optional cloud backup to Firebase Cloud Firestore without requiring upfront user login.
- **In-App Update Engine**: Integrated `UpdateService` which queries the GitHub Releases API and prompts users when new APK releases are published.

#### User Interface & Experience
- **Concept C Roof Ledger Theme**: Modern, senior-friendly aesthetic with high-contrast palette tokens (`#1D3557` Deep Navy, `#E9C46A` Warm Gold, `#2A9D8F` Paid Emerald, `#E76F51` Overdue Terracotta).
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
