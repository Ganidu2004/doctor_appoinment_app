import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:appoinment_app/core/theme_controller.dart';

class AddHospitalPage extends StatefulWidget {
  const AddHospitalPage({super.key});

  @override
  State<AddHospitalPage> createState() => _AddHospitalPageState();
}

class _AddHospitalPageState extends State<AddHospitalPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _districtController = TextEditingController();
  final _phoneController = TextEditingController();
  final _chargesController = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _districtController.dispose();
    _phoneController.dispose();
    _chargesController.dispose();
    super.dispose();
  }

  InputDecoration _fieldDeco(String label, IconData icon, bool isDark) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(
        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
        fontSize: 13,
        fontWeight: FontWeight.w600,
      ),
      floatingLabelStyle: TextStyle(
        color: isDark ? const Color(0xFFFB7185) : const Color(0xFFF43F5E),
        fontSize: 13,
        fontWeight: FontWeight.bold,
      ),
      filled: true,
      fillColor: isDark ? const Color(0xFF0F172A) : Colors.white,
      prefixIcon: Icon(icon, color: isDark ? const Color(0xFFFB7185) : const Color(0xFFF43F5E), size: 20),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: isDark ? const Color(0xFFFB7185) : const Color(0xFFF43F5E), width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
      ),
    );
  }

  Future<void> _saveHospital() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final double charges = double.tryParse(_chargesController.text.trim()) ?? 500.0;

      await FirebaseFirestore.instance.collection('hospital').add({
        'name': _nameController.text.trim(),
        'address': _addressController.text.trim(),
        'district': _districtController.text.trim(),
        'contact': _phoneController.text.trim(),
        'charges': charges,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Hospital registered successfully!")),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: ${e.toString()}")),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isDesktop = MediaQuery.of(context).size.width >= 800;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text("Register Hospital", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: isDark ? Colors.white : const Color(0xFF0F172A))),
        backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
        elevation: 0.5,
        iconTheme: IconThemeData(color: isDark ? Colors.white : const Color(0xFF0F172A)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              isDark ? Icons.wb_sunny_outlined : Icons.dark_mode_outlined,
              color: isDark ? Colors.amber : Colors.indigo,
            ),
            tooltip: "Toggle Dark/Light Mode",
            onPressed: () {
              ThemeController.instance.toggleTheme(!isDark);
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: isDesktop ? 760 : 500),
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blueGrey.withValues(alpha: isDark ? 0.2 : 0.08),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: Column(
                    children: [
                      // Creative Hero Header Banner
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(28),
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFFF43F5E), Color(0xFFE11D48), Color(0xFFBE123C)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
                              ),
                              child: const Icon(
                                Icons.domain_add_rounded,
                                color: Colors.white,
                                size: 36,
                              ),
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Text(
                                      "PARTNER NETWORK",
                                      style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.8),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    "Register Hospital",
                                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "Add a new healthcare facility to the network.",
                                    style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 13),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Form Container
                      Padding(
                        padding: const EdgeInsets.all(28.0),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (isDesktop) ...[
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextFormField(
                                        controller: _nameController,
                                        style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                                        decoration: _fieldDeco("Hospital Name", Icons.local_hospital_outlined, isDark),
                                        validator: (value) => value == null || value.trim().isEmpty ? 'Please enter hospital name' : null,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: TextFormField(
                                        controller: _chargesController,
                                        keyboardType: TextInputType.number,
                                        style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                                        decoration: _fieldDeco("Hospital Charges (LKR)", Icons.payment_outlined, isDark),
                                        validator: (value) {
                                          if (value == null || value.trim().isEmpty) return 'Please enter hospital charges';
                                          if (double.tryParse(value.trim()) == null) return 'Enter a valid number';
                                          return null;
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 18),
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextFormField(
                                        controller: _districtController,
                                        style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                                        decoration: _fieldDeco("District", Icons.map_outlined, isDark),
                                        validator: (value) => value == null || value.trim().isEmpty ? 'Please enter district' : null,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: TextFormField(
                                        controller: _phoneController,
                                        keyboardType: TextInputType.phone,
                                        style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                                        decoration: _fieldDeco("Contact Number", Icons.phone_outlined, isDark),
                                        validator: (value) {
                                          if (value == null || value.trim().isEmpty) return 'Please enter contact number';
                                          final phoneStr = value.trim();
                                          if (phoneStr.length < 9) return 'Enter a valid contact number';
                                          return null;
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 18),
                                TextFormField(
                                  controller: _addressController,
                                  style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                                  decoration: _fieldDeco("Official Address", Icons.location_on_outlined, isDark),
                                  validator: (value) => value == null || value.trim().isEmpty ? 'Please enter address' : null,
                                ),
                              ] else ...[
                                TextFormField(
                                  controller: _nameController,
                                  style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                                  decoration: _fieldDeco("Hospital Name", Icons.local_hospital_outlined, isDark),
                                  validator: (value) => value == null || value.trim().isEmpty ? 'Please enter hospital name' : null,
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: _addressController,
                                  style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                                  decoration: _fieldDeco("Official Address", Icons.location_on_outlined, isDark),
                                  validator: (value) => value == null || value.trim().isEmpty ? 'Please enter address' : null,
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: _districtController,
                                  style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                                  decoration: _fieldDeco("District", Icons.map_outlined, isDark),
                                  validator: (value) => value == null || value.trim().isEmpty ? 'Please enter district' : null,
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: _phoneController,
                                  keyboardType: TextInputType.phone,
                                  style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                                  decoration: _fieldDeco("Contact Number", Icons.phone_outlined, isDark),
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) return 'Please enter contact number';
                                    final phoneStr = value.trim();
                                    if (phoneStr.length < 9) return 'Enter a valid contact number';
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: _chargesController,
                                  keyboardType: TextInputType.number,
                                  style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                                  decoration: _fieldDeco("Hospital Charges (LKR)", Icons.payment_outlined, isDark),
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) return 'Please enter hospital charges';
                                    if (double.tryParse(value.trim()) == null) return 'Enter a valid number';
                                    return null;
                                  },
                                ),
                              ],

                              const SizedBox(height: 32),

                              Row(
                                children: [
                                  if (isDesktop) ...[
                                    Expanded(
                                      child: OutlinedButton(
                                        onPressed: () => Navigator.of(context).pop(),
                                        style: OutlinedButton.styleFrom(
                                          minimumSize: const Size(0, 50),
                                          foregroundColor: isDark ? Colors.white70 : Colors.grey.shade700,
                                          side: BorderSide(color: isDark ? const Color(0xFF334155) : Colors.grey.shade300),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                        ),
                                        child: const Text("Cancel", style: TextStyle(fontWeight: FontWeight.bold)),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                  ],
                                  Expanded(
                                    child: Container(
                                      height: 50,
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          colors: [Color(0xFFF43F5E), Color(0xFFE11D48)],
                                        ),
                                        borderRadius: BorderRadius.circular(16),
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color(0xFFE11D48).withValues(alpha: 0.3),
                                            blurRadius: 12,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: ElevatedButton.icon(
                                        onPressed: _isSaving ? null : _saveHospital,
                                        icon: const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                                        label: _isSaving
                                            ? const SizedBox(
                                                height: 20,
                                                width: 20,
                                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                              )
                                            : const Text(
                                                'Save Hospital',
                                                style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                                              ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.transparent,
                                          shadowColor: Colors.transparent,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
