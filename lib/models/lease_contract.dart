import 'package:intl/intl.dart';

/// Data model representing a Philippine Residential Lease Agreement.
class LeaseContract {
  final String landlordName;
  final String landlordAddress;
  final String landlordContact;
  final String tenantName;
  final String tenantAddress;
  final String tenantContact;
  final String tenantIdInfo;
  final String propertyName;
  final String unitCode;
  final String propertyAddress;
  final int monthlyRent;
  final int securityDeposit;
  final int advanceRent;
  final DateTime startDate;
  final DateTime endDate;
  final int dueDayOfMonth;
  final double lateFeePercent;
  final int maxOccupants;
  final String petPolicy;
  final String additionalRules;
  final String witness1Name;
  final String witness2Name;

  LeaseContract({
    required this.landlordName,
    this.landlordAddress = 'Metro Manila, Philippines',
    this.landlordContact = '',
    required this.tenantName,
    this.tenantAddress = 'Metro Manila, Philippines',
    this.tenantContact = '',
    this.tenantIdInfo = '',
    required this.propertyName,
    required this.unitCode,
    this.propertyAddress = 'Philippines',
    required this.monthlyRent,
    required this.securityDeposit,
    required this.advanceRent,
    required this.startDate,
    required this.endDate,
    this.dueDayOfMonth = 5,
    this.lateFeePercent = 5.0,
    this.maxOccupants = 2,
    this.petPolicy = 'Not Allowed',
    this.additionalRules = '',
    this.witness1Name = 'Witness 1',
    this.witness2Name = 'Witness 2',
  });

  /// Calculates duration in months
  int get durationInMonths {
    final diff = endDate.difference(startDate).inDays;
    return (diff / 30).round().clamp(1, 120);
  }

  /// Formatted date string (e.g. "October 1, 2026")
  static String formatDate(DateTime dt) {
    return DateFormat('MMMM d, yyyy').format(dt);
  }

  /// Converts a peso integer amount into capitalized English words.
  /// Example: 6500 -> "SIX THOUSAND FIVE HUNDRED PESOS"
  static String numberToPesoWords(int amount) {
    if (amount <= 0) return 'ZERO PESOS';

    final ones = [
      '', 'ONE', 'TWO', 'THREE', 'FOUR', 'FIVE', 'SIX', 'SEVEN', 'EIGHT', 'NINE',
      'TEN', 'ELEVEN', 'TWELVE', 'THIRTEEN', 'FOURTEEN', 'FIFTEEN', 'SIXTEEN',
      'SEVENTEEN', 'EIGHTEEN', 'NINETEEN'
    ];
    final tens = [
      '', '', 'TWENTY', 'THIRTY', 'FORTY', 'FIFTY', 'SIXTY', 'SEVENTY', 'EIGHTY', 'NINETY'
    ];

    String convertBelowThousand(int n) {
      if (n == 0) return '';
      if (n < 20) return ones[n];
      if (n < 100) {
        final t = tens[n ~/ 10];
        final r = ones[n % 10];
        return r.isEmpty ? t : '$t $r';
      }
      final h = '${ones[n ~/ 100]} HUNDRED';
      final rem = n % 100;
      if (rem == 0) return h;
      return '$h ${convertBelowThousand(rem)}';
    }

    var remaining = amount;
    final parts = <String>[];

    if (remaining >= 1000000) {
      final millions = remaining ~/ 1000000;
      parts.add('${convertBelowThousand(millions)} MILLION');
      remaining %= 1000000;
    }

    if (remaining >= 1000) {
      final thousands = remaining ~/ 1000;
      parts.add('${convertBelowThousand(thousands)} THOUSAND');
      remaining %= 1000;
    }

    if (remaining > 0) {
      parts.add(convertBelowThousand(remaining));
    }

    final words = parts.join(' ').replaceAll(RegExp(r'\s+'), ' ').trim();
    return '$words PESOS ONLY';
  }

  /// Ordinal representation of day (e.g. 5 -> "5th", 1 -> "1st")
  static String ordinal(int day) {
    if (day >= 11 && day <= 13) return '${day}th';
    switch (day % 10) {
      case 1:
        return '${day}st';
      case 2:
        return '${day}nd';
      case 3:
        return '${day}rd';
      default:
        return '${day}th';
    }
  }

