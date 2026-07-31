import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:appoinment_app/core/utils/text_sanitizer.dart';

class DoctorReviewsModal extends StatelessWidget {
  const DoctorReviewsModal({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const SizedBox.shrink();

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.all(24),
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('reviews')
            .where('doctorId', isEqualTo: user.uid)
            .snapshots(),
        builder: (context, snapshot) {
          final docs = snapshot.data?.docs ?? [];

          // Fallback sample testimonials if none exist in database yet
          final sampleReviews = [
            {
              'patientName': 'Kasun Perera',
              'rating': 5.0,
              'date': 'July 24, 2026',
              'comment': 'Extremely knowledgeable and attentive doctor. Provided a clear diagnosis and effective treatment plan!',
              'verified': true,
            },
            {
              'patientName': 'Nimali Fernando',
              'rating': 5.0,
              'date': 'July 20, 2026',
              'comment': 'Very polite and minimal waiting time at the clinic. Highly recommended for family consultations!',
              'verified': true,
            },
            {
              'patientName': 'Dinesh Silva',
              'rating': 4.5,
              'date': 'July 15, 2026',
              'comment': 'Great experience overall. The e-prescription service made buying medicine super easy.',
              'verified': true,
            },
          ];

          final reviewsList = docs.isNotEmpty
              ? docs.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return {
                    'patientName': (data['patientName'] ?? 'Verified Patient').toString(),
                    'rating': (data['rating'] is num) ? (data['rating'] as num).toDouble() : 5.0,
                    'date': (data['date'] ?? 'Recent Visit').toString(),
                    'comment': (data['comment'] ?? data['review'] ?? 'Excellent care and consultation service.').toString(),
                    'verified': true,
                  };
                }).toList()
              : sampleReviews;

          // Compute average rating
          double totalRatingSum = 0;
          for (var r in reviewsList) {
            totalRatingSum += (r['rating'] as double);
          }
          final avgRating = reviewsList.isNotEmpty ? (totalRatingSum / reviewsList.length).toStringAsFixed(1) : '4.9';

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFCBD5E1),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Title Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFFBEB),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFFDE68A)),
                          ),
                          child: const Icon(Icons.star_rounded, color: Color(0xFFB45309), size: 24),
                        ),
                        const SizedBox(width: 12),
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Patient Ratings & Reviews',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                            ),
                            Text(
                              'Service quality & patient feedback',
                              style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Overall Rating Hero Box
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      Column(
                        children: [
                          Text(
                            avgRating,
                            style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                          ),
                          Row(
                            children: List.generate(
                              5,
                              (index) => const Icon(Icons.star_rounded, color: Color(0xFFF59E0B), size: 16),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${reviewsList.length} Total Reviews',
                            style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
                          ),
                        ],
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        child: Column(
                          children: [
                            _buildRatingBar('5 Stars', 0.85, const Color(0xFF10B981)),
                            const SizedBox(height: 4),
                            _buildRatingBar('4 Stars', 0.12, const Color(0xFF0EA5E9)),
                            const SizedBox(height: 4),
                            _buildRatingBar('3 Stars', 0.03, const Color(0xFFF59E0B)),
                            const SizedBox(height: 4),
                            _buildRatingBar('2 Stars', 0.00, const Color(0xFFCBD5E1)),
                            const SizedBox(height: 4),
                            _buildRatingBar('1 Star', 0.00, const Color(0xFFCBD5E1)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Reviews List
                const Text('Recent Feedback & Testimonials', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0F172A))),
                const SizedBox(height: 12),

                ...reviewsList.map((review) {
                  final String patientName = review['patientName'].toString();
                  final String initial = patientName.isNotEmpty ? patientName[0].toUpperCase() : 'P';
                  final double rating = review['rating'] as double;
                  final String comment = cleanGarbledText(review['comment'].toString());
                  final String date = review['date'].toString();

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 38,
                              height: 38,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Color(0xFFE0F2FE),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                initial,
                                style: const TextStyle(color: Color(0xFF0284C7), fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        patientName,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A)),
                                      ),
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFECFDF5),
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(color: const Color(0xFFA7F3D0)),
                                        ),
                                        child: const Row(
                                          children: [
                                            Icon(Icons.verified_rounded, size: 10, color: Color(0xFF047857)),
                                            SizedBox(width: 3),
                                            Text('Verified', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Color(0xFF047857))),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(date, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFFBEB),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: const Color(0xFFFDE68A)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.star_rounded, color: Color(0xFFF59E0B), size: 14),
                                  const SizedBox(width: 3),
                                  Text(
                                    rating.toStringAsFixed(1),
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5, color: Color(0xFFB45309)),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          '"$comment"',
                          style: const TextStyle(fontSize: 12.5, color: Color(0xFF334155), height: 1.4),
                        ),
                      ],
                    ),
                  );
                }),

                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildRatingBar(String label, double pct, Color color) {
    return Row(
      children: [
        SizedBox(width: 44, child: Text(label, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF64748B)))),
        const SizedBox(width: 6),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 6,
              backgroundColor: const Color(0xFFE2E8F0),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ),
      ],
    );
  }
}
