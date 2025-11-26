class UploadFile {
  final String path;
  String name;
  final int size;
  UploadStatus status;
  String? errorMessage;

  UploadFile({
    required this.path,
    required this.name,
    required this.size,
    this.status = UploadStatus.pending,
    this.errorMessage,
  });

  String get displaySize {
    if (size < 1024) return '$size B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(2)} KB';
    if (size < 1024 * 1024 * 1024) {
      return '${(size / (1024 * 1024)).toStringAsFixed(2)} MB';
    }
    return '${(size / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }
}

enum UploadStatus { pending, uploading, completed, failed }
