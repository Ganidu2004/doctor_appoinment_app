import 'package:flutter/material.dart';

class DoctorNotificationsPage extends StatelessWidget {
  const DoctorNotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
      ),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Text(
            'No new notifications yet. Notifications for doctor profile updates, appointment changes, and important alerts will appear here.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ),
      ),
    );
  }
}
