import 'package:flutter/material.dart';
import 'patient_chat_page.dart';

class PatientSupportPage extends StatelessWidget {
  final bool showAppBar;
  const PatientSupportPage({super.key, this.showAppBar = false});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: showAppBar
          ? AppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              iconTheme: const IconThemeData(color: Colors.black),
              title: const Text('Support', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
              centerTitle: true,
              )
          : null,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('How can we help?', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text('Reach our support team for appointment issues, account help, or general assistance.', style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 20),
              _SupportCard(
                icon: Icons.phone,
                title: 'Call Support',
                subtitle: 'Speak to a care coordinator on weekdays from 8:00 AM to 8:00 PM.',
                actionLabel: '+94 11 234 5678',
                onTap: () {},
              ),
              const SizedBox(height: 12),
              _SupportCard(
                icon: Icons.email_outlined,
                title: 'Email Us',
                subtitle: 'Send your request and we will follow up within one business day.',
                actionLabel: 'support@appointmentapp.com',
                onTap: () {},
              ),
              const SizedBox(height: 12),
              _SupportCard(
                icon: Icons.chat_bubble_outline,
                title: 'Live Help',
                subtitle: 'Use our in-app chat for immediate assistance with bookings and updates.',
                actionLabel: 'Start chat',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const PatientChatPage(),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SupportCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String actionLabel;
  final VoidCallback onTap;

  const _SupportCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.blue.shade50,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: Colors.blue.shade100,
              child: Icon(icon, color: Colors.blue),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 13)),
                ],
              ),
            ),
            TextButton(onPressed: onTap, child: Text(actionLabel)),
          ],
        ),
      ),
    );
  }
}
