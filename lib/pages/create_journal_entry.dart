import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tracking_app/services/database_service.dart';
import 'package:tracking_app/services/media_service.dart';
import 'package:tracking_app/models/journal_entry.dart';

class CreateJournalEntryPage extends StatefulWidget {
  final DateTime date;
  final JournalEntry? existingEntry; // Optional - for editing

  const CreateJournalEntryPage({
    super.key,
    required this.date,
    this.existingEntry,
  });

  @override
  State<CreateJournalEntryPage> createState() => _CreateJournalEntryPageState();
}

class _CreateJournalEntryPageState extends State<CreateJournalEntryPage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  final DatabaseService _db = DatabaseService();
  final MediaService _mediaService = MediaService();
  final ImagePicker _picker = ImagePicker();

  String _selectedMood = 'Happy';
  String _selectedTag = 'Personal';
  bool _isLoading = false;

  // Media attachments
  final List<String> _imagePaths = [];
  final List<String> _audioPaths = []; // Keep for future implementation

  final List<Map<String, dynamic>> _moods = [
    {
      'label': 'Happy',
      'value': 9,
      'icon': Icons.sentiment_very_satisfied,
      'color': const Color(0xFFFFC4AB),
    },
    {
      'label': 'Neutral',
      'value': 5,
      'icon': Icons.sentiment_neutral,
      'color': const Color(0xFFA8E6CF),
    },
    {
      'label': 'Sad',
      'value': 3,
      'icon': Icons.sentiment_very_dissatisfied,
      'color': const Color(0xFFCDB4FF),
    },
    {
      'label': 'Tired',
      'value': 4,
      'icon': Icons.bedtime,
      'color': const Color(0xFF90CAF9),
    },
    {
      'label': 'Excited',
      'value': 10,
      'icon': Icons.bolt,
      'color': const Color(0xFFFFF59D),
    },
  ];

  final List<String> _tags = [
    'Personal',
    'Work',
    'Health',
    'Family',
    'Ideas',
    'Gratitude',
  ];

  @override
  void initState() {
    super.initState();

    // Pre-fill form if editing existing entry
    if (widget.existingEntry != null) {
      final entry = widget.existingEntry!;
      _titleController.text = entry.title;
      _contentController.text = entry.content;
      _imagePaths.addAll(entry.imagePaths);
      _audioPaths.addAll(entry.audioPaths);
      _selectedTag = entry.tags.isNotEmpty ? entry.tags.first : 'Personal';
      _selectedMood = _getMoodLabelFromValue(entry.mood);
    }
  }

  String _getMoodLabelFromValue(int moodValue) {
    if (moodValue >= 9) return 'Happy';
    if (moodValue >= 7) return 'Excited';
    if (moodValue >= 5) return 'Neutral';
    if (moodValue == 4) return 'Tired';
    return 'Sad';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final List<XFile> images = await _picker.pickMultiImage();

    if (images.isNotEmpty) {
      for (final image in images) {
        setState(() {
          // Add image to list
          final imageIndex = _imagePaths.length;
          _imagePaths.add(image.path);

          // Insert placeholder at cursor position in content
          final cursorPosition = _contentController.selection.baseOffset;
          final currentText = _contentController.text;

          // Create compact image marker (emoji format)
          final marker = ' 📷${imageIndex + 1} ';

          if (cursorPosition >= 0 && cursorPosition <= currentText.length) {
            // Insert at cursor position
            final newText =
                currentText.substring(0, cursorPosition) +
                marker +
                currentText.substring(cursorPosition);
            _contentController.text = newText;

            // Move cursor after the marker
            _contentController.selection = TextSelection.fromPosition(
              TextPosition(offset: cursorPosition + marker.length),
            );
          } else {
            // Append at end if cursor position invalid
            _contentController.text = currentText + marker;
          }
        });
      }
    }
  }

  void _removeImage(int index) {
    setState(() {
      _imagePaths.removeAt(index);
    });
  }

  void _removeAudio(int index) {
    setState(() {
      _audioPaths.removeAt(index);
    });
  }

  Future<void> _saveEntry() async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter a title')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final entryId =
          widget.existingEntry?.id ??
          DateTime.now().millisecondsSinceEpoch.toString();

      // Save new images to permanent location
      final List<String> savedImagePaths = List.from(
        widget.existingEntry?.imagePaths ?? [],
      );
      for (final imagePath in _imagePaths) {
        // Check if this is a new image (not already saved)
        if (!savedImagePaths.contains(imagePath)) {
          final savedPath = await _mediaService.saveImage(imagePath, entryId);
          savedImagePaths.add(savedPath);
        }
      }

      // Save audio files to permanent location
      final List<String> savedAudioPaths = List.from(
        widget.existingEntry?.audioPaths ?? [],
      );
      for (final audioPath in _audioPaths) {
        if (!savedAudioPaths.contains(audioPath)) {
          final savedPath = await _mediaService.saveAudio(audioPath, entryId);
          savedAudioPaths.add(savedPath);
        }
      }

      final entry = JournalEntry(
        id: entryId,
        date: widget.date,
        title: _titleController.text.trim(),
        content: _contentController.text.trim(),
        mood:
            _moods.firstWhere((m) => m['label'] == _selectedMood)['value']
                as int,
        type: 'daily',
        tags: [_selectedTag],
        imagePaths: savedImagePaths,
        audioPaths: savedAudioPaths,
      );

      await _db.saveJournalEntry(entry);

      if (!mounted) return;
      setState(() => _isLoading = false);
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error saving entry: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveEntry,
            child: Text(
              'Save',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: const Color(0xFFF39E75),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'How are you feeling?',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 80,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _moods.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final mood = _moods[index];
                  final isSelected = _selectedMood == mood['label'];
                  return GestureDetector(
                    onTap: () => setState(() => _selectedMood = mood['label']),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected ? mood['color'] : Colors.grey[100],
                        borderRadius: BorderRadius.circular(20),
                        border: isSelected
                            ? Border.all(color: Colors.black12)
                            : null,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            mood['icon'],
                            color: isSelected ? Colors.black87 : Colors.grey,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            mood['label'],
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                              color: isSelected ? Colors.black87 : Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 32),
            TextField(
              controller: _titleController,
              style: GoogleFonts.playfairDisplay(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              decoration: InputDecoration(
                hintText: 'Entry Title',
                border: InputBorder.none,
                hintStyle: GoogleFonts.playfairDisplay(
                  color: Colors.black38,
                  fontSize: 24,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _tags.map((tag) {
                final isSelected = _selectedTag == tag;
                return GestureDetector(
                  onTap: () => setState(() => _selectedTag = tag),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.black : Colors.grey[100],
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      tag,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: isSelected ? Colors.white : Colors.black54,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _contentController,
              maxLines: null,
              style: GoogleFonts.poppins(fontSize: 16, height: 1.5),
              decoration: InputDecoration(
                hintText: 'Start writing...',
                border: InputBorder.none,
                hintStyle: GoogleFonts.poppins(color: Colors.black38),
              ),
            ),

            const SizedBox(height: 24),

            // Media Attachments Section
            if (_imagePaths.isNotEmpty || _audioPaths.isNotEmpty) ...[
              Text(
                'Attachments',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),

              // Images preview
              if (_imagePaths.isNotEmpty)
                SizedBox(
                  height: 100,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _imagePaths.length,
                    itemBuilder: (context, index) {
                      return Container(
                        margin: const EdgeInsets.only(right: 8),
                        child: Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(
                                File(_imagePaths[index]),
                                width: 100,
                                height: 100,
                                fit: BoxFit.cover,
                              ),
                            ),
                            Positioned(
                              top: 4,
                              right: 4,
                              child: GestureDetector(
                                onTap: () => _removeImage(index),
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.close,
                                    size: 16,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),

              const SizedBox(height: 12),

              // Audio files list
              if (_audioPaths.isNotEmpty)
                ...List.generate(_audioPaths.length, (index) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.mic, color: Color(0xFFF39E75)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Audio Recording ${index + 1}',
                            style: GoogleFonts.poppins(fontSize: 14),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _removeAudio(index),
                        ),
                      ],
                    ),
                  );
                }),

              const SizedBox(height: 16),
            ],

            // Attachment buttons
            OutlinedButton.icon(
              onPressed: _pickImages,
              icon: const Icon(Icons.add_photo_alternate),
              label: const Text('Insert Image at Cursor'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
