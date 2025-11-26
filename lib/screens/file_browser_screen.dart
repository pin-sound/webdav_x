import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:webdav_client/webdav_client.dart' as webdav;

import '../services/storage_service.dart';
import '../services/webdav_service.dart';
import '../theme/app_theme.dart';
import '../utils/encryption_helper.dart';
import '../utils/file_renamer.dart';
import '../utils/page_transitions.dart';
import '../widgets/animated_gradient.dart';
import 'settings_screen.dart';

class FileBrowserScreen extends StatefulWidget {
  final String path;
  const FileBrowserScreen({super.key, required this.path});

  @override
  State<FileBrowserScreen> createState() => _FileBrowserScreenState();
}

class _FileBrowserScreenState extends State<FileBrowserScreen> {
  final _storageService = StorageService();
  final _webdavService = WebDavService();
  List<webdav.File> _files = [];
  bool _isLoading = true;
  String? _errorMessage;
  final Set<String> _downloadingFiles = {};

  @override
  void initState() {
    super.initState();
    _initializeAndLoad();
  }

  Future<void> _initializeAndLoad() async {
    final username = await _storageService.getUsername();
    final password = await _storageService.getPassword();

    if (username != null && password != null) {
      _webdavService.initialize(username, password, widget.path);
      await _loadFiles();
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('请先配置 WebDAV 设置'),
            duration: Duration(seconds: 1),
          ),
        );
        _navigateToSettings();
      }
    }
  }

  Future<void> _loadFiles() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final files = await _webdavService.listFiles('.');

      // Sort by modification time (newest first)
      files.sort((a, b) {
        final aTime = a.mTime ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bTime = b.mTime ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bTime.compareTo(aTime);
      });

      setState(() {
        _files = files;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  Future<void> _deleteFile(webdav.File file) async {
    SmartDialog.show(
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除 "${file.name}" 吗？'),
        actions: [
          TextButton(
            onPressed: () => SmartDialog.dismiss(),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () async {
              SmartDialog.dismiss();
              try {
                await _webdavService.deleteFile(file.name ?? '');

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('删除成功'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                }
                _loadFiles();
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('删除失败: $e'),
                      duration: const Duration(seconds: 1),
                    ),
                  );
                }
              }
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }

  Future<void> _downloadFile(webdav.File file) async {
    if (file.name == null) return;

    setState(() {
      _downloadingFiles.add(file.name!);
    });

    if (Platform.isAndroid) {
      if (await Permission.notification.isDenied) {
        await Permission.notification.request();
      }

      final service = FlutterBackgroundService();
      if (!await service.isRunning()) {
        await service.startService();
      }
      service.invoke("update", {"filenames": _downloadingFiles.toList()});
    }

    try {
      // Get downloads directory
      String? downloadPath;
      if (Platform.isAndroid) {
        // Try to use the public Download directory
        final directory = Directory('/storage/emulated/0/Download');
        if (await directory.exists()) {
          downloadPath = path.join(directory.path, 'WebDAV_X');
        } else {
          // Fallback to app-specific external storage
          final extDir = await getExternalStorageDirectory();
          if (extDir != null) {
            downloadPath = path.join(extDir.path, 'Download');
          }
        }
      } else if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
        final downloadDir = await getDownloadsDirectory();
        if (downloadDir != null) {
          downloadPath = path.join(downloadDir.path, 'WebDAV_X');
        }
      } else if (Platform.isIOS) {
        final docsDir = await getApplicationDocumentsDirectory();
        downloadPath = path.join(docsDir.path, 'Downloads');
      }

      // Final fallback
      if (downloadPath == null) {
        final dir = await getApplicationDocumentsDirectory();
        downloadPath = path.join(dir.path, 'WebDAV_X_Downloads');
      }

      // Ensure directory exists
      final directory = Directory(downloadPath);
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }

      var localPath = path.join(downloadPath, file.name);
      var shouldDecrypt = false;

      // Check if file is encrypted
      if (file.name != null && file.name!.endsWith('.enc')) {
        final result = await SmartDialog.show(
          builder: (context) {
            return AlertDialog(
              title: const Text('检测到加密文件'),
              content: const Text('是否在下载后自动解密？'),
              actions: [
                TextButton(
                  onPressed: () => SmartDialog.dismiss(result: false),
                  child: const Text('仅下载'),
                ),
                FilledButton(
                  onPressed: () => SmartDialog.dismiss(result: true),
                  child: const Text('下载并解密'),
                ),
              ],
            );
          },
        );

        if (result == null) {
          setState(() {
            _downloadingFiles.remove(file.name);
          });
          return; // Cancel download if dismissed
        }
        shouldDecrypt = result == true;
      }

      // Get unique path for the initial download
      localPath = await FileRenamer.getUniquePath(localPath);

      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('开始下载: ${path.basename(localPath)}'),
            duration: const Duration(seconds: 1),
          ),
        );
      }

      // Download file stream
      final stream = await _webdavService.downloadStream(file.name ?? '');

      // Write stream to local file
      final sink = File(localPath).openWrite();
      await sink.addStream(stream);
      await sink.close();

      if (shouldDecrypt) {
        if (mounted) {
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('正在解密...'),
              duration: Duration(seconds: 1),
            ),
          );
        }

        try {
          final encryptionPassword = await _storageService
              .getEncryptionPassword();
          if (encryptionPassword == null) {
            throw Exception('Encryption password not found');
          }

          // Determine final path using shared logic
          // Use file.name to ensure we strip .enc correctly
          final finalPath = await FileRenamer.prepareDecryptedPath(
            file.name ?? path.basename(localPath),
            downloadPath,
          );

          // Decrypt using streams
          // First, we need to read the downloaded encrypted file
          final encryptedFileStream = File(localPath).openRead();
          final decryptedStream = EncryptionHelper.decryptStream(
            encryptedFileStream,
            encryptionPassword,
          );

          // Write decrypted data to final path
          final sink = File(finalPath).openWrite();
          await sink.addStream(decryptedStream);
          await sink.close();

          // Remove the encrypted file
          final encryptedFile = File(localPath);
          await encryptedFile.delete();

          localPath = finalPath; // Update path for success message
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).clearSnackBars();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('解密失败: $e'),
                duration: const Duration(seconds: 2),
              ),
            );
          }
          // Keep the encrypted file if decryption fails
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('下载成功: ${path.basename(localPath)}'),
            duration: const Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('下载失败: $e'),
            duration: const Duration(seconds: 1),
          ),
        );
      }
    } finally {
      if (Platform.isAndroid) {
        final remainingFiles = _downloadingFiles
            .where((name) => name != file.name)
            .toList();
        final service = FlutterBackgroundService();

        if (remainingFiles.isEmpty) {
          service.invoke("stopService");
        } else {
          service.invoke("update", {"filenames": remainingFiles});
        }
      }

      if (mounted) {
        setState(() {
          _downloadingFiles.remove(file.name);
        });
      }
    }
  }

  Future<void> _navigateToSettings() async {
    final result = await Navigator.push(
      context,
      PageTransitions.defaultTransition(const SettingsScreen()),
    );

    if (result == true) {
      _initializeAndLoad();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text('浏览目录: ${widget.path}'),
        flexibleSpace: AppTheme.glassAppBarFlexibleSpace,
        actions: [
          IconButton(
            icon: const Icon(Icons.sync_rounded),
            onPressed: _loadFiles,
            tooltip: '刷新',
          ),
        ],
      ),
      body: AnimatedGradient(
        colors: [
          Colors.blue.shade50,
          Colors.purple.shade50,
          Colors.pink.shade50,
        ],
        child: SafeArea(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.error_outline_rounded,
                          size: 64,
                          color: Colors.red.shade400,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        '加载失败',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.orange.shade400,
                              Colors.deepOrange.shade400,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.orange.withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: _loadFiles,
                            borderRadius: BorderRadius.circular(12),
                            child: const Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.refresh_rounded,
                                    color: Colors.white,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    '重试',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
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
                )
              : _files.isEmpty
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
                          Icons.folder_open_rounded,
                          size: 80,
                          color: Colors.blue.shade200,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        '文件夹为空',
                        style: TextStyle(
                          fontSize: 24,
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                  itemCount: _files.length,
                  itemBuilder: (context, index) {
                    final file = _files[index];
                    final isDir = file.isDir ?? false;
                    final isEncrypted =
                        !isDir && (file.name?.endsWith('.enc') ?? false);

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isEncrypted
                              ? Colors.purple.withValues(alpha: 0.3)
                              : Colors.white.withValues(alpha: 0.6),
                          width: isEncrypted ? 1.5 : 1.0,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: isEncrypted
                                ? Colors.purple.withValues(alpha: 0.05)
                                : Colors.black.withValues(alpha: 0.03),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            // 序号
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: Colors.grey.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  '${index + 1}',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            // 文件图标
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: isDir
                                      ? [
                                          Colors.amber.shade100,
                                          Colors.orange.shade100,
                                        ]
                                      : (isEncrypted
                                            ? [
                                                Colors.purple.shade100,
                                                Colors.deepPurple.shade100,
                                              ]
                                            : [
                                                Colors.blue.shade100,
                                                Colors.cyan.shade100,
                                              ]),
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                isDir
                                    ? Icons.folder_rounded
                                    : (isEncrypted
                                          ? Icons.lock_outline_rounded
                                          : Icons.description_rounded),
                                color: isDir
                                    ? Colors.amber.shade700
                                    : (isEncrypted
                                          ? Colors.purple.shade600
                                          : Colors.blue.shade600),
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    file.name ?? 'Unknown',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 15,
                                      color: isEncrypted
                                          ? Colors.purple.shade800
                                          : Colors.grey.shade800,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Wrap(
                                    crossAxisAlignment:
                                        WrapCrossAlignment.center,
                                    spacing: 4,
                                    children: [
                                      if (file.size != null)
                                        Text(
                                          '${(file.size! / 1024).toStringAsFixed(2)} KB',
                                          style: TextStyle(
                                            color: Colors.grey.shade600,
                                            fontSize: 13,
                                          ),
                                        ),
                                      if (file.size != null &&
                                          file.mTime != null)
                                        Text(
                                          '•',
                                          style: TextStyle(
                                            color: Colors.grey.shade400,
                                            fontSize: 12,
                                          ),
                                        ),
                                      if (file.mTime != null)
                                        Text(
                                          file.mTime.toString().split('.')[0],
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey.shade500,
                                          ),
                                        ),
                                    ],
                                  ),
                                  if (isEncrypted)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.purple.withValues(
                                            alpha: 0.1,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                        child: Text(
                                          '已加密',
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: Colors.purple.shade600,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (!isDir)
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Colors.blue.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        onTap:
                                            _downloadingFiles.contains(
                                              file.name,
                                            )
                                            ? null
                                            : () => _downloadFile(file),
                                        borderRadius: BorderRadius.circular(8),
                                        child: Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child:
                                              _downloadingFiles.contains(
                                                file.name,
                                              )
                                              ? SizedBox(
                                                  width: 20,
                                                  height: 20,
                                                  child: CircularProgressIndicator(
                                                    strokeWidth: 2,
                                                    valueColor:
                                                        AlwaysStoppedAnimation<
                                                          Color
                                                        >(Colors.blue.shade600),
                                                  ),
                                                )
                                              : Icon(
                                                  Icons.file_download_outlined,
                                                  color: Colors.blue.shade600,
                                                  size: 20,
                                                ),
                                        ),
                                      ),
                                    ),
                                  ),
                                const SizedBox(width: 8),
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.red.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: () => _deleteFile(file),
                                      borderRadius: BorderRadius.circular(8),
                                      child: Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Icon(
                                          Icons.delete_outline_rounded,
                                          color: Colors.red.shade400,
                                          size: 20,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ),
    );
  }
}
