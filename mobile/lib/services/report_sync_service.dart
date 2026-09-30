import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/help_report.dart';
import 'offline_store.dart';

class ReportSyncService {
  final OfflineStore _store;

  /// Android emulator reaches the development computer
  /// through 10.0.2.2.
  final String baseUrl;

  final http.Client _client;

  ReportSyncService({
    OfflineStore? store,
    this.baseUrl = 'http://10.0.2.2:8000',
    http.Client? client,
  })  : _store = store ?? OfflineStore(),
        _client = client ?? http.Client();

  Future<SyncResult> syncPendingReports() async {
    final reports =
        await _store.getPendingReports();

    var synced = 0;
    var failed = 0;

    for (final row in reports) {
      final id = row['id'] as String;

      await _store.updateReportStatus(
        id,
        HelpReportStatus.syncing,
      );

      try {
        final payload = <String, dynamic>{
          'reportId': row['id'],
          'type': row['type'],
          'priority': row['severity'],
          'latitude': row['latitude'],
          'longitude': row['longitude'],
          'accuracyM': row['accuracy_m'],
          'peopleCount': 1,
          'needs': <String>[],
          'message': row['description'],
          'createdAt': row['created_at'],
          'status': 'OPEN',
        };

        final response = await _client.post(
          Uri.parse(
            '$baseUrl/api/v1/help-requests',
          ),
          headers: {
            'Content-Type': 'application/json',
            'Idempotency-Key': id,
          },
          body: jsonEncode(payload),
        );

        if (response.statusCode >= 200 &&
            response.statusCode < 300) {
          await _store.updateReportStatus(
            id,
            HelpReportStatus.synced,
          );

          synced++;
        } else {
          await _store.updateReportStatus(
            id,
            HelpReportStatus.syncFailed,
          );

          failed++;
        }
      } catch (_) {
        await _store.updateReportStatus(
          id,
          HelpReportStatus.syncFailed,
        );

        failed++;
      }
    }

    return SyncResult(
      attempted: reports.length,
      synced: synced,
      failed: failed,
    );
  }

  void dispose() {
    _client.close();
  }
}

class SyncResult {
  final int attempted;
  final int synced;
  final int failed;

  const SyncResult({
    required this.attempted,
    required this.synced,
    required this.failed,
  });
}