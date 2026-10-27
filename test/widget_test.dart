import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:tenera/main.dart';
import 'package:tenera/models/lease_contract.dart';
import 'package:tenera/models/payment.dart';
import 'package:tenera/models/property.dart';
import 'package:tenera/models/portfolio_analytics.dart';
import 'package:tenera/models/tenant.dart';
import 'package:tenera/screens/home_screen.dart';
import 'package:tenera/screens/lease_contract_screen.dart';
import 'package:tenera/screens/portfolio_analytics_screen.dart';
import 'package:tenera/screens/privacy_policy_screen.dart';
import 'package:tenera/screens/reports_export_screen.dart';
import 'package:tenera/screens/subscription_plans_screen.dart';
import 'package:tenera/services/database_helper.dart';
import 'package:tenera/services/plan_guard_service.dart';
import 'package:tenera/theme/app_theme.dart';

void main() {
  setUp(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    await DatabaseHelper.reset();
    final db = await databaseFactory.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (db, version) async {
          await DatabaseHelper.instance.createDbForTest(db);
        },
      ),
    );
    DatabaseHelper.setMockDatabase(db);
    SharedPreferences.setMockInitialValues({});
  });

  Future<void> pumpAppAndLoadDatabase(WidgetTester tester) async {
    await tester.pumpWidget(const TeneraApp());
    await tester.pump(const Duration(milliseconds: 1600));
    await tester.pump(const Duration(milliseconds: 1000));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    await tester.runAsync(() async {
      await Future.delayed(const Duration(milliseconds: 300));
    });
    await tester.pumpAndSettle();
  }

  testWidgets('First time user: splash screen builds logo and navigates to Privacy Policy',
      (WidgetTester tester) async {
    // Initial state: not accepted
    SharedPreferences.setMockInitialValues({
      PrivacyPolicyScreen.prefKeyAccepted: false,
    });

    await tester.pumpWidget(const TeneraApp());

    // Verify initial splash screen renders
    expect(find.text('Tenera'), findsOneWidget);
    expect(find.text('Tenant management, online or offline.'), findsOneWidget);

    // Fast forward through animations and async checks
    await tester.pump(const Duration(milliseconds: 1600));
    await tester.pump(const Duration(milliseconds: 1000));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();

    // Must navigate to Privacy Policy
    expect(find.text('Privacy & Terms'), findsOneWidget);
    expect(find.text('Tenera Privacy Policy'), findsOneWidget);
    expect(find.text('Accept & Continue'), findsOneWidget);

    // Tap checkbox and proceed
    await tester.tap(find.text('I have read and agree to the Tenera Terms of Use & Privacy Policy.'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Accept & Continue'));
    await tester.pumpAndSettle();

    // Now on WelcomeScreen
    final proceedBtn = find.text('Get Started & Open Dashboard');
    expect(proceedBtn, findsOneWidget);
    await tester.ensureVisible(proceedBtn);
    await tester.pumpAndSettle();
    await tester.tap(proceedBtn);
    await tester.pumpAndSettle();
    await tester.runAsync(() async {
      await Future.delayed(const Duration(milliseconds: 300));
    });
    await tester.pumpAndSettle();

    // Verified: Now on HomeScreen
    expect(find.text('Vacant units'), findsOneWidget);
    expect(find.text('Due soon'), findsOneWidget);
    expect(find.byKey(const Key('quick_action_record_payment')), findsOneWidget);
  });

  testWidgets('Returning user: splash screen navigates directly to Home',
      (WidgetTester tester) async {
    // Set privacy already accepted
    SharedPreferences.setMockInitialValues({
      PrivacyPolicyScreen.prefKeyAccepted: true,
    });

    await pumpAppAndLoadDatabase(tester);

    // Directly on HomeScreen
    expect(find.text('Vacant units'), findsOneWidget);
    expect(find.text('Due soon'), findsOneWidget);
    expect(find.byKey(const Key('quick_action_record_payment')), findsOneWidget);
    expect(find.text('Privacy & Terms'), findsNothing);
  });

  testWidgets('Quick action: Record payment logs payment and updates dashboard',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({
      PrivacyPolicyScreen.prefKeyAccepted: true,
    });

    await pumpAppAndLoadDatabase(tester);

    // Initial collected amount
    expect(find.text('₱42,000'), findsOneWidget);

    // Tap icon logo quick action for Record payment
    await tester.tap(find.byKey(const Key('quick_action_record_payment')));
    await tester.pumpAndSettle();

    // Verify modal is open
    expect(find.text('Record Rent Payment'), findsOneWidget);
    expect(find.text('Confirm & Log Payment'), findsOneWidget);

    // Confirm payment for first overdue tenant (₱3,500)
    final confirmBtn = find.text('Confirm & Log Payment');
    await tester.ensureVisible(confirmBtn);
    await tester.pumpAndSettle();
    await tester.tap(confirmBtn);
    await tester.pumpAndSettle();
    await tester.runAsync(() async {
      await Future.delayed(const Duration(milliseconds: 300));
    });
    await tester.pumpAndSettle();

    // Collected should now be ₱45,500
    expect(find.text('₱45,500'), findsOneWidget);
  });

  testWidgets('Bottom navigation switches between all 5 tabs properly',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({
      PrivacyPolicyScreen.prefKeyAccepted: true,
    });

    await pumpAppAndLoadDatabase(tester);

    // 1. Properties Tab
    await tester.tap(find.byKey(const Key('nav_properties')));
    await tester.pumpAndSettle();
    expect(find.text('Properties'), findsWidgets);
    expect(find.text('Mabini Apts'), findsOneWidget);
    expect(find.text('Total Portfolio'), findsOneWidget);

    // 2. Tenants Tab
    await tester.tap(find.byKey(const Key('nav_tenants')));
    await tester.pumpAndSettle();
    expect(find.text('Maria S.'), findsOneWidget);
    expect(find.text('Ramon D.'), findsOneWidget);

    // 3. Payments Tab
    await tester.tap(find.byKey(const Key('nav_payments')));
    await tester.pumpAndSettle();
    expect(find.text('Total Collections (October)'), findsOneWidget);
    expect(find.text('+ Record New Payment'), findsOneWidget);

    // 4. More Tab
    await tester.tap(find.byKey(const Key('nav_more')));
    await tester.pumpAndSettle();
    expect(find.text('Tenera Property Manager'), findsOneWidget);
    expect(find.text('Backup Data to Device'), findsOneWidget);

    // Return to Home Tab
    await tester.tap(find.byKey(const Key('nav_home')));
    await tester.pumpAndSettle();
    expect(find.text('Vacant units'), findsOneWidget);
  });

  testWidgets('Properties tab: tapping View Rooms opens PropertyRoomsScreen grid and returns',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({
      PrivacyPolicyScreen.prefKeyAccepted: true,
      SubscriptionPlansScreen.prefKeyCurrentPlan: 'pro',
    });

    await pumpAppAndLoadDatabase(tester);

    // Navigate to Properties
    await tester.tap(find.byKey(const Key('nav_properties')));
    await tester.pumpAndSettle();

    // Verify portfolio card and property cards exist
    expect(find.text('Total Portfolio'), findsOneWidget);
    expect(find.text('Mabini Apts'), findsOneWidget);
    expect(find.text('View Rooms'), findsWidgets);

    // Tap the first "View Rooms" button
    await tester.tap(find.text('View Rooms').first);
    await tester.pumpAndSettle();

    // Verify we are now on PropertyRoomsScreen with the rooms grid
    expect(find.text('Search property or unit'), findsOneWidget);
    expect(find.text('Occupied'), findsOneWidget);
    expect(find.text('Overdue'), findsOneWidget);
    expect(find.text('Vacant'), findsOneWidget);
    expect(find.text('R1'), findsOneWidget);
    expect(find.text('Add Room'), findsOneWidget);

    // Tap room R1 to view tenant and status details
    await tester.tap(find.text('R1'));
    await tester.pumpAndSettle();

    // Verify room details modal displays tenant and status
    expect(find.text('Unit R1 · Mabini Apts'), findsOneWidget);
    expect(find.text('Elena Santos'), findsOneWidget);
    expect(find.text('STATUS: OCCUPIED (Paid)'), findsOneWidget);
    expect(find.text('Press & hold to remove tenant'), findsOneWidget);

    // Test: Press and hold "Tenant Assigned" row to trigger removal confirmation
    await tester.longPress(find.byKey(const Key('tenant_assign_row')));
    await tester.pumpAndSettle();

    // Verify confirmation dialog appeared
    expect(find.text('Remove Tenant'), findsWidgets);
    expect(find.text('Are you sure you want to remove Elena Santos from Unit R1 in Mabini Apts?'), findsOneWidget);

    // Tap "Remove Tenant" button in dialog
    await tester.tap(find.widgetWithText(ElevatedButton, 'Remove Tenant'));
    await tester.pumpAndSettle();
    await tester.runAsync(() async {
      await Future.delayed(const Duration(milliseconds: 300));
    });
    await tester.pumpAndSettle();

    // Unit R1 should now be Vacant: open details again to verify
    await tester.tap(find.text('R1'));
    await tester.pumpAndSettle();
    expect(find.text('STATUS: VACANT (Available for Rent)'), findsOneWidget);
    expect(find.text('None (Vacant)'), findsOneWidget);

    // Close room details modal
    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pumpAndSettle();

    // Test: Direct long press on another occupied room block (R2) in grid
    await tester.longPress(find.text('R2'));
    await tester.pumpAndSettle();
    expect(find.text('Are you sure you want to remove Juan Carlos from Unit R2 in Mabini Apts?'), findsOneWidget);

    // Tap "Cancel" to verify cancel works
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    // Tap "Add Room" FAB to verify Add Room modal
    await tester.tap(find.text('Add Room'));
    await tester.pumpAndSettle();
    expect(find.text('Add New Room / Unit'), findsOneWidget);
    expect(find.text('Add Room to Property'), findsOneWidget);

    // Close Add Room modal
    await tester.tapAt(const Offset(20, 20));
    await tester.pumpAndSettle();

    // Tap back button
    await tester.tap(find.byTooltip('Back to Properties'));
    await tester.pumpAndSettle();
    await tester.runAsync(() async {
      await Future.delayed(const Duration(milliseconds: 300));
    });
    await tester.pumpAndSettle();

    // Verify we are back on the Properties tab with Total Portfolio and NO "Add property" floating action button below
    expect(find.text('Total Portfolio'), findsOneWidget);
    expect(find.byKey(const Key('fab_add_property')), findsNothing);
  });

  testWidgets('More tab: opens SubscriptionPlansScreen, toggles billing, and simulates activation',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({
      PrivacyPolicyScreen.prefKeyAccepted: true,
    });

    await pumpAppAndLoadDatabase(tester);

    // Navigate to More Tab
    await tester.tap(find.byKey(const Key('nav_more')));
    await tester.pumpAndSettle();

    // Verify subscription card is present
    expect(find.text('Tenera Pro & Plans'), findsOneWidget);
    expect(find.text('View Plans'), findsOneWidget);

    // Tap "View Plans"
    await tester.tap(find.text('View Plans'));
    await tester.pumpAndSettle();

    // Verify Plans screen is displayed with the 3 plans
    expect(find.text('Tenera Plans & Pricing'), findsOneWidget);
    expect(find.text('Starter'), findsOneWidget);
    expect(find.text('Tenera Pro'), findsOneWidget);
    expect(find.text('Business'), findsOneWidget);
    expect(find.text('MOST POPULAR · LANDLORD CHOICE'), findsOneWidget);

    // Toggle to Monthly billing
    await tester.tap(find.text('Monthly'));
    await tester.pumpAndSettle();
    expect(find.text('₱199'), findsOneWidget);

    // Scroll to and tap "Choose Tenera Pro"
    await tester.ensureVisible(find.text('Choose Tenera Pro'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Choose Tenera Pro'));
    await tester.pumpAndSettle();

    // Verify checkout bottom sheet
    expect(find.text('Activate Tenera Pro'), findsOneWidget);
    expect(find.text('GCash / QR Ph (Instant)'), findsOneWidget);
    expect(find.text('Google Play Billing'), findsOneWidget);

    // Confirm activation
    await tester.tap(find.text('Confirm & Activate with GCash'));
    await tester.pumpAndSettle();

    // Verify activation snackbar
    expect(find.text('🎉 Congratulations! Tenera Pro is now ACTIVE on this device.'), findsOneWidget);

    // Now Pro is active
    expect(find.text('ACTIVE PLAN'), findsOneWidget);
  });

  testWidgets('Tenants tab: search bar filters tenants by query and shows empty state',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({
      PrivacyPolicyScreen.prefKeyAccepted: true,
    });

    await pumpAppAndLoadDatabase(tester);

    // Navigate to Tenants tab
    await tester.tap(find.byKey(const Key('nav_tenants')));
    await tester.pumpAndSettle();

    // Search bar is present
    final searchField = find.byKey(const Key('tenants_search_field'));
    expect(searchField, findsOneWidget);
    expect(find.text('Maria S.'), findsOneWidget);
    expect(find.text('Ramon D.'), findsOneWidget);

    // Enter query 'Maria'
    await tester.enterText(searchField, 'Maria');
    await tester.pumpAndSettle();

    // Maria S. should be shown, Ramon D. should be filtered out
    expect(find.text('Maria S.'), findsOneWidget);
    expect(find.text('Ramon D.'), findsNothing);

    // Clear search using the clear suffix button
    await tester.tap(find.byIcon(Icons.clear_rounded));
    await tester.pumpAndSettle();

    // Both tenants are back
    expect(find.text('Maria S.'), findsOneWidget);
    expect(find.text('Ramon D.'), findsOneWidget);

    // Enter non-matching query
    await tester.enterText(searchField, 'NonExistentTenant999');
    await tester.pumpAndSettle();

    // Verify empty state is displayed
    expect(find.text('No tenants found for "nonexistenttenant999"'), findsOneWidget);
    expect(find.text('Clear Search'), findsOneWidget);

    // Tap "Clear Search" button
    await tester.tap(find.text('Clear Search'));
    await tester.pumpAndSettle();
    expect(find.text('Maria S.'), findsOneWidget);
  });

  testWidgets('App Guide: opens from More tab and filters by category',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({
      PrivacyPolicyScreen.prefKeyAccepted: true,
    });

    await pumpAppAndLoadDatabase(tester);

    // Navigate to More Tab
    await tester.tap(find.byKey(const Key('nav_more')));
    await tester.pumpAndSettle();

    // Scroll to and tap "Welcome & App Guide"
    await tester.ensureVisible(find.text('Welcome & App Guide'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Welcome & App Guide'));
    await tester.pumpAndSettle();

    // Verify App Guide screen is displayed
    expect(find.text('Tenera App Guide'), findsOneWidget);
    expect(find.text('HOW TO USE TENERA'), findsOneWidget);
    expect(find.text('Manage Properties & Room Grid'), findsOneWidget);
    expect(find.text('Assigning & Removing Tenants'), findsOneWidget);

    // Filter by 'Rooms & Grid'
    await tester.tap(find.text('Rooms & Grid'));
    await tester.pumpAndSettle();
    expect(find.text('Manage Properties & Room Grid'), findsOneWidget);

    // Tap Close Guide button to return
    await tester.tap(find.byTooltip('Close Guide'));
    await tester.pumpAndSettle();
    expect(find.text('Tenera Property Manager'), findsOneWidget);
  });

  testWidgets('Record payment: live tenant search, optional cash photo, and digital payment reference number',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({
      PrivacyPolicyScreen.prefKeyAccepted: true,
    });

    await pumpAppAndLoadDatabase(tester);

    // Open Record Payment dialog
    await tester.tap(find.byKey(const Key('quick_action_record_payment')));
    await tester.pumpAndSettle();

    // Verify Record Rent Payment sheet is open
    expect(find.text('Record Rent Payment'), findsOneWidget);

    // 1. Test live tenant search
    final searchField = find.byKey(const Key('record_tenant_search_field'));
    expect(searchField, findsOneWidget);

    // Type query "Juan"
    await tester.enterText(searchField, 'Juan');
    await tester.pumpAndSettle();

    // Matching candidate Juan Carlos should appear
    expect(find.text('Juan Carlos'), findsWidgets);

    // Tap Juan Carlos to select
    await tester.tap(find.text('Juan Carlos').first);
    await tester.pumpAndSettle();

    // 2. Test Optional Cash Photo when Cash is selected
    expect(find.text('Cash Photo Proof (Optional)'), findsOneWidget);
    final attachPhotoBtn = find.byKey(const Key('attach_cash_photo_button'));
    expect(attachPhotoBtn, findsOneWidget);

    // Tap to attach cash photo
    await tester.ensureVisible(attachPhotoBtn);
    await tester.pumpAndSettle();
    await tester.tap(attachPhotoBtn);
    await tester.pumpAndSettle();

    // Verify photo is attached
    expect(find.text('Attached'), findsOneWidget);
    expect(find.text('Proof of cash handed over'), findsOneWidget);

    // 3. Test Digital Payment (GCash / Bank Transfer) with Reference Number
    await tester.tap(find.text('GCash'));
    await tester.pumpAndSettle();

    // Reference number field appears
    expect(find.text('GCash Reference Number'), findsOneWidget);
    final refField = find.byKey(const Key('payment_reference_field'));
    expect(refField, findsOneWidget);

    await tester.enterText(refField, 'GCASH-99887766');
    await tester.pumpAndSettle();

    // 4. Confirm and log payment
    final confirmBtn = find.text('Confirm & Log Payment');
    await tester.ensureVisible(confirmBtn);
    await tester.pumpAndSettle();
    await tester.tap(confirmBtn);
    await tester.pumpAndSettle();
    await tester.runAsync(() async {
      await Future.delayed(const Duration(milliseconds: 300));
    });
    await tester.pumpAndSettle();

    // Verify payment was logged
    expect(find.textContaining('GCASH-99887766'), findsOneWidget);

    // Navigate to Payments tab to check receipt
    await tester.tap(find.byKey(const Key('nav_payments')));
    await tester.pumpAndSettle();

    expect(find.text('Juan Carlos'), findsWidgets);

    // Tap the record to open receipt
    await tester.tap(find.text('Juan Carlos').first);
    await tester.pumpAndSettle();

    // Verify receipt contains Reference / Txn No.
    expect(find.text('Rent Payment Receipt'), findsOneWidget);
    expect(find.text('Reference / Txn No.'), findsOneWidget);
    expect(find.text('GCASH-99887766'), findsOneWidget);
  });

  testWidgets('Utility Sub-Meter Splitter: opens, calculates electric kWh splits, saves and shares',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({
      PrivacyPolicyScreen.prefKeyAccepted: true,
      SubscriptionPlansScreen.prefKeyCurrentPlan: 'pro',
    });

    await pumpAppAndLoadDatabase(tester);

    // Tap the bolt action icon in the home app bar
    final utilityBtn = find.byKey(const Key('home_action_utility_splitter'));
    expect(utilityBtn, findsOneWidget);
    await tester.tap(utilityBtn);
    await tester.pump();
    await tester.runAsync(() async {
      await Future.delayed(const Duration(milliseconds: 400));
    });
    await tester.pumpAndSettle();

    // Verify Utility Sub-Meter Splitter screen is opened
    expect(find.text('Utility Sub-Meter Splitter'), findsOneWidget);
    expect(find.text('Electricity (kWh)'), findsOneWidget);
    expect(find.text('Water (m³)'), findsOneWidget);
    expect(find.text('Actual Bill Split'), findsOneWidget);
    expect(find.text('Fixed Rate'), findsOneWidget);
    expect(find.text('Equal Split'), findsOneWidget);

    // Verify rooms are loaded from SQLite
    expect(find.text('Mabini Apts'), findsOneWidget);
    expect(find.text('R1'), findsOneWidget);
    expect(find.text('Elena Santos'), findsOneWidget);

    // Toggle to Water (m³)
    await tester.tap(find.text('Water (m³)'));
    await tester.pump();
    await tester.runAsync(() async {
      await Future.delayed(const Duration(milliseconds: 300));
    });
    await tester.pumpAndSettle();
    expect(find.text('Total Water Bill (₱)'), findsOneWidget);

    // Toggle back to Electricity (kWh)
    await tester.tap(find.text('Electricity (kWh)'));
    await tester.pump();
    await tester.runAsync(() async {
      await Future.delayed(const Duration(milliseconds: 300));
    });
    await tester.pumpAndSettle();
    expect(find.text('Total Meralco Bill (₱)'), findsOneWidget);

    // Tap "Share Breakdown"
    await tester.tap(find.text('Share Breakdown'));
    await tester.pumpAndSettle();
    expect(find.text('Breakdown Copied!'), findsOneWidget);

    // Close breakdown dialog
    await tester.tap(find.text('Got it'));
    await tester.pumpAndSettle();

    // Tap "Save Readings"
    await tester.tap(find.text('Save Readings'));
    await tester.pump();
    await tester.runAsync(() async {
      await Future.delayed(const Duration(milliseconds: 300));
    });
    await tester.pumpAndSettle();
    expect(find.textContaining('Saved readings for Mabini Apts'), findsOneWidget);

    // Return to Home
    await tester.tap(find.byTooltip('Back'));
    await tester.pump();
    await tester.runAsync(() async {
      await Future.delayed(const Duration(milliseconds: 300));
    });
    await tester.pumpAndSettle();
    expect(find.text('Vacant units'), findsOneWidget);
  });

  testWidgets('1-Tap SMS Reminder: opens reminder modal, switches tones, and launches SMS',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({
      PrivacyPolicyScreen.prefKeyAccepted: true,
    });

    await pumpAppAndLoadDatabase(tester);

    // Tap quick action: Remind Tenants
    final remindAction = find.byKey(const Key('quick_action_remind'));
    expect(remindAction, findsOneWidget);
    await tester.tap(remindAction);
    await tester.pump();
    await tester.runAsync(() async {
      await Future.delayed(const Duration(milliseconds: 300));
    });
    await tester.pumpAndSettle();

    // Verify reminder dialog opens
    expect(find.textContaining('Remind'), findsOneWidget);
    expect(find.text('Message Tone:'), findsOneWidget);
    expect(find.text('Polite'), findsOneWidget);
    expect(find.text('Due Soon'), findsOneWidget);
    expect(find.text('Overdue'), findsWidgets);

    // Switch tone to "Due Soon"
    await tester.tap(find.text('Due Soon'));
    await tester.pumpAndSettle();
    expect(find.textContaining('due soon'), findsOneWidget);

    // Enter a phone number
    final phoneField = find.byType(TextField).last;
    await tester.enterText(phoneField, '09171234567');
    await tester.pumpAndSettle();

    // Tap "Send SMS"
    final sendSmsBtn = find.byKey(const Key('btn_send_sms_native'));
    expect(sendSmsBtn, findsOneWidget);
    await tester.tap(sendSmsBtn);
    await tester.pump();
    await tester.runAsync(() async {
      await Future.delayed(const Duration(milliseconds: 300));
    });
    await tester.pumpAndSettle();

    // Verify confirmation feedback
    expect(find.textContaining('Opening Messages'), findsOneWidget);
  });

  testWidgets('Revenue & BIR Tax Report: computes tax regimes, displays metrics, and exports CSV',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({
      PrivacyPolicyScreen.prefKeyAccepted: true,
    });

    late List<PaymentRecord> payments;
    late List<PropertyItem> props;
    late List<TenantBill> tenants;
    await tester.runAsync(() async {
      payments = await DatabaseHelper.instance.getPayments();
      props = await DatabaseHelper.instance.getProperties();
      tenants = await DatabaseHelper.instance.getTenants();
    });

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: ReportsExportScreen(
          initialPayments: payments,
          initialProperties: props,
          initialTenants: tenants,
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify Reports Screen UI loaded
    expect(find.text('BIR Tax & Revenue Reports'), findsOneWidget);
    expect(find.text('Report Filters & BIR Profile'), findsOneWidget);
    expect(find.text('Gross Collections'), findsOneWidget);
    expect(find.text('Estimated Tax Due'), findsOneWidget);
    expect(find.text('Net Revenue'), findsOneWidget);
    expect(find.text('Active Arrears'), findsOneWidget);

    // Verify Collections Ledger contains seeded payment entries
    expect(find.textContaining('Collections Ledger'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Juan Carlos'), 100);
    expect(find.text('Juan Carlos'), findsOneWidget);

    // Test CSV Preview Modal
    final previewBtn = find.byKey(const Key('btn_preview_csv'));
    expect(previewBtn, findsOneWidget);
    await tester.tap(previewBtn);
    await tester.pumpAndSettle();

    expect(find.text('CSV Export Preview'), findsOneWidget);
    expect(find.textContaining('TENERA PROPERTY MANAGER - REVENUE & BIR TAX REPORT'), findsOneWidget);
    expect(find.textContaining('Gross Amount (PHP)'), findsOneWidget);

    // Close preview modal
    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();

    // Test Copy CSV action
    final copyBtn = find.byKey(const Key('btn_copy_csv_appbar'));
    expect(copyBtn, findsOneWidget);
    await tester.tap(copyBtn);
    await tester.pump();
    await tester.runAsync(() async {
      await Future.delayed(const Duration(milliseconds: 300));
    });
    await tester.pumpAndSettle();

    // Verify SnackBar confirmation
    expect(find.textContaining('copied to clipboard'), findsOneWidget);
  });

  testWidgets('PlanGuardService: enforces 15-unit Starter limit and presents upgrade paywall',
      (WidgetTester tester) async {
    // Simulate Starter plan with expired trial (>14 days)
    final pastDate = DateTime.now().subtract(const Duration(days: 30)).toIso8601String();
    SharedPreferences.setMockInitialValues({
      SubscriptionPlansScreen.prefKeyCurrentPlan: 'starter',
      SubscriptionPlansScreen.prefKeyTrialStartDate: pastDate,
    });

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(child: Text('Plan Test Scaffold')),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final context = tester.element(find.text('Plan Test Scaffold'));

    // Under limit (10 units + 1 = 11 <= 15): allowed
    final canAddUnder = await PlanGuardService.canAddUnits(
      context: context,
      currentTotalUnits: 10,
      incomingUnits: 1,
    );
    expect(canAddUnder, isTrue);

    // At limit (15 units + 1 = 16 > 15): triggers paywall dialog and returns false
    final canAddOver = await PlanGuardService.canAddUnits(
      context: context,
      currentTotalUnits: 15,
      incomingUnits: 1,
    );
    expect(canAddOver, isFalse);

    await tester.pumpAndSettle();

    // Verify upgrade paywall modal contents
    expect(find.text('Starter Plan Limit Reached'), findsOneWidget);
    expect(find.text('Current Units: 15 / 15 Max'), findsOneWidget);
    expect(find.textContaining('The Starter Plan supports up to 15 rental units'), findsOneWidget);
    expect(find.byKey(const Key('btn_upgrade_to_pro_modal')), findsOneWidget);

    // Dismiss modal
    await tester.tap(find.text('Maybe Later'));
    await tester.pumpAndSettle();
    expect(find.text('Starter Plan Limit Reached'), findsNothing);

    // Verify that Pro subscribers are never blocked
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(SubscriptionPlansScreen.prefKeyCurrentPlan, 'pro');

    final canAddPro = await PlanGuardService.canAddUnits(
      context: context,
      currentTotalUnits: 50,
      incomingUnits: 10,
    );
    expect(canAddPro, isTrue);

    // Test Pro tool guarding:
    // Reset to starter plan
    await prefs.setString(SubscriptionPlansScreen.prefKeyCurrentPlan, 'starter');
    final canAccessStarter = await PlanGuardService.requirePro(
      context: context,
      featureName: 'Utility Sub-Meter Splitter',
      featureBenefit: 'Split electric & water bills accurately per room.',
    );
    expect(canAccessStarter, isFalse);
    await tester.pumpAndSettle();

    // Verify Pro Upgrade modal
    expect(find.text('Utility Sub-Meter Splitter'), findsOneWidget);
    expect(find.byKey(const Key('btn_upgrade_pro_feature_modal')), findsOneWidget);

    // Dismiss modal
    await tester.tap(find.text('Maybe Later'));
    await tester.pumpAndSettle();

    // Switch to Pro: access granted immediately
    await prefs.setString(SubscriptionPlansScreen.prefKeyCurrentPlan, 'pro');
    final canAccessPro = await PlanGuardService.requirePro(
      context: context,
      featureName: 'Utility Sub-Meter Splitter',
      featureBenefit: 'Split electric & water bills accurately per room.',
    );
    expect(canAccessPro, isTrue);
  });

  testWidgets('PlanGuardService: enforces Business tier requirement and presents Business upgrade paywall',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({
      PrivacyPolicyScreen.prefKeyAccepted: true,
      SubscriptionPlansScreen.prefKeyCurrentPlan: 'pro',
    });

    await pumpAppAndLoadDatabase(tester);
    final context = tester.element(find.byType(HomeScreen));

    // Pro subscriber attempting to access Business feature
    final canAccessPro = await PlanGuardService.requireBusiness(
      context: context,
      featureName: 'Portfolio Analytics',
      featureBenefit: 'Unlock cross-property yield comparisons.',
    );
    expect(canAccessPro, isFalse);
    await tester.pumpAndSettle();

    // Verify Business Upgrade modal is displayed with BUSINESS badge
    expect(find.text('Portfolio Analytics'), findsOneWidget);
    expect(find.text('BUSINESS'), findsWidgets);
    expect(find.byKey(const Key('btn_upgrade_business_feature_modal')), findsOneWidget);

    // Dismiss modal
    await tester.tap(find.text('Maybe Later'));
    await tester.pumpAndSettle();

    // Switch to Business: access granted
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(SubscriptionPlansScreen.prefKeyCurrentPlan, 'business');

    final canAccessBusiness = await PlanGuardService.requireBusiness(
      context: context,
      featureName: 'Portfolio Analytics',
      featureBenefit: 'Unlock cross-property yield comparisons.',
    );
    expect(canAccessBusiness, isTrue);
  });

  testWidgets('Multi-Property Portfolio Analytics: loads metrics, renders cross-property comparison, previews and exports CSV',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({
      PrivacyPolicyScreen.prefKeyAccepted: true,
      SubscriptionPlansScreen.prefKeyCurrentPlan: 'business',
    });

    await pumpAppAndLoadDatabase(tester);

    // Navigate to Properties tab
    await tester.tap(find.byKey(const Key('nav_properties')));
    await tester.pumpAndSettle();

    // Verify Multi-Property Analytics button is rendered on the Total Portfolio card
    expect(find.byKey(const Key('btn_open_portfolio_analytics')), findsOneWidget);

    // Retrieve summary via test database
    late PortfolioAnalyticsSummary summary;
    await tester.runAsync(() async {
      summary = await DatabaseHelper.instance.getPortfolioAnalytics();
    });

    // Pump PortfolioAnalyticsScreen directly with loaded summary
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: PortfolioAnalyticsScreen(
          initialSummary: summary,
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify PortfolioAnalyticsScreen is displayed
    expect(find.text('Portfolio Analytics'), findsOneWidget);
    expect(find.text('PORTFOLIO CASHFLOW & OCCUPANCY'), findsOneWidget);
    expect(find.text('Occupancy Rate'), findsOneWidget);
    expect(find.text('Collection Efficiency'), findsOneWidget);
    expect(find.text('Cross-Property Comparison (3)'), findsOneWidget);

    // Verify first property card (Mabini)
    expect(find.text('Mabini Apts'), findsOneWidget);

    // Scroll down to view remaining properties
    await tester.drag(find.byType(ListView), const Offset(0, -300));
    await tester.pumpAndSettle();
    expect(find.text('Rizal House'), findsOneWidget);

    await tester.drag(find.byType(ListView), const Offset(0, -300));
    await tester.pumpAndSettle();
    expect(find.text('Sampaguita Place'), findsOneWidget);

    // Test CSV preview dialog
    await tester.tap(find.byKey(const Key('btn_preview_portfolio_csv')));
    await tester.pumpAndSettle();
    expect(find.text('CSV Report Preview'), findsOneWidget);
    expect(find.textContaining('TENERA BUSINESS - MULTI-PROPERTY PORTFOLIO ANALYTICS REPORT'), findsOneWidget);

    // Tap "Copy CSV" inside modal
    await tester.tap(find.widgetWithText(ElevatedButton, 'Copy CSV'));
    await tester.pumpAndSettle();
    expect(find.text('CSV Report Preview'), findsNothing);

    // Test direct Copy CSV AppBar action
    await tester.tap(find.byKey(const Key('btn_copy_portfolio_csv_appbar')));
    await tester.pump();
    await tester.runAsync(() async {
      await Future.delayed(const Duration(milliseconds: 300));
    });
    await tester.pumpAndSettle();
    expect(find.textContaining('Portfolio Analytics CSV copied to clipboard'), findsOneWidget);
  });

  testWidgets('Caretaker / Staff Mode: PIN creation, financial masking, and unlock flow',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({
      PrivacyPolicyScreen.prefKeyAccepted: true,
      SubscriptionPlansScreen.prefKeyCurrentPlan: 'business',
    });

    await pumpAppAndLoadDatabase(tester);

    // Navigate to More tab
    await tester.tap(find.byKey(const Key('nav_more')));
    await tester.pumpAndSettle();

    // Scroll to Business Tier Tools
    await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -300));
    await tester.pumpAndSettle();

    // Verify Caretaker / Staff Mode tile exists
    expect(find.byKey(const Key('more_caretaker_mode')), findsOneWidget);

    // Tap to enable Caretaker Mode (prompts to set Master PIN)
    await tester.tap(find.byKey(const Key('more_caretaker_mode')));
    await tester.pumpAndSettle();

    expect(find.text('Create Master PIN'), findsOneWidget);

    // Enter mismatching PIN
    await tester.enterText(find.byKey(const Key('input_create_pin')), '1234');
    await tester.enterText(find.byKey(const Key('input_confirm_pin')), '9999');
    await tester.tap(find.byKey(const Key('btn_save_pin_and_enable')));
    await tester.pumpAndSettle();
    expect(find.text('PINs do not match'), findsOneWidget);

    // Enter matching PIN
    await tester.enterText(find.byKey(const Key('input_confirm_pin')), '1234');
    await tester.tap(find.byKey(const Key('btn_save_pin_and_enable')));
    await tester.pumpAndSettle();
    await tester.runAsync(() async {
      await Future.delayed(const Duration(milliseconds: 300));
    });
    await tester.pumpAndSettle();

    // Now in Caretaker Mode!
    // Verify top banner is active
    expect(find.byKey(const Key('banner_staff_mode_active')), findsOneWidget);
    expect(find.text('Caretaker Mode Active · Financials Hidden'), findsOneWidget);

    // Check Home tab financial masking
    await tester.tap(find.byKey(const Key('nav_home')));
    await tester.pumpAndSettle();
    expect(find.text('••••••'), findsWidgets);
    expect(find.text('Caretaker Rent Tracking'), findsOneWidget);

    // Check Properties tab masking
    await tester.tap(find.byKey(const Key('nav_properties')));
    await tester.pumpAndSettle();
    expect(find.text('••••••'), findsWidgets);
    expect(find.byKey(const Key('btn_open_portfolio_analytics')), findsNothing);

    // Check Payments tab masking
    await tester.tap(find.byKey(const Key('nav_payments')));
    await tester.pumpAndSettle();
    expect(find.text('••••••'), findsWidgets);

    // Exit Caretaker Mode via top banner
    await tester.tap(find.byKey(const Key('btn_exit_staff_mode_banner')));
    await tester.pumpAndSettle();

    expect(find.text('Exit Caretaker Mode'), findsOneWidget);

    // Test invalid PIN
    await tester.enterText(find.byKey(const Key('input_enter_staff_pin')), '0000');
    await tester.tap(find.byKey(const Key('btn_verify_staff_pin')));
    await tester.pumpAndSettle();
    expect(find.text('Incorrect PIN. Try again.'), findsOneWidget);

    // Enter valid PIN
    await tester.enterText(find.byKey(const Key('input_enter_staff_pin')), '1234');
    await tester.tap(find.byKey(const Key('btn_verify_staff_pin')));
    await tester.pumpAndSettle();
    await tester.runAsync(() async {
      await Future.delayed(const Duration(milliseconds: 300));
    });
    await tester.pumpAndSettle();

    // Banner removed, financials unmasked!
    expect(find.byKey(const Key('banner_staff_mode_active')), findsNothing);
  });

  test('LeaseContract model: converts currency to words and generates valid contract text', () {
    expect(LeaseContract.numberToPesoWords(6500), 'SIX THOUSAND FIVE HUNDRED PESOS ONLY');
    expect(LeaseContract.numberToPesoWords(13000), 'THIRTEEN THOUSAND PESOS ONLY');
    expect(LeaseContract.numberToPesoWords(1000000), 'ONE MILLION PESOS ONLY');
    expect(LeaseContract.ordinal(1), '1st');
    expect(LeaseContract.ordinal(2), '2nd');
    expect(LeaseContract.ordinal(3), '3rd');
    expect(LeaseContract.ordinal(5), '5th');
    expect(LeaseContract.ordinal(11), '11th');
    expect(LeaseContract.ordinal(22), '22nd');

    final contract = LeaseContract(
      landlordName: 'Juan Dela Cruz',
      landlordAddress: 'Quezon City',
      landlordContact: '09171234567',
      tenantName: 'Elena Santos',
      tenantAddress: 'Manila',
      tenantContact: '09189876543',
      tenantIdInfo: 'National ID: 1234',
      propertyName: 'Sampaguita Place',
      unitCode: 'Room 2B',
      propertyAddress: '123 Katipunan Ave',
      monthlyRent: 6500,
      securityDeposit: 13000,
      advanceRent: 6500,
      startDate: DateTime(2026, 11, 1),
      endDate: DateTime(2027, 11, 1),
      dueDayOfMonth: 5,
    );

    final text = contract.toFormattedContractText();
    expect(text.contains('CONTRACT OF LEASE'), isTrue);
    expect(text.contains('Juan Dela Cruz'), isTrue);
    expect(text.contains('Elena Santos'), isTrue);
    expect(text.contains('Sampaguita Place'), isTrue);
    expect(text.contains('Room 2B'), isTrue);
    expect(text.contains('SIX THOUSAND FIVE HUNDRED PESOS ONLY'), isTrue);
    expect(text.contains('SECTION 4: ADVANCE RENTAL & SECURITY DEPOSIT'), isTrue);
    expect(text.contains('SECTION 5: UTILITIES & SUB-METERING'), isTrue);
    expect(text.contains('SECTION 9: DEFAULT & TERMINATION'), isTrue);
  });

  testWidgets('Printable Philippine Lease Agreement: opens from More tab, edits clauses, switches to preview and prints/copies',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({
      PrivacyPolicyScreen.prefKeyAccepted: true,
      SubscriptionPlansScreen.prefKeyCurrentPlan: 'business',
    });

    await pumpAppAndLoadDatabase(tester);

    // Navigate to More tab
    await tester.tap(find.byKey(const Key('nav_more')));
    await tester.pumpAndSettle();

    // Scroll to Business Tier Tools
    await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -350));
    await tester.pumpAndSettle();

    // Verify Lease Contracts tile exists
    expect(find.byKey(const Key('more_lease_contracts')), findsOneWidget);

    // Tap to open LeaseContractScreen
    await tester.tap(find.byKey(const Key('more_lease_contracts')));
    await tester.pumpAndSettle();
    await tester.runAsync(() async {
      await Future.delayed(const Duration(milliseconds: 300));
    });
    await tester.pumpAndSettle();

    // Verify screen title and type
    expect(find.byType(LeaseContractScreen), findsOneWidget);
    expect(find.text('Lease Agreement Generator'), findsOneWidget);
    expect(find.text('Edit Agreement'), findsOneWidget);
    expect(find.text('Contract Preview'), findsOneWidget);

    // Test form fields
    expect(find.byKey(const Key('input_contract_landlord_name')), findsOneWidget);
    expect(find.byKey(const Key('input_contract_tenant_name')), findsOneWidget);
    // Scroll to rent field
    await tester.drag(find.byType(ListView), const Offset(0, -300));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('input_contract_rent')), findsOneWidget);

    // Change rent to 7500
    await tester.enterText(find.byKey(const Key('input_contract_rent')), '7500');
    await tester.pumpAndSettle();

    // Switch to Preview Tab
    await tester.tap(find.text('Contract Preview'));
    await tester.pumpAndSettle();

    // Verify rendered contract contains updated rent
    expect(find.byKey(const Key('text_rendered_contract')), findsOneWidget);
    expect(find.textContaining('7,500.00'), findsWidgets);

    // Tap "Copy All Text" button
    await tester.tap(find.byKey(const Key('btn_copy_contract')));
    await tester.pumpAndSettle();
    expect(find.text('✅ Full lease contract copied to clipboard! Ready to paste into Google Docs or Word.'), findsOneWidget);

    // Tap "Print View" button to open modal
    await tester.tap(find.byKey(const Key('btn_print_contract')));
    await tester.pumpAndSettle();
    expect(find.text('Print-Ready Contract'), findsOneWidget);
    expect(find.byKey(const Key('btn_modal_copy_contract')), findsOneWidget);

    // Tap modal copy button and close
    await tester.tap(find.byKey(const Key('btn_modal_copy_contract')));
    await tester.pumpAndSettle();
    expect(find.text('Contract copied! Paste and print from any text editor or browser.'), findsOneWidget);
  });

  testWidgets('VIP Priority Support: opens dedicated concierge modal for Business landlords',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({
      PrivacyPolicyScreen.prefKeyAccepted: true,
      SubscriptionPlansScreen.prefKeyCurrentPlan: 'business',
    });

    await pumpAppAndLoadDatabase(tester);

    // Navigate to More tab
    await tester.tap(find.byKey(const Key('nav_more')));
    await tester.pumpAndSettle();

    // Scroll to Business Tier Tools
    await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -380));
    await tester.pumpAndSettle();

    // Verify VIP Support tile exists
    expect(find.byKey(const Key('more_vip_support')), findsOneWidget);

    // Tap to open VIP Support Concierge
    await tester.tap(find.byKey(const Key('more_vip_support')));
    await tester.pumpAndSettle();

    // Verify modal options
    expect(find.text('Dedicated Philippine Concierge for Business Landlords'), findsOneWidget);
    expect(find.byKey(const Key('btn_vip_whatsapp')), findsOneWidget);
    expect(find.byKey(const Key('btn_vip_phone')), findsOneWidget);
    expect(find.byKey(const Key('btn_vip_email')), findsOneWidget);
    expect(find.text('WhatsApp Concierge'), findsOneWidget);
  });

  testWidgets('Plan-based dynamic tool visibility: Starter hides gated tools, Pro and Business reveal them',
      (WidgetTester tester) async {
    // 1. Initial State: Starter Plan
    SharedPreferences.setMockInitialValues({
      PrivacyPolicyScreen.prefKeyAccepted: true,
      SubscriptionPlansScreen.prefKeyCurrentPlan: 'starter',
    });

    await pumpAppAndLoadDatabase(tester);

    // Verify bills action in HomeScreen AppBar is HIDDEN for Starter
    expect(find.byKey(const Key('home_action_utility_splitter')), findsNothing);

    // Navigate to Properties tab: Portfolio Analytics button is HIDDEN
    await tester.tap(find.byKey(const Key('nav_properties')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('btn_open_portfolio_analytics')), findsNothing);

    // Navigate to More tab: Pro & Business tools sections are HIDDEN
    await tester.tap(find.byKey(const Key('nav_more')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('more_utility_calculator')), findsNothing);
    expect(find.byKey(const Key('more_reports_export')), findsNothing);
    expect(find.byKey(const Key('more_portfolio_analytics')), findsNothing);
    expect(find.byKey(const Key('more_caretaker_mode')), findsNothing);
    expect(find.byKey(const Key('more_lease_contracts')), findsNothing);
    expect(find.byKey(const Key('more_vip_support')), findsNothing);

    // Verify upgrade banner is visible
    expect(find.text('Tenera Pro & Plans'), findsOneWidget);
  });
}





