import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../models/help_report.dart';
import '../models/road.dart';

class OfflineStore {
  Database? _db;

  Future<Database> get db async {
    if (_db != null) return _db!;

    final path = p.join(
      await getDatabasesPath(),
      'urbanguard.db',
    );

    _db = await openDatabase(
      path,
      version: 3,
      onCreate: (database, _) async {
        await _createTables(database);
      },
      onUpgrade: (database, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await _createRoadTables(database);
        }

        if (oldVersion < 3) {
          await _upgradeReportsToVersion3(database);
        }
      },
    );

    return _db!;
  }

  Future<void> _createTables(Database database) async {
    await database.execute('''
      CREATE TABLE shelters(
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        lat REAL NOT NULL,
        lon REAL NOT NULL,
        capacity INTEGER NOT NULL,
        occupancy INTEGER NOT NULL,
        status TEXT NOT NULL
      )
    ''');

    await database.execute('''
      CREATE TABLE hazards(
        id TEXT PRIMARY KEY,
        road_id TEXT,
        severity TEXT,
        active INTEGER
      )
    ''');

    await database.execute('''
      CREATE TABLE reports(
        id TEXT PRIMARY KEY,
        created_at TEXT NOT NULL,
        latitude REAL,
        longitude REAL,
        accuracy_m REAL,
        type TEXT NOT NULL,
        severity TEXT NOT NULL,
        description TEXT NOT NULL,
        status TEXT NOT NULL
      )
    ''');

    await _createRoadTables(database);
  }

  Future<void> _createRoadTables(
    Database database,
  ) async {
    await database.execute('''
      CREATE TABLE IF NOT EXISTS road_nodes(
        id TEXT PRIMARY KEY,
        lat REAL NOT NULL,
        lon REAL NOT NULL
      )
    ''');

    await database.execute('''
      CREATE TABLE IF NOT EXISTS roads(
        id TEXT PRIMARY KEY,
        from_node TEXT NOT NULL,
        to_node TEXT NOT NULL,
        distance_m REAL NOT NULL,
        risk_score REAL NOT NULL,
        blocked INTEGER NOT NULL
      )
    ''');
  }

  Future<void> _upgradeReportsToVersion3(
    Database database,
  ) async {
    final tables = await database.rawQuery('''
      SELECT name
      FROM sqlite_master
      WHERE type = 'table'
        AND name = 'reports'
    ''');

    if (tables.isEmpty) {
      await database.execute('''
        CREATE TABLE reports(
          id TEXT PRIMARY KEY,
          created_at TEXT NOT NULL,
          latitude REAL,
          longitude REAL,
          accuracy_m REAL,
          type TEXT NOT NULL,
          severity TEXT NOT NULL,
          description TEXT NOT NULL,
          status TEXT NOT NULL
        )
      ''');

      return;
    }

    await database.execute('''
      ALTER TABLE reports
      ADD COLUMN created_at TEXT NOT NULL DEFAULT ''
    ''');

    await database.execute('''
      ALTER TABLE reports
      ADD COLUMN latitude REAL
    ''');

    await database.execute('''
      ALTER TABLE reports
      ADD COLUMN longitude REAL
    ''');

    await database.execute('''
      ALTER TABLE reports
      ADD COLUMN accuracy_m REAL
    ''');

    await database.execute('''
      ALTER TABLE reports
      ADD COLUMN type TEXT NOT NULL DEFAULT 'OTHER'
    ''');

    await database.execute('''
      ALTER TABLE reports
      ADD COLUMN severity TEXT NOT NULL DEFAULT 'LOW'
    ''');

    await database.execute('''
      ALTER TABLE reports
      ADD COLUMN description TEXT NOT NULL DEFAULT ''
    ''');

    await database.execute('''
      UPDATE reports
      SET created_at = ?
      WHERE created_at = ''
    ''', [
      DateTime.now().toUtc().toIso8601String(),
    ]);
  }

  Future<void> seedDemoPack() async {
    final raw = await rootBundle.loadString(
      'assets/offline_pack.json',
    );

    final pack =
        jsonDecode(raw) as Map<String, dynamic>;

    final database = await db;

    await database.transaction((txn) async {
      await txn.delete('shelters');
      await txn.delete('hazards');
      await txn.delete('road_nodes');
      await txn.delete('roads');

      final shelters =
          (pack['shelters'] as List<dynamic>? ?? const []);

      for (final item in shelters) {
        final shelter =
            item as Map<String, dynamic>;

        await txn.insert(
          'shelters',
          {
            'id': shelter['id'],
            'name': shelter['name'],
            'lat': shelter['lat'],
            'lon': shelter['lon'],
            'capacity': shelter['capacity'],
            'occupancy': shelter['occupancy'],
            'status': shelter['status'],
          },
          conflictAlgorithm:
              ConflictAlgorithm.replace,
        );
      }

      final nodes =
          (pack['roadNodes'] as List<dynamic>? ?? const []);

      for (final item in nodes) {
        final node =
            item as Map<String, dynamic>;

        await txn.insert(
          'road_nodes',
          {
            'id': node['id'],
            'lat': node['lat'],
            'lon': node['lon'],
          },
          conflictAlgorithm:
              ConflictAlgorithm.replace,
        );
      }

      final roads =
          (pack['roads'] as List<dynamic>? ?? const []);

      for (final item in roads) {
        final road =
            item as Map<String, dynamic>;

        await txn.insert(
          'roads',
          {
            'id': road['id'],
            'from_node': road['from'],
            'to_node': road['to'],
            'distance_m': road['distanceM'],
            'risk_score':
                road['riskScore'] ?? 0,
            'blocked':
                road['blocked'] == true ? 1 : 0,
          },
          conflictAlgorithm:
              ConflictAlgorithm.replace,
        );
      }

      final hazards =
          (pack['hazards'] as List<dynamic>? ?? const []);

      for (final item in hazards) {
        final hazard =
            item as Map<String, dynamic>;

        await txn.insert(
          'hazards',
          {
            'id': hazard['id'],
            'road_id': hazard['road_id'],
            'severity': hazard['severity'],
            'active':
                hazard['active'] == true ? 1 : 0,
          },
        );
      }
    });
  }

  Future<List<Map<String, dynamic>>> getShelters() async {
    final database = await db;

    return database.query(
      'shelters',
      orderBy: 'name ASC',
    );
  }

  Future<AStarData> getRoutingData() async {
    final database = await db;

    final nodeRows =
        await database.query('road_nodes');

    final roadRows =
        await database.query('roads');

    final coordinates =
        <String, ({double lat, double lon})>{};

    for (final row in nodeRows) {
      coordinates[row['id'] as String] = (
        lat: (row['lat'] as num).toDouble(),
        lon: (row['lon'] as num).toDouble(),
      );
    }

    final graph =
        <String, List<RoadEdge>>{};

    for (final row in roadRows) {
      final edge = RoadEdge(
        id: row['id'] as String,
        from: row['from_node'] as String,
        to: row['to_node'] as String,
        distanceM:
            (row['distance_m'] as num).toDouble(),
        riskScore:
            (row['risk_score'] as num).toDouble(),
        blocked:
            (row['blocked'] as num).toInt() == 1,
      );

      graph
          .putIfAbsent(edge.from, () => [])
          .add(edge);
    }

    return AStarData(
      graph: graph,
      coordinates: coordinates,
    );
  }

  Future<void> queueReport(
    HelpReport report,
  ) async {
    final database = await db;

    await database.insert(
      'reports',
      report.toMap(),
      conflictAlgorithm:
          ConflictAlgorithm.ignore,
    );
  }

  /// Returns reports that still need synchronization.
  ///
  /// Both PENDING and SYNC_FAILED are retryable.
  Future<List<Map<String, dynamic>>>
      getPendingReports() async {
    final database = await db;

    return database.query(
      'reports',
      where: 'status IN (?, ?)',
      whereArgs: [
        HelpReportStatus.pending.value,
        HelpReportStatus.syncFailed.value,
      ],
      orderBy: 'created_at ASC',
    );
  }

  /// Returns the number of reports that still need
  /// synchronization.
  ///
  /// SYNC_FAILED is included because it is retryable.
  Future<int> getPendingReportCount() async {
    final database = await db;

    final result = await database.rawQuery('''
      SELECT COUNT(*) AS count
      FROM reports
      WHERE status IN (?, ?)
    ''', [
      HelpReportStatus.pending.value,
      HelpReportStatus.syncFailed.value,
    ]);

    return (result.first['count'] as num).toInt();
  }

  Future<void> updateReportStatus(
    String id,
    HelpReportStatus status,
  ) async {
    final database = await db;

    await database.update(
      'reports',
      {
        'status': status.value,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}

class AStarData {
  final Map<String, List<RoadEdge>> graph;

  final Map<String, ({double lat, double lon})>
      coordinates;

  const AStarData({
    required this.graph,
    required this.coordinates,
  });
}