# Theme (Tenera design tokens)

Single source of truth for colors, type, spacing and shape. Matches the logo concepts (teal + amber, Sora + Inter). Contrast ratios below are approximate: verify with a contrast checker before finalizing.

## 1. Design Feel
Friendly, trustworthy, calm. Large readable text, generous space, rounded cards, one primary color. Built for non-technical landlords, so clarity beats decoration.

## 2. Color Palette

### Brand
| Token | Hex | Use | Contrast |
|---|---|---|---|
| `primary` | `#0E6B63` | Buttons, active tab, links, app bar accents | ~6.4:1 with white text |
| `primaryDeep` | `#0A4A45` | Pressed state, dark panels, headers | ~10:1 with white |
| `accent` | `#F2A33A` | Highlights, logo accent, badges, FAB icon glow | **Do not use as text on white (~2:1).** Use as a fill with dark ink text (~6.8:1) |
| `ink` | `#12302D` | Main text | ~13:1 on background |
| `inkMuted` | `#4B6662` | Secondary text, captions | ~5.7:1 on background |

### Surfaces
| Token | Hex | Use |
|---|---|---|
| `background` | `#F4F7F6` | App background |
| `surface` | `#FFFFFF` | Cards, sheets, inputs |
| `border` | `#DDE6E4` | Dividers, card outlines |

### Status (always pair color with an icon and a label)
| State | Text/Icon | Chip background | Label example |
|---|---|---|---|
| Paid | `#1E7A46` | `#E3F4EA` | Paid ✓ |
| Due soon | `#7A4F00` | `#FFF1D6` | Due in 3 days |
| Overdue | `#B3261E` | `#FBE5E3` | Overdue 5 days |
| Vacant | `#5F6B69` | `#ECEFEE` | Vacant |
| Sync pending | `#1F5FA8` | `#E2EDF9` | Waiting to sync |
| Synced | `#1E7A46` | `#E3F4EA` | Synced ✓ |

### Dark Mode (phase 2, optional)
| Token | Hex |
|---|---|
| `background` | `#0B1F1D` |
| `surface` | `#12302D` |
| `primary` | `#5FC2B6` |
| `ink` | `#EAF2F0` |
| `inkMuted` | `#A9BFBB` |

## 3. Typography
| Role | Font | Size / weight |
|---|---|---|
| Display / money totals | Sora | 28–32, 700 |
| Screen title | Sora | 22, 600 |
| Section title | Sora | 18, 600 |
| Body | Inter | 16, 400 (never below 14) |
| Label / button | Inter | 16, 500 |
| Caption | Inter | 13–14, 400 |

- Use **tabular figures** for amounts so numbers line up in ledgers.
- Support system font scaling up to 200% without clipping.
- **Bundle fonts in the app assets.** Do not use runtime font downloading (e.g. `google_fonts` fetching online), because Tenera must work offline.

## 4. Spacing, Shape, Elevation
| Token | Value |
|---|---|
| Spacing scale | 4, 8, 12, 16, 24, 32 |
| Screen padding | 16 |
| Card radius | 16 |
| Button / input radius | 12 |
| Chip radius | 999 (pill) |
| App icon radius | ~23% of icon width |
| Elevation | Mostly flat: 1px `border`, soft shadow only on sheets and the FAB |
| Min touch target | 48 × 48 dp |

## 5. Components (styling rules)
- **Primary button:** `primary` fill, white text, 52 dp tall, full width on forms.
- **Secondary button:** white fill, `primary` outline and text.
- **Destructive:** red text button, always with a confirmation dialog.
- **Record Payment FAB:** `primary` fill, white "+" icon and label ("Record payment"), not an icon alone.
- **Summary cards (Home):** white surface, big Sora number, small muted label.
- **Tenant row:** avatar initials, name, unit, status chip on the right.
- **Inputs:** white fill, 1px `border`, `primary` 2px focus ring, label always visible (no placeholder-only labels).
- **Empty states:** simple line illustration, one sentence, one button.

## 6. Icons
Rounded outline icons (Material Symbols Rounded or similar), 24 dp, always with a text label for key actions.

## 7. Logo Usage
- Mark in `primary` on white or `background`; white mark on `primary` or `primaryDeep`.
- Keep clear space equal to the mark's height ÷ 4 around the logo.
- Minimum size: 24 px for the mark alone.
- Final concept: **pending** (see the logo canvas, directions A / B / C).

## 8. Flutter Mapping (starter)
```dart
final lightScheme = ColorScheme.fromSeed(seedColor: const Color(0xFF0E6B63)).copyWith(
  primary: const Color(0xFF0E6B63),
  onPrimary: Colors.white,
  secondary: const Color(0xFFF2A33A),
  onSecondary: const Color(0xFF12302D),
  surface: Colors.white,
  onSurface: const Color(0xFF12302D),
  error: const Color(0xFFB3261E),
  outline: const Color(0xFFDDE6E4),
);

final teneraTheme = ThemeData(
  useMaterial3: true,
  colorScheme: lightScheme,
  scaffoldBackgroundColor: const Color(0xFFF4F7F6),
  fontFamily: 'Inter',
  cardTheme: CardThemeData(
    elevation: 0,
    color: Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: const BorderSide(color: Color(0xFFDDE6E4)),
    ),
  ),
);
```
Keep status colors in a custom `ThemeExtension` (`StatusColors`) so widgets never hard-code hex values.

## 9. Accessibility Checklist
- [ ] Body text ≥ 4.5:1, large text ≥ 3:1
- [ ] Status never conveyed by color alone
- [ ] 48 dp touch targets
- [ ] Layout tested at 200% font scale
- [ ] Screen-reader labels on icon-only buttons
