# Infrastructure (Tenera)

Languages, frameworks, tools, packages and extensions for building Tenera.
**Package names are proposals.** Check each one on pub.dev (maintenance, license, Android/iOS support) before adopting, and pin versions in `pubspec.lock`.

## 1. Key Decisions
| Decision | Choice | Consequence |
|---|---|---|
| App framework | **Flutter** (Dart) | One codebase for Android + iOS |
| Local database | **SQLite** | Data lives on the device; works fully offline |
| Login | **None in MVP** | No backend or user accounts required |
| Subscription | Store billing (Google Play / App Store) | Entitlement tied to the store account, restored via "Restore purchases" |

### What "no login" changes
- No server in the MVP, so hosting costs are close to zero.
- **No automatic multi-device sync.** One phone = one set of data.
- **Lost or broken phone = lost data**, unless there is a backup. A backup feature is therefore mandatory, not optional (see section 5).
- Entitlement checks come from the store (not from our server), so the "restore purchases" flow must be reliable.
- `Architecture.md` and `prd.md` still describe login, cloud sync and a backend (FR-1, FR-7, FR-12). They need updating to match, or those items move to a later phase.

## 2. Languages
| Language | Used for |
|---|---|
| **Dart** (latest stable) | All app code |
| **SQL** (SQLite dialect) | Schema, migrations, queries (through Drift) |
| **Kotlin / Swift** | Only if a native plugin needs configuration; avoid writing native code |
| **Markdown** | Planning docs, `agents.md` |
| **YAML** | `pubspec.yaml`, CI workflows |

## 3. Framework and Packages (proposed)

### Core
| Purpose | Package |
|---|---|
| SDK | Flutter (stable channel) |
| State management | `flutter_riverpod` |
| Navigation | `go_router` |
| Code generation | `build_runner`, `freezed`, `json_serializable` |
| IDs | `uuid` |
| Dates, currency, translations | `intl`, `flutter_localizations` (ARB files) |

### Database
| Purpose | Package |
|---|---|
| SQLite ORM, migrations, type-safe queries | `drift`, `drift_dev` |
| SQLite native library | `sqlite3_flutter_libs` |
| Encrypted database (optional, recommended for tenant data) | SQLCipher via `sqlcipher_flutter_libs` with Drift |
| Key storage | `flutter_secure_storage` |
| File paths | `path_provider`, `path` |

### Features
| Feature | Package |
|---|---|
| Local reminders for due and overdue rent | `flutter_local_notifications`, `timezone`, `flutter_timezone` |
| Receipts (PDF/image) | `pdf`, `printing` |
| Share receipts and reminders to chat/SMS | `share_plus` |
| Photos (receipts, IDs) | `image_picker`, `flutter_image_compress` |
| Backup export/import | `file_picker`, `archive` (zip the DB + photos) |
| App lock (PIN / biometric) | `local_auth` |
| Permissions | `permission_handler` |
| Subscriptions | `in_app_purchase` (official), or `purchases_flutter` (RevenueCat) if you want simpler receipt handling |
| Crash reporting | `sentry_flutter` or Firebase Crashlytics |
| Analytics (optional, keep minimal for privacy) | Firebase Analytics or a privacy-friendly alternative |

### Testing and quality
| Purpose | Tool |
|---|---|
| Unit and widget tests | `flutter_test`, `mocktail` |
| End-to-end | `integration_test` |
| Screenshots | golden tests |
| Lint rules | `flutter_lints` (or `very_good_analysis`) |
| In-memory DB for tests | Drift's in-memory SQLite |

## 4. Development Tools and Extensions

### Editor
- **VS Code** with the *Flutter* and *Dart* extensions, or **Android Studio** with the Flutter and Dart plugins
- VS Code extras: *Error Lens*, *GitLens*, *Drift* (query/schema support), *Material Icon Theme*

### SDKs and utilities
- Flutter SDK + Dart SDK (bundled), Android SDK and emulator, Xcode (macOS only, for iOS builds)
- **Flutter DevTools** (performance, widget inspector, memory)
- **DB Browser for SQLite** (inspect the database file during development)
- `flutter doctor` to verify the environment
- Git + GitHub

### Design
- **Figma** for wireframes and the prototype; export the chosen logo as SVG
- Google Fonts: **Sora** (wordmark and headings), **Inter** (body)

### AI-assisted development
- Claude Code with `agents.md` at the repo root for project rules

## 5. Backup and Data Safety (replaces cloud sync)
Since there is no account or server:
1. **Manual export:** one tap creates a `.zip` (database + photos) the user can save to Drive, WhatsApp/Viber, or a USB.
2. **Scheduled reminder:** monthly prompt "Back up your records".
3. **Android Auto Backup** enabled as a safety net (note: size limits apply).
4. **Import/restore** from a backup file on a new phone.
5. Optional later: user-chosen cloud backup (Google Drive) without a Tenera account.

## 6. CI/CD and Release
| Purpose | Tool |
|---|---|
| Source control | GitHub |
| Build, test, lint on every PR | GitHub Actions (`subosito/flutter-action`) |
| Store uploads and signing | Fastlane (or Codemagic as a Flutter-focused alternative) |
| Distribution to testers | Google Play Internal Testing, TestFlight |
| Accounts needed | Google Play Console (one-time fee), Apple Developer Program (yearly fee) |

## 7. Environments
| Environment | Purpose |
|---|---|
| `dev` | Local emulator/device, debug build |
| `staging` | Test build on internal track, test subscriptions (license testers) |
| `prod` | Store release |

## 8. Project Structure (suggested)
```
/lib
  /core        (theme, utils, localization, constants)
  /data        (drift database, DAOs, repositories)
  /domain      (entities, ledger and charge rules)
  /features    (tenants, units, payments, reports, settings, paywall)
/test
/integration_test
/docs          (the planning .md files)
```

## 9. Open Decisions
- [ ] Encrypt the database with SQLCipher (adds some size and complexity) or rely on device encryption plus app lock
- [ ] `in_app_purchase` vs RevenueCat
- [ ] Which analytics tool, if any
- [ ] Minimum Android version to support
- [ ] iOS at launch or Android first
- [ ] Whether cloud backup or sync (with optional accounts) comes in a later version
