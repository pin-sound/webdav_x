import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';

import '../models/upload_file.dart';
import '../services/storage_service.dart';
import '../services/webdav_service.dart';
import '../theme/app_theme.dart';
import '../utils/encryption_helper.dart';
import '../utils/file_renamer.dart';
import '../utils/page_transitions.dart';
import '../widgets/animated_gradient.dart';
import 'settings_screen.dart';

class UploadScreen extends StatefulWidget {
  final String path;
  const UploadScreen({super.key, required this.path});

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  final List<UploadFile> _files = [];
  final _storageService = StorageService();
  final _webdavService = WebDavService();
  bool _isInitialized = false;

  bool _encryptUpload = false;

  @override
  void initState() {
    super.initState();
    _initializeWebDav();
  }

  Future<void> _initializeWebDav() async {
    final username = await _storageService.getUsername();
    final password = await _storageService.getPassword();

    if (username != null && password != null) {
      _webdavService.initialize(username, password, widget.path);
      setState(() {
        _isInitialized = true;
      });
    }
  }

  Future<void> _pickFiles() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.any,
    );

    if (result != null) {
      setState(() {
        for (var file in result.files) {
          if (file.path != null) {
            // Check for duplicates: same name and same size
            final isDuplicate = _files.any(
              (f) => f.name == file.name && f.size == file.size,
            );

            if (!isDuplicate) {
              _files.add(
                UploadFile(path: file.path!, name: file.name, size: file.size),
              );
            }
          }
        }
        _sortFiles();
      });
    }
  }

  void _sortFiles() {
    _files.sort((a, b) {
      // Unfinished (pending/uploading/failed) first, Completed last
      final aScore = a.status == UploadStatus.completed ? 1 : 0;
      final bScore = b.status == UploadStatus.completed ? 1 : 0;
      return aScore.compareTo(bScore);
    });
  }

  Future<void> _uploadFile(UploadFile file) async {
    if (!_isInitialized) {
      SmartDialog.showToast(
        '请先配置 WebDAV 设置',
        displayTime: const Duration(seconds: 1),
      );
      await _navigateToSettings();
      return;
    }

    setState(() {
      file.status = UploadStatus.uploading;
    });

    try {
      // var uploadPath = file.path; // Unused
      var uploadName = FileRenamer.renameWithTimestamp(file.name);

      if (_encryptUpload) {
        uploadName += '.enc';
        final encryptionPassword = await _storageService
            .getEncryptionPassword();
        if (encryptionPassword == null) {
          throw Exception('Encryption password not found');
        }

        // Stream upload with encryption
        final fileStream = File(file.path).openRead();
        final encryptedStream = EncryptionHelper.encryptStream(
          fileStream,
          encryptionPassword,
        );

        // Calculate expected size for progress/headers
        final encryptedSize = EncryptionHelper.calculateEncryptedSize(
          file.size,
        );

        await _webdavService.uploadStream(
          encryptedStream,
          uploadName,
          encryptedSize,
        );
      } else {
        // Normal stream upload
        final fileStream = File(file.path).openRead();
        await _webdavService.uploadStream(fileStream, uploadName, file.size);
      }

      setState(() {
        file.status = UploadStatus.completed;
        _sortFiles();
      });

      if (mounted) {
        SmartDialog.showToast(
          '${file.name} 上传成功',
          displayTime: const Duration(seconds: 1),
        );
      }
    } catch (e) {
      setState(() {
        file.status = UploadStatus.failed;
        file.errorMessage = e.toString();
      });

      if (mounted) {
        SmartDialog.showToast(
          '上传失败: $e',
          displayTime: const Duration(seconds: 1),
        );
      }
    }
  }

  Future<void> _uploadAllFiles() async {
    if (!_isInitialized) {
      SmartDialog.showToast(
        '请先配置 WebDAV 设置',
        displayTime: const Duration(seconds: 1),
      );
      await _navigateToSettings();
      return;
    }

    final pendingFiles = _files
        .where(
          (f) =>
              f.status == UploadStatus.pending ||
              f.status == UploadStatus.failed,
        )
        .toList();

    if (pendingFiles.isEmpty) {
      SmartDialog.showToast(
        '没有待上传的文件',
        displayTime: const Duration(seconds: 1),
      );
      return;
    }

    for (var file in pendingFiles) {
      await _uploadFile(file);
    }
  }

  Future<void> _navigateToSettings() async {
    final result = await Navigator.push(
      context,
      PageTransitions.defaultTransition(const SettingsScreen()),
    );

    if (result == true) {
      await _initializeWebDav();
    }
  }

  void _removeFile(int index) {
    setState(() {
      _files.removeAt(index);
    });
  }

  void _clearAllFiles() {
    setState(() {
      _files.clear();
    });
  }

  Color _getStatusColor(UploadStatus status) {
    switch (status) {
      case UploadStatus.pending:
        return Colors.grey;
      case UploadStatus.uploading:
        return Colors.blue;
      case UploadStatus.completed:
        return Colors.green;
      case UploadStatus.failed:
        return Colors.red;
    }
  }

  IconData _getStatusIcon(UploadStatus status) {
    switch (status) {
      case UploadStatus.pending:
        return Icons.cloud_upload_outlined;
      case UploadStatus.uploading:
        return Icons.cloud_upload_outlined;
      case UploadStatus.completed:
        return Icons.check_circle_outline;
      case UploadStatus.failed:
        return Icons.error_outline;
    }
  }

  int get _pendingCount => _files
      .where(
        (f) =>
            f.status == UploadStatus.pending || f.status == UploadStatus.failed,
      )
      .length;

  void _editFileName(int index) {
    final file = _files[index];

    SmartDialog.show(
      builder: (context) => RenameDialog(
        initialName: file.name,
        onConfirm: (newName) {
          if (newName.isNotEmpty && newName != file.name) {
            setState(() {
              file.name = newName;
            });
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text('上传到: ${widget.path}'),
        flexibleSpace: AppTheme.glassAppBarFlexibleSpace,
      ),
      body: AnimatedGradient(
        colors: [
          Colors.blue.shade50,
          Colors.purple.shade50,
          Colors.pink.shade50,
        ],
        child: SafeArea(
          child: Column(
            children: [
              // 顶部操作区域
              Container(
                margin: const EdgeInsets.all(16.0),
                padding: const EdgeInsets.all(20.0),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.8),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.purple.withValues(alpha: 0.05),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final isSmallScreen = constraints.maxWidth < 500;
                        if (isSmallScreen) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _buildActionButton(
                                onPressed: _pickFiles,
                                icon: Icons.add_rounded,
                                label: '选择文件',
                                isPrimary: true,
                              ),
                              if (_files.isNotEmpty) ...[
                                const SizedBox(height: 12),
                                _buildActionButton(
                                  onPressed: _pendingCount > 0
                                      ? _uploadAllFiles
                                      : null,
                                  icon: Icons.cloud_upload_rounded,
                                  label: '上传全部 ($_pendingCount)',
                                  isPrimary: false,
                                  isAccent: true,
                                ),
                                const SizedBox(height: 12),
                                _buildActionButton(
                                  onPressed: _clearAllFiles,
                                  icon: Icons.delete_sweep_rounded,
                                  label: '清空列表',
                                  isPrimary: false,
                                ),
                              ],
                            ],
                          );
                        }
                        return Row(
                          children: [
                            Expanded(
                              child: _buildActionButton(
                                onPressed: _pickFiles,
                                icon: Icons.add_rounded,
                                label: '选择文件',
                                isPrimary: true,
                              ),
                            ),
                            if (_files.isNotEmpty) ...[
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildActionButton(
                                  onPressed: _pendingCount > 0
                                      ? _uploadAllFiles
                                      : null,
                                  icon: Icons.cloud_upload_rounded,
                                  label: '上传全部 ($_pendingCount)',
                                  isPrimary: false,
                                  isAccent: true,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildActionButton(
                                  onPressed: _clearAllFiles,
                                  icon: Icons.delete_sweep_rounded,
                                  label: '清空列表',
                                  isPrimary: false,
                                ),
                              ),
                            ],
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.link_rounded,
                                size: 16,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'https://dav.jianguoyun.com/dav/${widget.path}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[700],
                                    height: 1.0,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 16),
                          Row(
                            children: [
                              Icon(
                                _encryptUpload
                                    ? Icons.lock_rounded
                                    : Icons.lock_open_rounded,
                                size: 16,
                                color: _encryptUpload
                                    ? Colors.blue
                                    : Colors.grey[600],
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '加密上传',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[800],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const Spacer(),
                              Switch(
                                value: _encryptUpload,
                                onChanged: (value) {
                                  setState(() {
                                    _encryptUpload = value;
                                  });
                                },
                                activeThumbColor: Colors.blue,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // 文件列表区域
              Expanded(
                child: _files.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(32),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.5),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.blue.withValues(alpha: 0.1),
                                    blurRadius: 30,
                                    spreadRadius: 10,
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.cloud_upload_rounded,
                                size: 80,
                                color: Colors.blue.shade200,
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              '准备上传',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[800],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '点击上方按钮选择文件',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        itemCount: _files.length,
                        itemBuilder: (context, index) {
                          final file = _files[index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.7),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.6),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.03),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              leading: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: _getStatusColor(
                                    file.status,
                                  ).withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  _getStatusIcon(file.status),
                                  color: _getStatusColor(file.status),
                                  size: 24,
                                ),
                              ),
                              title: Text(
                                file.name,
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  Text(
                                    '大小: ${file.displaySize}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  if (file.status == UploadStatus.failed &&
                                      file.errorMessage != null)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Text(
                                        '错误: ${file.errorMessage}',
                                        style: TextStyle(
                                          color: Colors.red.shade400,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (file.status == UploadStatus.uploading)
                                    SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Colors.blue.shade400,
                                            ),
                                      ),
                                    )
                                  else if (file.status ==
                                          UploadStatus.pending ||
                                      file.status == UploadStatus.failed) ...[
                                    IconButton(
                                      icon: const Icon(Icons.edit_rounded),
                                      onPressed: () => _editFileName(index),
                                      tooltip: '编辑文件名',
                                      iconSize: 20,
                                      color: Colors.grey[700],
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.upload_rounded),
                                      onPressed: () => _uploadFile(file),
                                      tooltip: '上传',
                                      color: Colors.blue.shade600,
                                      iconSize: 20,
                                    ),
                                  ],
                                  IconButton(
                                    icon: const Icon(Icons.close_rounded),
                                    onPressed: () => _removeFile(index),
                                    tooltip: '移除',
                                    iconSize: 20,
                                    color: Colors.grey[400],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required VoidCallback? onPressed,
    required IconData icon,
    required String label,
    required bool isPrimary,
    bool isAccent = false,
  }) {
    final color = isPrimary
        ? Colors.blue.shade600
        : (isAccent ? Colors.purple.shade500 : Colors.grey.shade700);

    final backgroundColor = isPrimary
        ? Colors.blue.shade50
        : (isAccent ? Colors.purple.shade50 : Colors.transparent);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isPrimary || isAccent
                  ? color.withValues(alpha: 0.3)
                  : Colors.grey.shade300,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: onPressed != null ? color : Colors.grey.shade400,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: onPressed != null ? color : Colors.grey.shade400,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class RenameDialog extends StatefulWidget {
  final String initialName;
  final Function(String) onConfirm;

  const RenameDialog({
    super.key,
    required this.initialName,
    required this.onConfirm,
  });

  @override
  State<RenameDialog> createState() => _RenameDialogState();
}

class _RenameDialogState extends State<RenameDialog> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialName);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('编辑文件名'),
      content: TextField(
        controller: _controller,
        decoration: InputDecoration(
          labelText: '文件名',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        ),
        autofocus: true,
      ),
      actions: [
        TextButton(
          onPressed: () => SmartDialog.dismiss(),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: () {
            widget.onConfirm(_controller.text);
            SmartDialog.dismiss();
          },
          child: const Text('确认'),
        ),
      ],
    );
  }
}
