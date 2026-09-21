import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../theme/app_theme.dart';
import '../models/user_model.dart';

class ProfileDetailsScreen extends StatefulWidget {
  final PatientProfile profile;
  final bool isBengali;
  final Function(PatientProfile) onProfileUpdated;

  const ProfileDetailsScreen({
    super.key,
    required this.profile,
    this.isBengali = false,
    required this.onProfileUpdated,
  });

  @override
  State<ProfileDetailsScreen> createState() => _ProfileDetailsScreenState();
}

class _ProfileDetailsScreenState extends State<ProfileDetailsScreen> {
  late PatientProfile _currentProfile;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _currentProfile = widget.profile;
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 600,
        maxHeight: 600,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _currentProfile = _currentProfile.copyWith(photoPath: pickedFile.path);
        });
        widget.onProfileUpdated(_currentProfile);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                widget.isBengali ? "প্রোফাইল ছবি সফলভাবে আপডেট হয়েছে!" : "Profile photo updated successfully!",
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.isBengali ? "ছবি আপলোড করতে ব্যর্থ হয়েছে" : "Could not upload photo: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showPhotoOptions() {
    final isBn = widget.isBengali;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                isBn ? "প্রোফাইল ছবি পরিবর্তন করুন" : "Profile Photo Options",
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: AppTheme.primaryLight,
                  child: Icon(Icons.camera_alt_rounded, color: AppTheme.primary),
                ),
                title: Text(
                  isBn ? "ক্যামেরা দিয়ে ছবি তুলুন" : "Take Photo with Camera",
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: AppTheme.primaryLight,
                  child: Icon(Icons.photo_library_rounded, color: AppTheme.primary),
                ),
                title: Text(
                  isBn ? "গ্যালারি থেকে ছবি নির্বাচন করুন" : "Choose from Gallery",
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.gallery);
                },
              ),
              if (_currentProfile.photoPath != null)
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.red.shade50,
                    child: Icon(Icons.delete_outline_rounded, color: Colors.red.shade700),
                  ),
                  title: Text(
                    isBn ? "বর্তমান ছবি মুছুন" : "Remove Current Photo",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.red.shade700),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    setState(() {
                      _currentProfile = _currentProfile.copyWith(clearPhoto: true);
                    });
                    widget.onProfileUpdated(_currentProfile);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(isBn ? "ছবি মুছে ফেলা হয়েছে" : "Photo removed"),
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditProfileDialog() {
    final isBn = widget.isBengali;
    final nameCtrl = TextEditingController(text: _currentProfile.name);
    final phoneCtrl = TextEditingController(text: _currentProfile.phone);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          isBn ? "ব্যক্তিগত তথ্য সম্পাদন" : "Edit Personal Details",
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                style: const TextStyle(fontSize: 16),
                decoration: InputDecoration(
                  labelText: isBn ? "পুরো নাম" : "Full Name",
                  prefixIcon: const Icon(Icons.person_outline_rounded),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: phoneCtrl,
                keyboardType: TextInputType.phone,
                style: const TextStyle(fontSize: 16),
                decoration: InputDecoration(
                  labelText: isBn ? "ফোন নম্বর" : "Phone Number",
                  prefixIcon: const Icon(Icons.phone_outlined),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(isBn ? "বাতিল" : "Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameCtrl.text.trim().isNotEmpty) {
                setState(() {
                  _currentProfile = _currentProfile.copyWith(
                    name: nameCtrl.text.trim(),
                    phone: phoneCtrl.text.trim(),
                  );
                });
                widget.onProfileUpdated(_currentProfile);
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(isBn ? "তথ্য সফলভাবে সংরক্ষিত হয়েছে!" : "Details saved successfully!"),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            child: Text(isBn ? "সংরক্ষণ করুন" : "Save Changes"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isBn = widget.isBengali;

    return Scaffold(
      appBar: AppBar(
        title: Text(isBn ? "ব্যক্তিগত বিবরণ" : "Personal Profile"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Profile Picture Card with Upload/Update/Remove Actions
            Center(
              child: Stack(
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.primaryLight,
                      border: Border.all(color: AppTheme.primary, width: 3.5),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primary.withAlpha(45),
                          blurRadius: 14,
                          offset: const Offset(0, 4),
                        )
                      ],
                    ),
                    child: ClipOval(
                      child: _currentProfile.photoPath != null
                          ? Image.file(
                              File(_currentProfile.photoPath!),
                              fit: BoxFit.cover,
                              width: 120,
                              height: 120,
                            )
                          : const Icon(
                              Icons.elderly_rounded,
                              size: 70,
                              color: AppTheme.primary,
                            ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: _showPhotoOptions,
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppTheme.accent,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2.5),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(40),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.camera_alt_rounded, size: 20, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            Center(
              child: OutlinedButton.icon(
                onPressed: _showPhotoOptions,
                icon: const Icon(Icons.photo_camera_outlined, size: 20),
                label: Text(
                  _currentProfile.photoPath != null
                      ? (isBn ? "ছবি পরিবর্তন / মুছুন" : "Change / Remove Photo")
                      : (isBn ? "ছবি আপলোড করুন" : "Upload Photo"),
                  style: const TextStyle(fontSize: 15),
                ),
              ),
            ),
            const SizedBox(height: 28),

            // 2. Personal Details Card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    _buildDetailItem(
                      icon: Icons.person_rounded,
                      label: isBn ? "পুরো নাম" : "Full Name",
                      value: _currentProfile.name,
                    ),
                    const Divider(height: 24),
                    _buildDetailItem(
                      icon: Icons.email_rounded,
                      label: isBn ? "ইমেইল ঠিকানা" : "Email Address",
                      value: _currentProfile.email,
                    ),
                    const Divider(height: 24),
                    _buildDetailItem(
                      icon: Icons.phone_rounded,
                      label: isBn ? "ফোন নম্বর" : "Phone Number",
                      value: _currentProfile.phone,
                    ),
                    const Divider(height: 24),
                    _buildDetailItem(
                      icon: Icons.calendar_month_rounded,
                      label: isBn ? "নিবন্ধনের তারিখ" : "Registered Date",
                      value: _currentProfile.registeredDate,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 28),

            // 3. Edit Profile Button
            ElevatedButton.icon(
              onPressed: _showEditProfileDialog,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              icon: const Icon(Icons.edit_rounded, size: 22),
              label: Text(
                isBn ? "প্রোফাইল সম্পাদন করুন" : "Edit Profile Details",
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem({required IconData icon, required String label, required String value}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppTheme.primaryLight,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppTheme.primary, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
