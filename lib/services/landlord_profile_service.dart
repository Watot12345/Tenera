import 'package:shared_preferences/shared_preferences.dart';

class LandlordProfile {
  final String businessName;
  final String landlordName;
  final String phone;
  final String receiptFooter;

  const LandlordProfile({
    this.businessName = '',
    this.landlordName = '',
    this.phone = '',
    this.receiptFooter = '',
  });

  String get displayName => businessName.isNotEmpty ? businessName : (landlordName.isNotEmpty ? landlordName : 'Tenera Property Manager');
  String get displayReceiptHeader => businessName.isNotEmpty ? businessName.toUpperCase() : 'TENERA RENT RECEIPT';
}

class LandlordProfileService {
  static const String _keyBusinessName = 'landlord_profile_business_name';
  static const String _keyLandlordName = 'landlord_profile_landlord_name';
  static const String _keyPhone = 'landlord_profile_phone';
  static const String _keyReceiptFooter = 'landlord_profile_receipt_footer';

  static LandlordProfile _current = const LandlordProfile();
  static LandlordProfile get currentProfile => _current;

  static Future<LandlordProfile> getProfile() async {
    final prefs = await SharedPreferences.getInstance();
    _current = LandlordProfile(
      businessName: prefs.getString(_keyBusinessName) ?? '',
      landlordName: prefs.getString(_keyLandlordName) ?? '',
      phone: prefs.getString(_keyPhone) ?? '',
      receiptFooter: prefs.getString(_keyReceiptFooter) ?? '',
    );
    return _current;
  }

  static Future<void> saveProfile({
    required String businessName,
    required String landlordName,
    required String phone,
    required String receiptFooter,
  }) async {
    _current = LandlordProfile(
      businessName: businessName.trim(),
      landlordName: landlordName.trim(),
      phone: phone.trim(),
      receiptFooter: receiptFooter.trim(),
    );
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyBusinessName, _current.businessName);
    await prefs.setString(_keyLandlordName, _current.landlordName);
    await prefs.setString(_keyPhone, _current.phone);
    await prefs.setString(_keyReceiptFooter, _current.receiptFooter);
  }
}
