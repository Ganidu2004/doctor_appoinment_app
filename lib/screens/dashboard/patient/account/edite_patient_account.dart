import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import 'package:appoinment_app/services/notification_services.dart';

class PatientProfileEditPage extends StatefulWidget {
  final String userId;

  const PatientProfileEditPage({
    super.key, 
    required this.userId, 
  });

  @override
  State<PatientProfileEditPage> createState() => _PatientProfileEditPageState();
}

class _PatientProfileEditPageState extends State<PatientProfileEditPage> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _ageController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _nicController = TextEditingController();
  
  String? _selectedGender;
  bool _isLoading = true; 
  bool _isSaving = false;
  File? _selectedImage; 
  String _existingProfileImageUrl = ""; 

  final List<String> _genderOptions = ['Male', 'Female', 'Other'];

  @override
  void initState() {
    super.initState();
    _fetchUserData(); 
  }

  Future<void> _fetchUserData() async {
    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('patients')
          .doc(widget.userId)
          .get();

      if (doc.exists && doc.data() != null) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        
        setState(() {
          _firstNameController.text = data['firstName'] ?? '';
          _lastNameController.text = data['lastName'] ?? '';
          _phoneController.text = data['phone'] ?? '';
          _ageController.text = data['age']?.toString() ?? '';
          _addressController.text = data['address'] ?? '';
          _cityController.text = data['city'] ?? '';
          _nicController.text = data['nicNumber'] ?? '';
          _existingProfileImageUrl = data['profileImageUrl'] ?? '';

          if (_genderOptions.contains(data['gender'])) {
            _selectedGender = data['gender'];
          }
          _isLoading = false;
        });
      } else {
        setState(() { _isLoading = false; });
        _showSnackBar("No patient profile found.");
      }
    } catch (e) {
      setState(() { _isLoading = false; });
      debugPrint("Error fetching data: $e");
      _showSnackBar("Failed to load user data.");
    }
  }

  Future<String> _uploadImageToSupabase(String uid) async {
    if (_selectedImage == null) return _existingProfileImageUrl;

    try {
      final fileName = 'public/$uid/profile_${DateTime.now().millisecondsSinceEpoch}.jpg';
      
      await supabase.Supabase.instance.client.storage
          .from('profile_images') 
          .upload(fileName, _selectedImage!);

      final String publicUrl = supabase.Supabase.instance.client.storage
          .from('profile_images')
          .getPublicUrl(fileName);

      return publicUrl;
    } catch (e) {
      debugPrint("Supabase Upload Error: $e");
      throw Exception("Failed to upload profile image.");
    }
  }

  Future<void> _updatePatientProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() { _isSaving = true; });

    try {
      String imageUrl = _existingProfileImageUrl;
      if (_selectedImage != null) {
        imageUrl = await _uploadImageToSupabase(widget.userId);
      }

      final int parsedAge = int.tryParse(_ageController.text.trim()) ?? 0;

      await FirebaseFirestore.instance.collection('patients').doc(widget.userId).update({
        'firstName': _firstNameController.text.trim(),
        'lastName': _lastNameController.text.trim(),
        'name': '${_firstNameController.text.trim()} ${_lastNameController.text.trim()}', 
        'phone': _phoneController.text.trim(),
        'age': parsedAge,
        'gender': _selectedGender,
        'address': _addressController.text.trim(),
        'city': _cityController.text.trim(),
        'nicNumber': _nicController.text.trim().toUpperCase(),
        'profileImageUrl': imageUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      try {
        await NotificationService().showNotification(
          id: 102,
          title: 'Profile Updated Successfully',
          body: 'Your patient profile has been updated.',
        );
      } catch (e) {
        debugPrint('Notification error: $e');
      }

      _showSnackBar("Profile Updated Successfully!");
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      debugPrint("Error updating profile: $e");
      _showSnackBar("Error: ${e.toString()}");
    } finally {
      if (mounted) {
        setState(() { _isSaving = false; });
      }
    }
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _ageController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _nicController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Edit Profile", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator()) 
            : SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Update Your Information",
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        "Keep your profile details up to date for better channelings.",
                        style: TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                      const SizedBox(height: 32),

                      // 📸 --- IMAGE PICKER ---
                      Center(
                        child: Stack(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.blue.shade100, width: 3),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.08),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: CircleAvatar(
                                radius: 54,
                                backgroundColor: Colors.grey.shade100,
                                backgroundImage: _selectedImage != null 
                                    ? FileImage(_selectedImage!) 
                                    : (_existingProfileImageUrl.isNotEmpty 
                                        ? NetworkImage(_existingProfileImageUrl) as ImageProvider
                                        : null),
                                child: _selectedImage == null && _existingProfileImageUrl.isEmpty
                                    ? Icon(Icons.person_rounded, size: 55, color: Colors.blue.shade200)
                                    : null,
                              ),
                            ),
                            Positioned(
                              bottom: 0,
                              right: 2,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: const BoxDecoration(
                                  color: Colors.blue,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.camera_alt_rounded,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),

                      // --- FIRST & LAST NAME ---
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _firstNameController,
                              textCapitalization: TextCapitalization.words,
                              decoration: InputDecoration(
                                labelText: 'First Name',
                                labelStyle: TextStyle(color: Colors.grey[500], fontSize: 14),
                                filled: true,
                                fillColor: Colors.grey[50],
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide(color: Colors.grey.shade200),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: const BorderSide(color: Colors.blue, width: 1.5),
                                ),
                                errorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: const BorderSide(color: Colors.redAccent, width: 1),
                                ),
                                focusedErrorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
                                ),
                              ),
                              validator: (value) => value == null || value.trim().isEmpty ? 'Required' : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _lastNameController,
                              textCapitalization: TextCapitalization.words,
                              decoration: InputDecoration(
                                labelText: 'Last Name',
                                labelStyle: TextStyle(color: Colors.grey[500], fontSize: 14),
                                filled: true,
                                fillColor: Colors.grey[50],
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide(color: Colors.grey.shade200),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: const BorderSide(color: Colors.blue, width: 1.5),
                                ),
                                errorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: const BorderSide(color: Colors.redAccent, width: 1),
                                ),
                                focusedErrorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
                                ),
                              ),
                              validator: (value) => value == null || value.trim().isEmpty ? 'Required' : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // --- AGE & GENDER ---
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: TextFormField(
                              controller: _ageController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: 'Age',
                                labelStyle: TextStyle(color: Colors.grey[500], fontSize: 14),
                                filled: true,
                                fillColor: Colors.grey[50],
                                prefixIcon: Icon(Icons.cake_outlined, color: Colors.blue[400]),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide(color: Colors.grey.shade200),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: const BorderSide(color: Colors.blue, width: 1.5),
                                ),
                                errorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: const BorderSide(color: Colors.redAccent, width: 1),
                                ),
                                focusedErrorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) return 'Required';
                                if (int.tryParse(value) == null) return 'Invalid';
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 3,
                            child: DropdownButtonFormField<String>(
                              initialValue: _selectedGender,
                              decoration: InputDecoration(
                                labelText: 'Gender',
                                labelStyle: TextStyle(color: Colors.grey[500], fontSize: 14),
                                filled: true,
                                fillColor: Colors.grey[50],
                                prefixIcon: Icon(Icons.wc_outlined, color: Colors.blue[400]),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide(color: Colors.grey.shade200),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: const BorderSide(color: Colors.blue, width: 1.5),
                                ),
                                errorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: const BorderSide(color: Colors.redAccent, width: 1),
                                ),
                                focusedErrorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
                                ),
                              ),
                              items: _genderOptions.map((String gender) {
                                return DropdownMenuItem<String>(
                                  value: gender,
                                  child: Text(gender),
                                );
                              }).toList(),
                              onChanged: (newValue) {
                                setState(() { _selectedGender = newValue; });
                              },
                              validator: (value) => value == null ? 'Select Gender' : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // 🪪 --- NIC NUMBER ---
                      TextModelField(
                        controller: _nicController,
                        labelText: 'NIC Number',
                        prefixIcon: Icons.badge_outlined,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) return 'Please enter your NIC number';
                          final nicStr = value.trim().toUpperCase();
                          final oldNicRegEx = RegExp(r'^[0-9]{9}[VXvx]$');
                          final nicRegEx12 = RegExp(r'^[0-9]{12}$');
                          if (!oldNicRegEx.hasMatch(nicStr) && !nicRegEx12.hasMatch(nicStr)) {
                            return 'Enter a valid Sri Lankan NIC';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      // 📞 --- PHONE NUMBER ---
                      TextModelField(
                        controller: _phoneController,
                        labelText: 'Phone Number',
                        prefixIcon: Icons.phone_outlined,
                        keyboardType: TextInputType.phone,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) return 'Please enter your phone number';
                          final phoneStr = value.trim();
                          final phoneRegEx = RegExp(r'^0[0-9]{9}$');
                          if (!phoneRegEx.hasMatch(phoneStr)) return 'Enter a valid 10-digit phone number';
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      // --- ADDRESS ---
                      TextModelField(
                        controller: _addressController,
                        labelText: 'Address',
                        prefixIcon: Icons.home_outlined,
                        validator: (value) => value == null || value.trim().isEmpty ? 'Please enter your address' : null,
                      ),
                      const SizedBox(height: 20),

                      // --- CITY ---
                      TextModelField(
                        controller: _cityController,
                        labelText: 'City',
                        prefixIcon: Icons.location_city_outlined,
                        validator: (value) => value == null || value.trim().isEmpty ? 'Please enter your city' : null,
                      ),
                      const SizedBox(height: 40),

                      // --- SAVE BUTTON ---
                      Container(
                        width: double.infinity,
                        height: 52,
                        decoration: BoxDecoration(
                          gradient: _isSaving ? null : const LinearGradient(
                            colors: [Colors.blue, Colors.blueAccent],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: _isSaving ? null : [
                            BoxShadow(
                              color: Colors.blue.withValues(alpha: 0.25),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: _isSaving ? null : _updatePatientProfile,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          child: _isSaving
                              ? const SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                                )
                              : const Text(
                                  'Save Changes',
                                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
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

class TextModelField extends StatelessWidget {
  final TextEditingController controller;
  final String labelText;
  final IconData prefixIcon;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;

  const TextModelField({
    super.key,
    required this.controller,
    required this.labelText,
    required this.prefixIcon,
    this.keyboardType = TextInputType.text,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: labelText,
        labelStyle: TextStyle(color: Colors.grey[500], fontSize: 14),
        filled: true,
        fillColor: Colors.grey[50],
        prefixIcon: Icon(prefixIcon, color: Colors.blue[400]),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.blue, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
        ),
      ),
      validator: validator,
    );
  }
}