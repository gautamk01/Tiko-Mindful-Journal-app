import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tracking_app/models/journal_entry.dart';
import 'package:tracking_app/pages/create_journal_entry.dart';
import 'package:tracking_app/services/database_service.dart';

class ViewJournalEntryPage extends StatelessWidget {
  final JournalEntry entry;

  const ViewJournalEntryPage({super.key, required this.entry});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Theme.of(context).iconTheme.color,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, color: Color(0xFFF39E75)),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CreateJournalEntryPage(
                    date: entry.date,
                    existingEntry: entry,
                  ),
                ),
              );

              // If entry was updated, pop back with result
              if (result == true && context.mounted) {
                Navigator.pop(context, true);
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            onPressed: () => _showDeleteConfirmation(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date
            Text(
              _formatDate(entry.date),
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),

            // Title
            Text(
              entry.title,
              style: GoogleFonts.playfairDisplay(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color:
                    Theme.of(context).textTheme.titleLarge?.color ??
                    Colors.black,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 16),

            // Mood & Tags
            Row(
              children: [
                // Mood indicator
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _getMoodColor(entry.mood),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _getMoodIcon(entry.mood),
                        size: 16,
                        color:
                            Theme.of(context).textTheme.bodyLarge?.color ??
                            Colors.black87,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _getMoodLabel(entry.mood),
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color:
                              Theme.of(context).textTheme.bodyLarge?.color ??
                              Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),

                // Tags
                ...entry.tags.map(
                  (tag) => Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.black12),
                    ),
                    child: Text(
                      tag,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Content with inline images
            _buildContentWithImages(),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildContentWithImages() {
    // Parse content and display images inline
    String content = entry.content;

    final List<Widget> contentWidgets = [];

    // Split by emoji image markers like 📷1, 📷2, etc.
    final pattern = RegExp(r'📷(\d+)');
    final matches = pattern.allMatches(content);

    if (matches.isEmpty) {
      // No inline images - show content then images
      if (content.trim().isNotEmpty) {
        contentWidgets.add(
          Text(
            content.trim(),
            style: GoogleFonts.poppins(
              fontSize: 16,
              height: 1.6,
              color: Colors.black87,
            ),
          ),
        );
      }

      if (entry.imagePaths.isNotEmpty) {
        contentWidgets.add(const SizedBox(height: 24));
        contentWidgets.add(_buildImageGallery());
      }
    } else {
      // Has inline images - parse and display
      int lastIndex = 0;

      for (final match in matches) {
        // Add text before the marker
        if (match.start > lastIndex) {
          final textBefore = content.substring(lastIndex, match.start).trim();
          if (textBefore.isNotEmpty) {
            contentWidgets.add(
              Text(
                textBefore,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  height: 1.6,
                  color: Colors.grey.shade700,
                ),
              ),
            );
            contentWidgets.add(const SizedBox(height: 16));
          }
        }

        // Add the image
        final imageNumber = int.parse(match.group(1)!);
        final imageIndex = imageNumber - 1;

        if (imageIndex >= 0 && imageIndex < entry.imagePaths.length) {
          contentWidgets.add(
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(
                File(entry.imagePaths[imageIndex]),
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
          );
          contentWidgets.add(const SizedBox(height: 16));
        }

        lastIndex = match.end;
      }

      // Add remaining text after last image
      if (lastIndex < content.length) {
        final textAfter = content.substring(lastIndex).trim();
        if (textAfter.isNotEmpty) {
          contentWidgets.add(
            Text(
              textAfter,
              style: GoogleFonts.poppins(
                fontSize: 16,
                height: 1.6,
                color: Colors.grey.shade700,
              ),
            ),
          );
        }
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: contentWidgets,
    );
  }

  Widget _buildImageGallery() {
    if (entry.imagePaths.length == 1) {
      // Single image - full width
      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.file(
          File(entry.imagePaths[0]),
          width: double.infinity,
          fit: BoxFit.cover,
        ),
      );
    } else {
      // Multiple images - grid
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: entry.imagePaths.length,
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () => _viewFullImage(index),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(
                File(entry.imagePaths[index]),
                fit: BoxFit.cover,
              ),
            ),
          );
        },
      );
    }
  }

  void _viewFullImage(int index) {
    // TODO: Implement full-screen image viewer
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  Color _getMoodColor(int mood) {
    if (mood >= 8) return const Color(0xFFFFC4AB); // Happy
    if (mood >= 6) return const Color(0xFFA8E6CF); // Neutral
    if (mood >= 4) return const Color(0xFF90CAF9); // Tired
    return const Color(0xFFCDB4FF); // Sad
  }

  IconData _getMoodIcon(int mood) {
    if (mood >= 8) return Icons.sentiment_very_satisfied;
    if (mood >= 6) return Icons.sentiment_neutral;
    if (mood >= 4) return Icons.bedtime;
    return Icons.sentiment_dissatisfied;
  }

  String _getMoodLabel(int mood) {
    if (mood >= 8) return 'Happy';
    if (mood >= 6) return 'Neutral';
    if (mood >= 4) return 'Tired';
    return 'Sad';
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Entry?'),
          content: const Text(
            'Are you sure you want to delete this journal entry? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                // Delete the entry
                await DatabaseService().deleteJournalEntry(entry.id);

                if (!context.mounted) return;

                // Close dialog
                Navigator.pop(context);

                // Go back to journal page
                Navigator.pop(context, true);

                // Show success message
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Entry deleted'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }
}
