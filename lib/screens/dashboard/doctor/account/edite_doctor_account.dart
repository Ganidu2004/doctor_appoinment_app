import 'dart:io';
import 'package:appoinment_app/screens/dashboard/doctor/notification/services_notification.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart'; 
import 'package:supabase_flutter/supabase_flutter.dart' as supabase; 

// --- Hospital Controllers Model ---
class HospitalControllers {
  final TextEditingController nameController;
  final TextEditingController phoneController; 
  final List<TextEditingController> addressControllers;
  String? selectedDistrict; 

  HospitalControllers({
    required this.nameController,
    required this.phoneController,
    required this.addressControllers,
    this.selectedDistrict,
  });

  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    for (var controller in addressControllers) {
      controller.dispose();
    }
  }
}

// --- Doctor Profile Edit Page ---
class DoctorProfileEditPage extends StatefulWidget {
  final Map<String, dynamic> doctorData; 

  const DoctorProfileEditPage({
    super.key, 
    required this.doctorData, 
  });

  @override
  State<DoctorProfileEditPage> createState() => _DoctorProfileEditPageState();
}

class _DoctorProfileEditPageState extends State<DoctorProfileEditPage> {
  final _formKey = GlobalKey<FormState>();
  
  final _nameController = TextEditingController();
  final _aboutMeController = TextEditingController();
  final _personalPhoneController = TextEditingController(); 
  final _experienceController = TextEditingController();
  
  List<TextEditingController> _qualificationControllers = [];
  List<HospitalControllers> _hospitalControllers = [];

  String? _selectedGender;
  final List<String> _genders = ['Male', 'Female', 'Other'];

  String? _selectedSpecialization;
  final List<String> _specializations = [
    'Cardiologist', 'Pediatrician', 'Dermatologist', 'Neurologist',
    'General Practitioner', 'Orthopedic Surgeon', 'Psychiatrist'
  ];

  final List<String> _districts = [
    'Ampara', 'Anuradhapura', 'Badulla', 'Batticaloa', 'Colombo', 'Galle', 
    'Gampaha', 'Hambantota', 'Jaffna', 'Kalutara', 'Kandy', 'Kegalle', 
    'Kilinochchi', 'Kurunegala', 'Mannar', 'Matale', 'Matara', 'Monaragala', 
    'Mullaitivu', 'Nuwara Eliya', 'Polonnaruwa', 'Puttalam', 'Ratnapura', 
    'Trincomalee', 'Vavuniya'
  ];

  bool _isSaving = false;

  File? _pickedImage; 
  String? _existingImageUrl; 

  @override
  void initState() {
    super.initState();
    _loadDoctorData();
  }

