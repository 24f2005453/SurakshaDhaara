import 'package:flutter/material.dart';

import '../services/offline_store.dart';
import '../services/report_sync_service.dart';

class SyncReportsScreen extends StatefulWidget {
  const SyncReportsScreen({super.key});

  @override
  State<SyncReportsScreen> createState() =>
      _SyncReportsScreenState();
}

class _SyncReportsScreenState
    extends State<SyncReportsScreen> {
  final OfflineStore _store = OfflineStore();

  late final ReportSyncService _syncService;

  bool _syncing = false;

  int _pendingCount = 0;

  @override
  void initState() {
    super.initState();

    _syncService = ReportSyncService();

    _loadCount();
  }

  @override
  void dispose() {
    _syncService.dispose();
    super.dispose();
  }

  Future<void> _loadCount() async {
    final count =
        await _store.getPendingReportCount();

    if (!mounted) return;

    setState(() {
      _pendingCount = count;
    });
  }

  Future<void> _sync() async {
  if (_syncing) return;

  setState(() {
    _syncing = true;
  });

  try {
    final result =
        await _syncService.syncPendingReports();

    await _loadCount();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Attempted: ${result.attempted} • '
            'Synced: ${result.synced} • '
            'Failed: ${result.failed}',
          ),
        ),
      );
    }
  } catch (error) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Synchronization error: $error',
          ),
        ),
      );
    }
  }

  if (!mounted) return;

  setState(() {
    _syncing = false;
  });
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Report Sync'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding:
                    const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const Icon(
                      Icons.cloud_upload,
                      size: 48,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Reports awaiting sync',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$_pendingCount',
                      style: Theme.of(context)
                          .textTheme
                          .displaySmall,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed:
                  _syncing ? null : _sync,
              icon: _syncing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child:
                          CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(
                      Icons.sync,
                    ),
              label: Text(
                _syncing
                    ? 'Synchronizing...'
                    : 'Synchronize now',
              ),
              style: FilledButton.styleFrom(
                minimumSize:
                    const Size.fromHeight(56),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Reports remain stored locally. '
              'A failed synchronization does not '
              'delete the emergency report.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}