import 'package:flutter/material.dart';
import 'screens/pending_reports_screen.dart';
import 'screens/sync_reports_screen.dart';

import 'screens/need_help_screen.dart';
import 'screens/offline_map_screen.dart';

void main() {
  runApp(const UrbanGuardApp());
}

class UrbanGuardApp extends StatelessWidget {
  const UrbanGuardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'UrbanGuard',
      theme: ThemeData(
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('UrbanGuard'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Card(
            child: ListTile(
              title: const Text('Current risk'),
              subtitle: const Text('NORMAL'),
              leading: const Icon(Icons.shield),
            ),
          ),

          const SizedBox(height: 12),

          FilledButton.icon(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) =>
                      const OfflineMapScreen(),
                ),
              );
            },
            icon: const Icon(Icons.map),
            label: const Text(
              'Open offline map',
            ),
          ),

          FilledButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.route),
            label: const Text(
              'Find safe shelter',
            ),
          ),

          FilledButton.icon(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) =>
                      const NeedHelpScreen(),
                ),
              );
            },
            icon: const Icon(Icons.sos),
            label: const Text('Need help'),
          ),
          OutlinedButton.icon(
  onPressed: () {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            const PendingReportsScreen(),
      ),
    );
  },
  icon: const Icon(Icons.pending_actions),
  label: const Text('Pending reports'),
),
          OutlinedButton.icon(
            onPressed: () {},
            icon: const Icon(
              Icons.check_circle,
            ),
            label: const Text('I am safe'),
          ),
          OutlinedButton.icon(
  onPressed: () {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            const SyncReportsScreen(),
      ),
    );
  },
  icon: const Icon(Icons.sync),
  label: const Text('Sync reports'),
),
        ],
      ),
    );
  }
}