import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:io' show Platform;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../models/worker_model.dart';
import '../models/washing_service_model.dart';
import '../models/type_washing_service_model.dart';
import '../models/liquidation_model.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    // Initialize FFI for desktop platforms
    if (Platform.isLinux || Platform.isWindows || Platform.isMacOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, 'lavadero_motos.db');

    return await openDatabase(
      path,
      version: 4,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onConfigure: _onConfigure,
    );
  }

  Future<void> _onConfigure(Database db) async {
    // Enable foreign keys
    await db.execute('PRAGMA foreign_keys = ON');
  }

  Future<void> _onCreate(Database db, int version) async {
    // Workers table
    await db.execute('''
      CREATE TABLE workers (
        id_worker INTEGER PRIMARY KEY,
        nickname TEXT NOT NULL,
        price_worker REAL NOT NULL,
        state INTEGER DEFAULT 1,
        synced INTEGER DEFAULT 1,
        updated_at TEXT
      )
    ''');

    // Type washing services table
    await db.execute('''
      CREATE TABLE type_washing_services (
        id INTEGER PRIMARY KEY,
        detail TEXT NOT NULL,
        price_service REAL NOT NULL,
        synced INTEGER DEFAULT 1,
        updated_at TEXT
      )
    ''');

    // Washing services table
    await db.execute('''
      CREATE TABLE washing_services (
        id_service INTEGER PRIMARY KEY,
        date_service TEXT NOT NULL,
        worker_id INTEGER NOT NULL,
        type_service_id INTEGER NOT NULL,
        synced INTEGER DEFAULT 1,
        updated_at TEXT,
        FOREIGN KEY (worker_id) REFERENCES workers(id_worker) ON UPDATE CASCADE ON DELETE CASCADE,
        FOREIGN KEY (type_service_id) REFERENCES type_washing_services(id) ON UPDATE CASCADE ON DELETE CASCADE
      )
    ''');

    // Liquidations table
    await db.execute('''
      CREATE TABLE liquidations (
        id INTEGER PRIMARY KEY,
        date_liquidation TEXT NOT NULL,
        total_liquidation REAL NOT NULL,
        deductible REAL NOT NULL,
        tip REAL DEFAULT 0.0,
        worker_id INTEGER NOT NULL,
        synced INTEGER DEFAULT 1,
        updated_at TEXT,
        FOREIGN KEY (worker_id) REFERENCES workers(id_worker) ON UPDATE CASCADE ON DELETE CASCADE
      )
    ''');

    // Pending operations table
    await db.execute('''
      CREATE TABLE pending_operations (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        operation_type TEXT NOT NULL,
        entity_type TEXT NOT NULL,
        entity_id INTEGER,
        payload TEXT,
        created_at TEXT NOT NULL,
        retry_count INTEGER DEFAULT 0
      )
    ''');

    // Create indexes for better performance
    await db.execute('CREATE INDEX idx_workers_synced ON workers(synced)');
    await db.execute(
      'CREATE INDEX idx_services_synced ON washing_services(synced)',
    );
    await db.execute(
      'CREATE INDEX idx_types_synced ON type_washing_services(synced)',
    );
    await db.execute(
      'CREATE INDEX idx_liquidations_synced ON liquidations(synced)',
    );
    await db.execute(
      'CREATE INDEX idx_pending_ops_created ON pending_operations(created_at)',
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add liquidations table for version 2
      await db.execute('''
        CREATE TABLE liquidations (
          id INTEGER PRIMARY KEY,
          date_liquidation TEXT NOT NULL,
          total_liquidation REAL NOT NULL,
          deductible REAL NOT NULL,
          tip REAL DEFAULT 0.0,
          worker_id INTEGER NOT NULL,
          synced INTEGER DEFAULT 1,
          updated_at TEXT,
          FOREIGN KEY (worker_id) REFERENCES workers(id_worker) ON UPDATE CASCADE ON DELETE CASCADE
        )
      ''');
      await db.execute(
        'CREATE INDEX idx_liquidations_synced ON liquidations(synced)',
      );
    }
    if (oldVersion < 3) {
      // Add tip column for version 3
      await db.execute(
        'ALTER TABLE liquidations ADD COLUMN tip REAL DEFAULT 0.0',
      );
    }
    if (oldVersion < 4) {
      // Add state column to workers table for version 4
      await db.execute(
        'ALTER TABLE workers ADD COLUMN state INTEGER DEFAULT 1',
      );
    }
  }

  // WORKERS CRUD
  Future<int> insertWorker(Worker worker, {bool synced = true}) async {
    final db = await database;
    return await db.insert('workers', {
      'id_worker': worker.idWorker,
      'nickname': worker.nickname,
      'price_worker': worker.priceWorker,
      'state': worker.state ? 1 : 0,
      'synced': synced ? 1 : 0,
      'updated_at': DateTime.now().toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Worker>> getWorkers() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('workers');

    return List.generate(maps.length, (i) {
      return Worker(
        idWorker: maps[i]['id_worker'] as int,
        nickname: maps[i]['nickname'] as String,
        priceWorker: (maps[i]['price_worker'] as num).toDouble(),
        state: (maps[i]['state'] ?? 1) == 1,
      );
    });
  }

  Future<Worker?> getWorkerById(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'workers',
      where: 'id_worker = ?',
      whereArgs: [id],
    );

    if (maps.isEmpty) return null;

    return Worker(
      idWorker: maps[0]['id_worker'] as int,
      nickname: maps[0]['nickname'] as String,
      priceWorker: (maps[0]['price_worker'] as num).toDouble(),
      state: (maps[0]['state'] ?? 1) == 1,
    );
  }

  Future<int> updateWorker(Worker worker, {bool synced = true}) async {
    final db = await database;
    return await db.update(
      'workers',
      {
        'nickname': worker.nickname,
        'price_worker': worker.priceWorker,
        'state': worker.state ? 1 : 0,
        'synced': synced ? 1 : 0,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id_worker = ?',
      whereArgs: [worker.idWorker],
    );
  }

  // Update Worker ID (for sync)
  Future<void> updateWorkerId(int oldId, int newId) async {
    final db = await database;
    await db.transaction((txn) async {
      // Disable foreign keys temporarily if needed, but ON UPDATE CASCADE should handle it
      // However, SQLite support for ON UPDATE CASCADE needs to be enabled

      // Update the worker ID
      await txn.rawUpdate(
        'UPDATE workers SET id_worker = ? WHERE id_worker = ?',
        [newId, oldId],
      );
    });
  }

  Future<int> deleteWorker(int id) async {
    final db = await database;
    return await db.delete('workers', where: 'id_worker = ?', whereArgs: [id]);
  }

  // TYPE WASHING SERVICES CRUD
  Future<int> insertServiceType(
    TypeWashingService type, {
    bool synced = true,
  }) async {
    final db = await database;
    return await db.insert('type_washing_services', {
      'id': type.id,
      'detail': type.detail,
      'price_service': type.priceService,
      'synced': synced ? 1 : 0,
      'updated_at': DateTime.now().toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<TypeWashingService>> getServiceTypes() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'type_washing_services',
    );

    return List.generate(maps.length, (i) {
      return TypeWashingService(
        id: maps[i]['id'] as int,
        detail: maps[i]['detail'] as String,
        priceService: maps[i]['price_service'] as double,
      );
    });
  }

  Future<TypeWashingService?> getServiceTypeById(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'type_washing_services',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isEmpty) return null;

    return TypeWashingService(
      id: maps[0]['id'] as int,
      detail: maps[0]['detail'] as String,
      priceService: maps[0]['price_service'] as double,
    );
  }

  Future<int> updateServiceType(
    TypeWashingService type, {
    bool synced = true,
  }) async {
    final db = await database;
    return await db.update(
      'type_washing_services',
      {
        'detail': type.detail,
        'price_service': type.priceService,
        'synced': synced ? 1 : 0,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [type.id],
    );
  }

  // Update Service Type ID (for sync)
  Future<void> updateServiceTypeId(int oldId, int newId) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.rawUpdate(
        'UPDATE type_washing_services SET id = ? WHERE id = ?',
        [newId, oldId],
      );
    });
  }

  Future<int> deleteServiceType(int id) async {
    final db = await database;
    return await db.delete(
      'type_washing_services',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // WASHING SERVICES CRUD
  Future<int> insertService(
    WashingService service, {
    bool synced = true,
  }) async {
    final db = await database;
    return await db.insert('washing_services', {
      'id_service': service.idService,
      'date_service': service.dateService.toIso8601String(),
      'worker_id': service.worker.idWorker,
      'type_service_id': service.typeService.id,
      'synced': synced ? 1 : 0,
      'updated_at': DateTime.now().toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<WashingService>> getServices({int? limit, int? offset}) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT 
        ws.id_service,
        ws.date_service,
        w.id_worker,
        w.nickname,
        w.price_worker,
        w.state,
        t.id as type_id,
        t.detail,
        t.price_service
      FROM washing_services ws
      INNER JOIN workers w ON ws.worker_id = w.id_worker
      INNER JOIN type_washing_services t ON ws.type_service_id = t.id
      ORDER BY ws.date_service DESC
      ${limit != null ? 'LIMIT $limit' : ''}
      ${offset != null ? 'OFFSET $offset' : ''}
    ''');

    return List.generate(maps.length, (i) {
      return WashingService(
        idService: maps[i]['id_service'] as int,
        dateService: DateTime.parse(maps[i]['date_service'] as String),
        worker: Worker(
          idWorker: maps[i]['id_worker'] as int,
          nickname: maps[i]['nickname'] as String,
          priceWorker: (maps[i]['price_worker'] as num).toDouble(),
          state: (maps[i]['state'] ?? 1) == 1,
        ),
        typeService: TypeWashingService(
          id: maps[i]['type_id'] as int,
          detail: maps[i]['detail'] as String,
          priceService: (maps[i]['price_service'] as num).toDouble(),
        ),
      );
    });
  }

  Future<WashingService?> getServiceById(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.rawQuery(
      '''
      SELECT 
        ws.id_service,
        ws.date_service,
        w.id_worker,
        w.nickname,
        w.price_worker,
        w.state,
        t.id as type_id,
        t.detail,
        t.price_service
      FROM washing_services ws
      INNER JOIN workers w ON ws.worker_id = w.id_worker
      INNER JOIN type_washing_services t ON ws.type_service_id = t.id
      WHERE ws.id_service = ?
    ''',
      [id],
    );

    if (maps.isEmpty) return null;

    return WashingService(
      idService: maps[0]['id_service'] as int,
      dateService: DateTime.parse(maps[0]['date_service'] as String),
      worker: Worker(
        idWorker: maps[0]['id_worker'] as int,
        nickname: maps[0]['nickname'] as String,
        priceWorker: (maps[0]['price_worker'] as num).toDouble(),
        state: (maps[0]['state'] ?? 1) == 1,
      ),
      typeService: TypeWashingService(
        id: maps[0]['type_id'] as int,
        detail: maps[0]['detail'] as String,
        priceService: (maps[0]['price_service'] as num).toDouble(),
      ),
    );
  }

  Future<int> updateService(
    WashingService service, {
    bool synced = true,
  }) async {
    final db = await database;
    return await db.update(
      'washing_services',
      {
        'date_service': service.dateService.toIso8601String(),
        'worker_id': service.worker.idWorker,
        'type_service_id': service.typeService.id,
        'synced': synced ? 1 : 0,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id_service = ?',
      whereArgs: [service.idService],
    );
  }

  // Update Service ID (for sync)
  Future<void> updateServiceId(int oldId, int newId) async {
    final db = await database;
    await db.rawUpdate(
      'UPDATE washing_services SET id_service = ? WHERE id_service = ?',
      [newId, oldId],
    );
  }

  Future<int> deleteService(int id) async {
    final db = await database;
    return await db.delete(
      'washing_services',
      where: 'id_service = ?',
      whereArgs: [id],
    );
  }

  // LIQUIDATIONS CRUD
  Future<int> insertLiquidation(
    Liquidation liquidation, {
    bool synced = true,
  }) async {
    final db = await database;
    return await db.insert('liquidations', {
      'id': liquidation.id,
      'date_liquidation': liquidation.dateLiquidation
          .toIso8601String()
          .split('T')
          .first,
      'total_liquidation': liquidation.totalLiquidation,
      'deductible': liquidation.deductible,
      'tip': liquidation.tip,
      'worker_id': liquidation.worker.idWorker,
      'synced': synced ? 1 : 0,
      'updated_at': DateTime.now().toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Liquidation>> getLiquidations() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT 
        l.id,
        l.date_liquidation,
        l.total_liquidation,
        l.deductible,
        l.tip,
        w.id_worker,
        w.nickname,
        w.price_worker,
        w.state
      FROM liquidations l
      INNER JOIN workers w ON l.worker_id = w.id_worker
      ORDER BY l.date_liquidation DESC
    ''');

    return List.generate(maps.length, (i) {
      return Liquidation(
        id: maps[i]['id'] as int,
        dateLiquidation: DateTime.parse(maps[i]['date_liquidation'] as String),
        totalLiquidation: (maps[i]['total_liquidation'] as num).toDouble(),
        deductible: (maps[i]['deductible'] as num).toDouble(),
        tip: ((maps[i]['tip'] ?? 0.0) as num).toDouble(),
        worker: Worker(
          idWorker: maps[i]['id_worker'] as int,
          nickname: maps[i]['nickname'] as String,
          priceWorker: (maps[i]['price_worker'] as num).toDouble(),
          state: (maps[i]['state'] ?? 1) == 1,
        ),
      );
    });
  }

  Future<List<Liquidation>> getLiquidationsByWorker(int workerId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.rawQuery(
      '''
      SELECT 
        l.id,
        l.date_liquidation,
        l.total_liquidation,
        l.deductible,
        l.tip,
        w.id_worker,
        w.nickname,
        w.price_worker,
        w.state
      FROM liquidations l
      INNER JOIN workers w ON l.worker_id = w.id_worker
      WHERE l.worker_id = ?
      ORDER BY l.date_liquidation DESC
    ''',
      [workerId],
    );

    return List.generate(maps.length, (i) {
      return Liquidation(
        id: maps[i]['id'] as int,
        dateLiquidation: DateTime.parse(maps[i]['date_liquidation'] as String),
        totalLiquidation: (maps[i]['total_liquidation'] as num).toDouble(),
        deductible: (maps[i]['deductible'] as num).toDouble(),
        tip: ((maps[i]['tip'] ?? 0.0) as num).toDouble(),
        worker: Worker(
          idWorker: maps[i]['id_worker'] as int,
          nickname: maps[i]['nickname'] as String,
          priceWorker: (maps[i]['price_worker'] as num).toDouble(),
          state: (maps[i]['state'] ?? 1) == 1,
        ),
      );
    });
  }

  Future<Liquidation?> getLiquidationById(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.rawQuery(
      '''
      SELECT 
        l.id,
        l.date_liquidation,
        l.total_liquidation,
        l.deductible,
        l.tip,
        w.id_worker,
        w.nickname,
        w.price_worker,
        w.state
      FROM liquidations l
      INNER JOIN workers w ON l.worker_id = w.id_worker
      WHERE l.id = ?
    ''',
      [id],
    );

    if (maps.isEmpty) return null;

    return Liquidation(
      id: maps[0]['id'] as int,
      dateLiquidation: DateTime.parse(maps[0]['date_liquidation'] as String),
      totalLiquidation: (maps[0]['total_liquidation'] as num).toDouble(),
      deductible: (maps[0]['deductible'] as num).toDouble(),
      tip: ((maps[0]['tip'] ?? 0.0) as num).toDouble(),
      worker: Worker(
        idWorker: maps[0]['id_worker'] as int,
        nickname: maps[0]['nickname'] as String,
        priceWorker: (maps[0]['price_worker'] as num).toDouble(),
        state: (maps[0]['state'] ?? 1) == 1,
      ),
    );
  }

  Future<int> updateLiquidation(
    Liquidation liquidation, {
    bool synced = true,
  }) async {
    final db = await database;
    return await db.update(
      'liquidations',
      {
        'date_liquidation': liquidation.dateLiquidation
            .toIso8601String()
            .split('T')
            .first,
        'total_liquidation': liquidation.totalLiquidation,
        'deductible': liquidation.deductible,
        'tip': liquidation.tip,
        'worker_id': liquidation.worker.idWorker,
        'synced': synced ? 1 : 0,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [liquidation.id],
    );
  }

  // Update Liquidation ID (for sync)
  Future<void> updateLiquidationId(int oldId, int newId) async {
    final db = await database;
    await db.rawUpdate('UPDATE liquidations SET id = ? WHERE id = ?', [
      newId,
      oldId,
    ]);
  }

  Future<int> deleteLiquidation(int id) async {
    final db = await database;
    return await db.delete('liquidations', where: 'id = ?', whereArgs: [id]);
  }

  // PENDING OPERATIONS
  Future<int> addPendingOperation({
    required String operationType,
    required String entityType,
    int? entityId,
    String? payload,
  }) async {
    final db = await database;
    return await db.insert('pending_operations', {
      'operation_type': operationType,
      'entity_type': entityType,
      'entity_id': entityId,
      'payload': payload,
      'created_at': DateTime.now().toIso8601String(),
      'retry_count': 0,
    });
  }

  Future<List<Map<String, dynamic>>> getPendingOperations() async {
    final db = await database;
    return await db.query('pending_operations', orderBy: 'created_at ASC');
  }

  Future<int> deletePendingOperation(int id) async {
    final db = await database;
    return await db.delete(
      'pending_operations',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> incrementRetryCount(int id) async {
    final db = await database;
    return await db.rawUpdate(
      'UPDATE pending_operations SET retry_count = retry_count + 1 WHERE id = ?',
      [id],
    );
  }

  // UTILITY METHODS
  Future<void> clearAllData() async {
    final db = await database;
    await db.delete('workers');
    await db.delete('type_washing_services');
    await db.delete('washing_services');
    await db.delete('pending_operations');
  }

  Future<int> getUnsyncedCount() async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT 
        (SELECT COUNT(*) FROM workers WHERE synced = 0) +
        (SELECT COUNT(*) FROM type_washing_services WHERE synced = 0) +
        (SELECT COUNT(*) FROM washing_services WHERE synced = 0) +
        (SELECT COUNT(*) FROM liquidations WHERE synced = 0) as total
    ''');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  // DASHBOARD STATS (OFFLINE)
  Future<Map<String, dynamic>> getDashboardStats(DateTime date) async {
    final db = await database;
    final formattedDate =
        "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";

    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT 
        ws.id_service,
        ws.date_service,
        w.price_worker,
        t.detail as type_name,
        t.price_service
      FROM washing_services ws
      INNER JOIN workers w ON ws.worker_id = w.id_worker
      INNER JOIN type_washing_services t ON ws.type_service_id = t.id
      WHERE ws.date_service LIKE ?
    ''', ['$formattedDate%']);

    int totalServices = maps.length;
    double totalRevenue = 0.0;
    final Map<String, int> typeCounts = {};

    for (var row in maps) {
      final workerPrice = (row['price_worker'] as num?)?.toDouble() ?? 0.0;
      final servicePrice = (row['price_service'] as num?)?.toDouble() ?? 0.0;
      totalRevenue += (workerPrice + servicePrice);

      final typeName = row['type_name'] as String? ?? 'Desconocido';
      typeCounts[typeName] = (typeCounts[typeName] ?? 0) + 1;
    }

    final serviceTypeStats = typeCounts.entries.map((entry) {
      return {
        'name': entry.key,
        'count': entry.value,
      };
    }).toList();

    return {
      'totalServices': totalServices,
      'totalRevenue': totalRevenue,
      'serviceTypeStats': serviceTypeStats,
    };
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}
