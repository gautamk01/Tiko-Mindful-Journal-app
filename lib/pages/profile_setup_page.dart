import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tracking_app/main.dart';
import 'package:tracking_app/services/database_service.dart';

class ProfileSetupPage extends StatefulWidget {
  const ProfileSetupPage({super.key});

  @override
  State<ProfileSetupPage> createState() => _ProfileSetupPageState();
}

class _ProfileSetupPageState extends State<ProfileSetupPage> {
  final TextEditingController _nameController = TextEditingController();
  final DatabaseService _db = DatabaseService();
  final ImagePicker _picker = ImagePicker();
  String? _profileImagePath;

  final List<String> _goals = [
    'Better Sleep',
    'Stay Hydrated',
    'Exercise More',
    'Mindful Eating',
    'Stress Management',
    'Daily Journaling',
  ];

  final Set<String> _selectedGoals = {};

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 85,
    );

    if (image != null) {
      setState(() {
        _profileImagePath = image.path;
      });
    }
  }

  Future<void> _completeSetup() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter your name')));
      return;
    }

    // Save user data
    await _db.saveUserName(_nameController.text.trim());
    await _db.saveProfileImagePath(_profileImagePath);
    await _db.setFirstLaunch(false);

    if (!mounted) return;

    // Navigate to main app
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => const MainScaffold()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),

              Text(
                'Create Your Profile',
                style: GoogleFonts.poppins(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color:
                      Theme.of(context).textTheme.titleLarge?.color ??
                      Colors.black87,
                ),
              ),

              const SizedBox(height: 12),

              Text(
                'Let\'s personalize your wellness journey',
                style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey),
              ),

              const SizedBox(height: 50),

              // Profile Image Picker
              Center(
                child: GestureDetector(
                  onTap: _pickImage,
                  child: Stack(
                    children: [
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Theme.of(context).cardColor,
                          border: Border.all(
                            color: const Color(0xFFF39E75),
                            width: 3,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: _profileImagePath != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(60),
                                child: Image.file(
                                  File(_profileImagePath!),
                                  fit: BoxFit.cover,
                                ),
                              )
                            : const Icon(
                                Icons.person,
                                size: 60,
                                color: Color(0xFFF39E75),
                              ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF39E75),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.2),
                                blurRadius: 5,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.camera_alt,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              Center(
                child: Text(
                  'Tap to add your photo',
                  style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey),
                ),
              ),

              const SizedBox(height: 40),

              // Name input
              Text(
                'What should we call you?',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color:
                      Theme.of(context).textTheme.bodyLarge?.color ??
                      Colors.black87,
                ),
              ),

              const SizedBox(height: 12),

              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  hintText: 'Enter your name',
                  hintStyle: GoogleFonts.poppins(color: Colors.grey),
                  filled: true,
                  fillColor: Theme.of(context).cardColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                ),
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),

              const SizedBox(height: 40),

              // Goals section
              Text(
                'Choose your wellness goals (optional)',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color:
                      Theme.of(context).textTheme.bodyLarge?.color ??
                      Colors.black87,
                ),
              ),

              const SizedBox(height: 16),

              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: _goals.map((goal) {
                  final isSelected = _selectedGoals.contains(goal);
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        if (isSelected) {
                          _selectedGoals.remove(goal);
                        } else {
                          _selectedGoals.add(goal);
                        }
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFFF39E75)
                            : Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFFF39E75)
                              : Colors.black12,
                        ),
                      ),
                      child: Text(
                        goal,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: isSelected
                              ? Colors.white
                              : (Theme.of(context).textTheme.bodyLarge?.color ??
                                    Colors.black87),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 60),

              // Continue button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _completeSetup,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF39E75),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Continue',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
