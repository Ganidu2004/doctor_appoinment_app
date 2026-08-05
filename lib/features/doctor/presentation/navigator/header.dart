import 'package:appoinment_app/features/patient/presentation/screens/notifications_page.dart';
import 'package:appoinment_app/shared/widgets/doc_time_logo.dart';
import 'package:appoinment_app/core/theme_controller.dart';
import 'package:flutter/material.dart';

class CustomHeader extends StatelessWidget implements PreferredSizeWidget {
  final String title;

  const CustomHeader({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppBar(
      backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
      elevation: isDark ? 0 : 0.5,
      automaticallyImplyLeading: false,
      titleSpacing: 16,
      title: Row(
        children: [
          const DocTimeLogo(
            variant: DocTimeLogoVariant.horizontal,
            iconSize: 28,
            fontSize: 16,
          ),
          const SizedBox(width: 8),
          Container(
            height: 16,
            width: 1,
            color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: isDark ? Colors.white : const Color(0xFF0F172A),
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      actions: [
        ValueListenableBuilder<ThemeMode>(
          valueListenable: ThemeController.instance,
          builder: (context, mode, _) {
            final isDarkTheme = mode == ThemeMode.dark;
            return GestureDetector(
              onTap: () {
                ThemeController.instance.toggleTheme();
              },
              child: Container(
                margin: const EdgeInsets.only(right: 8, top: 8, bottom: 8),
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: isDarkTheme ? const Color(0xFF1E293B) : const Color(0xFFF0F9FF),
                  shape: BoxShape.circle,
                  border: Border.all(color: isDarkTheme ? const Color(0xFF334155) : const Color(0xFFBAE6FD)),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0EA5E9).withValues(alpha: isDarkTheme ? 0.25 : 0.15),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  isDarkTheme ? Icons.wb_sunny_rounded : Icons.dark_mode_rounded,
                  color: isDarkTheme ? Colors.amber : const Color(0xFF0EA5E9),
                  size: 20,
                ),
              ),
            );
          },
        ),
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const NotificationsPage()),
            );
          },
          child: Container(
            margin: const EdgeInsets.only(right: 16, top: 8, bottom: 8),
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF0F9FF),
              shape: BoxShape.circle,
              border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFBAE6FD)),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0EA5E9).withValues(alpha: isDark ? 0.25 : 0.15),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(
                  Icons.notifications_none_rounded,
                  color: Color(0xFF0EA5E9),
                  size: 22,
                ),
                Positioned(
                  right: -2,
                  top: -2,
                  child: Container(
                    width: 9,
                    height: 9,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444),
                      shape: BoxShape.circle,
                      border: Border.all(color: isDark ? const Color(0xFF1E293B) : Colors.white, width: 1.5),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
