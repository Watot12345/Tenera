# Tenera Property Manager

> **Senior-Friendly, Offline-First Property & Tenant Management**  
> Manage rental properties, track payments, take cash photos, record digital reference numbers, and keep 100% of your records locally on your device — with optional cloud sync to Firebase.

[![GitHub Release](https://img.shields.io/github/v/release/Watot12345/Tenera?color=E9C46A&label=Latest%20Release)](https://github.com/Watot12345/Tenera/releases/latest)
[![Android](https://img.shields.io/badge/Platform-Android%207.0%2B-2A9D8F)](https://github.com/Watot12345/Tenera/releases)
[![Offline First](https://img.shields.io/badge/Storage-SQLite%20Offline%20SSOT-1D3557)](https://github.com/Watot12345/Tenera)
[![License](https://img.shields.io/badge/License-MIT-blue)](https://github.com/Watot12345/Tenera/blob/main/LICENSE)

---

## 📲 Download the Latest Release

Get the latest official Android APK package directly from GitHub:

<div align="center" style="margin: 24px 0;">
  <a href="https://github.com/Watot12345/Tenera/releases/latest/download/app-release.apk" style="display:inline-block; background-color:#1D3557; color:#FFFFFF; font-weight:700; font-size:18px; padding:16px 32px; border-radius:14px; text-decoration:none; box-shadow:0 4px 14px rgba(29,53,87,0.35);">
    ⬇️ Download Tenera APK (v1.0)
  </a>
</div>

* 📂 **Release Changelog & Assets**: [View GitHub Releases](https://github.com/Watot12345/Tenera/releases)
* 📜 **Full Version Notes**: [Read Release Notes](releases.html)
* 🛡️ **Privacy & Terms**: [Read Privacy Policy](privacy-policy.html)

---

## 🚀 How to Install on Android (Sideload Guide)

If you downloaded the APK directly to your phone:

1. **Download APK**: Tap the download button above or select `app-release.apk` from the [Latest Release](https://github.com/Watot12345/Tenera/releases/latest).
2. **Enable Unknown Apps**:
   - If prompted *"For your security, your phone is not allowed to install unknown apps from this source"*, tap **Settings**.
   - Toggle **Allow from this source** ON.
3. **Install**: Tap **Install** on the prompt.
4. **Open Tenera**: Launch the app from your home screen or app drawer.
5. **In-App Updates**: Once installed, whenever a new release is posted on GitHub, Tenera will automatically prompt you via the built-in update checker! You can also manually check under **More ➔ Check for Updates**.

---

## 🌟 Key Features

### 1. 🏠 Roof Ledger Dashboard
- **Monthly Revenue at a Glance**: Live metrics of collected rent vs. expected rent for the month.
- **Vacancy & Overdue Tracking**: Instant status cards for overdue rent, due soon, and vacant units.
- **High-Contrast, Senior-Friendly Interface**: Clear typography, accessible color accents, and large touch targets.

### 2. ⚡ Quick Payment Logging
- **Instant Search**: Type tenant name, initials, or unit number to quickly select tenants.
- **Cash Photo Attachment**: Capture or attach photos of paper cash handover directly to payment records.
- **Digital Reference Numbers**: Log GCash and Bank Transfer reference codes for easy dispute resolution.
- **Dynamic Ledger Updating**: Automatically marks tenant as paid and increments month-to-date collections.

### 3. 🏢 Unit & Room Matrix
- **Visual Status Grid**: Color-coded room tiles (Occupied, Overdue, Vacant).
- **Tenant Management**: Long-press any room or tenant assignment to vacate/remove tenants.
- **Multi-Property Capacity**: Add multiple properties with custom unit codes and rental rates.

### 4. 📴 100% Offline Single Source of Truth + Cloud Sync
- **SQLite Database**: Works completely without Wi-Fi or mobile data. No forced login screens.
- **Firebase Sync**: Connect to Cloud Firestore when online with a single tap from the **More** tab.
- **Data Export & Backup**: Export local JSON backups directly to device storage.

---

## 🛠️ Developer Setup & Building from Source

```bash
# Clone the repository
git clone https://github.com/Watot12345/Tenera.git
cd Tenera

# Install Flutter dependencies
flutter pub get

# Run tests
flutter test

# Build release APK
flutter build apk --release
```

The compiled release APK will be located at:
`build/app/outputs/flutter-apk/app-release.apk`

---

## 📄 License & Attribution

Tenera is released under the [MIT License](https://github.com/Watot12345/Tenera/blob/main/LICENSE).  
Developed with ❤️ by the Tenera Team.
