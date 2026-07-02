import 'package:flutter/material.dart';

class SummaryMiniCard extends StatelessWidget {
  final IconData icon;
  final String count;
  final String label;
  final Color color;

  const SummaryMiniCard({
    super.key, 
    required this.icon, 
    required this.count, 
    required this.label, 
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CircleAvatar(
          radius: 36,
          backgroundColor: color.withValues(alpha: 0.1),
          child: Icon(icon, color: color, size: 28),
        ),
        const SizedBox(height: 6),
        Text(
          count, 
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
        ),
        const SizedBox(height: 2),
        Text(
          label, 
          style: TextStyle(fontSize: 15, color: Colors.grey.shade600, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}