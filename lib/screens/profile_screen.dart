import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive/hive.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'set_goals_screen.dart';
import '../services/permission_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String name = "Zenith";
  String email = "zenith@example.com";
  File? _profileImage;
  String _appVersion = "v1.0.0";

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
    _loadProfileImage();
    _loadAppVersion();
  }

  Future<void> _loadUserInfo() async {
    final box = Hive.box('userBox');
    if (!mounted) return;
    setState(() {
      name = box.get('name', defaultValue: 'Zenith');
      email = box.get('email', defaultValue: 'zenith@example.com');
    });
  }

  Future<void> _loadAppVersion() async {
    final info = await PackageInfo.fromPlatform();
    if (!mounted) return;
    setState(() {
      _appVersion = 'v${info.version}';
    });
  }

  Future<void> _loadProfileImage() async {
    final box = Hive.box('userBox');
    final path = box.get('profileImage') as String?;
    if (path != null && File(path).existsSync()) {
      if (!mounted) return;
      setState(() {
        _profileImage = File(path);
      });
    }
  }

  Future<void> _saveUserInfo(String newName, String newEmail) async {
    final box = Hive.box('userBox');
    await box.put('name', newName);
    await box.put('email', newEmail);
    if (!mounted) return;
    setState(() {
      name = newName;
      email = newEmail;
    });
  }

  void _showEditDialog() {
    final formKey = GlobalKey<FormState>(); // ✅ Fixed naming
    final nameController = TextEditingController(text: name);
    final emailController = TextEditingController(text: email);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Edit Profile"),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (value) =>
                    value == null || value.trim().isEmpty ? 'Name cannot be empty' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return 'Email cannot be empty';
                  final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                  return emailRegex.hasMatch(value) ? null : 'Enter a valid email';
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                _saveUserInfo(nameController.text.trim(), emailController.text.trim());
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple),
            child: const Text("Save", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showImagePickerDialog() {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_profileImage != null)
              ListTile(
                leading: const Icon(Icons.remove_red_eye),
                title: const Text("View Profile Picture"),
                onTap: () {
                  Navigator.pop(context);
                  showDialog(
                    context: context,
                    builder: (_) => Dialog(
                      backgroundColor: Colors.transparent,
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Image.file(_profileImage!),
                      ),
                    ),
                  );
                },
              ),
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: const Text("Take Photo"),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text("Choose from Gallery"),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    bool allowed = false;

    if (source == ImageSource.camera) {
      allowed = await requestCameraPermission(context);
    } else {
      allowed = await requestGalleryPermission(context);
    }

    if (!allowed || !mounted) return;

    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source, imageQuality: 85);

    if (picked != null) {
      final dir = await getApplicationDocumentsDirectory();
      final box = Hive.box('userBox');

      final oldPath = box.get('profileImage') as String?;
      if (oldPath != null && File(oldPath).existsSync()) {
        await File(oldPath).delete();
      }

      final newPath = '${dir.path}/profile_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final localImage = await File(picked.path).copy(newPath);

      await box.put('profileImage', localImage.path);
      if (!mounted) return;

      setState(() => _profileImage = localImage);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          backgroundColor: Colors.green[600],
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 2),
          content: Row(
            children: const [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 10),
              Text("Profile picture updated!", style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      );
    }
  }

  void _logout() async {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Confirm Logout"),
        content: const Text("Are you sure you want to log out?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);

              final userBox = Hive.box('userBox');
              final goalBox = Hive.box('goalBox');
              await userBox.delete('name');
              await userBox.delete('email');
              await goalBox.clear();

              if (!mounted) return;

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  behavior: SnackBarBehavior.floating,
                  margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                  backgroundColor: Colors.deepPurple,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  duration: const Duration(seconds: 2),
                  content: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.logout, color: Colors.white),
                      SizedBox(width: 10),
                      Text("Successfully logged out!", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              );

              await Future.delayed(const Duration(milliseconds: 400));
              if (!mounted) return;
              Navigator.pushNamedAndRemoveUntil(context, '/welcome', (route) => false);
            },
            child: const Text("Logout", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showPrivacyPolicy() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Privacy Policy"),
        content: const Text("We value your privacy. This app does not collect personal data."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("OK")),
        ],
      ),
    );
  }

  void _showAboutApp() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("About Trackify"),
        content: const Text(
          "Trackify is your all-in-one wellness tracker for steps, sleep, calories, and heart rate.\n\n"
          "Designed to keep your health goals on track — simply and beautifully.",
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Close")),
        ],
      ),
    );
  }

  void _contactSupport() async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: 'support@trackifyapp.com',
      query: 'subject=Support Request',
    );
    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F9FF),
      appBar: AppBar(
        title: const Text("Profile", style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            GestureDetector(
              onTap: _showImagePickerDialog,
              child: SizedBox(
                height: 90,
                width: 90,
                child: CircleAvatar(
                  backgroundColor: Colors.deepPurple[100],
                  child: _profileImage != null
                      ? ClipOval(
                          child: Image.file(
                            _profileImage!,
                            height: 90,
                            width: 90,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                const Icon(Icons.person, size: 40, color: Colors.white),
                          ),
                        )
                      : const Icon(Icons.person, size: 40, color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(name, style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold)),
            Text(email, style: GoogleFonts.poppins(color: Colors.grey[600])),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _showEditDialog,
              icon: const Icon(Icons.edit, color: Colors.white),
              label: const Text("Edit Profile", style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple),
            ),
            const SizedBox(height: 30),
            Divider(color: Colors.grey[300]),
            const SizedBox(height: 10),
            ListTile(
              leading: const Icon(FontAwesomeIcons.flag),
              title: const Text("Set Goals"),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SetGoalsScreen()),
                );
                if (!mounted) return;
                setState(() {});
              },
            ),
            ListTile(
              leading: const Icon(Icons.privacy_tip_outlined),
              title: const Text("Privacy Policy"),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: _showPrivacyPolicy,
            ),
            ListTile(
              leading: const Icon(Icons.support_agent),
              title: const Text("Contact Support"),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: _contactSupport,
            ),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text("App Version"),
              trailing: Text(_appVersion, style: const TextStyle(color: Colors.grey)),
            ),
            ListTile(
              leading: const Icon(Icons.info),
              title: const Text("About App"),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: _showAboutApp,
            ),
            const Spacer(),
            ElevatedButton.icon(
              onPressed: _logout,
              icon: const Icon(Icons.logout, color: Colors.white),
              label: const Text("Logout", style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
