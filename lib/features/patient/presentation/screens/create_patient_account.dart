import 'dart:io';
import 'package:appoinment_app/core/services/notification_services.dart';
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
  final _weightController = TextEditingController();
  
  String? _selectedGender;
  String? _selectedBloodGroup;
  bool _isSaving = false;
  bool _isPickingImage = false; 
  File? _selectedImage; 

  final List<String> _genderOptions = ['Male', 'Female', 'Other'];
  final List<String> _bloodGroupOptions = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];

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
      final fileName = '$uid/profile_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final bytes = await _selectedImage!.readAsBytes();
      
      await supabase.Supabase.instance.client.storage
          .from('profile_images') 
          .uploadBinary(
            fileName, 
            bytes,
            fileOptions: const supabase.FileOptions(
              cacheControl: '3600',
              upsert: true,
              contentType: 'image/jpeg',
            ),
          );

      final String publicUrl = supabase.Supabase.instance.client.storage
          .from('profile_images')
          .getPublicUrl(fileName);

      return publicUrl;
    } catch (e) {
      debugPrint("Supabase Upload Error: $e");
      return "";
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
          'weight': _weightController.text.trim().isNotEmpty ? '${_weightController.text.trim()} kg' : '70 kg',
          'bloodGroup': _selectedBloodGroup ?? 'O+',
          'address': _addressController.text.trim(),
          'city': _cityController.text.trim(),
          'nicNumber': _nicController.text.trim().toUpperCase(),
          'email': user.email,
          'profileImageUrl': imageUrl,
          'createdAt': FieldValue.serverTimestamp(),
        });
        
        try {
          await NotificationService().showNotification(
            id: 101,
            title: 'Profile Created Successfully',
            body: 'Your patient profile has been set up.',
          );
        } catch (e) {
          debugPrint('Notification error: $e');
        }

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
    _weightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF0EA5E9);
    const secondaryColor = Color(0xFF2563EB);
    const textDarkColor = Color(0xFF0F172A);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F8FF),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            children: [
              // --- CREATIVE TOP HEADER WITH GRADIENT ACCENT ---
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(32),
                    bottomRight: Radius.circular(32),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0EA5E9).withAlpha(15),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: primaryColor.withAlpha(25),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.verified_user_rounded, size: 14, color: primaryColor),
                          const SizedBox(width: 6),
                          const Text(
                            "PATIENT ONBOARDING",
                            style: TextStyle(
                              color: primaryColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      "Complete Your Profile",
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: textDarkColor,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "Please enter your details to set up your patient account.",
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // --- CREATIVE AVATAR PICKER ---
                    Center(
                      child: Column(
                        children: [
                          GestureDetector(
                            onTap: _pickImage,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                // Glowing background ring
                                Container(
                                  width: 116,
                                  height: 116,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: const LinearGradient(
                                      colors: [primaryColor, secondaryColor],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: primaryColor.withAlpha(80),
                                        blurRadius: 16,
                                        offset: const Offset(0, 6),
                                      ),
                                    ],
                                  ),
                                ),
                                // Inner avatar container
                                Container(
                                  width: 108,
                                  height: 108,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white,
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(3.0),
                                    child: CircleAvatar(
                                      radius: 50,
                                      backgroundColor: const Color(0xFFF1F5F9),
                                      backgroundImage: _selectedImage != null
                                          ? FileImage(_selectedImage!)
                                          : null,
                                      child: _selectedImage == null
                                          ? Icon(Icons.person_rounded, size: 52, color: Colors.grey.shade400)
                                          : null,
                                    ),
                                  ),
                                ),
                                // Camera badge button
                                Positioned(
                                  bottom: 2,
                                  right: 2,
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: const LinearGradient(
                                        colors: [primaryColor, secondaryColor],
                                      ),
                                      border: Border.all(color: Colors.white, width: 2.5),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withAlpha(30),
                                          blurRadius: 6,
                                          offset: const Offset(0, 3),
                                        ),
                                      ],
                                    ),
                                    child: _isPickingImage
                                        ? const SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          )
                                        : const Icon(
                                            Icons.camera_alt_rounded,
                                            color: Colors.white,
                                            size: 16,
                                          ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 200),
                            child: _selectedImage != null
                                ? Container(
                                    key: const ValueKey("selected"),
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.green.shade50,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: Colors.green.shade200),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.check_circle_rounded, size: 14, color: Colors.green.shade600),
                                        const SizedBox(width: 4),
                                        Text(
                                          "Photo added",
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.green.shade700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                : Text(
                                    "Tap to upload photo",
                                    key: const ValueKey("unselected"),
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: primaryColor,
                                    ),
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // --- FORM SECTION ---
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // --- SECTION 1: PERSONAL INFORMATION ---
                      _buildSectionCard(
                        title: "Personal Information",
                        icon: Icons.person_outline_rounded,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _firstNameController,
                                  textCapitalization: TextCapitalization.words,
                                  decoration: _buildInputDecoration(
                                    labelText: 'First Name',
                                    hintText: 'John',
                                  ),
                                  validator: (value) => value == null || value.trim().isEmpty ? 'Required' : null,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextFormField(
                                  controller: _lastNameController,
                                  textCapitalization: TextCapitalization.words,
                                  decoration: _buildInputDecoration(
                                    labelText: 'Last Name',
                                    hintText: 'Doe',
                                  ),
                                  validator: (value) => value == null || value.trim().isEmpty ? 'Required' : null,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: TextFormField(
                                  controller: _ageController,
                                  keyboardType: TextInputType.number,
                                  decoration: _buildInputDecoration(
                                    labelText: 'Age',
                                    prefixIcon: Icons.cake_outlined,
                                    hintText: '25',
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
                                  decoration: _buildInputDecoration(
                                    labelText: 'Gender',
                                    prefixIcon: Icons.wc_outlined,
                                  ),
                                  dropdownColor: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
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
                        ],
                      ),
                      const SizedBox(height: 16),

                      // --- SECTION 2: HEALTH DETAILS ---
                      _buildSectionCard(
                        title: "Health Metrics",
                        icon: Icons.favorite_outline_rounded,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: TextFormField(
                                  controller: _weightController,
                                  keyboardType: TextInputType.number,
                                  decoration: _buildInputDecoration(
                                    labelText: 'Weight (kg)',
                                    prefixIcon: Icons.scale_outlined,
                                    hintText: '70',
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) return 'Required';
                                    if (double.tryParse(value) == null) return 'Invalid';
                                    return null;
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                flex: 3,
                                child: DropdownButtonFormField<String>(
                                  initialValue: _selectedBloodGroup,
                                  decoration: _buildInputDecoration(
                                    labelText: 'Blood Group',
                                    prefixIcon: Icons.bloodtype_outlined,
                                  ),
                                  dropdownColor: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  items: _bloodGroupOptions.map((String bg) {
                                    return DropdownMenuItem<String>(
                                      value: bg,
                                      child: Text(bg),
                                    );
                                  }).toList(),
                                  onChanged: (newValue) {
                                    setState(() {
                                      _selectedBloodGroup = newValue;
                                    });
                                  },
                                  validator: (value) => value == null ? 'Select Group' : null,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          TextModelField(
                            controller: _nicController,
                            labelText: 'NIC Number',
                            hintText: '123456789V or 123456789012',
                            prefixIcon: Icons.badge_outlined,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter your NIC number';
                              }
                              final nicStr = value.trim().toUpperCase();
                              final oldNicRegEx = RegExp(r'^[0-9]{9}[VXvx]$');
                              final newNicRegEx = RegExp(r'^[0-9]{12}$');

                              if (!oldNicRegEx.hasMatch(nicStr) && !newNicRegEx.hasMatch(nicStr)) {
                                return 'Enter a valid Sri Lankan NIC (e.g., 123456789V)';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // --- SECTION 3: CONTACT & LOCATION ---
                      _buildSectionCard(
                        title: "Contact & Address",
                        icon: Icons.location_on_outlined,
                        children: [
                          TextModelField(
                            controller: _phoneController,
                            labelText: 'Phone Number',
                            hintText: '0771234567',
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
                          const SizedBox(height: 16),
                          TextModelField(
                            controller: _addressController,
                            labelText: 'Address',
                            hintText: '123 Main Street',
                            prefixIcon: Icons.home_outlined,
                            validator: (value) => value == null || value.trim().isEmpty ? 'Please enter your address' : null,
                          ),
                          const SizedBox(height: 16),
                          TextModelField(
                            controller: _cityController,
                            labelText: 'City',
                            hintText: 'Colombo',
                            prefixIcon: Icons.location_city_outlined,
                            validator: (value) => value == null || value.trim().isEmpty ? 'Please enter your city' : null,
                          ),
                        ],
                      ),
                      const SizedBox(height: 28),

                      // --- CREATIVE GRADIENT SUBMIT BUTTON ---
                      Container(
                        width: double.infinity,
                        height: 56,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          gradient: const LinearGradient(
                            colors: [primaryColor, secondaryColor],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: primaryColor.withAlpha(90),
                              blurRadius: 18,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: _isSaving ? null : _savePatientProfile,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: _isSaving
                              ? const SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.5,
                                  ),
                                )
                              : const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'Create Account',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 17,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                                    SizedBox(width: 8),
                                    Icon(
                                      Icons.arrow_forward_rounded,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ],
                                ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- HELPER WIDGET FOR SECTION CARDS ---
  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0EA5E9).withAlpha(10),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF0EA5E9).withAlpha(20),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 20, color: const Color(0xFF0EA5E9)),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  // --- INPUT DECORATION BUILDER ---
  static InputDecoration _buildInputDecoration({
    required String labelText,
    IconData? prefixIcon,
    String? hintText,
  }) {
    const primaryColor = Color(0xFF0EA5E9);
    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
      labelStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 14, fontWeight: FontWeight.w500),
      prefixIcon: prefixIcon != null ? Icon(prefixIcon, color: primaryColor, size: 22) : null,
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1.2),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: primaryColor, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.2),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFEF4444), width: 2),
      ),
    );
  }
}

class TextModelField extends StatelessWidget {
  final TextEditingController controller;
  final String labelText;
  final String? hintText;
  final IconData prefixIcon;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;

  const TextModelField({
    super.key,
    required this.controller,
    required this.labelText,
    this.hintText,
    required this.prefixIcon,
    this.keyboardType = TextInputType.text,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: _PatientProfileCreatePageState._buildInputDecoration(
        labelText: labelText,
        prefixIcon: prefixIcon,
        hintText: hintText,
      ),
      validator: validator,
    );
  }
}