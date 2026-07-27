import 'package:flutter/material.dart';

class AppointmentCard extends StatelessWidget {
  final String name;
  final String type;
  final String time;
  final String status;
  final String? amount;
  final String? reason;
  final String? imageUrl;
  final VoidCallback? onAccept;
  final VoidCallback? onDecline;
  final VoidCallback? onReceipt;
  final VoidCallback? onRx;
  final VoidCallback? onComplete;

  const AppointmentCard({
    super.key,
    required this.name,
    required this.type,
    required this.time,
    required this.status,
    this.amount,
    this.reason,
    this.imageUrl,
    this.onAccept,
    this.onDecline,
    this.onReceipt,
    this.onRx,
    this.onComplete,
  });

  String _formatName(String rawName) {
    if (rawName.trim().isEmpty) return 'Patient';
    final words = rawName.trim().split(' ').where((w) => w.isNotEmpty).map((word) {
      if (word.length <= 1) return word.toUpperCase();
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
    return words;
  }

  @override
  Widget build(BuildContext context) {
    final String cleanStatus = status.toUpperCase();
    final bool isConfirmed = cleanStatus == "CONFIRMED" || cleanStatus == "COMPLETED";
    final bool isCancelled = cleanStatus == "CANCELLED";

    Color statusColor;
    Color statusBg;
    Color statusBorder;
    String statusLabel;

    if (isConfirmed) {
      statusColor = const Color(0xFFB45309);
      statusBg = const Color(0xFFFFFBEB);
      statusBorder = const Color(0xFFFDE68A);
      statusLabel = cleanStatus == "COMPLETED" ? 'COMPLETED' : 'CONFIRMED';
    } else if (isCancelled) {
      statusColor = const Color(0xFFB91C1C);
      statusBg = const Color(0xFFFEF2F2);
      statusBorder = const Color(0xFFFECACA);
      statusLabel = 'CANCELLED';
    } else {
      statusColor = const Color(0xFF0284C7);
      statusBg = const Color(0xFFF0F9FF);
      statusBorder = const Color(0xFFBAE6FD);
      statusLabel = 'PENDING';
    }

    final formattedName = _formatName(name);
    final String initial = formattedName.isNotEmpty ? formattedName[0].toUpperCase() : 'P';
    final String displayAmount = amount != null && amount!.trim().isNotEmpty
        ? amount!
        : 'LKR 1,200';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {},
            splashColor: statusColor.withValues(alpha: 0.1),
            highlightColor: statusColor.withValues(alpha: 0.05),
            child: Stack(
              children: [
                // Left Accent Bar Strip
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  child: Container(
                    width: 6,
                    color: statusColor,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top Row: Avatar + Name & Subtitle + Status Pill
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Circular Avatar
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFFE0F2FE),
                              border: Border.all(color: const Color(0xFFBAE6FD), width: 1.5),
                              image: (imageUrl != null && imageUrl!.isNotEmpty)
                                  ? DecorationImage(
                                      image: NetworkImage(imageUrl!),
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                            ),
                            alignment: Alignment.center,
                            child: (imageUrl == null || imageUrl!.isEmpty)
                                ? Text(
                                    initial,
                                    style: const TextStyle(
                                      color: Color(0xFF0284C7),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 22,
                                    ),
                                  )
                                : null,
                          ),
                          const SizedBox(width: 14),
                          // Patient Name & Subtitle
                          Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              formattedName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Color(0xFF0F172A),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              type.isEmpty ? 'District General Hospital Hambantota' : type,
                              style: const TextStyle(
                                color: Color(0xFF94A3B8),
                                fontSize: 12.5,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Status Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: statusBg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: statusBorder),
                        ),
                        child: Text(
                          statusLabel,
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 10.5,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // Middle Date & Fee Container
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.calendar_month_rounded, size: 16, color: Color(0xFF0EA5E9)),
                            const SizedBox(width: 8),
                            Text(
                              time,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                          ],
                        ),
                        Text(
                          displayAmount,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0EA5E9),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Reason Note Section (If Available)
                  if (reason != null && reason!.trim().isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFFBEB),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFFDE68A)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.chat_bubble_outline_rounded, size: 14, color: Color(0xFFB45309)),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              reason!,
                              style: const TextStyle(color: Color(0xFF92400E), fontSize: 12, height: 1.35),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Action Buttons Row (Decline, Accept, Receipt, Rx)
                  const SizedBox(height: 14),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (onDecline != null) ...[
                          OutlinedButton.icon(
                            onPressed: onDecline,
                            style: OutlinedButton.styleFrom(
                              backgroundColor: const Color(0xFFFEF2F2),
                              side: const BorderSide(color: Color(0xFFFECACA)),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            icon: const Icon(Icons.close_rounded, size: 15, color: Color(0xFFEF4444)),
                            label: const Text(
                              'Decline',
                              style: TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        if (onAccept != null) ...[
                          ElevatedButton.icon(
                            onPressed: onAccept,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF10B981),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            icon: const Icon(Icons.check_circle_rounded, size: 15, color: Colors.white),
                            label: const Text(
                              'Accept',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        if (onComplete != null) ...[
                          ElevatedButton.icon(
                            onPressed: onComplete,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF10B981),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            icon: const Icon(Icons.check_circle_rounded, size: 15, color: Colors.white),
                            label: const Text(
                              'Complete',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        if (onReceipt != null) ...[
                          OutlinedButton.icon(
                            onPressed: onReceipt,
                            style: OutlinedButton.styleFrom(
                              backgroundColor: Colors.white,
                              side: const BorderSide(color: Color(0xFFCBD5E1)),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            icon: const Icon(Icons.receipt_long_rounded, size: 15, color: Color(0xFF475569)),
                            label: const Text(
                              'Receipt 📄',
                              style: TextStyle(color: Color(0xFF334155), fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        if (onRx != null)
                          ElevatedButton.icon(
                            onPressed: onRx,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0EA5E9),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            icon: const Icon(Icons.history_edu_rounded, size: 15, color: Colors.white),
                            label: const Text(
                              'Rx 📝',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
          ),
        ),
      ),
    );
  }
}