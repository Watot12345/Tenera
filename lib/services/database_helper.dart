import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import '../models/payment.dart';
import '../models/portfolio_analytics.dart';
import '../models/property.dart';
import '../models/tenant.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  // Test injection support
  static void setMockDatabase(Database db) {
    _database = db;
  }

  Future<void> createDbForTest(Database db) async {
    await _createDB(db, 1);
  }

  static Future<void> reset() async {
    if (_database != null) {
      if (_database!.isOpen) {
        await _database!.close();
      }
      _database = null;
    }
  }

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('tenera.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final Database db;
    if (kIsWeb) {
      databaseFactory = databaseFactoryFfiWeb;
      db = await databaseFactory.openDatabase(
        filePath,
        options: OpenDatabaseOptions(
          version: 1,
          onCreate: _createDB,
        ),
      );
    } else {
      final dbPath = await getDatabasesPath();
      final path = join(dbPath, filePath);

      db = await openDatabase(
        path,
        version: 1,
        onCreate: _createDB,
      );
    }

    final tables = await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table' AND name='properties'");
    if (tables.isEmpty) {
      await _createDB(db, 1);
    } else {
      final count = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM properties')) ?? 0;
      if (count == 0) {
        await _seedInitialData(db);
      }
    }

    return db;
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE properties (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        address TEXT NOT NULL,
        total_units INTEGER NOT NULL,
        occupied_units INTEGER NOT NULL,
        monthly_revenue INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        is_synced INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE rooms (
        id TEXT PRIMARY KEY,
        property_id TEXT NOT NULL,
        code TEXT NOT NULL,
        status TEXT NOT NULL,
        tenant_name TEXT,
        rent_amount INTEGER,
        status_text TEXT,
        updated_at INTEGER NOT NULL,
        is_synced INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (property_id) REFERENCES properties (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE tenants (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        initials TEXT NOT NULL,
        location TEXT NOT NULL,
        amount INTEGER NOT NULL,
        status_text TEXT NOT NULL,
        is_overdue INTEGER NOT NULL DEFAULT 0,
        is_paid INTEGER NOT NULL DEFAULT 0,
        updated_at INTEGER NOT NULL,
        is_synced INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE payments (
        id TEXT PRIMARY KEY,
        tenant_name TEXT NOT NULL,
        location TEXT NOT NULL,
        amount INTEGER NOT NULL,
        method TEXT NOT NULL,
        date_formatted TEXT NOT NULL,
        reference_no TEXT,
        cash_image_name TEXT,
        created_at INTEGER NOT NULL,
        is_synced INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await _seedInitialData(db);
  }

  Future<void> _seedInitialData(Database db) async {
    final now = DateTime.now().millisecondsSinceEpoch;

    // Seed Properties
    await db.insert('properties', {
      'id': 'p1',
      'name': 'Mabini Apts',
      'address': '124 Mabini St, Manila',
      'total_units': 12,
      'occupied_units': 11,
      'monthly_revenue': 46000,
      'updated_at': now,
      'is_synced': 1,
    });

    await db.insert('properties', {
      'id': 'p2',
      'name': 'Rizal House',
      'address': '88 Rizal Ave, Pasay City',
      'total_units': 8,
      'occupied_units': 7,
      'monthly_revenue': 28600,
      'updated_at': now,
      'is_synced': 1,
    });

    await db.insert('properties', {
      'id': 'p3',
      'name': 'Sampaguita Place',
      'address': '22 Sampaguita St, Quezon City',
      'total_units': 4,
      'occupied_units': 3,
      'monthly_revenue': 13500,
      'updated_at': now,
      'is_synced': 1,
    });

    // Seed Rooms for Mabini Apts (p1)
    final p1Rooms = [
      {'code': 'R1', 'status': 'occupied', 'tenant_name': 'Elena Santos', 'rent_amount': 3500, 'status_text': 'Paid'},
      {'code': 'R2', 'status': 'occupied', 'tenant_name': 'Juan Carlos', 'rent_amount': 4000, 'status_text': 'Paid'},
      {'code': 'R3', 'status': 'overdue', 'tenant_name': 'Maria S.', 'rent_amount': 3500, 'status_text': '5 days late'},
      {'code': 'R4', 'status': 'occupied', 'tenant_name': 'Roberto Gomez', 'rent_amount': 4000, 'status_text': 'Paid'},
      {'code': 'R5', 'status': 'occupied', 'tenant_name': 'Carlos Tan', 'rent_amount': 3500, 'status_text': 'Paid'},
      {'code': 'R6', 'status': 'occupied', 'tenant_name': 'Liza M.', 'rent_amount': 3800, 'status_text': 'Paid'},
      {'code': '2A', 'status': 'occupied', 'tenant_name': 'Danilo P.', 'rent_amount': 4200, 'status_text': 'Paid'},
      {'code': '2B', 'status': 'overdue', 'tenant_name': 'Ramon D.', 'rent_amount': 5000, 'status_text': '2 days late'},
      {'code': '2C', 'status': 'occupied', 'tenant_name': 'Grace L.', 'rent_amount': 4500, 'status_text': 'Paid'},
      {'code': '2D', 'status': 'occupied', 'tenant_name': 'Benjie S.', 'rent_amount': 4000, 'status_text': 'Paid'},
      {'code': '2E', 'status': 'vacant', 'tenant_name': null, 'rent_amount': 4000, 'status_text': null},
      {'code': '2F', 'status': 'occupied', 'tenant_name': 'Patricia B.', 'rent_amount': 4200, 'status_text': 'Paid'},
    ];

    for (final r in p1Rooms) {
      await db.insert('rooms', {
        'id': 'p1_${r['code']}',
        'property_id': 'p1',
        'code': r['code'],
        'status': r['status'],
        'tenant_name': r['tenant_name'],
        'rent_amount': r['rent_amount'],
        'status_text': r['status_text'],
        'updated_at': now,
        'is_synced': 1,
      });
    }

    // Seed Rooms for Rizal House (p2)
    final p2Rooms = [
      {'code': '1A', 'status': 'occupied', 'tenant_name': 'Ana P.', 'rent_amount': 4000, 'status_text': 'In 4 days'},
      {'code': '1B', 'status': 'occupied', 'tenant_name': 'Jun R.', 'rent_amount': 3000, 'status_text': 'In 2 days'},
      {'code': '1C', 'status': 'occupied', 'tenant_name': 'Mateo Cruz', 'rent_amount': 5000, 'status_text': 'Paid'},
      {'code': '1D', 'status': 'occupied', 'tenant_name': 'Rosa Diaz', 'rent_amount': 4500, 'status_text': 'Paid'},
      {'code': 'R5', 'status': 'occupied', 'tenant_name': 'Arnold V.', 'rent_amount': 3200, 'status_text': 'Paid'},
      {'code': 'R6', 'status': 'occupied', 'tenant_name': 'Joy T.', 'rent_amount': 3200, 'status_text': 'Paid'},
      {'code': 'R7', 'status': 'occupied', 'tenant_name': 'Victor N.', 'rent_amount': 3500, 'status_text': 'Paid'},
      {'code': 'R8', 'status': 'vacant', 'tenant_name': null, 'rent_amount': 3500, 'status_text': null},
    ];

    for (final r in p2Rooms) {
      await db.insert('rooms', {
        'id': 'p2_${r['code']}',
        'property_id': 'p2',
        'code': r['code'],
        'status': r['status'],
        'tenant_name': r['tenant_name'],
        'rent_amount': r['rent_amount'],
        'status_text': r['status_text'],
        'updated_at': now,
        'is_synced': 1,
      });
    }

    // Seed Rooms for Sampaguita Place (p3)
    final p3Rooms = [
      {'code': 'S1', 'status': 'occupied', 'tenant_name': 'Felipe K.', 'rent_amount': 4500, 'status_text': 'Paid'},
      {'code': 'S2', 'status': 'occupied', 'tenant_name': 'Teresa M.', 'rent_amount': 4500, 'status_text': 'Paid'},
      {'code': 'S3', 'status': 'occupied', 'tenant_name': 'Gabriel R.', 'rent_amount': 4500, 'status_text': 'Paid'},
      {'code': 'S4', 'status': 'vacant', 'tenant_name': null, 'rent_amount': 4500, 'status_text': null},
    ];

    for (final r in p3Rooms) {
      await db.insert('rooms', {
        'id': 'p3_${r['code']}',
        'property_id': 'p3',
        'code': r['code'],
        'status': r['status'],
        'tenant_name': r['tenant_name'],
        'rent_amount': r['rent_amount'],
        'status_text': r['status_text'],
        'updated_at': now,
        'is_synced': 1,
      });
    }

    // Seed Tenants
    final tenants = [
      {'id': 't1', 'name': 'Maria S.', 'initials': 'MS', 'location': 'Room 3 · Mabini Apts', 'amount': 3500, 'status_text': '5 days late', 'is_overdue': 1, 'is_paid': 0},
      {'id': 't2', 'name': 'Ramon D.', 'initials': 'RD', 'location': 'Unit 2B · Mabini Apts', 'amount': 5000, 'status_text': '2 days late', 'is_overdue': 1, 'is_paid': 0},
      {'id': 't3', 'name': 'Jun R.', 'initials': 'JR', 'location': 'Room 5 · Rizal House', 'amount': 3000, 'status_text': 'In 2 days', 'is_overdue': 0, 'is_paid': 0},
      {'id': 't4', 'name': 'Ana P.', 'initials': 'AP', 'location': 'Unit 1A · Rizal House', 'amount': 4000, 'status_text': 'In 4 days', 'is_overdue': 0, 'is_paid': 0},
      {'id': 't5', 'name': 'Juan Carlos', 'initials': 'JC', 'location': 'Room 1 · Mabini Apts', 'amount': 4000, 'status_text': 'Paid Oct 25', 'is_overdue': 0, 'is_paid': 1},
      {'id': 't6', 'name': 'Elena Santos', 'initials': 'ES', 'location': 'Room 2 · Mabini Apts', 'amount': 3500, 'status_text': 'Paid Oct 24', 'is_overdue': 0, 'is_paid': 1},
      {'id': 't7', 'name': 'Mateo Cruz', 'initials': 'MC', 'location': 'Unit 3A · Rizal House', 'amount': 5000, 'status_text': 'Paid Oct 22', 'is_overdue': 0, 'is_paid': 1},
      {'id': 't8', 'name': 'Rosa Diaz', 'initials': 'RD', 'location': 'Unit 2A · Rizal House', 'amount': 4500, 'status_text': 'Paid Oct 20', 'is_overdue': 0, 'is_paid': 1},
      {'id': 't9', 'name': 'Roberto Gomez', 'initials': 'RG', 'location': 'Room R4 · Mabini Apts', 'amount': 4000, 'status_text': 'Paid Oct 18', 'is_overdue': 0, 'is_paid': 1},
      {'id': 't10', 'name': 'Carlos Tan', 'initials': 'CT', 'location': 'Room R5 · Mabini Apts', 'amount': 3500, 'status_text': 'Paid Oct 17', 'is_overdue': 0, 'is_paid': 1},
      {'id': 't11', 'name': 'Liza M.', 'initials': 'LM', 'location': 'Room R6 · Mabini Apts', 'amount': 3800, 'status_text': 'Paid Oct 16', 'is_overdue': 0, 'is_paid': 1},
      {'id': 't12', 'name': 'Danilo P.', 'initials': 'DP', 'location': 'Unit 2A · Mabini Apts', 'amount': 4200, 'status_text': 'Paid Oct 15', 'is_overdue': 0, 'is_paid': 1},
      {'id': 't13', 'name': 'Grace L.', 'initials': 'GL', 'location': 'Unit 2C · Mabini Apts', 'amount': 4500, 'status_text': 'Paid Oct 14', 'is_overdue': 0, 'is_paid': 1},
      {'id': 't14', 'name': 'Benjie S.', 'initials': 'BS', 'location': 'Unit 2D · Mabini Apts', 'amount': 4000, 'status_text': 'Paid Oct 12', 'is_overdue': 0, 'is_paid': 1},
      {'id': 't15', 'name': 'Patricia B.', 'initials': 'PB', 'location': 'Unit 2F · Mabini Apts', 'amount': 1000, 'status_text': 'Paid Oct 10', 'is_overdue': 0, 'is_paid': 1},
      {'id': 't16', 'name': 'Arnold V.', 'initials': 'AV', 'location': 'Room R5 · Rizal House', 'amount': 3200, 'status_text': 'Paid Oct 8', 'is_overdue': 0, 'is_paid': 1},
      {'id': 't17', 'name': 'Joy T.', 'initials': 'JT', 'location': 'Room R6 · Rizal House', 'amount': 3200, 'status_text': 'Paid Oct 7', 'is_overdue': 0, 'is_paid': 1},
      {'id': 't18', 'name': 'Victor N.', 'initials': 'VN', 'location': 'Room R7 · Rizal House', 'amount': 3500, 'status_text': 'Paid Oct 5', 'is_overdue': 0, 'is_paid': 1},
      {'id': 't19', 'name': 'Felipe K.', 'initials': 'FK', 'location': 'Unit S1 · Sampaguita Place', 'amount': 4500, 'status_text': 'Paid Oct 5', 'is_overdue': 0, 'is_paid': 1},
      {'id': 't20', 'name': 'Teresa M.', 'initials': 'TM', 'location': 'Unit S2 · Sampaguita Place', 'amount': 4500, 'status_text': 'Paid Oct 4', 'is_overdue': 0, 'is_paid': 1},
      {'id': 't21', 'name': 'Gabriel R.', 'initials': 'GR', 'location': 'Unit S3 · Sampaguita Place', 'amount': 4500, 'status_text': 'Paid Oct 3', 'is_overdue': 0, 'is_paid': 1},
    ];

    for (final t in tenants) {
      await db.insert('tenants', {
        ...t,
        'updated_at': now,
        'is_synced': 1,
      });
    }

    // Seed Payment Ledger (Total: ₱42,000 month-to-date)
    final payments = [
      {
        'id': 'pay1',
        'tenant_name': 'Juan Carlos',
        'location': 'Room 1 · Mabini Apts',
        'amount': 4000,
        'method': 'GCash',
        'date_formatted': 'Oct 25, 10:30 AM',
        'reference_no': 'GCASH-49182394',
        'cash_image_name': null,
      },
      {
        'id': 'pay2',
        'tenant_name': 'Elena Santos',
        'location': 'Room 2 · Mabini Apts',
        'amount': 3500,
        'method': 'Cash',
        'date_formatted': 'Oct 24, 2:15 PM',
        'reference_no': null,
        'cash_image_name': 'cash_elena_oct24.jpg',
      },
      {
        'id': 'pay3',
        'tenant_name': 'Mateo Cruz',
        'location': 'Unit 3A · Rizal House',
        'amount': 5000,
        'method': 'Bank Transfer',
        'date_formatted': 'Oct 22, 4:00 PM',
        'reference_no': 'BPI-993821-TXN',
        'cash_image_name': null,
      },
      {
        'id': 'pay4',
        'tenant_name': 'Rosa Diaz',
        'location': 'Unit 2A · Rizal House',
        'amount': 4500,
        'method': 'Cash',
        'date_formatted': 'Oct 20, 9:00 AM',
        'reference_no': null,
        'cash_image_name': null,
      },
      {
        'id': 'pay5',
        'tenant_name': 'Roberto Gomez',
        'location': 'Room R4 · Mabini Apts',
        'amount': 4000,
        'method': 'Cash',
        'date_formatted': 'Oct 18, 3:00 PM',
        'reference_no': null,
        'cash_image_name': null,
      },
      {
        'id': 'pay6',
        'tenant_name': 'Carlos Tan',
        'location': 'Room R5 · Mabini Apts',
        'amount': 3500,
        'method': 'GCash',
        'date_formatted': 'Oct 17, 11:20 AM',
        'reference_no': 'GCASH-7821901',
        'cash_image_name': null,
      },
      {
        'id': 'pay7',
        'tenant_name': 'Liza M.',
        'location': 'Room R6 · Mabini Apts',
        'amount': 3800,
        'method': 'GCash',
        'date_formatted': 'Oct 16, 9:15 AM',
        'reference_no': 'GCASH-4412098',
        'cash_image_name': null,
      },
      {
        'id': 'pay8',
        'tenant_name': 'Danilo P.',
        'location': 'Unit 2A · Mabini Apts',
        'amount': 4200,
        'method': 'Bank Transfer',
        'date_formatted': 'Oct 15, 1:40 PM',
        'reference_no': 'BDO-552140',
        'cash_image_name': null,
      },
      {
        'id': 'pay9',
        'tenant_name': 'Grace L.',
        'location': 'Unit 2C · Mabini Apts',
        'amount': 4500,
        'method': 'Cash',
        'date_formatted': 'Oct 14, 5:30 PM',
        'reference_no': null,
        'cash_image_name': null,
      },
      {
        'id': 'pay10',
        'tenant_name': 'Benjie S.',
        'location': 'Unit 2D · Mabini Apts',
        'amount': 4000,
        'method': 'Cash',
        'date_formatted': 'Oct 12, 10:00 AM',
        'reference_no': null,
        'cash_image_name': null,
      },
      {
        'id': 'pay11',
        'tenant_name': 'Patricia B.',
        'location': 'Unit 2F · Mabini Apts',
        'amount': 1000,
        'method': 'GCash',
        'date_formatted': 'Oct 10, 2:00 PM',
        'reference_no': 'GCASH-1192837',
        'cash_image_name': null,
      },
    ];

    for (final p in payments) {
      await db.insert('payments', {
        ...p,
        'created_at': now,
        'is_synced': 1,
      });
    }
  }

  // ----------------------------------------------------
  // PROPERTIES CRUD
  // ----------------------------------------------------
  Future<List<PropertyItem>> getProperties() async {
    final db = await database;
    final propMaps = await db.query('properties', orderBy: 'id ASC');

    final List<PropertyItem> result = [];
    for (final p in propMaps) {
      final propId = p['id'] as String;
      final roomMaps = await db.query(
        'rooms',
        where: 'property_id = ?',
        whereArgs: [propId],
        orderBy: 'code ASC',
      );

      final rooms = roomMaps.map((r) {
        RoomStatus status;
        switch (r['status'] as String) {
          case 'occupied':
            status = RoomStatus.occupied;
            break;
          case 'overdue':
            status = RoomStatus.overdue;
            break;
          case 'vacant':
          default:
            status = RoomStatus.vacant;
            break;
        }

        return RoomUnit(
          code: r['code'] as String,
          status: status,
          tenantName: r['tenant_name'] as String?,
          rentAmount: r['rent_amount'] as int?,
          statusText: r['status_text'] as String?,
        );
      }).toList();

      result.add(PropertyItem(
        id: propId,
        name: p['name'] as String,
        address: p['address'] as String,
        totalUnits: p['total_units'] as int,
        occupiedUnits: p['occupied_units'] as int,
        monthlyRevenue: p['monthly_revenue'] as int,
        rooms: rooms,
      ));
    }

    return result;
  }

  // ----------------------------------------------------
  // PORTFOLIO ANALYTICS (BUSINESS TIER)
  // ----------------------------------------------------
  Future<PortfolioAnalyticsSummary> getPortfolioAnalytics() async {
    final properties = await getProperties();
    final tenants = await getTenants();
    final payments = await getPayments();

    final List<PropertyAnalyticsItem> propertyItems = [];
    int totalPortfolioUnits = 0;
    int totalPortfolioOccupied = 0;
    int totalPortfolioOverdue = 0;
    int totalPortfolioVacant = 0;
    int totalPotentialRent = 0;
    int totalCollected = 0;
    int totalArrears = 0;

    // Calculate sum of potential revenue first for share calculation
    for (final p in properties) {
      final potential = p.rooms.isNotEmpty
          ? p.rooms.fold(0, (sum, r) => sum + (r.rentAmount ?? 0))
          : p.monthlyRevenue;
      totalPotentialRent += potential;
    }

    for (final p in properties) {
      final totalUnits = p.rooms.isNotEmpty ? p.rooms.length : p.totalUnits;
      final occupiedUnits = p.rooms.isNotEmpty
          ? p.rooms.where((r) => r.status == RoomStatus.occupied || r.status == RoomStatus.overdue).length
          : p.occupiedUnits;
      final overdueUnits = p.rooms.isNotEmpty
          ? p.rooms.where((r) => r.status == RoomStatus.overdue).length
          : 0;
      final vacantUnits = totalUnits - occupiedUnits;

      final potentialRev = p.rooms.isNotEmpty
          ? p.rooms.fold(0, (sum, r) => sum + (r.rentAmount ?? 0))
          : p.monthlyRevenue;

      // Match payments for this property by name
      final propPayments = payments.where((pay) {
        return pay.location.toLowerCase().contains(p.name.toLowerCase());
      }).toList();
      final collected = propPayments.fold(0, (sum, pay) => sum + pay.amount);

      // Match arrears for this property
      final propOverdueTenants = tenants.where((t) {
        return t.isOverdue && t.location.toLowerCase().contains(p.name.toLowerCase());
      }).toList();
      int arrears = propOverdueTenants.fold(0, (sum, t) => sum + t.amount);
      if (arrears == 0 && overdueUnits > 0) {
        arrears = p.rooms
            .where((r) => r.status == RoomStatus.overdue)
            .fold(0, (sum, r) => sum + (r.rentAmount ?? 0));
      }

      final occRate = totalUnits > 0 ? (occupiedUnits / totalUnits) * 100.0 : 0.0;
      final collRate = potentialRev > 0 ? (collected / potentialRev) * 100.0 : 0.0;
      final sharePct = totalPotentialRent > 0 ? (potentialRev / totalPotentialRent) * 100.0 : 0.0;
      final avgRent = totalUnits > 0 ? (potentialRev / totalUnits).round() : 0;

      propertyItems.add(PropertyAnalyticsItem(
        propertyId: p.id,
        propertyName: p.name,
        propertyAddress: p.address,
        totalUnits: totalUnits,
        occupiedUnits: occupiedUnits,
        overdueUnits: overdueUnits,
        vacantUnits: vacantUnits,
        potentialRevenue: potentialRev,
        collectedRevenue: collected,
        arrearsAmount: arrears,
        occupancyRate: occRate,
        collectionRate: collRate,
        revenueSharePercent: sharePct,
        averageRentPerUnit: avgRent,
      ));

      totalPortfolioUnits += totalUnits;
      totalPortfolioOccupied += occupiedUnits;
      totalPortfolioOverdue += overdueUnits;
      totalPortfolioVacant += vacantUnits;
      totalCollected += collected;
      totalArrears += arrears;
    }

    final overallOccRate = totalPortfolioUnits > 0
        ? (totalPortfolioOccupied / totalPortfolioUnits) * 100.0
        : 0.0;
    final overallCollRate = totalPotentialRent > 0
        ? (totalCollected / totalPotentialRent) * 100.0
        : 0.0;

    return PortfolioAnalyticsSummary(
      totalProperties: properties.length,
      totalUnits: totalPortfolioUnits,
      totalOccupied: totalPortfolioOccupied,
      totalOverdue: totalPortfolioOverdue,
      totalVacant: totalPortfolioVacant,
      totalPotentialMonthlyRent: totalPotentialRent,
      totalCollected: totalCollected,
      totalArrears: totalArrears,
      overallOccupancyRate: overallOccRate,
      overallCollectionRate: overallCollRate,
      propertyItems: propertyItems,
    );
  }

  Future<void> insertProperty(PropertyItem property) async {
    final db = await database;
    final now = DateTime.now().millisecondsSinceEpoch;

    await db.transaction((txn) async {
      await txn.insert('properties', {
        'id': property.id,
        'name': property.name,
        'address': property.address,
        'total_units': property.totalUnits,
        'occupied_units': property.occupiedUnits,
        'monthly_revenue': property.monthlyRevenue,
        'updated_at': now,
        'is_synced': 0,
      });

      for (final r in property.rooms) {
        await txn.insert('rooms', {
          'id': '${property.id}_${r.code}',
          'property_id': property.id,
          'code': r.code,
          'status': r.status.name,
          'tenant_name': r.tenantName,
          'rent_amount': r.rentAmount,
          'status_text': r.statusText,
          'updated_at': now,
          'is_synced': 0,
        });
      }
    });
  }

  Future<void> updateProperty(PropertyItem property) async {
    final db = await database;
    final now = DateTime.now().millisecondsSinceEpoch;

    await db.transaction((txn) async {
      await txn.update(
        'properties',
        {
          'name': property.name,
          'address': property.address,
          'total_units': property.totalUnits,
          'occupied_units': property.occupiedUnits,
          'monthly_revenue': property.monthlyRevenue,
          'updated_at': now,
          'is_synced': 0,
        },
        where: 'id = ?',
        whereArgs: [property.id],
      );

      // Re-sync rooms
      await txn.delete('rooms', where: 'property_id = ?', whereArgs: [property.id]);
      for (final r in property.rooms) {
        await txn.insert('rooms', {
          'id': '${property.id}_${r.code}',
          'property_id': property.id,
          'code': r.code,
          'status': r.status.name,
          'tenant_name': r.tenantName,
          'rent_amount': r.rentAmount,
          'status_text': r.statusText,
          'updated_at': now,
          'is_synced': 0,
        });
      }
    });
  }

  // ----------------------------------------------------
  // ROOMS CRUD
  // ----------------------------------------------------
  Future<void> insertRoom(String propertyId, RoomUnit room) async {
    final db = await database;
    final now = DateTime.now().millisecondsSinceEpoch;

    await db.insert(
      'rooms',
      {
        'id': '${propertyId}_${room.code}',
        'property_id': propertyId,
        'code': room.code,
        'status': room.status.name,
        'tenant_name': room.tenantName,
        'rent_amount': room.rentAmount,
        'status_text': room.statusText,
        'updated_at': now,
        'is_synced': 0,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    await _recalculateProperty(propertyId);
  }

  Future<void> vacateRoom(String propertyId, String roomCode) async {
    final db = await database;
    final now = DateTime.now().millisecondsSinceEpoch;

    await db.update(
      'rooms',
      {
        'status': 'vacant',
        'tenant_name': null,
        'status_text': null,
        'updated_at': now,
        'is_synced': 0,
      },
      where: 'property_id = ? AND code = ?',
      whereArgs: [propertyId, roomCode],
    );

    await _recalculateProperty(propertyId);
  }

  Future<void> _recalculateProperty(String propertyId) async {
    final db = await database;
    final rooms = await db.query('rooms', where: 'property_id = ?', whereArgs: [propertyId]);

    final total = rooms.length;
    final occupied = rooms.where((r) => r['status'] != 'vacant').length;
    final rev = rooms
        .where((r) => r['status'] != 'vacant')
        .fold(0, (sum, r) => sum + ((r['rent_amount'] as int?) ?? 0));

    await db.update(
      'properties',
      {
        'total_units': total,
        'occupied_units': occupied,
        'monthly_revenue': rev,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
        'is_synced': 0,
      },
      where: 'id = ?',
      whereArgs: [propertyId],
    );
  }

  // ----------------------------------------------------
  // TENANTS CRUD
  // ----------------------------------------------------
  Future<List<TenantBill>> getTenants() async {
    final db = await database;
    final maps = await db.query('tenants', orderBy: 'name ASC');

    return maps.map((t) {
      return TenantBill(
        id: t['id'] as String,
        name: t['name'] as String,
        initials: t['initials'] as String,
        location: t['location'] as String,
        amount: t['amount'] as int,
        statusText: t['status_text'] as String,
        isOverdue: (t['is_overdue'] as int) == 1,
        isPaid: (t['is_paid'] as int) == 1,
      );
    }).toList();
  }

  Future<void> insertTenant(TenantBill tenant) async {
    final db = await database;
    final now = DateTime.now().millisecondsSinceEpoch;

    await db.insert(
      'tenants',
      {
        'id': tenant.id,
        'name': tenant.name,
        'initials': tenant.initials,
        'location': tenant.location,
        'amount': tenant.amount,
        'status_text': tenant.statusText,
        'is_overdue': tenant.isOverdue ? 1 : 0,
        'is_paid': tenant.isPaid ? 1 : 0,
        'updated_at': now,
        'is_synced': 0,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateTenant(TenantBill tenant) async {
    final db = await database;
    final now = DateTime.now().millisecondsSinceEpoch;

    await db.update(
      'tenants',
      {
        'name': tenant.name,
        'initials': tenant.initials,
        'location': tenant.location,
        'amount': tenant.amount,
        'status_text': tenant.statusText,
        'is_overdue': tenant.isOverdue ? 1 : 0,
        'is_paid': tenant.isPaid ? 1 : 0,
        'updated_at': now,
        'is_synced': 0,
      },
      where: 'id = ?',
      whereArgs: [tenant.id],
    );
  }

  Future<void> deleteTenant(String id) async {
    final db = await database;
    await db.delete('tenants', where: 'id = ?', whereArgs: [id]);
  }

  // ----------------------------------------------------
  // PAYMENTS CRUD
  // ----------------------------------------------------
  Future<List<PaymentRecord>> getPayments() async {
    final db = await database;
    final maps = await db.query('payments', orderBy: 'created_at DESC');

    return maps.map((p) {
      return PaymentRecord(
        id: p['id'] as String,
        tenantName: p['tenant_name'] as String,
        location: p['location'] as String,
        amount: p['amount'] as int,
        method: p['method'] as String,
        dateFormatted: p['date_formatted'] as String,
        referenceNo: p['reference_no'] as String?,
        cashImageName: p['cash_image_name'] as String?,
      );
    }).toList();
  }

  Future<void> recordPayment({
    required PaymentRecord payment,
    required TenantBill updatedTenant,
  }) async {
    final db = await database;
    final now = DateTime.now().millisecondsSinceEpoch;

    await db.transaction((txn) async {
      await txn.insert('payments', {
        'id': payment.id,
        'tenant_name': payment.tenantName,
        'location': payment.location,
        'amount': payment.amount,
        'method': payment.method,
        'date_formatted': payment.dateFormatted,
        'reference_no': payment.referenceNo,
        'cash_image_name': payment.cashImageName,
        'created_at': now,
        'is_synced': 0,
      });

      await txn.update(
        'tenants',
        {
          'name': updatedTenant.name,
          'initials': updatedTenant.initials,
          'location': updatedTenant.location,
          'amount': updatedTenant.amount,
          'status_text': updatedTenant.statusText,
          'is_overdue': updatedTenant.isOverdue ? 1 : 0,
          'is_paid': updatedTenant.isPaid ? 1 : 0,
          'updated_at': now,
          'is_synced': 0,
        },
        where: 'id = ?',
        whereArgs: [updatedTenant.id],
      );
    });
  }

  Future<void> insertPayment(PaymentRecord payment) async {
    final db = await database;
    final now = DateTime.now().millisecondsSinceEpoch;

    await db.insert('payments', {
      'id': payment.id,
      'tenant_name': payment.tenantName,
      'location': payment.location,
      'amount': payment.amount,
      'method': payment.method,
      'date_formatted': payment.dateFormatted,
      'reference_no': payment.referenceNo,
      'cash_image_name': payment.cashImageName,
      'created_at': now,
      'is_synced': 0,
    });
  }

  // ----------------------------------------------------
  // SYNC ENGINE HELPERS (For Firebase)
  // ----------------------------------------------------
  Future<List<Map<String, dynamic>>> getUnsynced(String table) async {
    final db = await database;
    return await db.query(table, where: 'is_synced = ?', whereArgs: [0]);
  }

  Future<void> markSynced(String table, String id) async {
    final db = await database;
    await db.update(
      table,
      {'is_synced': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
