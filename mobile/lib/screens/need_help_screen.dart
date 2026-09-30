import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:uuid/uuid.dart';

import '../models/help_report.dart';
import '../services/offline_store.dart';

class NeedHelpScreen extends StatefulWidget {
  const NeedHelpScreen({super.key});

  @override
  State<NeedHelpScreen> createState() =>
      _NeedHelpScreenState();
}

class _NeedHelpScreenState
    extends State<NeedHelpScreen> {
  final OfflineStore _store = OfflineStore();

  final TextEditingController
      _descriptionController =
      TextEditingController();

  HelpType _type = HelpType.flood;
  HelpSeverity _severity = HelpSeverity.high;

  Position? _position;

  bool _loadingLocation = true;
  bool _saving = false;

  String _locationStatus =
      'Getting current location...';

  @override
  void initState() {
    super.initState();
    _getLocation();
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _getLocation() async {
    try {
      final serviceEnabled =
          await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        if (!mounted) return;

        setState(() {
          _loadingLocation = false;
          _locationStatus =
              'Location services are disabled.';
        });

        return;
      }

      var permission =
          await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission =
            await Geolocator.requestPermission();
      }

      if (permission ==
              LocationPermission.denied ||
          permission ==
              LocationPermission.deniedForever) {
        if (!mounted) return;

        setState(() {
          _loadingLocation = false;
          _locationStatus =
              'Location permission unavailable. '
              'Report can still be saved without GPS.';
        });

        return;
      }

      final position =
          await Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      if (!mounted) return;

      setState(() {
        _position = position;
        _loadingLocation = false;
        _locationStatus =
            'GPS accuracy: '
            '${position.accuracy.round()} m';
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _loadingLocation = false;
        _locationStatus =
            'GPS unavailable. '
            'Report can still be saved locally.';
      });
    }
  }

  Future<void> _submitReport() async {
    if (_saving) return;

    setState(() {
      _saving = true;
    });

    try {
      final report = HelpReport(
        id: const Uuid().v4(),
        createdAt: DateTime.now().toUtc(),
        latitude: _position?.latitude,
        longitude: _position?.longitude,
        accuracyM: _position?.accuracy,
        type: _type,
        severity: _severity,
        description:
            _descriptionController.text.trim(),
        status: HelpReportStatus.pending,
      );

      await _store.queueReport(report);

      if (!mounted) return;

      setState(() {
        _saving = false;
      });

      await showDialog<void>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text(
              'Help request saved',
            ),
            content: const Text(
              'Your report is stored on this device '
              'and marked PENDING. It will be '
              'synchronized when the connection '
              'service is implemented.',
            ),
            actions: [
              FilledButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('OK'),
              ),
            ],
          );
        },
      );

      if (!mounted) return;

      Navigator.pop(context);
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _saving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not save report: $error',
          ),
        ),
      );
    }
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: 8,
      ),
      child: Text(
        title,
        style: Theme.of(context)
            .textTheme
            .titleMedium
            ?.copyWith(
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Need Help'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Card(
              child: Padding(
                padding:
                    const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _loadingLocation
                                ? 'Getting GPS...'
                                : _locationStatus,
                          ),
                        ),
                      ],
                    ),
                    if (_position != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Location: '
                        '${_position!.latitude.toStringAsFixed(6)}, '
                        '${_position!.longitude.toStringAsFixed(6)}',
                        style: const TextStyle(
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            _sectionTitle('What is happening?'),

            Card(
              child: Padding(
                padding:
                    const EdgeInsets.all(8),
                child: RadioGroup<HelpType>(
                  groupValue: _type,
                  onChanged: (value) {
                    if (value == null) {
                      return;
                    }

                    setState(() {
                      _type = value;
                    });
                  },
                  child: Column(
                    children: HelpType.values
                        .map(
                          (type) =>
                              RadioListTile<HelpType>(
                            value: type,
                            title: Text(
                              type.label,
                            ),
                            secondary: Icon(
                              _iconForType(type),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            _sectionTitle('Severity'),

            Card(
              child: Padding(
                padding:
                    const EdgeInsets.all(8),
                child:
                    RadioGroup<HelpSeverity>(
                  groupValue: _severity,
                  onChanged: (value) {
                    if (value == null) {
                      return;
                    }

                    setState(() {
                      _severity = value;
                    });
                  },
                  child: Column(
                    children: HelpSeverity.values
                        .map(
                          (severity) =>
                              RadioListTile<
                                  HelpSeverity>(
                            value: severity,
                            title: Text(
                              severity.label,
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            _sectionTitle(
              'Additional information',
            ),

            TextField(
              controller:
                  _descriptionController,
              maxLines: 4,
              maxLength: 500,
              decoration: const InputDecoration(
                border:
                    OutlineInputBorder(),
                hintText:
                    'Describe what you need...',
              ),
            ),

            const SizedBox(height: 20),

            FilledButton.icon(
              onPressed:
                  _saving ? null : _submitReport,
              icon: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child:
                          CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.sos),
              label: Text(
                _saving
                    ? 'Saving...'
                    : 'Save Help Request',
              ),
              style: FilledButton.styleFrom(
                minimumSize:
                    const Size.fromHeight(56),
              ),
            ),

            const SizedBox(height: 12),

            const Text(
              'Offline mode: the report is stored '
              'on this device until synchronization '
              'is available.',
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

  IconData _iconForType(HelpType type) {
    switch (type) {
      case HelpType.flood:
        return Icons.water;
      case HelpType.trapped:
        return Icons.lock;
      case HelpType.medical:
        return Icons.medical_services;
      case HelpType.fire:
        return Icons.local_fire_department;
      case HelpType.roadBlocked:
        return Icons.block;
      case HelpType.other:
        return Icons.help_outline;
    }
  }
}