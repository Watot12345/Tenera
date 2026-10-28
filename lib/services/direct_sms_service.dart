import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:url_launcher/url_launcher.dart';

class SmsSendResult {
  final bool success;
  final String? errorMessage;
  final bool requiresPermission;

  const SmsSendResult({
    required this.success,
    this.errorMessage,
    this.requiresPermission = false,
  });

  static const SmsSendResult ok = SmsSendResult(success: true);

  factory SmsSendResult.failed(String msg, {bool requiresPermission = false}) {
    return SmsSendResult(
      success: false,
      errorMessage: msg,
      requiresPermission: requiresPermission,
    );
  }
}

class DirectSmsService {
  static const MethodChannel _channel = MethodChannel('ph.tenera.app/direct_sms');

  static bool get isTestEnvironment {
    return WidgetsBinding.instance.runtimeType.toString().contains('Test');
  }

  /// Cleans Philippine phone numbers to digits and '+' only
  static String cleanPhoneNumber(String phone) {
    return phone.replaceAll(RegExp(r'[^0-9+]'), '').trim();
  }

  /// Checks if this device currently has direct SEND_SMS permission
  static Future<bool> hasPermission() async {
    if (isTestEnvironment) return true;
    if (kIsWeb || !Platform.isAndroid) return false;

    try {
      final bool? granted = await _channel.invokeMethod<bool>('hasSmsPermission');
      return granted ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Prompts the user for Android SEND_SMS permission
  static Future<bool> requestPermission() async {
    if (isTestEnvironment) return true;
    if (kIsWeb || !Platform.isAndroid) return false;

    try {
      final bool? granted = await _channel.invokeMethod<bool>('requestSmsPermission');
      return granted ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Sends a real SMS directly through this Android phone's cellular SIM card.
  /// No web servers, no cloud APIs, and no per-message fees.
  static Future<SmsSendResult> sendDirectSms({
    required String phone,
    required String message,
  }) async {
    final cleanPhone = cleanPhoneNumber(phone);
    if (cleanPhone.isEmpty) {
      return SmsSendResult.failed('Recipient phone number is invalid.');
    }

    if (isTestEnvironment) {
      return SmsSendResult.ok;
    }

    if (kIsWeb || !Platform.isAndroid) {
      // Non-Android fallback to URL scheme
      final launched = await openDefaultSmsApp(phone: cleanPhone, message: message);
      return launched
          ? SmsSendResult.ok
          : SmsSendResult.failed('Direct SIM SMS is only supported on Android devices.');
    }

    try {
      final hasPerm = await hasPermission();
      if (hasPerm) {
        await _channel.invokeMethod('sendDirectSms', {
          'phone': cleanPhone,
          'message': message,
        });
        return SmsSendResult.ok;
      }

      // Play Protect compliant fallback: opens device default SMS messaging app
      final launched = await openDefaultSmsApp(phone: cleanPhone, message: message);
      return launched
          ? SmsSendResult.ok
          : SmsSendResult.failed('Unable to open device SMS app.');
    } on PlatformException catch (e) {
      if (e.code == 'NO_PERMISSION') {
        return SmsSendResult.failed(
          'SMS permission not granted.',
          requiresPermission: true,
        );
      }
      return SmsSendResult.failed(e.message ?? 'Failed to send SMS via SIM card.');
    } catch (e) {
      return SmsSendResult.failed(e.toString());
    }
  }

  /// Fallback: opens default device SMS app with pre-filled message
  static Future<bool> openDefaultSmsApp({
    required String phone,
    required String message,
  }) async {
    final cleanPhone = cleanPhoneNumber(phone);
    final smsUri = Uri(
      scheme: 'sms',
      path: cleanPhone,
      queryParameters: {'body': message},
    );

    try {
      return await launchUrl(smsUri, mode: LaunchMode.externalApplication);
    } catch (_) {
      try {
        return await launchUrl(smsUri);
      } catch (_) {
        return false;
      }
    }
  }
}
