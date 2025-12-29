import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tracking_app/services/database_service.dart';
import 'package:tracking_app/services/export_import_service.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final DatabaseService _db = DatabaseService();
  final ExportImportService _exportImportService = ExportImportService();
  final ImagePicker _picker = ImagePicker();
  String _userName = '';
  String? _profileImagePath;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() {
    setState(() {
      _userName = _db.getUserName() ?? 'User';
      _profileImagePath = _db.getProfileImagePath();
    });
  }

  Future<void> _editProfileImage() async {
    final ImageSource? source = await showDialog<ImageSource>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text('Choose Image Source'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Camera'),
                subtitle: const Text('Take a new photo'),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Gallery'),
                subtitle: const Text('Choose from gallery'),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
            ],
          ),
        );
      },
    );

    if (source == null) return;

    final XFile? image = await _picker.pickImage(
      source: source,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 85,
    );

    if (image != null) {
      await _db.saveProfileImagePath(image.path);

      // Reload to update UI in real-time
      setState(() {
        _profileImagePath = image.path;
      });

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Profile image updated!')));
    }
  }

  Future<void> _exportData() async {
    final result = await _exportImportService.exportData();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result),
        duration: const Duration(seconds: 4),
        backgroundColor: result.contains('failed') ? Colors.red : Colors.green,
      ),
    );
  }

  Future<void> _importData() async {
    final result = await _exportImportService.importData();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result),
        duration: const Duration(seconds: 4),
        backgroundColor: result.contains('failed') || result.contains('No file')
            ? Colors.red
            : Colors.green,
      ),
    );

    // Reload data after successful import
    if (result.contains('successful')) {
      _loadUserData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F4),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),

              Text(
                'Settings',
                style: GoogleFonts.poppins(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),

              const SizedBox(height: 40),

              // Profile section
              _buildSection(
                title: 'Profile',
                child: Column(
                  children: [
                    // Profile Image Preview
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          _profileImagePath != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(50),
                                  child: Image.file(
                                    File(_profileImagePath!),
                                    width: 100,
                                    height: 100,
                                    fit: BoxFit.cover,
                                  ),
                                )
                              : const CircleAvatar(
                                  radius: 50,
                                  backgroundImage: NetworkImage(
                                    'https://i.pravatar.cc/150?img=68',
                                  ),
                                ),
                          const SizedBox(height: 12),
                          Text(
                            _userName,
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(),
                    _buildListTile(
                      icon: Icons.camera_alt_outlined,
                      title: 'Change Photo',
                      subtitle: 'Update your profile picture',
                      onTap: _editProfileImage,
                    ),
                    const Divider(),
                    _buildListTile(
                      icon: Icons.person_outline,
                      title: 'Edit Name',
                      subtitle: _userName,
                      onTap: _editName,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Data Management section
              _buildSection(
                title: 'Data Management',
                child: Column(
                  children: [
                    _buildListTile(
                      icon: Icons.backup_outlined,
                      title: 'Export Data',
                      subtitle: 'Backup your wellness data',
                      onTap: _exportData,
                    ),
                    const SizedBox(height: 12),
                    _buildListTile(
                      icon: Icons.upload,
                      title: 'Import Data',
                      subtitle: 'Restore from backup',
                      onTap: _importData,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              const SizedBox(height: 24),

              // Creator section
              _buildSection(
                title: 'Creator',
                child: Column(
                  children: [
                    _buildListTile(
                      icon: Icons.code,
                      title: 'Developed by',
                      subtitle: 'Gautam Krishna M',
                      onTap: null,
                    ),
                    const Divider(height: 1),
                    _buildListTile(
                      icon: Icons.email_outlined,
                      title: 'Email',
                      subtitle: 'gautamkrishna.mooppil.dev@gmail.com',
                      onTap: () => _launchUrl(
                        'mailto:gautamkrishna.mooppil.dev@gmail.com',
                      ),
                    ),
                    const Divider(height: 1),
                    _buildListTile(
                      icon: Icons.link,
                      title: 'GitHub',
                      subtitle: 'github.com/gautamk01',
                      onTap: () => _launchUrl('https://github.com/gautamk01'),
                    ),
                    const Divider(height: 1),
                    _buildListTile(
                      icon: Icons.work_outline,
                      title: 'LinkedIn',
                      subtitle: 'linkedin.com/in/gautam-krishna-dev',
                      onTap: () => _launchUrl(
                        'https://linkedin.com/in/gautam-krishna-dev',
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // App Info section
              _buildSection(
                title: 'About',
                child: Column(
                  children: [
                    _buildListTile(
                      icon: Icons.info_outline,
                      title: 'App Version',
                      subtitle: '1.0.0',
                      onTap: null,
                    ),
                  ],
                ),
              ),

              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.all(20),
                  child: Center(child: CircularProgressIndicator()),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection({required String title, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black54,
              letterSpacing: 0.5,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: child,
        ),
      ],
    );
  }

  Widget _buildListTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFFF39E75).withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: const Color(0xFFF39E75), size: 20),
      ),
      title: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.poppins(fontSize: 13, color: Colors.black54),
      ),
      trailing: onTap != null
          ? const Icon(Icons.chevron_right, color: Colors.black26)
          : null,
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    );
  }

  void _editName() {
    showDialog(
      context: context,
      builder: (context) {
        final controller = TextEditingController(text: _userName);
        return AlertDialog(
          title: Text('Edit Name', style: GoogleFonts.poppins()),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(hintText: 'Enter your name'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                if (controller.text.trim().isNotEmpty) {
                  await _db.saveUserName(controller.text.trim());
                  _loadUserData();
                  if (!mounted) return;
                  Navigator.pop(context);
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _launchUrl(String urlString) async {
    final Uri url = Uri.parse(urlString);
    try {
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        throw Exception('Could not launch $url');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not open link: $e')));
    }
  }
}
