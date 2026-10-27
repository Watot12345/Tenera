import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';
import 'plan_guard_service.dart';

class StaffModeService {
  static const String prefKeyIsStaffMode = 'is_staff_mode_active';
  static const String prefKeyStaffPin = 'staff_mode_master_pin';

  /// Returns true if Caretaker / Staff Mode is active (financials masked)
  static Future<bool> isStaffMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(prefKeyIsStaffMode) ?? false;
  }

  /// Returns true if the Landlord has established a Master PIN
  static Future<bool> hasPin() async {
    final prefs = await SharedPreferences.getInstance();
    final pin = prefs.getString(prefKeyStaffPin);
    return pin != null && pin.trim().length >= 4;
  }

  /// Sets or updates the 4-digit Master Landlord PIN
  static Future<void> setPin(String pin) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(prefKeyStaffPin, pin.trim());
  }

  /// Verifies the entered PIN against the stored Master PIN
  static Future<bool> verifyPin(String enteredPin) async {
    final prefs = await SharedPreferences.getInstance();
    final storedPin = prefs.getString(prefKeyStaffPin);
    return storedPin != null && storedPin == enteredPin.trim();
  }

  /// Activates Caretaker / Staff Mode
  static Future<void> enableStaffMode() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(prefKeyIsStaffMode, true);
  }

  /// Deactivates Caretaker / Staff Mode (restores Landlord full view)
  static Future<void> disableStaffMode() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(prefKeyIsStaffMode, false);
  }

  /// Toggles Caretaker / Staff Mode with Business plan verification and PIN security
  static Future<void> toggleStaffMode(
    BuildContext context, {
    required FutureOr<void> Function() onModeChanged,
  }) async {
    final canAccess = await PlanGuardService.requireBusiness(
      context: context,
      featureName: 'Caretaker / Staff Mode',
      featureBenefit:
          'Safely hand your phone to caretakers or staff. Mask net revenues and profits with 4-digit PIN protection while allowing payment recording.',
    );
    if (!canAccess || !context.mounted) return;

    final isCurrentlyStaff = await isStaffMode();

    if (isCurrentlyStaff) {
      // Exiting Staff Mode requires entering the Master PIN
      if (!context.mounted) return;
      showEnterPinDialog(
        context,
        onSuccess: () async {
          await disableStaffMode();
          await onModeChanged();
        },
      );
    } else {
      // Entering Staff Mode
      final pinExists = await hasPin();
      if (!context.mounted) return;

      if (!pinExists) {
        showSetPinDialog(
          context,
          onPinSet: () async {
            await enableStaffMode();
            await onModeChanged();
          },
        );
      } else {
        showConfirmEnableDialog(
          context,
          onConfirmed: () async {
            await enableStaffMode();
            await onModeChanged();
          },
        );
      }
    }
  }

  /// Dialog allowing landlord to configure a 4-digit Master PIN
  static void showSetPinDialog(
    BuildContext context, {
    required FutureOr<void> Function() onPinSet,
  }) {
    final pinController = TextEditingController();
    final confirmController = TextEditingController();
    String? errorMessage;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogCtx, setState) {
            return AlertDialog(
              backgroundColor: AppTheme.surface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Row(
                children: [
                  Icon(Icons.pin_rounded, color: AppTheme.primaryDeep),
                  SizedBox(width: 10),
                  Text(
                    'Create Master PIN',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Set a 4-digit PIN required to exit Caretaker Mode and restore full financial access.',
                    style: TextStyle(fontSize: 13, color: AppTheme.inkMuted, height: 1.4),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    key: const Key('input_create_pin'),
                    controller: pinController,
                    keyboardType: TextInputType.number,
                    obscureText: true,
                    maxLength: 4,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(
                      labelText: 'New 4-Digit PIN',
                      filled: true,
                      fillColor: AppTheme.background,
                      counterText: '',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppTheme.border),
                      ),
                      prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    key: const Key('input_confirm_pin'),
                    controller: confirmController,
                    keyboardType: TextInputType.number,
                    obscureText: true,
                    maxLength: 4,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(
                      labelText: 'Confirm PIN',
                      filled: true,
                      fillColor: AppTheme.background,
                      counterText: '',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppTheme.border),
                      ),
                      prefixIcon: const Icon(Icons.lock_rounded, size: 20),
                    ),
                  ),
                  if (errorMessage != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      errorMessage!,
                      style: const TextStyle(color: AppTheme.statusOverdue, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel', style: TextStyle(color: AppTheme.inkMuted)),
                ),
                ElevatedButton(
                  key: const Key('btn_save_pin_and_enable'),
                  onPressed: () async {
                    final pin = pinController.text.trim();
                    final confirm = confirmController.text.trim();

                    if (pin.length < 4) {
                      setState(() => errorMessage = 'PIN must be exactly 4 digits');
                      return;
                    }
                    if (pin != confirm) {
                      setState(() => errorMessage = 'PINs do not match');
                      return;
                    }

                    await setPin(pin);
                    if (!ctx.mounted) return;
                    Navigator.pop(ctx);
                    await onPinSet();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryDeep,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Save & Enable'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// Dialog prompting for PIN verification to exit Caretaker Mode
  static void showEnterPinDialog(
    BuildContext context, {
    required FutureOr<void> Function() onSuccess,
  }) {
    final pinController = TextEditingController();
    String? errorMessage;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogCtx, setState) {
            return AlertDialog(
              backgroundColor: AppTheme.surface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Row(
                children: [
                  Icon(Icons.lock_person_rounded, color: AppTheme.primaryDeep),
                  SizedBox(width: 10),
                  Text(
                    'Exit Caretaker Mode',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Enter your 4-digit Master Landlord PIN to restore financial visibility.',
                    style: TextStyle(fontSize: 13, color: AppTheme.inkMuted, height: 1.4),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    key: const Key('input_enter_staff_pin'),
                    controller: pinController,
                    keyboardType: TextInputType.number,
                    obscureText: true,
                    autofocus: true,
                    maxLength: 4,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(
                      labelText: 'Master PIN',
                      filled: true,
                      fillColor: AppTheme.background,
                      counterText: '',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppTheme.border),
                      ),
                      prefixIcon: const Icon(Icons.password_rounded, size: 20),
                    ),
                  ),
                  if (errorMessage != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      errorMessage!,
                      style: const TextStyle(color: AppTheme.statusOverdue, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel', style: TextStyle(color: AppTheme.inkMuted)),
                ),
                ElevatedButton(
                  key: const Key('btn_verify_staff_pin'),
                  onPressed: () async {
                    final entered = pinController.text.trim();
                    final isValid = await verifyPin(entered);

                    if (!isValid) {
                      setState(() => errorMessage = 'Incorrect PIN. Try again.');
                      return;
                    }

                    if (!ctx.mounted) return;
                    Navigator.pop(ctx);
                    await onSuccess();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryDeep,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Unlock'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// Confirmation dialog before activating Caretaker Mode
  static void showConfirmEnableDialog(
    BuildContext context, {
    required FutureOr<void> Function() onConfirmed,
  }) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppTheme.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.shield_outlined, color: AppTheme.primaryDeep),
              SizedBox(width: 10),
              Text(
                'Enable Caretaker Mode?',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
              ),
            ],
          ),
          content: const Text(
            'In Caretaker Mode, all gross revenues, expected rental profits, and BIR tax reports are masked. Staff can still search units and record tenant payments.',
            style: TextStyle(fontSize: 13, color: AppTheme.inkMuted, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: AppTheme.inkMuted)),
            ),
            ElevatedButton.icon(
              key: const Key('btn_confirm_enable_staff_mode'),
              onPressed: () async {
                Navigator.pop(ctx);
                await onConfirmed();
              },
              icon: const Icon(Icons.check_rounded, size: 18),
              label: const Text('Enable Mode'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryDeep,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        );
      },
    );
  }
}
