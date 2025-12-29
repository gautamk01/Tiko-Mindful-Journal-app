import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

class MediaService {
  /// Get the journal media directory
  Future<Directory> getMediaDirectory() async {
    final appDocDir = await getApplicationDocumentsDirectory();
    final mediaDir = Directory('${appDocDir.path}/journal_media');
    if (!await mediaDir.exists()) {
      await mediaDir.create(recursive: true);
    }
    return mediaDir;
  }

  /// Get images directory
  Future<Directory> getImagesDirectory() async {
    final mediaDir = await getMediaDirectory();
    final imagesDir = Directory('${mediaDir.path}/images');
    if (!await imagesDir.exists()) {
      await imagesDir.create(recursive: true);
    }
    return imagesDir;
  }

  /// Get audio directory
  Future<Directory> getAudioDirectory() async {
    final mediaDir = await getMediaDirectory();
    final audioDir = Directory('${mediaDir.path}/audio');
    if (!await audioDir.exists()) {
      await audioDir.create(recursive: true);
    }
    return audioDir;
  }

  /// Save image to journal media directory
  Future<String> saveImage(String sourcePath, String entryId) async {
    final imagesDir = await getImagesDirectory();
    final fileName =
        '${entryId}_${DateTime.now().millisecondsSinceEpoch}${path.extension(sourcePath)}';
    final destPath = '${imagesDir.path}/$fileName';

    await File(sourcePath).copy(destPath);
    return destPath;
  }

  /// Save audio to journal media directory
  Future<String> saveAudio(String sourcePath, String entryId) async {
    final audioDir = await getAudioDirectory();
    final fileName =
        '${entryId}_${DateTime.now().millisecondsSinceEpoch}${path.extension(sourcePath)}';
    final destPath = '${audioDir.path}/$fileName';

    await File(sourcePath).copy(destPath);
    return destPath;
  }

  /// Delete a media file
  Future<void> deleteMediaFile(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      print('Error deleting file: $e');
    }
  }

  /// Delete all media files for an entry
  Future<void> deleteEntryMedia(
    List<String> imagePaths,
    List<String> audioPaths,
  ) async {
    for (final imagePath in imagePaths) {
      await deleteMediaFile(imagePath);
    }
    for (final audioPath in audioPaths) {
      await deleteMediaFile(audioPath);
    }
  }

  /// Get relative path from absolute path
  Future<String> getRelativePath(String absolutePath) async {
    final mediaDir = await getMediaDirectory();
    final mediaDirPath = mediaDir.path;

    if (absolutePath.startsWith(mediaDirPath)) {
      return absolutePath.substring(mediaDirPath.length + 1);
    }
    return absolutePath;
  }

  /// Get absolute path from relative path
  Future<String> getAbsolutePath(String relativePath) async {
    final mediaDir = await getMediaDirectory();
    return '${mediaDir.path}/$relativePath';
  }

  /// Check if file exists
  Future<bool> fileExists(String filePath) async {
    return await File(filePath).exists();
  }

  /// Get file size in bytes
  Future<int> getFileSize(String filePath) async {
    final file = File(filePath);
    if (await file.exists()) {
      return await file.length();
    }
    return 0;
  }

  /// Copy directory recursively
  Future<void> copyDirectory(Directory source, Directory destination) async {
    if (!await destination.exists()) {
      await destination.create(recursive: true);
    }

    await for (final entity in source.list(recursive: false)) {
      if (entity is Directory) {
        final newDirectory = Directory(
          path.join(destination.absolute.path, path.basename(entity.path)),
        );
        await copyDirectory(entity.absolute, newDirectory);
      } else if (entity is File) {
        await entity.copy(
          path.join(destination.path, path.basename(entity.path)),
        );
      }
    }
  }
}
