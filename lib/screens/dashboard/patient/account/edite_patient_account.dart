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

  // 🔄 Firestore එකෙන් දත්ත ලබාගැනීමේ Function එක
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
        title: const Text("Edit Profile", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator()) 
            : SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Update Your Information",
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        "Keep your profile details up to date for better channelings.",
                        style: TextStyle(color: Colors.grey, fontSize: 14),
                      ),
                      const SizedBox(height: 32),

                      // 📸 --- IMAGE PICKER ---
                      Center(
                        child: Stack(
                          children: [
                            CircleAvatar(
                              radius: 54,
                              backgroundColor: Colors.grey.shade200,
                              backgroundImage: _selectedImage != null 
                                  ? FileImage(_selectedImage!) 
                                  : (_existingProfileImageUrl.isNotEmpty 
                                      ? NetworkImage(_existingProfileImageUrl) as ImageProvider
                                      : null),
                              child: _selectedImage == null && _existingProfileImageUrl.isEmpty
                                  ? Icon(Icons.person, size: 55, color: Colors.grey.shade400)
                                  : null,
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
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
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
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
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
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                prefixIcon: const Icon(Icons.cake_outlined),
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
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                prefixIcon: const Icon(Icons.wc_outlined),
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
                          final newNicRegEx = RegExp(r'^[0-9]{12}$');
                          if (!oldNicRegEx.hasMatch(nicStr) && !newNicRegEx.hasMatch(nicStr)) {
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
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _isSaving ? null : _updatePatientProfile,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        prefixIcon: Icon(prefixIcon),
      ),
      validator: validator,
    );
  }
}