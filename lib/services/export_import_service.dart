import 'dart:convert';
import 'dart:io';
import 'package:archive/archive_io.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:tracking_app/models/daily_metrics.dart';
import 'package:tracking_app/models/journal_entry.dart';
import 'package:tracking_app/services/database_service.dart';
import 'package:tracking_app/services/media_service.dart';

class ExportImportService {
  final DatabaseService _db = DatabaseService();
  final MediaService _mediaService = MediaService();

  /// Export all data including media files to ZIP
  Future<String> exportData() async {
    try {
      // Get all data
      final journalEntries = _db.getAllJournalEntries();
      final metrics = _db.getAllMetrics();
      final userName = _db.getUserName();
      final profileImagePath = _db.getProfileImagePath();

      // Create temp directory for export
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final exportDirPath = '${tempDir.path}/wellness_export_$timestamp';
      final exportDir = Directory(exportDirPath);
      await exportDir.create(recursive: true);

      // Prepare data with relative paths for media
      final mediaDir = await _mediaService.getMediaDirectory();
      final List<Map<String, dynamic>> journalEntriesJson = [];

      for (final entry in journalEntries) {
        final entryJson = entry.toJson();

        // Convert absolute paths to relative
        entryJson['imagePaths'] = entry.imagePaths
            .map((p) => _getRelativePath(p, mediaDir.path))
            .toList();
        entryJson['audioPaths'] = entry.audioPaths
            .map((p) => _getRelativePath(p, mediaDir.path))
            .toList();

        journalEntriesJson.add(entryJson);
      }

      // Create JSON data
      final exportData = {
        'version': '2.0', // Updated version for media support
        'export_date': DateTime.now().toIso8601String(),
        'user': {'name': userName},
        'journal_entries': journalEntriesJson,
        'daily_metrics': metrics.map((m) => m.toJson()).toList(),
      };

      // Write data.json
      final jsonString = const JsonEncoder.withIndent('  ').convert(exportData);
      final dataFile = File('${exportDir.path}/data.json');
      await dataFile.writeAsString(jsonString);

      // Copy media files
      final exportMediaDir = Directory('${exportDir.path}/media');
      await exportMediaDir.create(recursive: true);

      if (await mediaDir.exists()) {
        await _mediaService.copyDirectory(mediaDir, exportMediaDir);
      }

      // Copy profile image if exists
      if (profileImagePath != null && await File(profileImagePath).exists()) {
        final profileFile = File(profileImagePath);
        final profileDest = File(
          '${exportDir.path}/profile_image${path.extension(profileImagePath)}',
        );
        await profileFile.copy(profileDest.path);

        // Add profile image to user data
        final userData = exportData['user'] as Map<String, dynamic>;
        userData['profile_image'] =
            'profile_image${path.extension(profileImagePath)}';

        // Update JSON
        await dataFile.writeAsString(
          const JsonEncoder.withIndent('  ').convert(exportData),
        );
      }

      // Create ZIP file in Downloads
      final downloadsDir = Directory('/storage/emulated/0/Download');
      if (!await downloadsDir.exists()) {
        await downloadsDir.create(recursive: true);
      }

      final fileName = 'wellness_backup_$timestamp.zip';
      final zipPath = '${downloadsDir.path}/$fileName';

      final encoder = ZipFileEncoder();
      encoder.create(zipPath);
      encoder.addDirectory(exportDir);
      encoder.close();

      // Cleanup temp directory
      await exportDir.delete(recursive: true);

      return 'Backup saved to Downloads/$fileName';
    } catch (e) {
      debugPrint('Export error: $e');
      return 'Export failed: $e';
    }
  }

  /// Import data from ZIP file including media
  Future<String> importData() async {
    try {
      // Pick ZIP file
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: [
          'zip',
          'json',
        ], // Support both for backward compatibility
      );

      if (result == null || result.files.isEmpty) {
        return 'No file selected';
      }

      final filePath = result.files.single.path!;
      final fileExt = path.extension(filePath).toLowerCase();

      // Handle old JSON format
      if (fileExt == '.json') {
        return await _importLegacyJson(filePath);
      }

      // Handle new ZIP format
      if (fileExt != '.zip') {
        return 'Invalid file format. Please select a ZIP or JSON file.';
      }

      // Create temp directory for extraction
      final tempDir = await getTemporaryDirectory();
      final extractPath =
          '${tempDir.path}/import_${DateTime.now().millisecondsSinceEpoch}';
      final extractDir = Directory(extractPath);
      await extractDir.create(recursive: true);

      // Extract ZIP file
      final bytes = await File(filePath).readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);

      // Extract all files
      for (final file in archive) {
        final filename = file.name;
        if (file.isFile) {
          final data = file.content as List<int>;
          final outFile = File('${extractDir.path}/$filename');
          await outFile.create(recursive: true);
          await outFile.writeAsBytes(data);
        } else {
          await Directory(
            '${extractDir.path}/$filename',
          ).create(recursive: true);
        }
      }

      // Find data.json - it might be in root or in a subdirectory
      File? dataFile;

      // Check root level first
      final rootDataFile = File('${extractDir.path}/data.json');
      if (await rootDataFile.exists()) {
        dataFile = rootDataFile;
      } else {
        // Search in subdirectories
        await for (final entity in extractDir.list(recursive: true)) {
          if (entity is File && entity.path.endsWith('data.json')) {
            dataFile = entity;
            break;
          }
        }
      }

