import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart'; 
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

class PatientProfileCreatePage extends StatefulWidget {
  final VoidCallback onProfileCreated;

  const PatientProfileCreatePage({super.key, required this.onProfileCreated});

  @override
  State<PatientProfileCreatePage> createState() => _PatientProfileCreatePageState();
}

class _PatientProfileCreatePageState extends State<PatientProfileCreatePage> {
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
  bool _isSaving = false;
  bool _isPickingImage = false; 
  File? _selectedImage; 

  final List<String> _genderOptions = ['Male', 'Female', 'Other'];

  Future<void> _pickImage() async {
    if (_isPickingImage) return;

    setState(() {
      _isPickingImage = true;
    });

    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70, 
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      debugPrint("Error picking image: $e");
    } finally {
      setState(() {
        _isPickingImage = false;
      });
    }
  }

  Future<String> _uploadImageToSupabase(String uid) async {
    if (_selectedImage == null) return "";

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

  Future<void> _savePatientProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        String imageUrl = "";
        if (_selectedImage != null) {
          imageUrl = await _uploadImageToSupabase(user.uid);
        }

        final int parsedAge = int.tryParse(_ageController.text.trim()) ?? 0;

        await FirebaseFirestore.instance.collection('patients').doc(user.uid).set({
          'uid': user.uid,
          'role': 'patient',
          'firstName': _firstNameController.text.trim(),
          'lastName': _lastNameController.text.trim(),
          'name': '${_firstNameController.text.trim()} ${_lastNameController.text.trim()}', 
          'phone': _phoneController.text.trim(),
          'age': parsedAge,
          'gender': _selectedGender,
          'address': _addressController.text.trim(),
          'city': _cityController.text.trim(),
          'nicNumber': _nicController.text.trim().toUpperCase(),
          'email': user.email,
          'profileImageUrl': imageUrl,
          'createdAt': FieldValue.serverTimestamp(),
        });
        
        widget.onProfileCreated();
      }
    } catch (e) {
      if (!mounted) return;
      debugPrint("Error saving patient profile: $e");
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
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                const Text(
                  "Complete Your Profile",
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Please enter your details to set up your patient account.",
                  style: TextStyle(color: Colors.grey, fontSize: 15),
                ),
                const SizedBox(height: 32),

                // 📸 --- IMAGE PICKER UI SECTION ---
                Center(
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 54,
                        backgroundColor: Colors.grey.shade200,
                        backgroundImage: _selectedImage != null 
                            ? FileImage(_selectedImage!) 
                            : null,
                        child: _selectedImage == null
                            ? Icon(Icons.person, size: 55, color: Colors.grey.shade400)
                            : null,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 4,
                        child: GestureDetector(
                          onTap: _pickImage,
                          child: const CircleAvatar(
                            radius: 18,
                            backgroundColor: Colors.blue,
                            child: Icon(Icons.camera_alt, color: Colors.white, size: 18),
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
                          setState(() {
                            _selectedGender = newValue;
                          });
                        },
                        validator: (value) => value == null ? 'Select Gender' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // 🪪 --- NIC NUMBER FIELD (with Validation) ---
                TextModelField(
                  controller: _nicController,
                  labelText: 'NIC Number',
                  prefixIcon: Icons.badge_outlined,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your NIC number';
                    }
                    
                    final nicStr = value.trim().toUpperCase();
                    final oldNicRegEx = RegExp(r'^[0-9]{9}[VXvx]$');
                    final newNicRegEx = RegExp(r'^[0-9]{12}$');

                    if (!oldNicRegEx.hasMatch(nicStr) && !newNicRegEx.hasMatch(nicStr)) {
                      return 'Enter a valid Sri Lankan NIC (e.g., 123456789V or 123456789012)';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // 📞 --- PHONE NUMBER FIELD (with Validation) ---
                TextModelField(
                  controller: _phoneController,
                  labelText: 'Phone Number',
                  prefixIcon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your phone number';
                    }

                    final phoneStr = value.trim();
                    final phoneRegEx = RegExp(r'^0[0-9]{9}$');

                    if (!phoneRegEx.hasMatch(phoneStr)) {
                      return 'Enter a valid 10-digit phone number (e.g., 0771234567)';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Address Field
                TextModelField(
                  controller: _addressController,
                  labelText: 'Address',
                  prefixIcon: Icons.home_outlined,
                  validator: (value) => value == null || value.trim().isEmpty ? 'Please enter your address' : null,
                ),
                const SizedBox(height: 20),

                // City Field
                TextModelField(
                  controller: _cityController,
                  labelText: 'City',
                  prefixIcon: Icons.location_city_outlined,
                  validator: (value) => value == null || value.trim().isEmpty ? 'Please enter your city' : null,
                ),
                const SizedBox(height: 40),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _savePatientProfile,
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
                            'Create Account',
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