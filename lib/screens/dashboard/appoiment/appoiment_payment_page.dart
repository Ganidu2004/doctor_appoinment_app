import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ConfirmBookingScreen extends StatefulWidget {
  final String doctorId;
  final String patientUid;
  final String scheduleId;
  final String appointmentDate;
  final String appointmentTime;

  const ConfirmBookingScreen({
    super.key,
    required this.doctorId,
    required this.patientUid,
    required this.scheduleId,
    required this.appointmentDate,
    required this.appointmentTime,
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

      setState(() {
        _doctorData = doctorSnap.data() ?? {};
        _scheduleData = scheduleSnap.data() ?? {};
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

      final hospitalCharges = _parseFee(_scheduleData?['hospitalCharges']) > 0
          ? _parseFee(_scheduleData?['hospitalCharges'])
          : double.parse((consultationFee * 0.15).toStringAsFixed(2));

      final appointmentRef = await FirebaseFirestore.instance.collection('appointments').add({
        'doctorId': widget.doctorId,
        'patientUid': widget.patientUid,
        'scheduleId': widget.scheduleId,
        'doctorName': doctorName,
        'specialization': specialization,
        'hospitalName': hospitalName,
        'date': widget.appointmentDate,
        'time': widget.appointmentTime,
        'consultationFee': consultationFee,
        'hospitalCharges': hospitalCharges,
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
        'hospitalCharges': hospitalCharges,
        'paymentMethod': _selectedPaymentMethod,
        'paymentStatus': 'Pending',
        'paymentDate': FieldValue.serverTimestamp(),
      });

      await appointmentRef.update({
        'paymentId': paymentRef.id,
      });

      if (!mounted) return;

      // 1. Show Success Notification
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Appointment booked successfully!'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );

      // 2. Delay navigation so the SnackBar is visible for a moment
      await Future.delayed(const Duration(seconds: 1));

      if (!mounted) return;

      // 3. Navigate to SuccessPage
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const SuccessPage()),
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
    final bool selected = _selectedPaymentMethod == title;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedPaymentMethod = title),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: selected ? Colors.blue.shade50 : Colors.white,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: selected ? Colors.blue : Colors.grey.shade300, width: selected ? 2 : 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (leading != null)
                    leading
                  else if (icon != null)
                    Icon(icon, color: selected ? Colors.blue : Colors.grey.shade700),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      title,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontWeight: FontWeight.bold, color: selected ? Colors.blue : Colors.black87),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(subtitle, style: TextStyle(color: Colors.grey.shade700, fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: const BackButton(),
        title: const Text('Confirm Booking', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Review Appointment', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 10),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 25,
                          backgroundImage: _doctorData?['profileImageUrl'] != null && (_doctorData?['profileImageUrl'] as String).isNotEmpty
                              ? NetworkImage(_doctorData!['profileImageUrl'] as String)
                              : null,
                          backgroundColor: Colors.grey.shade200,
                          child: _doctorData?['profileImageUrl'] == null || (_doctorData?['profileImageUrl'] as String).isEmpty
                              ? const Icon(Icons.person, color: Colors.grey)
                              : null,
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Dr. ${_doctorData?['name'] ?? 'Doctor'}', style: const TextStyle(fontWeight: FontWeight.bold)),
                              Text(_doctorData?['specialization'] ?? 'Specialist', style: const TextStyle(color: Colors.blue)),
                              Text(_scheduleData?['hospitalName'] ?? 'Hospital/Clinic', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(children: [const Icon(Icons.calendar_today, size: 16), const SizedBox(width: 5), Text(widget.appointmentDate)]),
                        Row(children: [const Icon(Icons.access_time, size: 16), const SizedBox(width: 5), Text(widget.appointmentTime)]),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const SizedBox(width: 5),
                        Text('Consultation Fee: ${_formatCurrency(_parseFee(_scheduleData?['consultationFee']))}'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text('Patient Details', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _patientNameController,
              decoration: const InputDecoration(hintText: 'Patient Name', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _reasonController,
              decoration: const InputDecoration(hintText: 'Reason for Visit', border: OutlineInputBorder()),
              maxLines: 3,
            ),
            const SizedBox(height: 20),
            const Text('Payment Options', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Row(
              children: [
                _buildPaymentOption(
                  title: 'Card Payment',
                  subtitle: 'Pay using debit or credit card information',
                  icon: Icons.credit_card,
                ),
                const SizedBox(width: 12),
                _buildPaymentOption(
                  title: 'Direct Payment',
                  subtitle: 'Pay at the hospital or clinic after your visit',
                  leading: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: _selectedPaymentMethod == 'Direct Payment' ? Colors.blue.shade100 : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'LKR.',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _selectedPaymentMethod == 'Direct Payment' ? Colors.blue : Colors.grey.shade700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Card(
              child: ListTile(
                leading: const Icon(Icons.payment, color: Colors.blue),
                title: Text(_selectedPaymentMethod),
                subtitle: const Text('Appointment will be recorded with this payment method.'),
                trailing: Text('Total ${_formatCurrency(_parseFee(_scheduleData?['consultationFee']))}', style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _confirmBooking,
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 15)),
                child: _isSaving
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Confirm Appointment'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SuccessPage extends StatelessWidget {
  const SuccessPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 100),
              const SizedBox(height: 20),
              const Text(
                "Booking Successful!",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
                child: const Text("Back to Home"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}