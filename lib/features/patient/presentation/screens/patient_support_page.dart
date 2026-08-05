import 'package:flutter/material.dart';
import 'patient_chat_page.dart';

class PatientSupportPage extends StatefulWidget {
  final bool showAppBar;
  const PatientSupportPage({super.key, this.showAppBar = false});

  @override
  State<PatientSupportPage> createState() => _PatientSupportPageState();
}

class _PatientSupportPageState extends State<PatientSupportPage> {
  int? _expandedFaqIndex;

  final List<Map<String, String>> _faqs = [
    {
      'question': 'How do I cancel or reschedule an appointment?',
      'answer':
          'Go to the Appointments tab in your bottom bar, select your booking, and tap "Cancel" or "Reschedule". You can choose a new date or request cancellation.',
    },
    {
      'question': 'What happens if a doctor cancels my consultation?',
      'answer':
          'If a doctor cancels, a Cancellation Invoice is automatically generated. You can view the details under your appointment and choose an instant refund or pick a new slot.',
    },
    {
      'question': 'How long do refunds take to process?',
      'answer':
          'Card refunds are credited back to your original payment method within 1–3 business days after cancellation confirmation.',
    },
    {
      'question': 'How can I view my booking receipts and invoices?',
      'answer':
          'You can access all past consultation receipts directly by expanding any appointment card on your Appointments page.',
    },
  ];

