import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'admin_chat_room_page.dart';

class AdminSupportChatsPage extends StatelessWidget {
  final bool isEmbedded;
  const AdminSupportChatsPage({super.key, this.isEmbedded = false});

  String _formatTime(Timestamp? timestamp) {
    if (timestamp == null) return '';
    final date = timestamp.toDate();
    final now = DateTime.now();
    
    if (date.year == now.year && date.month == now.month && date.day == now.day) {
      return DateFormat('hh:mm a').format(date);
    }
    return DateFormat('MMM dd, yyyy').format(date);
  }

  @override
  Widget build(BuildContext context) {
    final bodyContent = StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('support_chats')
          .orderBy('lastMessageTime', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final chats = snapshot.data?.docs ?? [];

        if (chats.isEmpty) {
          return Builder(
            builder: (context) {
              final isDark = Theme.of(context).brightness == Brightness.dark;
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.chat_outlined, size: 64,
                          color: isDark ? const Color(0xFF334155) : Colors.grey.shade300),
                      const SizedBox(height: 16),
                      Text(
                        'No Active Chats',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Patient support chats will appear here when they send messages.',
                        style: TextStyle(color: isDark ? const Color(0xFF94A3B8) : Colors.grey, fontSize: 13),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: chats.length,
          itemBuilder: (context, index) {
            final doc = chats[index];
            final data = doc.data() as Map<String, dynamic>;
            final patientUid = data['patientUid'] ?? doc.id;
            final patientName = data['patientName'] ?? 'Patient';
            final patientEmail = data['patientEmail'] ?? '';
            final lastMessage = data['lastMessage'] ?? 'No messages yet';
            final lastMessageTime = data['lastMessageTime'] as Timestamp?;
            final unread = data['unreadByAdmin'] ?? false;

            return Builder(
              builder: (context) {
                final isDark = Theme.of(context).brightness == Brightness.dark;
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.02),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                    border: Border.all(
                      color: unread
                          ? const Color(0xFF2563EB).withValues(alpha: 0.4)
                          : (isDark ? const Color(0xFF334155) : Colors.grey.shade100),
                      width: unread ? 1.5 : 1.0,
                    ),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: CircleAvatar(
                      radius: 24,
                      backgroundColor: unread
                          ? (isDark ? const Color(0xFF1E3A8A) : const Color(0xFFEFF6FF))
                          : (isDark ? const Color(0xFF1E293B) : Colors.grey.shade100),
                      child: Icon(
                        Icons.person,
                        color: unread
                            ? const Color(0xFF60A5FA)
                            : (isDark ? const Color(0xFF64748B) : Colors.grey.shade600),
                      ),
                    ),
                    title: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            patientName,
                            style: TextStyle(
                              fontWeight: unread ? FontWeight.bold : FontWeight.w600,
                              fontSize: 15,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          _formatTime(lastMessageTime),
                          style: TextStyle(
                            fontSize: 11,
                            color: unread
                                ? const Color(0xFF60A5FA)
                                : (isDark ? const Color(0xFF64748B) : Colors.grey),
                            fontWeight: unread ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (patientEmail.isNotEmpty)
                                  Text(
                                    patientEmail,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isDark ? const Color(0xFF64748B) : Colors.grey.shade500,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                const SizedBox(height: 2),
                                Text(
                                  lastMessage,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: unread
                                        ? (isDark ? const Color(0xFFE2E8F0) : Colors.black87)
                                        : (isDark ? const Color(0xFF94A3B8) : Colors.grey.shade600),
                                    fontWeight: unread ? FontWeight.w500 : FontWeight.normal,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          if (unread)
                            Container(
                              margin: const EdgeInsets.only(left: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF2563EB),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Text(
                                'NEW',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AdminChatRoomPage(
                            patientUid: patientUid,
                            patientName: patientName,
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            );
          },
        );
      },
    );

    if (isEmbedded) {
      return bodyContent;
    }

    return Builder(
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Scaffold(
          backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
          appBar: AppBar(
            backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
            elevation: 0.5,
            iconTheme: IconThemeData(color: isDark ? Colors.white : Colors.black),
            title: Text(
              'Support Chats',
              style: TextStyle(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.bold),
            ),
          ),
          body: bodyContent,
        );
      },
    );
  }
}
