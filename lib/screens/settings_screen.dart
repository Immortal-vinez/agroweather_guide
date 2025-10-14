import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: const Color(0xFF4CAF50),
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ListTile(
            leading: const Icon(Icons.person, color: Color(0xFF4CAF50)),
            title: const Text('Profile'),
            subtitle: const Text('Manage your profile information'),
            onTap: () {},
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.notifications, color: Color(0xFF4CAF50)),
            title: const Text('Notifications'),
            subtitle: const Text('Notification preferences'),
            onTap: () {},
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.palette, color: Color(0xFF4CAF50)),
            title: const Text('Theme'),
            subtitle: const Text('Light/Dark mode'),
            onTap: () {},
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.info, color: Color(0xFF4CAF50)),
            title: const Text('About'),
            subtitle: const Text('App information'),
            onTap: () {},
          ),
        ],
      ),
    );
  }
}
