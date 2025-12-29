import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tracking_app/widgets/date_strip.dart';
import 'package:tracking_app/widgets/header_section.dart';
import 'package:tracking_app/widgets/physical_state_section.dart';
import 'package:tracking_app/widgets/stats_card.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const HeaderSection(),
              const SizedBox(height: 20),
              DateStrip(onDateSelected: (date) {}),
              const SizedBox(height: 30),

              // Activity Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Text(
                  'Today\'s Activity',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color:
                        Theme.of(context).textTheme.titleLarge?.color ??
                        Colors.black,
                  ),
                ),
              ),

              const SizedBox(height: 16),

              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.0),
                child: Row(
                  children: [
                    Expanded(
                      child: StatsCard(
                        title: 'Sleeping Times',
                        value: '8h 40m',
                        icon: Icons.bedtime_outlined,
                        iconColor: Color(0xFFD88B9E),
                        iconBgColor: Color(0xFFFBE4D8),
                      ),
                    ),
                    SizedBox(width: 15),
                    Expanded(
                      child: StatsCard(
                        title: 'Mood Level',
                        value: '8/10',
                        icon: Icons.sentiment_satisfied_outlined,
                        iconColor: Color(0xFFD88B9E),
                        iconBgColor: Color(0xFFFBE4D8),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),
              const PhysicalStateSection(),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}
