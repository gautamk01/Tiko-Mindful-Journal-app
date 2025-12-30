import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class DateStrip extends StatefulWidget {
  final Function(DateTime) onDateSelected;

  const DateStrip({super.key, required this.onDateSelected});

  @override
  State<DateStrip> createState() => _DateStripState();
}

class _DateStripState extends State<DateStrip> {
  DateTime _selectedDate = DateTime.now();
  final List<DateTime> _dates = [];

  @override
  void initState() {
    super.initState();
    _generateDates();
  }

  void _generateDates() {
    _dates.clear();
    // Generate 7 days centered around the selected date: 3 before, selected, 3 after
    for (int i = -3; i <= 3; i++) {
      _dates.add(_selectedDate.add(Duration(days: i)));
    }
  }

  void _updateSelectedDate(DateTime newDate) {
    setState(() {
      _selectedDate = newDate;
      _generateDates(); // Regenerate dates around the new selection
    });
    widget.onDateSelected(newDate);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Your Activities',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color:
                      Theme.of(context).textTheme.titleLarge?.color ??
                      Colors.black,
                ),
              ),
              GestureDetector(
                onTap: () async {
                  final DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2030),
                    builder: (context, child) {
                      return Theme(
                        data: Theme.of(context).copyWith(
                          colorScheme: ColorScheme(
                            primary: const Color(0xFFF39E75),
                            onPrimary: Colors.white,
                            onSurface:
                                Theme.of(context).brightness == Brightness.dark
                                ? Colors.white
                                : Colors.black,
                            brightness: Theme.of(context).brightness,
                            secondary: const Color(0xFFF39E75),
                            onSecondary: Colors.white,
                            error: Colors.red,
                            onError: Colors.white,
                            surface:
                                Theme.of(context).brightness == Brightness.dark
                                ? Colors.grey.shade900
                                : Colors.white,
                          ),
                        ),
                        child: child!,
                      );
                    },
                  );
                  if (picked != null && picked != _selectedDate) {
                    _updateSelectedDate(picked);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF39E75).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.calendar_today,
                    color: Color(0xFFF39E75),
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 90,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            scrollDirection: Axis.horizontal,
            itemCount: _dates.length,
            separatorBuilder: (context, index) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final date = _dates[index];
              final isSelected =
                  _selectedDate.year == date.year &&
                  _selectedDate.month == date.month &&
                  _selectedDate.day == date.day;

              final isToday =
                  DateTime.now().year == date.year &&
                  DateTime.now().month == date.month &&
                  DateTime.now().day == date.day;

              return GestureDetector(
                onTap: () => _updateSelectedDate(date),
                child: Container(
                  width: 65,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFFF39E75)
                        : (Theme.of(context).brightness == Brightness.dark
                              ? Theme.of(context).cardColor
                              : Colors.white),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: const Color(
                                0xFFF39E75,
                              ).withValues(alpha: 0.4),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : [],
                    border: isToday && !isSelected
                        ? Border.all(color: const Color(0xFFF39E75), width: 2.5)
                        : isSelected
                        ? null
                        : Border.all(
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                ? Colors.grey.shade800
                                : Colors.grey.shade200,
                          ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _getDayName(date.weekday),
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: isSelected
                              ? Colors.white
                              : (Theme.of(context).brightness == Brightness.dark
                                    ? Colors.grey
                                    : Colors.black45),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        date.day.toString(),
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: isSelected
                              ? Colors.white
                              : (Theme.of(context).textTheme.bodyLarge?.color ??
                                    Colors.black87),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  String _getDayName(int weekday) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[weekday - 1];
  }
}
