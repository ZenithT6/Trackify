// 📁 profile_screen.dart

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
  double? height;
  double? weight;
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
      height = box.get('height');
      weight = box.get('weight');
    });
  }

  Future<void> _saveUserInfo(String newName, String newEmail, double? newHeight, double? newWeight) async {
    final box = Hive.box('userBox');
    await box.put('name', newName);
    await box.put('email', newEmail);
    if (newHeight != null) await box.put('height', newHeight);
    if (newWeight != null) await box.put('weight', newWeight);
    if (!mounted) return;
    setState(() {
      name = newName;
      email = newEmail;
      height = newHeight;
      weight = newWeight;
    });
  }

  void _showEditDialog() {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: name);
    final emailController = TextEditingController(text: email);
    final heightController = TextEditingController(text: height?.toString() ?? '');
    final weightController = TextEditingController(text: weight?.toString() ?? '');

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
                validator: (value) => value == null || value.trim().isEmpty ? 'Name cannot be empty' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return 'Email cannot be empty';
                  final regex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                  return regex.hasMatch(value) ? null : 'Enter a valid email';
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: heightController,
                decoration: const InputDecoration(labelText: 'Height (cm)'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: weightController,
                decoration: const InputDecoration(labelText: 'Weight (kg)'),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                final parsedHeight = double.tryParse(heightController.text);
                final parsedWeight = double.tryParse(weightController.text);
                _saveUserInfo(
                  nameController.text.trim(),
                  emailController.text.trim(),
                  parsedHeight,
                  parsedWeight,
                );
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

  Future<void> _loadProfileImage() async {
    final box = Hive.box('userBox');
    final path = box.get('profileImage') as String?;
    if (path != null && File(path).existsSync()) {
      if (!mounted) return;
      setState(() => _profileImage = File(path));
    }
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
    bool granted = false;
    if (source == ImageSource.camera) {
      granted = await requestCameraPermission(context);
    } else {
      granted = await requestGalleryPermission(context);
    }

    if (!granted || !mounted) return;

    final picked = await ImagePicker().pickImage(source: source, imageQuality: 85);
    if (picked == null) return;

    final dir = await getApplicationDocumentsDirectory();
    final newPath = '${dir.path}/profile_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final newImage = await File(picked.path).copy(newPath);

    final box = Hive.box('userBox');
    final oldPath = box.get('profileImage') as String?;
    if (oldPath != null && File(oldPath).existsSync()) {
      await File(oldPath).delete();
    }

    await box.put('profileImage', newImage.path);
    setState(() => _profileImage = newImage);
  }

  Future<void> _loadAppVersion() async {
    final info = await PackageInfo.fromPlatform();
    if (!mounted) return;
    setState(() => _appVersion = 'v${info.version}');
  }

  void _logout() async {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Confirm Logout"),
        content: const Text("Are you sure you want to log out?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await Hive.box('sessionBox').clear();
              await Hive.box('userBox').clear();
              await Hive.box('goalBox').clear();
              if (!mounted) return;
              Navigator.pushNamedAndRemoveUntil(context, '/welcome', (route) => false);
            },
            child: const Text("Logout", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _contactSupport() async {
    final emailUri = Uri(
      scheme: 'mailto',
      path: 'support@trackifyapp.com',
      query: 'subject=Support Request',
    );
    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    }
  }

  void _showAboutApp() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("About Trackify"),
        content: const Text("Trackify helps you monitor your wellness goals.\n\nAll-in-one tracker for steps, sleep, calories, and heart rate."),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("Close"))],
      ),
    );
  }

  void _showPrivacyPolicy() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Privacy Policy"),
        content: const Text("This app stores your data locally and does not share it externally."),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("OK"))],
      ),
    );
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
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            GestureDetector(
              onTap: _showImagePickerDialog,
              child: CircleAvatar(
                radius: 45,
                backgroundColor: Colors.deepPurple[100],
                child: _profileImage != null
                    ? ClipOval(child: Image.file(_profileImage!, fit: BoxFit.cover, width: 90, height: 90))
                    : const Icon(Icons.person, size: 40, color: Colors.white),
              ),
            ),
            const SizedBox(height: 16),
            Text(name, style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold)),
            Text(email, style: GoogleFonts.poppins(color: Colors.grey[600])),
            const SizedBox(height: 8),
            Text(height != null ? "Height: ${height!.toStringAsFixed(0)} cm" : "Height: Not set"),
            Text(weight != null ? "Weight: ${weight!.toStringAsFixed(1)} kg" : "Weight: Not set"),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _showEditDialog,
              icon: const Icon(Icons.edit, color: Colors.white),
              label: const Text("Edit Profile", style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple),
            ),
            const SizedBox(height: 30),
            Divider(color: Colors.grey[300]),
            ListTile(
              leading: const Icon(FontAwesomeIcons.flag),
              title: const Text("Set Goals"),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SetGoalsScreen())),
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