  void _showCategoryDialog(BuildContext context, String title, String desc) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        surfaceTintColor: Colors.transparent,
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
        ),
        content: Text(
          desc,
          style: TextStyle(
            color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
            height: 1.5,
            fontSize: 13.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Got it',
              style: TextStyle(color: Color(0xFF0EA5E9), fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: widget.showAppBar
          ? AppBar(
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              elevation: 0.5,
              iconTheme: IconThemeData(color: isDark ? Colors.white : const Color(0xFF0F172A)),
              title: Text(
                'Support Hub',
                style: TextStyle(color: isDark ? Colors.white : const Color(0xFF0F172A), fontWeight: FontWeight.bold),
              ),
              centerTitle: true,
            )
          : null,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header & Live Status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'How can we help? 👋',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'We are here for your appointments & care questions',
                          style: TextStyle(
                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF064E3B) : const Color(0xFFECFDF5),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: isDark ? const Color(0xFF059669) : const Color(0xFFA7F3D0)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.circle, color: Color(0xFF10B981), size: 8),
                        const SizedBox(width: 6),
                        Text(
                          'Online',
                          style: TextStyle(
                            color: isDark ? const Color(0xFF34D399) : const Color(0xFF047857),
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Hero Live Chat Gradient Banner
              Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0EA5E9), Color(0xFF2563EB)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0EA5E9).withValues(alpha: 0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.bolt_rounded, color: Colors.amber, size: 14),
                                  SizedBox(width: 4),
                                  Text(
                                    'Recommended',
                                    style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              'Live In-App Chat',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Chat 1-on-1 with a care coordinator for instant help.',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.9),
                                fontSize: 12.5,
                              ),
                            ),
                            const SizedBox(height: 14),
                            ElevatedButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => const PatientChatPage()),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
                                foregroundColor: isDark ? Colors.white : const Color(0xFF0284C7),
                                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                elevation: 0,
                              ),
                              icon: const Icon(Icons.chat_rounded, size: 16),
                              label: const Text(
                                'Start Live Chat',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.support_agent_rounded, size: 48, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 22),

              // Quick Topic Categories
              Text(
                'Quick Support Topics',
                style: TextStyle(fontSize: 16.5, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF0F172A)),
              ),
              const SizedBox(height: 12),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.6,
                children: [
                  _buildTopicCard(
                    context,
                    icon: Icons.calendar_month_rounded,
                    iconColor: const Color(0xFF0EA5E9),
                    bgColor: const Color(0xFFE0F2FE),
                    title: 'Appointments',
                    subtitle: 'Booking & rescheduling',
                    onTap: () => _showCategoryDialog(
                      context,
                      'Appointment Support',
                      'To manage your appointments, visit the Appointments tab. You can view booking details, reschedule slots, or cancel with automatic refund tracking.',
                    ),
                  ),
                  _buildTopicCard(
                    context,
                    icon: Icons.receipt_long_rounded,
                    iconColor: const Color(0xFF10B981),
                    bgColor: const Color(0xFFDCFCE7),
                    title: 'Billing & Refunds',
                    subtitle: 'Invoices & charges',
                    onTap: () => _showCategoryDialog(
                      context,
                      'Billing & Refunds',
                      'All consultation charges and cancellation refund invoices are listed under your appointment history. Online card refunds process within 1-3 business days.',
                    ),
                  ),
                  _buildTopicCard(
                    context,
                    icon: Icons.medical_services_rounded,
                    iconColor: const Color(0xFF8B5CF6),
                    bgColor: const Color(0xFFF3E8FF),
                    title: 'Doctors & Care',
                    subtitle: 'Specialists & profiles',
                    onTap: () => _showCategoryDialog(
                      context,
                      'Doctor Consultations',
                      'Browse top specialists using the Find Doctor tab. Check ratings, qualifications, experience, and available time slots.',
                    ),
                  ),
                  _buildTopicCard(
                    context,
                    icon: Icons.shield_outlined,
                    iconColor: const Color(0xFFF97316),
                    bgColor: const Color(0xFFFFEDD5),
                    title: 'Account Help',
                    subtitle: 'Security & login',
                    onTap: () => _showCategoryDialog(
                      context,
                      'Account & Security',
                      'Update your profile details or change your password under the Profile tab. If you experience login issues, contact our Live Helper.',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),

              // Alternative Support Channels
              Text(
                'Other Ways to Connect',
                style: TextStyle(fontSize: 16.5, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF0F172A)),
              ),
              const SizedBox(height: 12),

              // Phone Channel Card
              _buildChannelCard(
                icon: Icons.phone_in_talk_rounded,
                iconColor: const Color(0xFF0284C7),
                bgColor: const Color(0xFFEFF6FF),
                borderColor: const Color(0xFFBAE6FD),
                title: 'Call Support Team',
                subtitle: 'Mon – Fri (8:00 AM – 8:00 PM)',
                actionText: '+94 11 234 5678',
                onTap: () {},
              ),
              const SizedBox(height: 12),

              // Email Channel Card
              _buildChannelCard(
                icon: Icons.mark_email_read_rounded,
                iconColor: const Color(0xFF7C3AED),
                bgColor: const Color(0xFFF5F3FF),
                borderColor: const Color(0xFFDDD6FE),
                title: 'Email Care Coordinator',
                subtitle: 'Get detailed email help within 24h',
                actionText: 'support@doc-time.com',
                onTap: () {},
              ),
              const SizedBox(height: 24),

              // FAQ Accordion Section
              Text(
                'Frequently Asked Questions',
                style: TextStyle(fontSize: 16.5, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF0F172A)),
              ),
              const SizedBox(height: 12),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _faqs.length,
                itemBuilder: (context, index) {
                  final faq = _faqs[index];
                  final isExpanded = _expandedFaqIndex == index;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                    ),
                    child: Material(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      clipBehavior: Clip.antiAlias,
                      child: Theme(
                        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                        child: ExpansionTile(
                          key: Key('faq-$index'),
                          initiallyExpanded: isExpanded,
                          onExpansionChanged: (expanded) {
                            setState(() {
                              _expandedFaqIndex = expanded ? index : null;
                            });
                          },
                          iconColor: const Color(0xFF0EA5E9),
                          collapsedIconColor: isDark ? Colors.white70 : const Color(0xFF64748B),
                          title: Text(
                            faq['question']!,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13.5,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                          ),
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                              child: Text(
                                faq['answer']!,
                                style: TextStyle(
                                  color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
                                  fontSize: 13,
                                  height: 1.45,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopicCard(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isDark ? iconColor.withValues(alpha: 0.2) : bgColor,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      fontSize: 11,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChannelCard({
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required Color borderColor,
    required String title,
    required String subtitle,
    required String actionText,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? iconColor.withValues(alpha: 0.15) : bgColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: isDark ? iconColor.withValues(alpha: 0.3) : borderColor),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: isDark ? iconColor.withValues(alpha: 0.15) : bgColor,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: isDark ? iconColor.withValues(alpha: 0.3) : borderColor),
            ),
            child: Text(
              actionText,
              style: TextStyle(
                color: iconColor,
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
