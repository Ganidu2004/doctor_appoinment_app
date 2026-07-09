import 'dart:io';
import 'package:appoinment_app/screens/dashboard/doctor/notification/services_notification.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart'; 
import 'package:supabase_flutter/supabase_flutter.dart' as supabase; 

// --- Doctor Profile Page ---
class DoctorProfileCreatePage extends StatefulWidget {
  final VoidCallback onProfileCreated;
  final Map<String, dynamic>? existingData; 

  const DoctorProfileCreatePage({
    super.key, 
    required this.onProfileCreated,
    this.existingData, 
  });

  @override
  State<DoctorProfileCreatePage> createState() => _DoctorProfileCreatePageState();
}

class _DoctorProfileCreatePageState extends State<DoctorProfileCreatePage> {
  final _formKey = GlobalKey<FormState>();
  
  final _nameController = TextEditingController();
  final _aboutMeController = TextEditingController();
  final _personalPhoneController = TextEditingController(); 
  final _experienceController = TextEditingController();
  
  List<TextEditingController> _qualificationControllers = [];

  // Hospital selection state
  List<Map<String, dynamic>> _availableHospitals = [];
  List<Map<String, dynamic>> _selectedHospitals = [];
  bool _isLoadingHospitals = true;

  String? _selectedGender;
  final List<String> _genders = ['Male', 'Female', 'Other'];

  String? _selectedSpecialization;
  final List<String> _specializations = [
    'Cardiologist', 'Pediatrician', 'Dermatologist', 'Neurologist',
    'General Practitioner', 'Orthopedic Surgeon', 'Psychiatrist'
  ];

  bool _isSaving = false;

  File? _pickedImage; 
  String? _existingImageUrl; 

  @override
  void initState() {
    super.initState();
    _loadHospitals();
    
    if (widget.existingData != null) {
      final data = widget.existingData!;
      
      _nameController.text = data['name'] ?? '';
      _aboutMeController.text = data['aboutMe'] ?? '';
      _personalPhoneController.text = data['personalPhone'] ?? data['phone'] ?? '';
      _experienceController.text = data['experience']?.toString() ?? '';
      _existingImageUrl = data['profileImageUrl'] ?? data['imageUrl']; 
      
      if (_genders.contains(data['gender'])) {
        _selectedGender = data['gender'];
      }
      if (_specializations.contains(data['specialization'])) {
        _selectedSpecialization = data['specialization'];
      }

      if (data['qualifications'] != null && (data['qualifications'] as List).isNotEmpty) {
        _qualificationControllers = (data['qualifications'] as List).map((q) {
          return TextEditingController(text: q.toString());
        }).toList();
      } else {
        _qualificationControllers = [TextEditingController()];
      }
    } else {
      _qualificationControllers = [TextEditingController()];
    }
  }

