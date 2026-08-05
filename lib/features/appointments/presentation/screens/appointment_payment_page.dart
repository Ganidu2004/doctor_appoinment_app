import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:appoinment_app/core/services/notification_services.dart';
import 'hospital_booking_pass_page.dart';

class ConfirmBookingScreen extends StatefulWidget {
  final String doctorId;
  final String patientUid;
  final String scheduleId;
  final String appointmentDate;
  final String appointmentTime;
  final String consultationType;

  const ConfirmBookingScreen({
    super.key,
    required this.doctorId,
    required this.patientUid,
    required this.scheduleId,
    required this.appointmentDate,
    required this.appointmentTime,
    this.consultationType = 'In-Person Clinic Visit',
  });

  @override
  State<ConfirmBookingScreen> createState() => _ConfirmBookingScreenState();
}

class _ConfirmBookingScreenState extends State<ConfirmBookingScreen> {
  final _patientNameController = TextEditingController();
  final _reasonController = TextEditingController();
  bool _isSaving = false;
  bool _isLoading = true;
  String _selectedPaymentMethod = 'Card Payment';
  Map<String, dynamic>? _doctorData;
  Map<String, dynamic>? _scheduleData;
  double _hospitalCharges = 0.0;

  @override
  void initState() {
    super.initState();
    _patientNameController.text = FirebaseAuth.instance.currentUser?.displayName ?? '';
    _loadAppointmentData();
  }

