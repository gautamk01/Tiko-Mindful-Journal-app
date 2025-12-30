import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PhysicalStateSection extends StatelessWidget {
  const PhysicalStateSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Physical state',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              const Icon(Icons.tune, color: Colors.black54),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Row(
            children: [
              Expanded(
                flex: 4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStatItem(
                      color: const Color(0xFFE4B7E5),
                      label: '8h Target',
                      subLabel: 'Sleep Goal',
                    ),
                    const SizedBox(height: 20),
                    _buildStatItem(
                      color: const Color(0xFF86BFD3),
                      label: '6.5h Achieved',
                      subLabel: 'Last Night',
                    ),
                    const SizedBox(height: 20),
                    _buildStatItem(
                      color: const Color(0xFFF3DA85),
                      label: '1.5h Missing',
                      subLabel: 'Deficit',
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 6,
                child: SizedBox(
                  height: 150,
                  child: Stack(
                    children: [
                      PieChart(
                        PieChartData(
                          sectionsSpace: 0,
                          centerSpaceRadius: 40,
                          startDegreeOffset: -90,
                          sections: [
                            PieChartSectionData(
                              color: const Color(
                                0xFFE4B7E5,
                              ).withValues(alpha: 0.5),
                              value: 40,
                              radius: 35,
                              showTitle: false,
                            ),
                            PieChartSectionData(
                              color: const Color(0xFF86BFD3),
                              value: 40,
                              radius: 35,
                              showTitle: false,
                            ),
                            PieChartSectionData(
                              color: const Color(0xFFD4E157),
                              value: 20,
                              radius: 35,
                              showTitle: false,
                            ),
                          ],
                        ),
                      ),
                      Center(
                        child: Text(
                          '87%',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem({
    required Color color,
    required String label,
    required String subLabel,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 4,
          height: 40,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
            Text(
              subLabel,
              style: GoogleFonts.poppins(fontSize: 12, color: Colors.black54),
            ),
          ],
        ),
      ],
    );
  }
}