  Future<void> _loadHospitals() async {
    try {
      final snapshot = await FirebaseFirestore.instance.collection('hospital').get();
      final seenIds = <String>{};
      final seenNames = <String>{};
      final hospitals = <Map<String, dynamic>>[];
      
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final name = (data['name'] ?? 'Unknown Hospital').trim();
        final id = doc.id;
        
        if (seenIds.add(id)) {
          if (seenNames.add(name.toLowerCase())) {
            hospitals.add({
              'id': id,
              'hospitalName': name,
              'address': data['address'] ?? '',
              'district': data['district'] ?? '',
              'hospitalPhone': data['contact'] ?? '',
              'charges': data['charges'] is num ? (data['charges'] as num).toDouble() : 0.0,
            });
          }
        }
      }

      // Pre-select hospitals if editing existing data
      List<Map<String, dynamic>> preSelected = [];
      if (widget.existingData != null && widget.existingData!['hospitalsList'] != null) {
        final existingList = widget.existingData!['hospitalsList'] as List;
        for (var existing in existingList) {
          final hMap = existing as Map<String, dynamic>;
          final hospitalId = hMap['hospitalId'] ?? '';
          // Try to match by ID first, then by name as fallback
          final match = hospitals.firstWhere(
            (h) => h['id'] == hospitalId,
            orElse: () => hospitals.firstWhere(
              (h) => h['hospitalName'] == hMap['hospitalName'],
              orElse: () => <String, dynamic>{},
            ),
          );
          if (match.isNotEmpty && !preSelected.any((s) => s['id'] == match['id'])) {
            preSelected.add(match);
          }
        }
      }

      if (mounted) {
        setState(() {
          _availableHospitals = hospitals;
          _selectedHospitals = preSelected;
          _isLoadingHospitals = false;
        });
      }
    } catch (e) {
      debugPrint("Error loading hospitals: $e");
      if (mounted) setState(() => _isLoadingHospitals = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _aboutMeController.dispose();
    _personalPhoneController.dispose();
    _experienceController.dispose();
    for (var controller in _qualificationControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    
    if (image != null) {
      setState(() {
        _pickedImage = File(image.path);
      });
    }
  }

  void _addQualificationField() {
    setState(() {
      _qualificationControllers.add(TextEditingController());
    });
  }

  void _removeQualificationField(int index) {
    if (_qualificationControllers.length > 1) {
      setState(() {
        _qualificationControllers[index].dispose();
        _qualificationControllers.removeAt(index);
      });
    }
  }

  Future<void> _saveProfile() async {
  if (!_formKey.currentState!.validate()) return;

  if (_selectedHospitals.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Please select at least one hospital.'), backgroundColor: Colors.redAccent),
    );
    return;
  }

  setState(() {
    _isSaving = true;
  });

  try {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      
      String finalImageUrl = _existingImageUrl ?? "";

      if (_pickedImage != null) {
        final fileName = '${user.uid}/profile.jpg'; 
        
        try {
          await supabase.Supabase.instance.client.storage
              .from('profile_images')
              .upload(
                fileName, 
                _pickedImage!, 
                fileOptions: const supabase.FileOptions(
                  cacheControl: '3600', 
                  upsert: true,
                  contentType: 'image/jpeg',
                ),
              );
              
          final String publicUrl = supabase.Supabase.instance.client.storage
              .from('profile_images')
              .getPublicUrl(fileName);
          
          finalImageUrl = "$publicUrl?t=${DateTime.now().millisecondsSinceEpoch}";
        } catch (storageError) {
          debugPrint("Supabase Storage Error: $storageError");
          throw 'Storage Upload Failed: $storageError';
        }
      }

      List<String> qualificationsList = _qualificationControllers
          .map((c) => c.text.trim())
          .where((text) => text.isNotEmpty)
          .toList();

      List<String> hospitalPhonesList = _selectedHospitals
          .map((h) => (h['hospitalPhone'] ?? '').toString())
          .where((text) => text.isNotEmpty)
          .toList();

      List<Map<String, dynamic>> finalHospitalsList = _selectedHospitals
          .map((h) => {
            'hospitalId': h['id'] ?? '',
            'hospitalName': h['hospitalName'] ?? '',
            'hospitalPhone': h['hospitalPhone'] ?? '',
            'hospitalDistrict': h['district'] ?? '',
            'hospitalAddresses': [h['address'] ?? ''].where((a) => a.isNotEmpty).toList(),
          })
          .toList();

      final Map<String, dynamic> updatedData = {
        'name': _nameController.text.trim(),
        'gender': _selectedGender ?? '',
        'specialization': _selectedSpecialization ?? 'General',
        'phone': _personalPhoneController.text.trim(),
        'personalPhone': _personalPhoneController.text.trim(),
        'experience': int.tryParse(_experienceController.text.trim()) ?? 0,
        'hospitalPhones': hospitalPhonesList,
        'hospitalsList': finalHospitalsList,
        'qualifications': qualificationsList,
        'aboutMe': _aboutMeController.text.trim(),
        'profileImageUrl': finalImageUrl, 
        'imageUrl': finalImageUrl,
      };

      bool isUpdating = widget.existingData != null;
      if (!isUpdating) {
        updatedData['uid'] = user.uid;
        updatedData['createdAt'] = FieldValue.serverTimestamp();
      }

      await FirebaseFirestore.instance
          .collection('doctors') 
          .doc(user.uid)         
          .set(updatedData, SetOptions(merge: true)); 

      await NotificationService.showNotification(
        id: 1,
        title: isUpdating ? 'Profile Updated!' : 'Profile Created!',
        body: isUpdating 
              ? 'Your profile details have been updated.' 
              : 'Your profile has been created.',
      );

      if (!mounted) return;
      widget.onProfileCreated();
    }
  } catch (e) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Profile saving failed: $e')),
    );
  } finally {
    if (mounted) {
      setState(() {
        _isSaving = false;
      });
    }
  }
}

  // Build the hospital selection section
  Widget _buildHospitalSelectionSection() {
    if (_isLoadingHospitals) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: const Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
              SizedBox(width: 12),
              Text('Loading hospitals...', style: TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      );
    }

    if (_availableHospitals.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.red[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red[200]!),
        ),
        child: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.redAccent),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'No hospitals available. Please contact the admin to add hospitals.',
                style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      );
    }

    // Filter out already-selected hospitals from the dropdown
    final unselectedHospitals = _availableHospitals
        .where((h) => !_selectedHospitals.any((s) => s['id'] == h['id']))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Dropdown to add a hospital
        if (unselectedHospitals.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[400]!),
              color: Colors.white,
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<Map<String, dynamic>>(
                value: null,
                isExpanded: true,
                hint: const Row(
                  children: [
                    Icon(Icons.add_business, color: Color(0xFF0D47A1), size: 20),
                    SizedBox(width: 10),
                    Text('Select a hospital to add'),
                  ],
                ),
                icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF0D47A1)),
                items: unselectedHospitals.map((hospital) {
                  final district = hospital['district'] ?? '';
                  final displayName = district.isNotEmpty
                      ? "${hospital['hospitalName']} — $district"
                      : hospital['hospitalName'] ?? 'Unknown Hospital';
                  return DropdownMenuItem<Map<String, dynamic>>(
                    value: hospital,
                    child: Row(
                      children: [
                        const Icon(Icons.local_hospital, color: Color(0xFF0D47A1), size: 20),
                        const SizedBox(width: 10),
                        Expanded(child: Text(displayName, overflow: TextOverflow.ellipsis)),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedHospitals.add(value);
                    });
                  }
                },
              ),
            ),
          ),

        if (unselectedHospitals.isEmpty && _selectedHospitals.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green[200]!),
            ),
            child: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 20),
                SizedBox(width: 8),
                Text('All available hospitals have been selected.', 
                  style: TextStyle(color: Colors.green, fontSize: 13, fontWeight: FontWeight.w500)),
              ],
            ),
          ),

        const SizedBox(height: 12),

        // Selected hospitals as cards
        if (_selectedHospitals.isNotEmpty)
          ...List.generate(_selectedHospitals.length, (index) {
            final hospital = _selectedHospitals[index];
            final district = hospital['district'] ?? '';
            final address = hospital['address'] ?? '';
            final contact = hospital['hospitalPhone'] ?? '';
            
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.blue[50]?.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0D47A1).withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.local_hospital, color: Color(0xFF0D47A1), size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          hospital['hospitalName'] ?? 'Unknown',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        if (district.isNotEmpty || address.isNotEmpty)
                          Text(
                            [address, district].where((s) => s.isNotEmpty).join(', '),
                            style: TextStyle(color: Colors.grey[600], fontSize: 12),
                          ),
                        if (contact.isNotEmpty)
                          Text(
                            '📞 $contact',
                            style: TextStyle(color: Colors.grey[500], fontSize: 11),
                          ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.redAccent, size: 20),
                    onPressed: () {
                      setState(() {
                        _selectedHospitals.removeAt(index);
                      });
                    },
                    tooltip: 'Remove hospital',
                  ),
                ],
              ),
            );
          }),
        
        if (_selectedHospitals.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              'No hospitals selected. Please select at least one hospital from the dropdown above.',
              style: TextStyle(color: Colors.grey[500], fontStyle: FontStyle.italic, fontSize: 13),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Complete Doctor Profile'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            onPressed: () => FirebaseAuth.instance.signOut(),
          ),
        ],
      ),
      body: _isSaving
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text("Saving profile & uploading image... Please wait."),
                ],
              ),
            )
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // --- PROFILE IMAGE SELECTOR SECTION ---
                      Center(
                        child: GestureDetector(
                          onTap: _pickImage,
                          child: Stack(
                            children: [
                              CircleAvatar(
                                radius: 55,
                                backgroundColor: Colors.grey.shade200,
                                backgroundImage: _pickedImage != null 
                                    ? FileImage(_pickedImage!) 
                                    : (_existingImageUrl != null ? NetworkImage(_existingImageUrl!) : null) as ImageProvider?,
                                child: _pickedImage == null && _existingImageUrl == null
                                    ? Icon(Icons.add_a_photo_outlined, size: 36, color: Colors.grey.shade600)
                                    : null,
                              ),
                              Positioned(
                                bottom: 0,
                                right: 2,
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: const BoxDecoration(color: Color(0xFF0D47A1), shape: BoxShape.circle),
                                  child: const Icon(Icons.camera_alt, color: Colors.white, size: 16),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      TextFormField(
                        controller: _nameController,
                        textCapitalization: TextCapitalization.words,
                        decoration: InputDecoration(
                          labelText: 'Full Name',
                          prefixIcon: const Icon(Icons.person_outline),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        validator: (value) => value == null || value.trim().isEmpty ? 'Please enter name' : null,
                      ),
                      const SizedBox(height: 16),
                      // Experience Field
                      TextFormField(
                        controller: _experienceController,
                                          keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Years of Experience',
                                                hintText: 'Enter number of years (e.g., 5)',
                                                prefixIcon: const Icon(Icons.work_outline),
                                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                              ),
                                              validator: (value) {
                                                if (value == null || value.trim().isEmpty) return 'Please enter your experience';
                                                final n = int.tryParse(value.trim());
                                                if (n == null) return 'Enter a valid number';
                                                if (n < 0 || n > 80) return 'Enter a realistic number of years';
                                                return null;
                                              },
                                              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                            ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        initialValue: _selectedGender,
                        hint: const Text('Select Gender'),
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.wc_outlined),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        items: _genders.map((String value) {
                          return DropdownMenuItem<String>(value: value, child: Text(value));
                        }).toList(),
                        onChanged: (newValue) => setState(() => _selectedGender = newValue),
                        validator: (value) => value == null ? 'Please select your gender' : null,
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        initialValue: _selectedSpecialization,
                        hint: const Text('Select Specialization'),
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.assignment_ind_outlined),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        items: _specializations.map((String value) {
                          return DropdownMenuItem<String>(value: value, child: Text(value));
                        }).toList(),
                        onChanged: (newValue) => setState(() => _selectedSpecialization = newValue),
                        validator: (value) => value == null ? 'Please select a specialty' : null,
                      ),
                      const SizedBox(height: 24),
                      const Text('Contact Information', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0D47A1))),
                      const Divider(),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _personalPhoneController,
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          labelText: 'Personal Contact Number',
                          prefixIcon: const Icon(Icons.phone_android_outlined),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        validator: (value) => value == null || value.trim().isEmpty ? 'Please enter personal phone number.' : null,
                      ),
                      const SizedBox(height: 24),

                      // --- HOSPITAL SELECTION SECTION ---
                      const Text('Hospitals & Addresses Details', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0D47A1))),
                      const Divider(),
                      const SizedBox(height: 8),
                      _buildHospitalSelectionSection(),

                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Qualifications / Degrees', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          TextButton.icon(onPressed: _addQualificationField, icon: const Icon(Icons.add), label: const Text('Add More')),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _qualificationControllers.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10.0),
                            child: Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _qualificationControllers[index],
                                    decoration: InputDecoration(labelText: 'Qualification #${index + 1}', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                                    validator: (value) => value == null || value.trim().isEmpty ? 'Enter the Degree' : null,
                                  ),
                                ),
                                if (_qualificationControllers.length > 1)
                                  IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red), onPressed: () => _removeQualificationField(index)),
                              ],
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _aboutMeController,
                        maxLines: 4,
                        decoration: InputDecoration(
                          labelText: 'About Me',
                          alignLabelWithHint: true,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        validator: (value) => value == null || value.trim().isEmpty ? 'Please include a brief introduction about yourself.' : null,
                      ),
                      const SizedBox(height: 32),
                      ElevatedButton(
                        onPressed: _saveProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0D47A1),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Save Profile & Continue', style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}