  @override
  void dispose() {
    _patientNameController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _loadAppointmentData() async {
    try {
      final doctorSnap = await FirebaseFirestore.instance.collection('doctors').doc(widget.doctorId).get();
      final scheduleSnap = await FirebaseFirestore.instance
          .collection('doctors')
          .doc(widget.doctorId)
          .collection('schedules')
          .doc(widget.scheduleId)
          .get();

      // Fetch the currently logged-in patient's details
      final patientSnap = await FirebaseFirestore.instance.collection('patients').doc(widget.patientUid).get();

      double loadedHospitalCharges = 0.0;
      final scheduleData = scheduleSnap.data() ?? {};
      final hospitalId = scheduleData['hospitalId']?.toString() ?? '';
      if (hospitalId.isNotEmpty) {
        final hospitalSnap = await FirebaseFirestore.instance.collection('hospital').doc(hospitalId).get();
        if (hospitalSnap.exists && hospitalSnap.data() != null) {
          final chargesVal = hospitalSnap.data()!['charges'];
          if (chargesVal is num) {
            loadedHospitalCharges = chargesVal.toDouble();
          } else if (chargesVal is String) {
            loadedHospitalCharges = double.tryParse(chargesVal) ?? 0.0;
          }
        }
      }

      setState(() {
        _doctorData = doctorSnap.data() ?? {};
        _scheduleData = scheduleData;
        _hospitalCharges = loadedHospitalCharges;
        if (patientSnap.exists && patientSnap.data() != null) {
          final patientData = patientSnap.data()!;
          final name = patientData['name']?.toString() ?? '';
          if (name.isNotEmpty) {
            _patientNameController.text = name;
          }
        }
      });
    } catch (error) {
      debugPrint('Failed to load appointment data: $error');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Unable to load appointment details.')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  double _parseFee(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  int _parseTimeToMinutes(String timeStr) {
    if (timeStr.isEmpty) return 0;
    final clean = timeStr.trim();
    try {
      final dt = DateFormat('hh:mm a').parseLoose(clean);
      return dt.hour * 60 + dt.minute;
    } catch (_) {}
    try {
      final dt = DateFormat('HH:mm').parseLoose(clean);
      return dt.hour * 60 + dt.minute;
    } catch (_) {}
    return 0;
  }

  Future<void> _confirmBooking() async {
    if (_patientNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter patient name.')));
      return;
    }

    final doctorName = _doctorData?['name'] ?? 'Doctor';
    final specialization = _doctorData?['specialization'] ?? 'Specialist';
    final hospitalName = _scheduleData?['hospitalName'] ?? 'Hospital/Clinic';
    final consultationFee = _parseFee(_scheduleData?['consultationFee']);

    setState(() => _isSaving = true);

    try {
      final patient = FirebaseAuth.instance.currentUser;
      if (patient == null) {
        throw Exception('Patient must be logged in to book an appointment.');
      }

      final String generatedBookingNo = 'DOC-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';

      // Cumulative token calculation across preceding time blocks up to current slot
      final existingBookingsSnap = await FirebaseFirestore.instance
          .collection('appointments')
          .where('doctorId', isEqualTo: widget.doctorId)
          .where('date', isEqualTo: widget.appointmentDate)
          .get();

      final int selectedMinutes = _parseTimeToMinutes(widget.appointmentTime);
      int precedingBookingsCount = 0;
      int currentSlotBookingsCount = 0;

      for (var doc in existingBookingsSnap.docs) {
        final data = doc.data();
        final timeStr = (data['time'] ?? '').toString();
        if (timeStr.isEmpty) continue;

        final slotMinutes = _parseTimeToMinutes(timeStr);
        if (slotMinutes < selectedMinutes) {
          precedingBookingsCount++;
        } else if (slotMinutes == selectedMinutes) {
          currentSlotBookingsCount++;
        }
      }

      final int tokenNumber = precedingBookingsCount + currentSlotBookingsCount + 1;
      final String queueToken = '#${tokenNumber.toString().padLeft(2, '0')}';

      final appointmentRef = await FirebaseFirestore.instance.collection('appointments').add({
        'bookingNo': generatedBookingNo,
        'tokenNumber': tokenNumber,
        'queueToken': queueToken,
        'doctorId': widget.doctorId,
        'patientUid': widget.patientUid,
        'scheduleId': widget.scheduleId,
        'doctorName': doctorName,
        'specialization': specialization,
        'hospitalName': hospitalName,
        'date': widget.appointmentDate,
        'time': widget.appointmentTime,
        'consultationType': widget.consultationType,
        'queueStatus': 'waiting',
        'consultationFee': consultationFee,
        'hospitalCharges': _hospitalCharges,
        'patientName': _patientNameController.text.trim(),
        'reason': _reasonController.text.trim(),
        'paymentMethod': _selectedPaymentMethod,
        'status': 'Booked',
        'createdAt': FieldValue.serverTimestamp(),
      });

      final paymentRef = await FirebaseFirestore.instance.collection('payments').add({
        'appointmentId': appointmentRef.id,
        'patientId': patient.uid,
        'doctorId': widget.doctorId,
        'amount': consultationFee,
        'hospitalCharges': _hospitalCharges,
        'paymentMethod': _selectedPaymentMethod,
        'paymentStatus': 'Pending',
        'paymentDate': FieldValue.serverTimestamp(),
      });

      await appointmentRef.update({
        'paymentId': paymentRef.id,
      });

      if (!mounted) return;

      // 1. Show Success Notification
      try {
        await NotificationService().showNotification(
          id: 501,
          title: 'Appointment Booked Successfully',
          body: 'Your booking ($generatedBookingNo) was confirmed.',
        );
      } catch (err) {
        debugPrint('Notification error: $err');
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Appointment $generatedBookingNo booked successfully!'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );

      // 2. Delay navigation so the SnackBar is visible for a moment
      await Future.delayed(const Duration(seconds: 1));

      if (!mounted) return;

      // 3. Navigate to SuccessPage with appointmentId
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => SuccessPage(appointmentId: appointmentRef.id)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to book appointment: $e')));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  String _formatCurrency(double amount) {
    return 'LKR ${amount.toStringAsFixed(amount.truncateToDouble() == amount ? 0 : 2).replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (match) => ',',
    )}';
  }

  Widget _buildPaymentOption({required String title, required String subtitle, IconData? icon, Widget? leading}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bool selected = _selectedPaymentMethod == title;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedPaymentMethod = title),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: selected ? (isDark ? const Color(0xFF0F172A) : const Color(0xFFF0F9FF)) : (isDark ? const Color(0xFF1E293B) : Colors.white),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? const Color(0xFF0EA5E9) : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
              width: selected ? 1.8 : 1,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: const Color(0xFF0EA5E9).withValues(alpha: 0.15),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: selected ? (isDark ? const Color(0xFF0369A1) : const Color(0xFFE0F2FE)) : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9)),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: leading ?? Icon(icon, size: 18, color: selected ? (isDark ? Colors.white : const Color(0xFF0EA5E9)) : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B))),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      title,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13.5,
                        color: selected ? (isDark ? Colors.white : const Color(0xFF0369A1)) : (isDark ? Colors.white : const Color(0xFF0F172A)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: TextStyle(color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B), fontSize: 11.5, height: 1.3),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: Color(0xFF0EA5E9)),
              const SizedBox(height: 16),
              Text(
                'Loading booking summary...',
                style: TextStyle(color: isDark ? Colors.white70 : const Color(0xFF475569), fontSize: 14, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      );
    }

    final double consultationFee = _parseFee(_scheduleData?['consultationFee']);
    final double totalFee = consultationFee + _hospitalCharges;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0.5,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: isDark ? Colors.white : const Color(0xFF0F172A), size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          children: [
            Text(
              'Confirm & Checkout',
              style: TextStyle(color: isDark ? Colors.white : const Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 2),
            Text(
              'Step 2 of 2 • Final Review',
              style: TextStyle(color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B), fontSize: 11, fontWeight: FontWeight.w500),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Section 1: Appointment & Doctor Review Card
                  Text('Consultation Summary', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.5, color: isDark ? Colors.white : const Color(0xFF0F172A))),
                  const SizedBox(height: 10),
                  Container(
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 26,
                                backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFE0F2FE),
                                backgroundImage: _doctorData?['profileImageUrl'] != null && (_doctorData?['profileImageUrl'] as String).isNotEmpty
                                    ? NetworkImage(_doctorData!['profileImageUrl'] as String)
                                    : null,
                                child: _doctorData?['profileImageUrl'] == null || (_doctorData?['profileImageUrl'] as String).isEmpty
                                    ? const Icon(Icons.person_rounded, color: Color(0xFF0EA5E9), size: 26)
                                    : null,
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Dr. ${_doctorData?['name'] ?? 'Doctor'}',
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15.5, color: isDark ? Colors.white : const Color(0xFF0F172A)),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      _doctorData?['specialization'] ?? 'Specialist',
                                      style: const TextStyle(color: Color(0xFF0284C7), fontWeight: FontWeight.bold, fontSize: 12.5),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      _scheduleData?['hospitalName'] ?? 'Hospital/Clinic',
                                      style: TextStyle(fontSize: 12, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Divider(height: 1, color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9)),
                          ),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF0F9FF),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFBAE6FD)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.calendar_month_rounded, size: 16, color: Color(0xFF0284C7)),
                                    const SizedBox(width: 6),
                                    Text(
                                      widget.appointmentDate,
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5, color: isDark ? Colors.white : const Color(0xFF0F172A)),
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFBAE6FD)),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.access_time_rounded, size: 14, color: Color(0xFF0284C7)),
                                      const SizedBox(width: 4),
                                      Text(
                                        widget.appointmentTime,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF0284C7)),
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
                  const SizedBox(height: 20),

                  // Section 2: Patient Information Inputs
                  Text('Patient Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.5, color: isDark ? Colors.white : const Color(0xFF0F172A))),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        TextField(
                          controller: _patientNameController,
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: isDark ? Colors.white : const Color(0xFF0F172A)),
                          decoration: InputDecoration(
                            labelText: 'Patient Full Name',
                            labelStyle: TextStyle(color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B), fontSize: 13),
                            prefixIcon: const Icon(Icons.person_outline_rounded, color: Color(0xFF0EA5E9), size: 20),
                            filled: true,
                            fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0))),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0))),
                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF0EA5E9), width: 1.5)),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _reasonController,
                          style: TextStyle(fontSize: 14, color: isDark ? Colors.white : const Color(0xFF0F172A)),
                          maxLines: 2,
                          decoration: InputDecoration(
                            labelText: 'Reason for Visit / Symptoms (Optional)',
                            alignLabelWithHint: true,
                            labelStyle: TextStyle(color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B), fontSize: 13),
                            prefixIcon: const Padding(
                              padding: EdgeInsets.only(bottom: 24),
                              child: Icon(Icons.medical_information_outlined, color: Color(0xFF0EA5E9), size: 20),
                            ),
                            filled: true,
                            fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0))),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0))),
                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF0EA5E9), width: 1.5)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Section 3: Payment Options
                  Text('Payment Method', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.5, color: isDark ? Colors.white : const Color(0xFF0F172A))),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _buildPaymentOption(
                        title: 'Card Payment',
                        subtitle: 'Debit / Credit card online',
                        icon: Icons.credit_card_rounded,
                      ),
                      const SizedBox(width: 10),
                      _buildPaymentOption(
                        title: 'Direct Payment',
                        subtitle: 'Pay at hospital counter',
                        icon: Icons.payments_rounded,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Section 4: Charges Receipt Card
                  Text('Charges Breakdown', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.5, color: isDark ? Colors.white : const Color(0xFF0F172A))),
                  const SizedBox(height: 10),
                  Container(
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Doctor Consultation Fee', style: TextStyle(color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B), fontSize: 13)),
                              Text(_formatCurrency(consultationFee), style: TextStyle(fontWeight: FontWeight.w600, color: isDark ? Colors.white : const Color(0xFF0F172A), fontSize: 13.5)),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Hospital / Clinic Charges', style: TextStyle(color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B), fontSize: 13)),
                              Text(_formatCurrency(_hospitalCharges), style: TextStyle(fontWeight: FontWeight.w600, color: isDark ? Colors.white : const Color(0xFF0F172A), fontSize: 13.5)),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Platform Service Fee', style: TextStyle(color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B), fontSize: 13)),
                              const Text('FREE ✨', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF10B981), fontSize: 12)),
                            ],
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Divider(height: 1, color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9)),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Total Payment', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15.5, color: isDark ? Colors.white : const Color(0xFF0F172A))),
                              Text(
                                _formatCurrency(totalFee),
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF0284C7)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Refund Guarantee Pill
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF064E3B) : const Color(0xFFECFDF5),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: isDark ? const Color(0xFF059669) : const Color(0xFFA7F3D0)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.shield_outlined, color: Color(0xFF10B981), size: 18),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            "100% Free Cancellation up to 24 hours prior to appointment slot.",
                            style: TextStyle(fontSize: 12, color: isDark ? const Color(0xFF34D399) : const Color(0xFF047857), fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),

          // Bottom Action Bar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 16,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Total Amount', style: TextStyle(fontSize: 11.5, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B), fontWeight: FontWeight.w500)),
                          const SizedBox(height: 2),
                          Text(
                            _formatCurrency(totalFee),
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: isDark ? Colors.white : const Color(0xFF0F172A)),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF0F9FF),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFBAE6FD)),
                        ),
                        child: Text(
                          _selectedPaymentMethod,
                          style: TextStyle(color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0369A1), fontWeight: FontWeight.bold, fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF0EA5E9), Color(0xFF2563EB)],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF0EA5E9).withValues(alpha: 0.35),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _confirmBooking,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white),
                              )
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Confirm & Book Appointment',
                                    style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                                  ),
                                  SizedBox(width: 8),
                                  Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
                                ],
                              ),
                      ),
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

