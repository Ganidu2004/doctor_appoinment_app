import 'package:flutter/material.dart';

class StatCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final String sub;
  final Color iconColor;

  const StatCard({
    super.key, 
    required this.icon, 
    required this.title, 
    required this.value, 
    required this.sub, 
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: iconColor, size: 32),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value, 
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 2),
              Text(
                title, 
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          if (sub.isNotEmpty) 
            Text(
              sub, 
              style: const TextStyle(fontSize: 12, color: Colors.green, fontWeight: FontWeight.bold),
            )
          else
            const SizedBox(height: 14), 
        ],
      ),
    );
  }
}