      if (dataFile == null || !await dataFile.exists()) {
        await extractDir.delete(recursive: true);
        return 'Import failed: data.json not found in backup file';
      }

      // Read and parse JSON
      final jsonString = await dataFile.readAsString();
      final data = jsonDecode(jsonString) as Map<String, dynamic>;

      // Validate version
      final version = data['version'] ?? '1.0';
      if (version != '2.0' && version != '1.0') {
        await extractDir.delete(recursive: true);
        return 'Unsupported backup version';
      }

      // Clear existing data before importing
      await _db.clearAllData();

      // Get the directory containing data.json (might be root or subdirectory)
      final dataFileDir = dataFile.parent;

      // Import media files
      final mediaSourceDir = Directory('${dataFileDir.path}/media');
      if (await mediaSourceDir.exists()) {
        final mediaDestDir = await _mediaService.getMediaDirectory();
        await _mediaService.copyDirectory(mediaSourceDir, mediaDestDir);
      }

      // Convert relative paths to absolute paths
      final mediaDir = await _mediaService.getMediaDirectory();
      if (data.containsKey('journal_entries')) {
        for (final entryJson in data['journal_entries'] as List) {
          final entry = entryJson as Map<String, dynamic>;

          // Convert image paths
          if (entry.containsKey('imagePaths')) {
            entry['imagePaths'] = (entry['imagePaths'] as List)
                .map((p) => path.join(mediaDir.path, p.toString()))
                .toList();
          }

          // Convert audio paths
          if (entry.containsKey('audioPaths')) {
            entry['audioPaths'] = (entry['audioPaths'] as List)
                .map((p) => path.join(mediaDir.path, p.toString()))
                .toList();
          }
        }
      }

      // Import journal entries
      int importedEntries = 0;
      if (data.containsKey('journal_entries')) {
        for (final entryJson in data['journal_entries'] as List) {
          final entry = JournalEntry.fromJson(
            entryJson as Map<String, dynamic>,
          );
          await _db.saveJournalEntry(entry);
          importedEntries++;
        }
      }

      // Import metrics
      int importedMetrics = 0;
      if (data.containsKey('daily_metrics')) {
        for (final metricJson in data['daily_metrics'] as List) {
          final metric = DailyMetrics.fromJson(
            metricJson as Map<String, dynamic>,
          );
          await _db.saveDailyMetrics(metric);
          importedMetrics++;
        }
      }

      // Import user data
      if (data.containsKey('user')) {
        final userData = data['user'] as Map<String, dynamic>;
        if (userData.containsKey('name')) {
          await _db.saveUserName(userData['name'] as String);
        }

        // Import profile image if exists
        if (userData.containsKey('profile_image')) {
          final profileImageName = userData['profile_image'] as String;
          final profileSource = File('${dataFileDir.path}/$profileImageName');

          if (await profileSource.exists()) {
            final appDir = await getApplicationDocumentsDirectory();
            final profileDest = File('${appDir.path}/$profileImageName');
            await profileSource.copy(profileDest.path);
            await _db.saveProfileImagePath(profileDest.path);
          }
        }
      }

      // Cleanup
      await extractDir.delete(recursive: true);

      return 'Import successful!\nImported:\n• $importedEntries journal entries\n• $importedMetrics daily records\n• Media files restored';
    } catch (e) {
      debugPrint('Import error: $e');
      return 'Import failed: $e';
    }
  }

  /// Backward compatibility: Import old JSON format
  Future<String> _importLegacyJson(String filePath) async {
    return await _importJsonOnly(filePath);
  }

  /// Backward compatibility: Import old JSON format
  Future<String> _importJsonOnly(String filePath) async {
    try {
      final file = File(filePath);
      final jsonString = await file.readAsString();
      final data = jsonDecode(jsonString) as Map<String, dynamic>;

      if (data['version'] != '1.0') {
        return 'Unsupported backup version';
      }

      await _db.clearAllData();

      if (data['user'] != null && data['user']['name'] != null) {
        await _db.saveUserName(data['user']['name']);
      }

      int importedEntries = 0;
      if (data['journal_entries'] != null) {
        final entries = (data['journal_entries'] as List)
            .map((e) => JournalEntry.fromJson(e))
            .toList();

        for (final entry in entries) {
          await _db.saveJournalEntry(entry);
          importedEntries++;
        }
      }

      int importedMetrics = 0;
      if (data['daily_metrics'] != null) {
        final metricsList = (data['daily_metrics'] as List)
            .map((m) => DailyMetrics.fromJson(m))
            .toList();

        for (final metric in metricsList) {
          await _db.saveDailyMetrics(metric);
          importedMetrics++;
        }
      }

      return 'Import successful!\nImported $importedEntries journal entries and $importedMetrics daily records.';
    } catch (e) {
      return 'Import failed: $e';
    }
  }

  /// Convert absolute path to relative path
  String _getRelativePath(String absolutePath, String basePath) {
    if (absolutePath.startsWith(basePath)) {
      return absolutePath.substring(basePath.length + 1);
    }
    return absolutePath;
  }
}