  void _loadDoctorData() {
    final data = widget.doctorData;
    
    _nameController.text = data['name'] ?? '';
    _aboutMeController.text = data['aboutMe'] ?? '';
    _personalPhoneController.text = data['personalPhone'] ?? data['phone'] ?? '';
    _existingImageUrl = data['profileImageUrl'] ?? data['imageUrl']; 
    _experienceController.text = data['experience']?.toString() ?? '';
    
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

    if (data['hospitalsList'] != null && (data['hospitalsList'] as List).isNotEmpty) {
      _hospitalControllers = (data['hospitalsList'] as List).map((h) {
        final hMap = h as Map<String, dynamic>;
        
        List<TextEditingController> addrControllers = [];
        if (hMap['hospitalAddresses'] != null && (hMap['hospitalAddresses'] as List).isNotEmpty) {
          addrControllers = (hMap['hospitalAddresses'] as List).map((addr) {
            return TextEditingController(text: addr.toString());
          }).toList();
        } else {
          addrControllers = [TextEditingController()];
        }

        String? dist = hMap['hospitalDistrict'];
        if (dist != null && !_districts.contains(dist)) {
          dist = null; 
        }

        return HospitalControllers(
          nameController: TextEditingController(text: hMap['hospitalName'] ?? ''),
          phoneController: TextEditingController(text: hMap['hospitalPhone'] ?? ''),
          addressControllers: addrControllers,
          selectedDistrict: dist,
        );
      }).toList();
    } else {
      _hospitalControllers = [
        HospitalControllers(
          nameController: TextEditingController(), 
          phoneController: TextEditingController(), 
          addressControllers: [TextEditingController()],
        )
      ];
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _aboutMeController.dispose();
    _personalPhoneController.dispose();
    _experienceController.dispose();
    for (var hController in _hospitalControllers) {
      hController.dispose();
    }
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

  void _addHospitalField() {
    setState(() {
      _hospitalControllers.add(
        HospitalControllers(
          nameController: TextEditingController(), 
          phoneController: TextEditingController(), 
          addressControllers: [TextEditingController()],
        ),
      );
    });
  }

  void _removeHospitalField(int index) {
    if (_hospitalControllers.length > 1) {
      setState(() {
        _hospitalControllers[index].dispose();
        _hospitalControllers.removeAt(index);
      });
    }
  }

  void _addAddressField(int hospitalIndex) {
    setState(() {
      _hospitalControllers[hospitalIndex].addressControllers.add(TextEditingController());
    });
  }

  void _removeAddressField(int hospitalIndex, int addressIndex) {
    if (_hospitalControllers[hospitalIndex].addressControllers.length > 1) {
      setState(() {
        _hospitalControllers[hospitalIndex].addressControllers[addressIndex].dispose();
        _hospitalControllers[hospitalIndex].addressControllers.removeAt(addressIndex);
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

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        
        String finalImageUrl = _existingImageUrl ?? "";

        if (_pickedImage != null) {
          final fileName = '${user.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg';
          
          await supabase.Supabase.instance.client.storage
              .from('avatars')
              .upload(fileName, _pickedImage!, fileOptions: const supabase.FileOptions(cacheControl: '3600', upsert: true));

          finalImageUrl = supabase.Supabase.instance.client.storage
              .from('avatars')
              .getPublicUrl(fileName);
        }

        List<String> qualificationsList = _qualificationControllers
            .map((c) => c.text.trim())
            .where((text) => text.isNotEmpty)
            .toList();

        List<String> hospitalPhonesList = _hospitalControllers
            .map((h) => h.phoneController.text.trim())
            .where((text) => text.isNotEmpty)
            .toList();

        List<Map<String, dynamic>> finalHospitalsList = _hospitalControllers
          .where((h) => h.nameController.text.trim().isNotEmpty)
          .map((h) => {
            'hospitalName': h.nameController.text.trim(),
            'hospitalPhone': h.phoneController.text.trim(), 
            'hospitalDistrict': h.selectedDistrict ?? '', 
            'hospitalAddresses': h.addressControllers
              .map((ac) => ac.text.trim())
              .where((text) => text.isNotEmpty)
              .toList(),
          })
          .toList();

        List<dynamic> existingSchedules = widget.doctorData['schedules'] ?? [];

        final Map<String, dynamic> updatedData = {
          'name': _nameController.text.trim(),
          'gender': _selectedGender ?? '',
          'specialization': _selectedSpecialization ?? 'General',
          'phone': _personalPhoneController.text.trim(),
          'personalPhone': _personalPhoneController.text.trim(),
                    'experience': int.tryParse(_experienceController.text.trim()) ?? (widget.doctorData['experience'] is int ? widget.doctorData['experience'] : int.tryParse(widget.doctorData['experience']?.toString() ?? '0') ?? 0),
                    'hospitalPhones': hospitalPhonesList,
          'hospitalsList': finalHospitalsList,
          'qualifications': qualificationsList,
          'aboutMe': _aboutMeController.text.trim(),
          'schedules': existingSchedules, 
          'profileImageUrl': finalImageUrl, 
          'imageUrl': finalImageUrl,
          'updatedAt': FieldValue.serverTimestamp(), 
        };

        // Firestore Update කිරීම
        await FirebaseFirestore.instance
            .collection('doctors') 
            .doc(user.uid)         
            .update(updatedData);  

        await NotificationService.showNotification(
          id: 2,
          title: 'Profile Updated Successfully!',
          body: 'Your professional changes are now live.',
        );

        if (!mounted) return;
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Changes saved successfully!'), backgroundColor: Colors.green),
        );
        Navigator.of(context).pop(); 
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Update failed: $e'), backgroundColor: Colors.redAccent),
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Professional Profile'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _isSaving
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text("Updating your profile details... Please wait."),
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
                      // --- PROFILE IMAGE EDIT SECTION ---
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

                      // Years of Experience
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
                      const Text('Contact Information', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Hospitals & Addresses Details', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
                          TextButton.icon(onPressed: _addHospitalField, icon: const Icon(Icons.add_business_outlined), label: const Text('Add Hospital')),
                        ],
                      ),
                      const Divider(),
                      const SizedBox(height: 8),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _hospitalControllers.length,
                        itemBuilder: (context, hIndex) {
                          return Container(
                            margin: const EdgeInsets.only(bottom: 20.0),
                            padding: const EdgeInsets.all(16.0),
                            decoration: BoxDecoration(
                              color: Colors.grey[50], 
                              borderRadius: BorderRadius.circular(12), 
                              border: Border.all(color: Colors.grey[300]!),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('Hospital / Clinic Box #${hIndex + 1}', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey[800], fontSize: 14)),
                                    if (_hospitalControllers.length > 1)
                                      IconButton(icon: const Icon(Icons.delete_forever, color: Colors.redAccent), onPressed: () => _removeHospitalField(hIndex)),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                TextFormField(
                                  controller: _hospitalControllers[hIndex].nameController,
                                  textCapitalization: TextCapitalization.words,
                                  decoration: const InputDecoration(labelText: 'Hospital / Clinic Name', prefixIcon: Icon(Icons.local_hospital), filled: true, fillColor: Colors.white, border: OutlineInputBorder()),
                                  validator: (v) => v == null || v.trim().isEmpty ? 'Please enter a hospital name' : null,
                                ),
                                const SizedBox(height: 12),
                                TextFormField(
                                  controller: _hospitalControllers[hIndex].phoneController,
                                  keyboardType: TextInputType.phone,
                                  decoration: const InputDecoration(labelText: 'Hospital Phone Number', prefixIcon: Icon(Icons.phone_in_talk_outlined), filled: true, fillColor: Colors.white, border: OutlineInputBorder()),
                                  validator: (v) => v == null || v.trim().isEmpty ? 'Please enter hospital phone number' : null,
                                ),
                                const SizedBox(height: 12),
                                DropdownButtonFormField<String>(
                                  initialValue: _hospitalControllers[hIndex].selectedDistrict,
                                  hint: const Text('Select Hospital District'),
                                  decoration: const InputDecoration(prefixIcon: Icon(Icons.map_outlined), filled: true, fillColor: Colors.white, border: OutlineInputBorder()),
                                  items: _districts.map((String district) {
                                    return DropdownMenuItem<String>(value: district, child: Text(district));
                                  }).toList(),
                                  onChanged: (newValue) => setState(() => _hospitalControllers[hIndex].selectedDistrict = newValue),
                                  validator: (value) => value == null ? 'Please select the district' : null,
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('Hospital Addresses', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.blueGrey)),
                                    TextButton.icon(
                                      onPressed: () => _addAddressField(hIndex), 
                                      icon: const Icon(Icons.add, size: 16), 
                                      label: const Text('Add Address', style: TextStyle(fontSize: 12)),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Column(
                                  children: List.generate(
                                    _hospitalControllers[hIndex].addressControllers.length,
                                    (aIndex) {
                                      return Padding(
                                        padding: const EdgeInsets.only(bottom: 8.0),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: TextFormField(
                                                controller: _hospitalControllers[hIndex].addressControllers[aIndex],
                                                maxLines: 2,
                                                decoration: const InputDecoration(labelText: 'Address', filled: true, fillColor: Colors.white, border: OutlineInputBorder()),
                                                validator: (v) => v == null || v.trim().isEmpty ? 'Please enter the address' : null,
                                              ),
                                            ),
                                            if (_hospitalControllers[hIndex].addressControllers.length > 1)
                                              IconButton(icon: const Icon(Icons.remove_circle_outline, color: Colors.red), onPressed: () => _removeAddressField(hIndex, aIndex)),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
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
                        onPressed: _updateProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade700,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Save Changes', style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}