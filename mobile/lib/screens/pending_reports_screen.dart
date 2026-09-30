import 'package:flutter/material.dart';

import '../services/offline_store.dart';

class PendingReportsScreen extends StatefulWidget {
  const PendingReportsScreen({super.key});

  @override
  State<PendingReportsScreen> createState() =>
      _PendingReportsScreenState();
}

class _PendingReportsScreenState
    extends State<PendingReportsScreen> {
  final OfflineStore _store = OfflineStore();

  List<Map<String, dynamic>> _reports = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  Future<void> _loadReports() async {
    try {
      final reports =
          await _store.getPendingReports();

      if (!mounted) return;

      setState(() {
        _reports = reports;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _loading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not load reports: $error',
          ),
        ),
      );
    }
  }

  String _formatDate(String value) {
    final date = DateTime.tryParse(value);

    if (date == null) {
      return value;
    }

    return date.toLocal().toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pending Reports'),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : RefreshIndicator(
              onRefresh: _loadReports,
              child: _reports.isEmpty
                  ? ListView(
                      children: const [
                        SizedBox(height: 120),
                        Center(
                          child: Text(
                            'No pending reports.',
                          ),
                        ),
                      ],
                    )
                  : ListView.builder(
                      padding:
                          const EdgeInsets.all(16),
                      itemCount: _reports.length,
                      itemBuilder:
                          (context, index) {
                        final report =
                            _reports[index];

                        final latitude =
                            report['latitude'];

                        final longitude =
                            report['longitude'];

                        final accuracy =
                            report['accuracy_m'];

                        return Card(
                          margin:
                              const EdgeInsets.only(
                            bottom: 12,
                          ),
                          child: Padding(
                            padding:
                                const EdgeInsets.all(
                              16,
                            ),
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment
                                      .start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.sos,
                                    ),
                                    const SizedBox(
                                      width: 8,
                                    ),
                                    Expanded(
                                      child: Text(
                                        '${report['type']} • '
                                        '${report['severity']}',
                                        style:
                                            const TextStyle(
                                          fontWeight:
                                              FontWeight
                                                  .bold,
                                          fontSize: 17,
                                        ),
                                      ),
                                    ),
                                    Chip(
                                      label: Text(
                                        report[
                                            'status'],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(
                                  height: 12,
                                ),
                                Text(
                                  'ID: ${report['id']}',
                                  style:
                                      const TextStyle(
                                    fontSize: 11,
                                  ),
                                ),
                                const SizedBox(
                                  height: 6,
                                ),
                                if (latitude != null &&
                                    longitude !=
                                        null)
                                  Text(
                                    'Location: '
                                    '${(latitude as num).toDouble().toStringAsFixed(6)}, '
                                    '${(longitude as num).toDouble().toStringAsFixed(6)}',
                                  ),
                                if (accuracy !=
                                    null)
                                  Text(
                                    'Accuracy: '
                                    '${(accuracy as num).toDouble().round()} m',
                                  ),
                                const SizedBox(
                                  height: 6,
                                ),
                                Text(
                                  'Created: '
                                  '${_formatDate(report['created_at'] as String)}',
                                ),
                                if ((report['description']
                                        as String)
                                    .isNotEmpty) ...[
                                  const SizedBox(
                                    height: 8,
                                  ),
                                  Text(
                                    report[
                                        'description'],
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}