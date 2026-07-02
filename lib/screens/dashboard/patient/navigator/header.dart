import 'package:appoinment_app/const.dart';
import 'package:flutter/material.dart';

class PatientHeader extends StatelessWidget implements PreferredSizeWidget {
  final String userName;

  const PatientHeader({super.key, required this.userName});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      automaticallyImplyLeading: false,
      titleSpacing: 16,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            child:  const Icon(
              Icons.local_hospital_rounded, 
              size: 64, 
              color: primaryColor
            ),
          ),
          const SizedBox(width: 8),
          const Text(
            'DOC TIME',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.notifications_none, color: Colors.black, size: 26),
          onPressed: () {},
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class PatientGreetingHeader extends StatelessWidget {
  final String name;
  final String profileImageUrl;

  const PatientGreetingHeader({
    super.key, 
    required this.name, 
    required this.profileImageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Hello, $name!',
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black),
                ),
                const SizedBox(width: 6),
                const Text('👋', style: TextStyle(fontSize: 22)),
              ],
            ),
            const SizedBox(height: 4),
            const Text(
              'How are you feeling today?',
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
          ],
        ),
        Stack(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: Colors.grey.shade300,
              child: ClipOval(
                child: profileImageUrl.isNotEmpty
                    ? Image.network(
                        profileImageUrl,
                        width: 48,
                        height: 48,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => 
                            Icon(Icons.person, size: 24, color: Colors.grey.shade600),
                      )
                    : Icon(Icons.person_outline, size: 24, color: Colors.grey.shade600),
              ),
            ),
            Positioned(
              right: 1,
              bottom: 1,
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
              ),
            )
          ],
        )
      ],
    );
  }
}