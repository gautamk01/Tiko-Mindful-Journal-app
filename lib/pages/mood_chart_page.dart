import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tracking_app/models/hourly_mood.dart';
import 'package:tracking_app/services/database_service.dart';
import 'package:tracking_app/services/notification_service.dart';
import 'package:tracking_app/widgets/mood_selector_dialog.dart';

class MoodChartPage extends StatefulWidget {
  const MoodChartPage({super.key});

  @override
  State<MoodChartPage> createState() => _MoodChartPageState();
}

class _MoodChartPageState extends State<MoodChartPage>
    with WidgetsBindingObserver {
  final DatabaseService _db = DatabaseService();

  DateTime _selectedDate = DateTime.now();
  List<HourlyMood> _moods = [];

  @override
  void initState() {
    super.initState();
    _loadMoods();
    // Initialize notifications lazily when actually used
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Reload moods when app comes back to foreground
      _loadMoods();
    }
  }

  void _loadMoods() {
    setState(() {
      _moods = _db.getHourlyMoodsForDate(_selectedDate);
    });
  }

  void _changeDate(int days) {
    setState(() {
      _selectedDate = _selectedDate.add(Duration(days: days));
      _loadMoods();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Mood Timeline',
          style: GoogleFonts.playfairDisplay(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color:
                Theme.of(context).textTheme.titleLarge?.color ?? Colors.black,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.notifications_outlined,
              color: Colors.grey.shade600,
            ),
            onPressed: () async {
              // Capture context before async gap
              final scaffoldMessenger = ScaffoldMessenger.of(context);

              await NotificationService().sendTestNotification();
              if (!mounted) return;

              // Use captured messenger
              scaffoldMessenger.showSnackBar(
                const SnackBar(
                  content: Text('Notification sent! Check notification tray'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            tooltip: 'Send Test Notification',
          ),
          IconButton(
            icon: const Icon(Icons.emoji_emotions, color: Color(0xFFF39E75)),
            onPressed: () async {
              await showDialog(
                context: context,
                builder: (context) => const MoodSelectorDialog(),
              );
              _loadMoods();
            },
            tooltip: 'Quick Mood Entry',
          ),
          IconButton(
            icon: const Icon(Icons.auto_fix_high, color: Colors.purple),
            onPressed: _generateDemoData,
            tooltip: 'Generate Demo Data (Dec 28)',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            _buildDateNavigation(),
            const SizedBox(height: 32),
            Expanded(
              child: _moods.isEmpty
                  ? _buildEmptyState()
                  : Column(
                      children: [
                        Expanded(child: _buildMoodChart()),
                        const SizedBox(height: 16),
                        _buildDayAverage(),
                      ],
                    ),
            ),
            const SizedBox(height: 12),
            _buildMoodLegend(),
          ],
        ),
      ),
    );
  }

  Widget _buildDateNavigation() {
    final isToday =
        _selectedDate.year == DateTime.now().year &&
        _selectedDate.month == DateTime.now().month &&
        _selectedDate.day == DateTime.now().day;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () => _changeDate(-1),
          ),
          Column(
            children: [
              Text(
                _formatDate(_selectedDate),
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (isToday)
                Text(
                  'Today',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: const Color(0xFFF39E75),
                    fontWeight: FontWeight.w500,
                  ),
                ),
            ],
          ),
          IconButton(
            icon: Icon(
              Icons.chevron_right,
              color: isToday
                  ? Colors.grey.shade300
                  : Theme.of(context).iconTheme.color ?? Colors.black,
            ),
            onPressed: isToday ? null : () => _changeDate(1),
          ),
        ],
      ),
    );
  }

  Widget _buildMoodChart() {
    final spots = <FlSpot>[];
    for (var i = 0; i < _moods.length; i++) {
      final mood = _moods[i];
      final hour = mood.timestamp.hour + (mood.timestamp.minute / 60);
      spots.add(FlSpot(hour, mood.mood.toDouble()));
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 16, bottom: 8),
            child: Text(
              'Mood Level (6 AM - 10 PM)',
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade400,
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Container(
                width: 1400, // Reduced width for restricted time range (16h)
                padding: const EdgeInsets.only(right: 24, top: 10, bottom: 10),
                child: LineChart(
                  LineChartData(
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: true,
                      verticalInterval: 0.5,
                      horizontalInterval: 1,
                      getDrawingHorizontalLine: (value) {
                        return FlLine(
                          color: Colors.grey.shade100,
                          strokeWidth: 1,
                          dashArray: [5, 5],
                        );
                      },
                      getDrawingVerticalLine: (value) {
                        final isFullHour = value % 1 == 0;
                        return FlLine(
                          color: isFullHour
                              ? (Theme.of(context).brightness == Brightness.dark
                                    ? Colors.grey.shade800
                                    : Colors.grey.shade200)
                              : (Theme.of(context).brightness == Brightness.dark
                                    ? Colors.grey.shade900
                                    : Colors.grey.shade50),
                          strokeWidth: isFullHour ? 1.0 : 0.5,
                        );
                      },
                    ),
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          interval: 1,
                          getTitlesWidget: (value, meta) {
                            const moods = ['', '😞', '😐', '🙂', '😊', '😄'];
                            if (value >= 1 && value <= 5) {
                              return Text(
                                moods[value.toInt()],
                                style: const TextStyle(fontSize: 20),
                              );
                            }
                            return const SizedBox();
                          },
                          reservedSize: 40,
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          interval: 1,
                          getTitlesWidget: (value, meta) {
                            if (value >= 6 && value <= 22) {
                              final hour = value.toInt();
                              String timeLabel;
                              if (hour == 12) {
                                timeLabel = '12 PM';
                              } else if (hour > 12) {
                                timeLabel = '${hour - 12} PM';
                              } else {
                                timeLabel = '$hour AM';
                              }
                              return Padding(
                                padding: const EdgeInsets.only(top: 14),
                                child: Text(
                                  timeLabel,
                                  style: GoogleFonts.dmSans(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.grey,
                                  ),
                                ),
                              );
                            }
                            return const SizedBox();
                          },
                          reservedSize: 40,
                        ),
                      ),
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    minX: 6, // Start at 6 AM
                    maxX: 22, // End at 10 PM
                    minY: 0.5,
                    maxY: 5.5,
                    lineTouchData: LineTouchData(
                      touchTooltipData: LineTouchTooltipData(
                        getTooltipColor: (spot) =>
                            Colors.black.withValues(alpha: 0.8),
                        tooltipPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        tooltipMargin: 16,
                        getTooltipItems: (touchedSpots) {
                          return touchedSpots.map((spot) {
                            const moods = [
                              '',
                              'Sad',
                              'Okay',
                              'Good',
                              'Happy',
                              'Great',
                            ];
                            final moodLabel = moods[spot.y.toInt()];
                            final hour = spot.x.toInt();
                            final minute = ((spot.x - hour) * 60).toInt();
                            final timeStr =
                                '${hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour)}:${minute.toString().padLeft(2, '0')} ${hour >= 12 && hour < 24 ? 'PM' : 'AM'}';
                            return LineTooltipItem(
                              '$moodLabel\n',
                              const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                              children: [
                                TextSpan(
                                  text: timeStr,
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.8),
                                    fontSize: 11,
                                    fontWeight: FontWeight.normal,
                                  ),
                                ),
                              ],
                            );
                          }).toList();
                        },
                      ),
                      handleBuiltInTouches: true,
                    ),
                    lineBarsData: [
                      LineChartBarData(
                        spots: spots,
                        isCurved: true,
                        curveSmoothness: 0.35,
                        color: const Color(0xFFF39E75),
                        barWidth: 4,
                        isStrokeCapRound: true,
                        shadow: const Shadow(
                          color: Colors.black12,
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                        dotData: FlDotData(
                          show: true,
                          getDotPainter: (spot, percent, barData, index) {
                            return FlDotCirclePainter(
                              radius: 6,
                              color: Colors.white,
                              strokeWidth: 3,
                              strokeColor: const Color(0xFFF39E75),
                            );
                          },
                        ),
                        belowBarData: BarAreaData(
                          show: true,
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFFF39E75).withValues(alpha: 0.4),
                              const Color(0xFFF39E75).withValues(alpha: 0.0),
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDayAverage() {
    if (_moods.isEmpty) return const SizedBox.shrink();

    final sum = _moods.fold(0, (prev, element) => prev + element.mood);
    final average = sum / _moods.length;

    String emoji = '😐';
    String label = 'Okay';
    Color color = Colors.grey;

    if (average >= 4.2) {
      emoji = '😄';
      label = 'Great';
      color = Colors.green;
    } else if (average >= 3.4) {
      emoji = '😊';
      label = 'Happy';
      color = Colors.lightGreen;
    } else if (average >= 2.6) {
      emoji = '🙂';
      label = 'Good';
      color = Colors.orangeAccent;
    } else if (average >= 1.8) {
      emoji = '😐';
      label = 'Okay';
      color = Colors.orange;
    } else {
      emoji = '😞';
      label = 'Sad';
      color = Colors.redAccent;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Overall Mood:  ',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color:
                  Theme.of(context).textTheme.bodyLarge?.color ??
                  Colors.black87,
            ),
          ),
          Text(emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 8),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.mood_outlined, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'No mood records for this day',
            style: GoogleFonts.poppins(
              fontSize: 18,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap the bell icon to test notifications',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey.shade400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMoodLegend() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildLegendItem('😞', 'Sad', 1),
          _buildLegendItem('😐', 'Okay', 2),
          _buildLegendItem('🙂', 'Good', 3),
          _buildLegendItem('😊', 'Happy', 4),
          _buildLegendItem('😄', 'Great', 5),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String emoji, String label, int value) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 24)),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey.shade600),
        ),
      ],
    );
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

  Future<void> _generateDemoData() async {
    final now = DateTime.now();
    // Target Dec 28 of the current year (or previous year if today is before Dec 28, but assuming current year is fine for demo)
    final demoDate = DateTime(now.year, 12, 28);

    // Clear existing data for that day to avoid duplicates/mess
    final existing = _db.getHourlyMoodsForDate(demoDate);
    for (var m in existing) {
      await _db.deleteHourlyMood(m.id);
    }

    // Generate a nice curve
    // 6 AM: Waking up groggy (2)
    // 8 AM: Coffee (3)
    // 10 AM: Productive work (4)
    // 12 PM: Lunch (5)
    // 2 PM: Afternoon slump (3)
    // 4 PM: Meeting stress (2)
    // 6 PM: Done with work (4)
    // 8 PM: Relaxing (5)
    // 10 PM: Sleepy content (4)

    final Map<int, int> demoMoods = {
      6: 2,
      8: 3,
      10: 4,
      12: 5,
      14: 3,
      16: 2,
      18: 4,
      20: 5,
      22: 4,
    };

    for (var entry in demoMoods.entries) {
      final hour = entry.key;
      final moodLevel = entry.value;

      final mood = HourlyMood(
        id: DateTime.now().millisecondsSinceEpoch.toString() + hour.toString(),
        timestamp: DateTime(
          demoDate.year,
          demoDate.month,
          demoDate.day,
          hour,
          0,
        ),
        mood: moodLevel,
        note: 'Demo entry',
      );
      await _db.saveHourlyMood(mood);
    }

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Generated demo data for Dec 28!')),
    );

    // If we are currently viewing Dec 28, refresh. If not, maybe switch to it?
    // Let's switch to Dec 28 to show it immediately.
    setState(() {
      _selectedDate = demoDate;
      _loadMoods();
    });
  }
}
