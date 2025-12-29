import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tracking_app/models/hourly_mood.dart';
import 'package:tracking_app/services/database_service.dart';

class MoodSelectorDialog extends StatelessWidget {
  const MoodSelectorDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'How are you feeling?',
              style: GoogleFonts.playfairDisplay(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color:
                    Theme.of(context).textTheme.titleLarge?.color ??
                    Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap to record your mood',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 32),

            // All 5 mood options
            _buildMoodButton(context, '😞', 'Sad', 1),
            const SizedBox(height: 16),
            _buildMoodButton(context, '😐', 'Okay', 2),
            const SizedBox(height: 16),
            _buildMoodButton(context, '🙂', 'Good', 3),
            const SizedBox(height: 16),
            _buildMoodButton(context, '😊', 'Happy', 4),
            const SizedBox(height: 16),
            _buildMoodButton(context, '😄', 'Great', 5),
          ],
        ),
      ),
    );
  }

  Widget _buildMoodButton(
    BuildContext context,
    String emoji,
    String label,
    int value,
  ) {
    return Material(
      color: Theme.of(context).cardColor,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () async {
          // Save mood
          final mood = HourlyMood(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            timestamp: DateTime.now(),
            mood: value,
          );

          await DatabaseService().saveHourlyMood(mood);

          // Close dialog
          if (context.mounted) {
            Navigator.of(context).pop();

            // Show confirmation
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('$emoji $label mood recorded!'),
                duration: const Duration(seconds: 2),
                backgroundColor: const Color(0xFFF39E75),
              ),
            );
          }
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
          child: Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 32)),
              const SizedBox(width: 16),
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