  /// Generates the complete, legally formatted Philippine Lease Agreement contract text.
  String toFormattedContractText() {
    final currencyFmt = NumberFormat('#,##0.00');
    final formattedRent = currencyFmt.format(monthlyRent);
    final formattedDeposit = currencyFmt.format(securityDeposit);
    final formattedAdvance = currencyFmt.format(advanceRent);

    final rentWords = numberToPesoWords(monthlyRent);
    final depositWords = numberToPesoWords(securityDeposit);
    final advanceWords = numberToPesoWords(advanceRent);

    final startStr = formatDate(startDate);
    final endStr = formatDate(endDate);
    final durationMonths = durationInMonths;
    final ordinalDueDay = ordinal(dueDayOfMonth);

    final cleanLandlord = landlordName.trim().isEmpty ? 'LANDLORD NAME' : landlordName.trim();
    final cleanTenant = tenantName.trim().isEmpty ? 'TENANT NAME' : tenantName.trim();
    final cleanProperty = propertyName.trim().isEmpty ? 'PROPERTY NAME' : propertyName.trim();
    final cleanUnit = unitCode.trim().isEmpty ? 'UNIT CODE' : unitCode.trim();
    final cleanAddress = propertyAddress.trim().isEmpty ? 'PHILIPPINES' : propertyAddress.trim();

    final buffer = StringBuffer();

    buffer.writeln('================================================================================');
    buffer.writeln('                          CONTRACT OF LEASE                             ');
    buffer.writeln('                     (Residential Tenancy Agreement)                    ');
    buffer.writeln('================================================================================\n');

    buffer.writeln('KNOW ALL MEN BY THESE PRESENTS:\n');
    buffer.writeln(
        'This CONTRACT OF LEASE is entered into and executed this ${DateFormat('d').format(startDate)} day of ${DateFormat('MMMM, yyyy').format(startDate)}, by and between:\n');

    buffer.writeln('  LESSOR (Landlord):');
    buffer.writeln('    $cleanLandlord, of legal age, Filipino, residing at $landlordAddress,');
    if (landlordContact.trim().isNotEmpty) {
      buffer.writeln('    with Contact No.: $landlordContact,');
    }
    buffer.writeln('    hereinafter referred to as the "LESSOR";\n');

    buffer.writeln('  - and -\n');

    buffer.writeln('  LESSEE (Tenant):');
    buffer.writeln('    $cleanTenant, of legal age, Filipino, residing at $tenantAddress,');
    if (tenantContact.trim().isNotEmpty) {
      buffer.writeln('    with Contact No.: $tenantContact,');
    }
    if (tenantIdInfo.trim().isNotEmpty) {
      buffer.writeln('    bearing ID Credentials: $tenantIdInfo,');
    }
    buffer.writeln('    hereinafter referred to as the "LESSEE";\n');

    buffer.writeln('WITNESSETH: That\n');
    buffer.writeln('  WHEREAS, the LESSOR is the lawful owner and administrator of the residential property');
    buffer.writeln('  known as "$cleanProperty", situated at $cleanAddress;\n');
    buffer.writeln('  WHEREAS, the LESSOR desires to lease unto the LESSEE, and the LESSEE desires to take in');
    buffer.writeln('  lease from the LESSOR, the designated premises described as Unit / Room $cleanUnit;\n');

    buffer.writeln('NOW, THEREFORE, for and in consideration of the monthly rentals herein reserved and');
    buffer.writeln('the faithful covenants mutually expressed, both parties hereby covenant and agree as follows:\n');

    buffer.writeln('--------------------------------------------------------------------------------');
    buffer.writeln('SECTION 1: LEASED PREMISES & PURPOSE');
    buffer.writeln('--------------------------------------------------------------------------------');
    buffer.writeln('The leased premises consists of Unit / Room $cleanUnit located within $cleanProperty,');
    buffer.writeln('situated at $cleanAddress.');
    buffer.writeln('The premises shall be occupied solely for private residential dwelling purposes by not');
    buffer.writeln('more than $maxOccupants occupant(s). Any commercial usage, unlawful trade, or unauthorized');
    buffer.writeln('manufacturing within the premises is strictly prohibited.\n');

    buffer.writeln('--------------------------------------------------------------------------------');
    buffer.writeln('SECTION 2: TERM OF LEASE');
    buffer.writeln('--------------------------------------------------------------------------------');
    buffer.writeln('This lease shall be for an initial period of $durationMonths month(s), commencing on');
    buffer.writeln('$startStr and expiring on $endStr.');
    buffer.writeln('Any extension or renewal shall be subject to mutual written agreement between the parties');
    buffer.writeln('at least thirty (30) days prior to the expiration of this contract.\n');

    buffer.writeln('--------------------------------------------------------------------------------');
    buffer.writeln('SECTION 3: MONTHLY RENTAL & PAYMENT TERMS');
    buffer.writeln('--------------------------------------------------------------------------------');
    buffer.writeln('The agreed monthly rental is fixed at ₱$formattedRent ($rentWords),');
    buffer.writeln('payable on or before the $ordinalDueDay day of each calendar month without need of notice');
    buffer.writeln('or demand.');
    buffer.writeln('Any installment not remitted after a five (5) day grace period shall be subject to a late');
    buffer.writeln('charge penalty of ${lateFeePercent.toStringAsFixed(1)}% per month until fully satisfied.\n');

    buffer.writeln('--------------------------------------------------------------------------------');
    buffer.writeln('SECTION 4: ADVANCE RENTAL & SECURITY DEPOSIT');
    buffer.writeln('--------------------------------------------------------------------------------');
    buffer.writeln('Upon execution of this Contract, the LESSEE shall remit to the LESSOR:');
    buffer.writeln('  (a) ADVANCE RENTAL: ₱$formattedAdvance ($advanceWords),');
    buffer.writeln('      applied towards the first month(s) of tenancy.');
    buffer.writeln('  (b) SECURITY DEPOSIT: ₱$formattedDeposit ($depositWords).');
    buffer.writeln('      The security deposit shall be held by the LESSOR throughout the tenancy as guarantee');
    buffer.writeln('      for the full and faithful compliance by the LESSEE. Under no circumstance shall the deposit');
    buffer.writeln('      be credited as monthly rental during the active lease.');
    buffer.writeln('      Upon expiration and after peaceful vacation and turnover of the unit, any unpaid utility');
    buffer.writeln('      sub-meter balances or tenant damages shall be deducted, and any net residue shall be');
    buffer.writeln('      refunded to the LESSEE within thirty (30) calendar days.\n');

    buffer.writeln('--------------------------------------------------------------------------------');
    buffer.writeln('SECTION 5: UTILITIES & SUB-METERING');
    buffer.writeln('--------------------------------------------------------------------------------');
    buffer.writeln('Electric power and water consumed within Unit $cleanUnit shall be calculated through');
    buffer.writeln('designated sub-meters. The LESSEE warrants to pay all sub-meter electric and water bills');
    buffer.writeln('directly to the LESSOR within five (5) days upon presentation of statement.\n');

    buffer.writeln('--------------------------------------------------------------------------------');
    buffer.writeln('SECTION 6: PROHIBITION AGAINST SUBLEASING');
    buffer.writeln('--------------------------------------------------------------------------------');
    buffer.writeln('The LESSEE shall not directly or indirectly sublease, assign, transfer, or encumber');
    buffer.writeln('the leased premises or any part thereof to any other person without the prior express');
    buffer.writeln('written permission of the LESSOR. Any unauthorized transfer shall be null and void and');
    buffer.writeln('cause for instant termination of this lease.\n');

    buffer.writeln('--------------------------------------------------------------------------------');
    buffer.writeln('SECTION 7: PET POLICY & HOUSE RULES');
    buffer.writeln('--------------------------------------------------------------------------------');
    buffer.writeln('  (a) Pet Policy: $petPolicy.');
    buffer.writeln('  (b) Quiet Hours: Observance of quiet hours between 10:00 PM and 7:00 AM daily.');
    buffer.writeln('  (c) Waste Management: Observance of local municipal trash segregation and sanitation.');
    if (additionalRules.trim().isNotEmpty) {
      buffer.writeln('  (d) Special Stipulations:');
      buffer.writeln('      ${additionalRules.trim()}');
    }
    buffer.writeln('');

    buffer.writeln('--------------------------------------------------------------------------------');
    buffer.writeln('SECTION 8: REPAIRS & SANITARY MAINTENANCE');
    buffer.writeln('--------------------------------------------------------------------------------');
    buffer.writeln('The LESSEE acknowledges receipt of the leased unit in good, clean, and tenantable condition.');
    buffer.writeln('Ordinary minor repairs arising from normal occupancy shall be answered by the LESSEE.');
    buffer.writeln('Major structural repairs not occasioned by negligence of the LESSEE shall be the responsibility');
    buffer.writeln('of the LESSOR.\n');

    buffer.writeln('--------------------------------------------------------------------------------');
    buffer.writeln('SECTION 9: DEFAULT & TERMINATION');
    buffer.writeln('--------------------------------------------------------------------------------');
    buffer.writeln('Failure to pay rent for two (2) consecutive months, or substantial breach of any covenant');
    buffer.writeln('herein, shall entitle the LESSOR to terminate this agreement immediately, forfeit the deposit,');
    buffer.writeln('and re-enter the premises in accordance with the Philippine Rent Control Act and the Civil Code.\n');

    buffer.writeln('IN WITNESS WHEREOF, the LESSOR and the LESSEE have signed this instrument on the date');
    buffer.writeln('and place first above written.\n\n');

    buffer.writeln('_______________________________________       _______________________________________');
    buffer.writeln('LESSOR: $cleanLandlord                        LESSEE: $cleanTenant');
    if (landlordContact.trim().isNotEmpty || tenantContact.trim().isNotEmpty) {
      final lContact = landlordContact.trim().padRight(35);
      buffer.writeln('Tel: $lContact  Tel: ${tenantContact.trim()}');
    }
    buffer.writeln('\n');

    buffer.writeln('SIGNED IN THE PRESENCE OF:\n\n');
    buffer.writeln('_______________________________________       _______________________________________');
    buffer.writeln('Witness: ${witness1Name.trim()}                 Witness: ${witness2Name.trim()}\n');

    buffer.writeln('================================================================================');
    buffer.writeln('                   Generated by Tenera Business Edition                         ');
    buffer.writeln('================================================================================');

    return buffer.toString();
  }
}
