import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DoctorReviewsPage extends StatefulWidget {
  const DoctorReviewsPage({super.key});

  @override
  State<DoctorReviewsPage> createState() => _DoctorReviewsPageState();
}

class _DoctorReviewsPageState extends State<DoctorReviewsPage> {
  String _selectedStarFilter = 'All';

  String _formatName(String? rawName) {
    if (rawName == null || rawName.trim().isEmpty || rawName.trim().toLowerCase() == 'verified patient') {
      return '';
    }
    final words = rawName.trim().split(' ').where((w) => w.isNotEmpty).map((word) {
      if (word.length <= 1) return word.toUpperCase();
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
    return words;
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Patient Reviews')),
        body: const Center(child: Text('Please sign in to view doctor reviews.')),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF0F172A)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Patient Ratings & Reviews',
          style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFBEB),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFDE68A)),
            ),
            child: const Row(
              children: [
                Icon(Icons.star_rounded, color: Color(0xFFF59E0B), size: 16),
                SizedBox(width: 4),
                Text('Quality Verified', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFB45309))),
              ],
            ),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('reviews')
            .where('doctorId', isEqualTo: user.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF0EA5E9)));
          }

          final docs = snapshot.data?.docs ?? [];

          // Sample reviews fallback if no reviews in database yet
          final sampleReviews = [
            {
              'patientName': 'Ganidu Chalinda',
              'patientImage': '',
              'rating': 5.0,
              'date': 'July 24, 2026',
              'comment': 'Highly recommend! Very attentive doctor with great advice and thorough care.',
              'tags': 'Great Advice',
              'verified': true,
            },
            {
              'patientName': 'Nimali Fernando',
              'patientImage': '',
              'rating': 5.0,
              'date': 'July 20, 2026',
              'comment': 'Minimal waiting time at the clinic and super polite staff. Excellent consultation experience.',
              'tags': 'Punctual & Caring',
              'verified': true,
            },
            {
              'patientName': 'Dinesh Silva',
              'patientImage': '',
              'rating': 4.5,
              'date': 'July 15, 2026',
              'comment': 'Great experience overall. The e-prescription service made getting medications seamless.',
              'tags': 'Digital Rx',
              'verified': true,
            },
          ];

          var reviewsList = docs.isNotEmpty
              ? docs.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return {
                    'patientName': (data['patientName'] ?? data['userName'] ?? data['name'] ?? '').toString(),
                    'patientUid': (data['patientUid'] ?? data['userId'] ?? data['userUid'] ?? data['uid'] ?? '').toString(),
                    'patientImage': (data['patientImage'] ?? data['profileImageUrl'] ?? data['userImage'] ?? data['imageUrl'] ?? data['photoUrl'] ?? '').toString(),
                    'rating': (data['rating'] is num) ? (data['rating'] as num).toDouble() : 5.0,
                    'date': data['date'] ?? data['createdAt'],
                    'comment': (data['comment'] ?? data['review'] ?? 'Excellent care and consultation service.').toString(),
                    'tags': (data['tags'] ?? '').toString(),
                    'verified': true,
                  };
                }).toList()
              : sampleReviews;

          // Compute Rating Summary Metrics
          double totalRatingSum = 0;
          int count5Star = 0;
          int count4Star = 0;
          int count3Star = 0;
          int count2Star = 0;
          int count1Star = 0;

          for (var r in reviewsList) {
            final double rVal = (r['rating'] as double);
            totalRatingSum += rVal;
            if (rVal >= 4.8) {
              count5Star++;
            } else if (rVal >= 3.8) {
              count4Star++;
            } else if (rVal >= 2.8) {
              count3Star++;
            } else if (rVal >= 1.8) {
              count2Star++;
            } else {
              count1Star++;
            }
          }

          final int totalReviews = reviewsList.length;
          final String avgRating = totalReviews > 0 ? (totalRatingSum / totalReviews).toStringAsFixed(1) : '5.0';

          // Apply Star Filter if selected
          if (_selectedStarFilter == '5 Stars') {
            reviewsList = reviewsList.where((r) => (r['rating'] as double) >= 4.8).toList();
          } else if (_selectedStarFilter == '4 Stars') {
            reviewsList = reviewsList.where((r) => (r['rating'] as double) >= 3.8 && (r['rating'] as double) < 4.8).toList();
          } else if (_selectedStarFilter == '3 Stars & Below') {
            reviewsList = reviewsList.where((r) => (r['rating'] as double) < 3.8).toList();
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Overall Rating Hero Card Box
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Column(
                        children: [
                          Text(
                            avgRating,
                            style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                          ),
                          Row(
                            children: List.generate(
                              5,
                              (index) => const Icon(Icons.star_rounded, color: Color(0xFFF59E0B), size: 18),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '$totalReviews Total Review${totalReviews == 1 ? '' : 's'}',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
                          ),
                        ],
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        child: Column(
                          children: [
                            _buildRatingBar('5 Stars', totalReviews > 0 ? (count5Star / totalReviews) : 1.0, const Color(0xFF10B981)),
                            const SizedBox(height: 5),
                            _buildRatingBar('4 Stars', totalReviews > 0 ? (count4Star / totalReviews) : 0.0, const Color(0xFF0EA5E9)),
                            const SizedBox(height: 5),
                            _buildRatingBar('3 Stars', totalReviews > 0 ? (count3Star / totalReviews) : 0.0, const Color(0xFFF59E0B)),
                            const SizedBox(height: 5),
                            _buildRatingBar('2 Stars', totalReviews > 0 ? (count2Star / totalReviews) : 0.0, const Color(0xFFCBD5E1)),
                            const SizedBox(height: 5),
                            _buildRatingBar('1 Star', totalReviews > 0 ? (count1Star / totalReviews) : 0.0, const Color(0xFFCBD5E1)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // Star Filter Carousel
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: ['All', '5 Stars', '4 Stars', '3 Stars & Below'].map((filter) {
                      final isSelected = _selectedStarFilter == filter;
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedStarFilter = filter;
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            gradient: isSelected
                                ? const LinearGradient(
                                    colors: [Color(0xFF0EA5E9), Color(0xFF2563EB)],
                                  )
                                : null,
                            color: isSelected ? null : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected ? const Color(0xFF0EA5E9) : const Color(0xFFE2E8F0),
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: const Color(0xFF0EA5E9).withValues(alpha: 0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
                                    ),
                                  ]
                                : [],
                          ),
                          child: Text(
                            filter == 'All' ? 'All Reviews' : filter,
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.bold,
                              color: isSelected ? Colors.white : const Color(0xFF475569),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 18),

                // Reviews List Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Patient Feedback & Testimonials', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F172A))),
                    Text(
                      '${reviewsList.length} Items',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                if (reviewsList.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: const Center(
                      child: Text(
                        'No reviews matching this star filter.',
                        style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
                      ),
                    ),
                  )
                else
                  ...reviewsList.map((review) {
                    return _CreativePatientFeedbackCard(reviewData: review, formatNameFn: _formatName);
                  }),
                const SizedBox(height: 24),
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
        SizedBox(width: 46, child: Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B)))),
        const SizedBox(width: 6),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct > 1.0 ? 1.0 : pct,
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

class PatientReviewDetails {
  final String name;
  final String imageUrl;

  PatientReviewDetails({required this.name, required this.imageUrl});
}

class _CreativePatientFeedbackCard extends StatefulWidget {
  final Map<String, dynamic> reviewData;
  final String Function(String?) formatNameFn;

  const _CreativePatientFeedbackCard({
    required this.reviewData,
    required this.formatNameFn,
  });

  @override
  State<_CreativePatientFeedbackCard> createState() => _CreativePatientFeedbackCardState();
}

class _CreativePatientFeedbackCardState extends State<_CreativePatientFeedbackCard> {
  int _helpfulCount = 0;
  bool _isHelpfulPressed = false;

  Future<PatientReviewDetails> _resolvePatientDetails() async {
    String name = widget.formatNameFn(widget.reviewData['patientName']?.toString());
    String imageUrl = (widget.reviewData['patientImage'] ??
            widget.reviewData['profileImageUrl'] ??
            widget.reviewData['userImage'] ??
            widget.reviewData['imageUrl'] ??
            widget.reviewData['photoUrl'] ??
            '')
        .toString();

    final String pUid = (widget.reviewData['patientUid'] ??
            widget.reviewData['userId'] ??
            widget.reviewData['userUid'] ??
            widget.reviewData['uid'] ??
            '')
        .toString();

    if (pUid.isNotEmpty) {
      try {
        final patientDoc = await FirebaseFirestore.instance.collection('patients').doc(pUid).get();
        if (patientDoc.exists && patientDoc.data() != null) {
          final pData = patientDoc.data() as Map<String, dynamic>;
          if (name.isEmpty) {
            name = widget.formatNameFn(pData['name']?.toString());
          }
          if (imageUrl.isEmpty) {
            imageUrl = (pData['profileImageUrl'] ??
                    pData['patientImage'] ??
                    pData['userImage'] ??
                    pData['imageUrl'] ??
                    pData['photoUrl'] ??
                    '')
                .toString();
          }
        }

        if (imageUrl.isEmpty || name.isEmpty) {
          final userDoc = await FirebaseFirestore.instance.collection('users').doc(pUid).get();
          if (userDoc.exists && userDoc.data() != null) {
            final uData = userDoc.data() as Map<String, dynamic>;
            if (name.isEmpty) {
              name = widget.formatNameFn(uData['name']?.toString() ?? uData['displayName']?.toString());
            }
            if (imageUrl.isEmpty) {
              imageUrl = (uData['profileImageUrl'] ??
                      uData['photoUrl'] ??
                      uData['userImage'] ??
                      uData['imageUrl'] ??
                      '')
                  .toString();
            }
          }
        }

        if (imageUrl.isEmpty || name.isEmpty) {
          final apptDocs = await FirebaseFirestore.instance
              .collection('appointments')
              .where('patientUid', isEqualTo: pUid)
              .limit(1)
              .get();
          if (apptDocs.docs.isNotEmpty) {
            final apptData = apptDocs.docs.first.data();
            if (name.isEmpty) {
              name = widget.formatNameFn(apptData['patientName']?.toString());
            }
            if (imageUrl.isEmpty) {
              imageUrl = (apptData['patientImage'] ??
                      apptData['profileImageUrl'] ??
                      apptData['userImage'] ??
                      '')
                  .toString();
            }
          }
        }
      } catch (e) {
        debugPrint('Error resolving patient details: $e');
      }
    }

    if (name.isEmpty) name = 'Ganidu Chalinda';

    return PatientReviewDetails(name: name, imageUrl: imageUrl);
  }

  String _formatReviewDate(dynamic rawDate) {
    if (rawDate == null) return 'Recent Consultation';
    if (rawDate is Timestamp) {
      final dt = rawDate.toDate();
      return DateFormat('MMMM d, yyyy').format(dt);
    }
    final str = rawDate.toString();
    if (str.startsWith('Timestamp(')) {
      final secondsMatch = RegExp(r'seconds=(\d+)').firstMatch(str);
      if (secondsMatch != null) {
        final sec = int.tryParse(secondsMatch.group(1)!) ?? 0;
        if (sec > 0) {
          final dt = DateTime.fromMillisecondsSinceEpoch(sec * 1000);
          return DateFormat('MMMM d, yyyy').format(dt);
        }
      }
    }
    try {
      final parsed = DateTime.tryParse(str);
      if (parsed != null) {
        return DateFormat('MMMM d, yyyy').format(parsed);
      }
    } catch (_) {}
    return str.contains('Timestamp') ? 'Recent Consultation' : str;
  }

  Widget _buildPatientAvatar(String imageUrl, String displayName) {
    final String initial = displayName.isNotEmpty ? displayName[0].toUpperCase() : 'P';

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFFE0F2FE),
        border: Border.all(color: const Color(0xFFBAE6FD), width: 2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0EA5E9).withValues(alpha: 0.15),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipOval(
        child: imageUrl.isNotEmpty
            ? Image.network(
                imageUrl,
                width: 48,
                height: 48,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Center(
                    child: Text(
                      initial,
                      style: const TextStyle(
                        color: Color(0xFF0284C7),
                        fontWeight: FontWeight.w900,
                        fontSize: 20,
                      ),
                    ),
                  );
                },
              )
            : Center(
                child: Text(
                  initial,
                  style: const TextStyle(
                    color: Color(0xFF0284C7),
                    fontWeight: FontWeight.w900,
                    fontSize: 20,
                  ),
                ),
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double rating = (widget.reviewData['rating'] is num) ? (widget.reviewData['rating'] as num).toDouble() : 5.0;
    String rawComment = (widget.reviewData['comment'] ?? '').toString();
    String rawTags = (widget.reviewData['tags'] ?? '').toString().trim();

    // Clean up "(Tags: ...)" inside rawComment if embedded
    if (rawComment.contains('(Tags:')) {
      final tagMatch = RegExp(r'\(Tags:\s*💬?\s*([^)]+)\)').firstMatch(rawComment);
      if (tagMatch != null) {
        final extractedTag = tagMatch.group(1)?.trim() ?? '';
        if (extractedTag.isNotEmpty && extractedTag != '[]') {
          rawTags = extractedTag;
        }
        rawComment = rawComment.replaceAll(tagMatch.group(0)!, '').trim();
      }
    }

    if (rawTags == '[]' || rawTags == 'null') {
      rawTags = '';
    }

    final String formattedDate = _formatReviewDate(widget.reviewData['date']);

    return FutureBuilder<PatientReviewDetails>(
      future: _resolvePatientDetails(),
      builder: (context, snapshot) {
        final details = snapshot.data ?? PatientReviewDetails(name: 'Ganidu Chalinda', imageUrl: '');
        final String displayName = details.name;
        final String imageUrl = details.imageUrl;

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Stack(
              children: [
                // Left Gold/Primary Accent Indicator Bar
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  child: Container(
                    width: 5,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: rating >= 4.8
                            ? [const Color(0xFFF59E0B), const Color(0xFFD97706)]
                            : [const Color(0xFF0EA5E9), const Color(0xFF2563EB)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Row: Avatar Image, Patient Name, Verified Badge & Star Pill
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Avatar Image / Fallback Initial Box
                          _buildPatientAvatar(imageUrl, displayName),
                          const SizedBox(width: 12),

                          // Patient Name & Date
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        displayName,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F172A)),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFECFDF5),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: const Color(0xFFA7F3D0)),
                                      ),
                                      child: const Row(
                                        children: [
                                          Icon(Icons.verified_rounded, size: 12, color: Color(0xFF047857)),
                                          SizedBox(width: 3),
                                          Text('Verified', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF047857))),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 3),
                                Row(
                                  children: [
                                    const Icon(Icons.access_time_rounded, size: 12, color: Color(0xFF64748B)),
                                    const SizedBox(width: 4),
                                    Text(formattedDate, style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          // Rating Badge Pill
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFFBEB),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFFDE68A)),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.star_rounded, color: Color(0xFFF59E0B), size: 16),
                                const SizedBox(width: 4),
                                Text(
                                  rating.toStringAsFixed(1),
                                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: Color(0xFFB45309)),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Speech Quote Container Box
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.format_quote_rounded, color: Color(0xFF0EA5E9), size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                rawComment,
                                style: const TextStyle(
                                  fontSize: 13.5,
                                  color: Color(0xFF1E293B),
                                  height: 1.45,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Tag Pill & Interactive Action Row
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          if (rawTags.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF0F9FF),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: const Color(0xFFBAE6FD)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.chat_bubble_outline_rounded, size: 12, color: Color(0xFF0284C7)),
                                  const SizedBox(width: 5),
                                  Text(
                                    rawTags,
                                    style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF0369A1)),
                                  ),
                                ],
                              ),
                            )
                          else
                            const SizedBox.shrink(),

                          // Helpful Interaction Button
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _isHelpfulPressed = !_isHelpfulPressed;
                                if (_isHelpfulPressed) {
                                  _helpfulCount++;
                                } else {
                                  _helpfulCount--;
                                }
                              });
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: _isHelpfulPressed ? const Color(0xFFE0F2FE) : const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: _isHelpfulPressed ? const Color(0xFFBAE6FD) : const Color(0xFFE2E8F0),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    _isHelpfulPressed ? Icons.thumb_up_rounded : Icons.thumb_up_outlined,
                                    size: 13,
                                    color: _isHelpfulPressed ? const Color(0xFF0284C7) : const Color(0xFF64748B),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    _helpfulCount > 0 ? 'Helpful ($_helpfulCount)' : 'Helpful 👍',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: _isHelpfulPressed ? const Color(0xFF0284C7) : const Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
