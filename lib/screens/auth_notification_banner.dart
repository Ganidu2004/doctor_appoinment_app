import 'package:flutter/material.dart';

enum NotificationType { error, success, info }

class AuthNotificationBanner extends StatelessWidget {
  final String message;
  final NotificationType type;

  const AuthNotificationBanner({
    super.key, 
    required this.message, 
    required this.type
  });

  @override
  Widget build(BuildContext context) {
    // Context-aware color profiles matching your design
    Color bgColor;
    Color contentColor;
    IconData icon;

    switch (type) {
      case NotificationType.error:
        bgColor = const Color(0xFFFEF2F2); 
        contentColor = const Color(0xFFEF4444); 
        icon = Icons.error_outline_rounded;
        break;
      case NotificationType.success:
        bgColor = const Color(0xFFF0FDF4); 
        contentColor = const Color(0xFF22C55E); 
        icon = Icons.check_circle_outline_rounded;
        break;
      case NotificationType.info:
        bgColor = const Color(0xFFF0F9FF); 
        contentColor = const Color(0xFF0EA5E9); 
        icon = Icons.info_outline_rounded;
        break;
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      transitionBuilder: (Widget child, Animation<double> animation) {
        return FadeTransition(
          opacity: animation,
          child: SizeTransition(
            sizeFactor: animation,
            alignment: Alignment.topCenter,
            child: child,
          ),
        );
      },
      child: message.isEmpty
          ? const SizedBox.shrink()
          : Container(
              margin: const EdgeInsets.only(bottom: 20),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: contentColor.withValues(alpha: 0.15), width: 1.5),
              ),
              child: Row(
                children: [
                  Icon(icon, color: contentColor, size: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      message,
                      style: TextStyle(
                        color: contentColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
