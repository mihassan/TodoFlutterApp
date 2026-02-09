import 'package:flutter/material.dart';

/// Placeholder settings screen.
///
/// Will be replaced with profile info, sign out, theme toggle in Phase 12.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: const [
          ListTile(
            leading: Icon(Icons.person_outline),
            title: Text('Profile'),
            subtitle: Text('Coming soon'),
          ),
          ListTile(
            leading: Icon(Icons.palette_outlined),
            title: Text('Theme'),
            subtitle: Text('Coming soon'),
          ),
          ListTile(
            leading: Icon(Icons.logout),
            title: Text('Sign out'),
            subtitle: Text('Coming soon'),
          ),
        ],
      ),
    );
  }
}
