import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class PatientChatPage extends StatefulWidget {
  const PatientChatPage({super.key});

  @override
  State<PatientChatPage> createState() => _PatientChatPageState();
}

class _PatientChatPageState extends State<PatientChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final user = FirebaseAuth.instance.currentUser;
  String _patientName = "Patient";
  String _patientEmail = "";
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchPatientInfo();
  }

  Future<void> _fetchPatientInfo() async {
    if (user == null) return;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('patients')
          .doc(user!.uid)
          .get();

      if (doc.exists && doc.data() != null) {
        final data = doc.data() as Map<String, dynamic>;
        setState(() {
          _patientName = data['name'] ?? "Patient";
          _patientEmail = data['email'] ?? user!.email ?? "";
          _isLoading = false;
        });
      } else {
        setState(() {
          _patientEmail = user!.email ?? "";
          _isLoading = false;
        });
      }

      // Mark messages as read by patient when entering chat
      await _markAsRead();
    } catch (e) {
      debugPrint("Error fetching patient info: $e");
      setState(() => _isLoading = false);
    }
  }

  Future<void> _markAsRead() async {
    if (user == null) return;
    try {
      await FirebaseFirestore.instance
          .collection('support_chats')
          .doc(user!.uid)
          .update({'unreadByPatient': false});
    } catch (_) {}
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || user == null) return;

    _messageController.clear();

    final chatRef = FirebaseFirestore.instance
        .collection('support_chats')
        .doc(user!.uid);

    final messageData = {
      'senderId': user!.uid,
      'senderName': _patientName,
      'text': text,
      'timestamp': FieldValue.serverTimestamp(),
    };

    final roomData = {
      'patientUid': user!.uid,
      'patientName': _patientName,
      'patientEmail': _patientEmail,
      'lastMessage': text,
      'lastMessageTime': FieldValue.serverTimestamp(),
      'unreadByAdmin': true,
      'unreadByPatient': false,
    };

    // Use a batch to write message and update/set room metadata
    final batch = FirebaseFirestore.instance.batch();
    batch.set(chatRef, roomData, SetOptions(merge: true));
    batch.set(chatRef.collection('messages').doc(), messageData);

    try {
      await batch.commit();
      _scrollToBottom();
    } catch (e) {
      debugPrint("Error sending message: $e");
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0.0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  String _formatTime(Timestamp? timestamp) {
    if (timestamp == null) return '';
    final date = timestamp.toDate();
    return DateFormat('hh:mm a').format(date);
  }

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text("Please sign in to access support chat.")),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: Colors.black),
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.blue.shade50,
              child: const Icon(Icons.support_agent, color: Colors.blue),
            ),
            const SizedBox(width: 12),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Live Helper',
                  style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text(
                  'Active Support Agent',
                  style: TextStyle(color: Colors.green, fontSize: 11, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('support_chats')
                        .doc(user!.uid)
                        .collection('messages')
                        .orderBy('timestamp', descending: true)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      // Mark messages as read by patient when new message arrives
                      if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                        _markAsRead();
                      }

                      final messages = snapshot.data?.docs ?? [];

                      if (messages.isEmpty) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey.shade300),
                                const SizedBox(height: 16),
                                const Text(
                                  'Start a Conversation',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Ask us anything about your appointments or account. An agent will respond in real time.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Colors.grey, fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      return ListView.builder(
                        controller: _scrollController,
                        reverse: true,
                        padding: const EdgeInsets.all(16),
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          final msg = messages[index];
                          final data = msg.data() as Map<String, dynamic>;
                          final senderId = data['senderId'] ?? '';
                          final isMe = senderId == user!.uid;
                          final text = data['text'] ?? '';
                          final timestamp = data['timestamp'] as Timestamp?;

                          return Align(
                            alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                            child: Container(
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              constraints: BoxConstraints(
                                maxWidth: MediaQuery.of(context).size.width * 0.75,
                              ),
                              decoration: BoxDecoration(
                                color: isMe ? const Color(0xFF2563EB) : Colors.white,
                                borderRadius: BorderRadius.only(
                                  topLeft: const Radius.circular(16),
                                  topRight: const Radius.circular(16),
                                  bottomLeft: isMe ? const Radius.circular(16) : Radius.zero,
                                  bottomRight: isMe ? Radius.zero : const Radius.circular(16),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.02),
                                    blurRadius: 5,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    text,
                                    style: TextStyle(
                                      color: isMe ? Colors.white : Colors.black87,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _formatTime(timestamp),
                                    style: TextStyle(
                                      color: isMe ? Colors.white.withValues(alpha: 0.6) : Colors.grey,
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  color: Colors.white,
                  child: SafeArea(
                    child: Row(
                      children: [
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(24),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: TextField(
                              controller: _messageController,
                              textCapitalization: TextCapitalization.sentences,
                              decoration: const InputDecoration(
                                hintText: 'Type a message...',
                                border: InputBorder.none,
                              ),
                              maxLines: null,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: _sendMessage,
                          child: Container(
                            height: 44,
                            width: 44,
                            decoration: const BoxDecoration(
                              color: Color(0xFF2563EB),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.send, color: Colors.white, size: 20),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
