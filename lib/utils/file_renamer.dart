import 'dart:io';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as path;

class FileRenamer {
  /// Generates a new filename with timestamp prefix
  /// Format: WebDavX于YYYY年MM月DD日HH点mm分ss秒上传-originalname.ext
  static String renameWithTimestamp(String originalPath) {
    final timestamp = DateFormat('yyyy年MM月dd日HH点mm分ss秒').format(DateTime.now());
    final fileName = path.basename(originalPath);
    final extension = path.extension(fileName);
    final nameWithoutExtension = path.basenameWithoutExtension(fileName);

    return 'WebDavX于$timestamp上传-$nameWithoutExtension$extension';
  }

  /// Ensures a unique file path by appending (N) if the file already exists.
  static Future<String> getUniquePath(String filePath) async {
    // Check if any file system entity exists at the path (File or Directory)
    if (await FileSystemEntity.type(filePath) ==
        FileSystemEntityType.notFound) {
      return filePath;
    }

    final dir = path.dirname(filePath);
    final filename = path.basename(filePath);
    final extension = path.extension(filename);
    final nameWithoutExtension = path.basenameWithoutExtension(filename);

    int counter = 1;
    while (true) {
      // Append (counter) before the extension
      // Example: file.txt -> file(1).txt
      final newFilename = '$nameWithoutExtension($counter)$extension';
      final newPath = path.join(dir, newFilename);

      if (await FileSystemEntity.type(newPath) ==
          FileSystemEntityType.notFound) {
        return newPath;
      }
      counter++;
    }
  }

  /// Prepares a unique path for a decrypted file.
  /// Strips .enc extension if present, then ensures uniqueness in the output directory.
  static Future<String> prepareDecryptedPath(
    String originalPath,
    String outputDir,
  ) async {
    var filename = path.basename(originalPath);
    if (filename.endsWith('.enc')) {
      filename = filename.substring(0, filename.length - 4);
    }

    final outputPath = path.join(outputDir, filename);
    return getUniquePath(outputPath);
  }
}
