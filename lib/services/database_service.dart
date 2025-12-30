import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:tracking_app/models/daily_metrics.dart';
import 'package:tracking_app/models/journal_entry.dart';
import 'package:tracking_app/models/hourly_mood.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  static const String journalBoxName = 'journal_entries';
  static const String metricsBoxName = 'daily_metrics';
  static const String userBoxName = 'user_data';

  late Box<JournalEntry> _journalBox;
  late Box<DailyMetrics> _metricsBox;
  late Box _userBox;

  Future<void> init() async {
    await Hive.initFlutter();

    // Register adapters
    Hive.registerAdapter(JournalEntryAdapter());
    Hive.registerAdapter(DailyMetricsAdapter());
    Hive.registerAdapter(HourlyMoodAdapter());

    // Open boxes
    _journalBox = await Hive.openBox<JournalEntry>(journalBoxName);
    _metricsBox = await Hive.openBox<DailyMetrics>(metricsBoxName);
    _userBox = await Hive.openBox(userBoxName);
    await Hive.openBox<HourlyMood>('hourly_moods');
  }

  // User Data Methods
  Future<void> saveUserName(String name) async {
    await _userBox.put('userName', name);
  }

  String? getUserName() {
    return _userBox.get('userName');
  }

  Future<void> saveProfileImagePath(String? path) async {
    await _userBox.put('profileImagePath', path);
  }

  String? getProfileImagePath() {
    return _userBox.get('profileImagePath');
  }

  Box<JournalEntry> getJournalEntriesBox() {
    return _journalBox;
  }

  Future<void> setFirstLaunch(bool value) async {
    await _userBox.put('isFirstLaunch', value);
  }

  bool isFirstLaunch() {
    return _userBox.get('isFirstLaunch', defaultValue: true);
  }

  // Theme Methods
  Future<void> saveThemeMode(String mode) async {
    await _userBox.put('themeMode', mode);
  }

  String getThemeMode() {
    return _userBox.get('themeMode', defaultValue: 'system');
  }

  ValueListenable<Box> getUserDataListenable() {
    return _userBox.listenable();
  }

  // Journal Methods
  Future<void> saveJournalEntry(JournalEntry entry) async {
    await _journalBox.put(entry.id, entry);
  }

  JournalEntry? getJournalEntry(String id) {
    return _journalBox.get(id);
  }

  List<JournalEntry> getAllJournalEntries() {
    return _journalBox.values.toList();
  }

  List<JournalEntry> getEntriesForDate(DateTime date) {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

    return _journalBox.values.where((entry) {
      return entry.date.isAfter(startOfDay) && entry.date.isBefore(endOfDay);
    }).toList();
  }

  Future<void> deleteJournalEntry(String id) async {
    await _journalBox.delete(id);
  }

  // Daily Metrics Methods
  Future<void> saveDailyMetrics(DailyMetrics metrics) async {
    final key = _getDateKey(metrics.date);
    await _metricsBox.put(key, metrics);
  }

  DailyMetrics? getMetricsForDate(DateTime date) {
    final key = _getDateKey(date);
    return _metricsBox.get(key);
  }

  List<DailyMetrics> getAllMetrics() {
    return _metricsBox.values.toList();
  }

  DailyMetrics? getTodayMetrics() {
    return getMetricsForDate(DateTime.now());
  }

  Future<void> deleteMetrics(DateTime date) async {
    final key = _getDateKey(date);
    await _metricsBox.delete(key);
  }

  // Helper method to create consistent date keys
  String _getDateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  // Clear all data
  Future<void> clearAllData() async {
    await _journalBox.clear();
    await _metricsBox.clear();
    await _userBox.clear();
    final hourlyMoodBox = Hive.box<HourlyMood>('hourly_moods');
    await hourlyMoodBox.clear();
  }

  //  ===== Hourly Mood Methods =====

  Future<void> saveHourlyMood(HourlyMood mood) async {
    final box = Hive.box<HourlyMood>('hourly_moods');
    await box.put(mood.id, mood);
  }

  List<HourlyMood> getHourlyMoodsForDate(DateTime date) {
    final box = Hive.box<HourlyMood>('hourly_moods');
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return box.values.where((mood) {
      return mood.timestamp.isAfter(
            startOfDay.subtract(const Duration(seconds: 1)),
          ) &&
          mood.timestamp.isBefore(endOfDay);
    }).toList()..sort((a, b) => a.timestamp.compareTo(b.timestamp));
  }

  /// Get all mood entries for today
  List<HourlyMood> getMoodEntriesForToday() {
    return getHourlyMoodsForDate(DateTime.now());
  }

  List<HourlyMood> getAllHourlyMoods() {
    final box = Hive.box<HourlyMood>('hourly_moods');
    return box.values.toList();
  }

  Future<void> deleteHourlyMood(String id) async {
    final box = Hive.box<HourlyMood>('hourly_moods');
    await box.delete(id);
  }
}