class SuccessPage extends StatelessWidget {
  final String? appointmentId;

  const SuccessPage({super.key, this.appointmentId});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Success Animated Circle Icon
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF064E3B) : const Color(0xFFECFDF5),
                    shape: BoxShape.circle,
                    border: Border.all(color: isDark ? const Color(0xFF059669) : const Color(0xFFA7F3D0), width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF10B981).withValues(alpha: 0.25),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 72),
                ),
                const SizedBox(height: 24),
                Text(
                  "Booking Confirmed!",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    "Your appointment has been successfully scheduled. We've issued an official Hospital Verification Pass for your visit.",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13.5, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B), height: 1.45),
                  ),
                ),
                const SizedBox(height: 32),

                // Success Actions Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.verified_rounded, color: Color(0xFF0EA5E9), size: 18),
                          const SizedBox(width: 6),
                          Text(
                            "Hospital Verification Pass Issued",
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: isDark ? Colors.white : const Color(0xFF0F172A)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Text(
                        "Present your digital pass or reference number at the hospital reception counter upon arrival.",
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12.5, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Primary Button: View Official Hospital Pass
                if (appointmentId != null && appointmentId!.isNotEmpty) ...[
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF0EA5E9), Color(0xFF2563EB)],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF0EA5E9).withValues(alpha: 0.35),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => HospitalBookingPassPage(appointmentId: appointmentId),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        icon: const Icon(Icons.qr_code_2_rounded, color: Colors.white, size: 20),
                        label: const Text(
                          "View Hospital Pass",
                          style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                ],

                // Secondary Button: Back to Home
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                      side: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    icon: Icon(Icons.home_rounded, color: isDark ? Colors.white : const Color(0xFF0F172A), size: 18),
                    label: Text(
                      "Back to Home",
                      style: TextStyle(color: isDark ? Colors.white : const Color(0xFF0F172A), fontSize: 14, fontWeight: FontWeight.bold),
                    ),
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