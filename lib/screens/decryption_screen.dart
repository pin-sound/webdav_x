import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import '../utils/encryption_helper.dart';
import '../utils/file_renamer.dart';
import '../widgets/animated_gradient.dart';

class DecryptionScreen extends StatefulWidget {
  const DecryptionScreen({super.key});

  @override
  State<DecryptionScreen> createState() => _DecryptionScreenState();
}

class _DecryptionScreenState extends State<DecryptionScreen> {
  bool _isProcessing = false;
  final List<String> _logs = [];
  final ScrollController _logScrollController = ScrollController();
  final _storageService = StorageService();

  void _addLog(String message) {
    setState(() {
      _logs.add(message);
    });
    // Scroll to bottom
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_logScrollController.hasClients) {
        _logScrollController.animateTo(
          _logScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _decryptSingleFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles();

      if (result != null && result.files.single.path != null) {
        final filePath = result.files.single.path!;

        if (!filePath.endsWith('.enc')) {
          _addLog('错误: 选择的文件不是加密文件 (.enc)');
          SmartDialog.showToast('请选择 .enc 文件');
          return;
        }

        setState(() {
          _isProcessing = true;
        });
        _addLog('开始解密文件: ${path.basename(filePath)}');

        try {
          final encryptionPassword = await _storageService
              .getEncryptionPassword();
          if (encryptionPassword == null) {
            throw Exception('Encryption password not found');
          }

          // Determine output path
          // Determine output path
          String outputDir;
          if (Platform.isAndroid) {
            // Try to use the public Download directory
            final directory = Directory('/storage/emulated/0/Download');
            if (await directory.exists()) {
              outputDir = path.join(directory.path, 'WebDAV_X_Decrypted');
            } else {
              // Fallback to app-specific external storage
              final extDir = await getExternalStorageDirectory();
              if (extDir != null) {
                outputDir = path.join(extDir.path, 'Decrypted');
              } else {
                // Final fallback to app documents
                final docsDir = await getApplicationDocumentsDirectory();
                outputDir = path.join(docsDir.path, 'Decrypted');
              }
            }
          } else if (Platform.isWindows ||
              Platform.isLinux ||
              Platform.isMacOS) {
            final downloadDir = await getDownloadsDirectory();
            if (downloadDir != null) {
              outputDir = path.join(downloadDir.path, 'WebDAV_X_Decrypted');
            } else {
              final docsDir = await getApplicationDocumentsDirectory();
              outputDir = path.join(docsDir.path, 'Decrypted');
            }
          } else if (Platform.isIOS) {
            final docsDir = await getApplicationDocumentsDirectory();
            outputDir = path.join(docsDir.path, 'Decrypted');
          } else {
            // Default to same directory as input file for other platforms (or if logic fails)
            outputDir = path.dirname(filePath);
          }

          // Ensure directory exists
          final directory = Directory(outputDir);
          if (!await directory.exists()) {
            await directory.create(recursive: true);
          }

          // Determine output path using shared logic
          var outputPath = await FileRenamer.prepareDecryptedPath(
            filePath,
            outputDir,
          );

          // Decrypt using streams
          final fileStream = File(filePath).openRead();
          final decryptedStream = EncryptionHelper.decryptStream(
            fileStream,
            encryptionPassword,
          );

          // Write to file
          final sink = File(outputPath).openWrite();
          await sink.addStream(decryptedStream);
          await sink.close();

          _addLog('✅ 解密成功');
          _addLog('保存路径: $outputPath');
          SmartDialog.showToast('解密成功');
        } catch (e) {
          _addLog('❌ 解密失败: $e');
          SmartDialog.showToast('解密失败');
        } finally {
          setState(() {
            _isProcessing = false;
          });
        }
      }
    } catch (e) {
      _addLog('❌ 发生错误: $e');
      setState(() {
        _isProcessing = false;
      });
    }
  }

  Future<void> _decryptFolder() async {
    try {
      String? selectedDirectory = await FilePicker.platform.getDirectoryPath();

      if (selectedDirectory != null) {
        setState(() {
          _isProcessing = true;
        });
        _addLog('开始扫描文件夹: $selectedDirectory');

        final dir = Directory(selectedDirectory);
        if (!await dir.exists()) {
          _addLog('错误: 文件夹不存在');
          setState(() {
            _isProcessing = false;
          });
          return;
        }

        int successCount = 0;
        int failCount = 0;
        int skippedCount = 0;

        try {
          await for (final entity in dir.list()) {
            if (entity is File) {
              if (entity.path.endsWith('.enc')) {
                _addLog('正在解密: ${path.basename(entity.path)}...');
                try {
                  final encryptionPassword = await _storageService
                      .getEncryptionPassword();
                  if (encryptionPassword == null) {
                    throw Exception('Encryption password not found');
                  }

                  // Determine output path using shared logic
                  var outputPath = await FileRenamer.prepareDecryptedPath(
                    entity.path,
                    dir.path,
                  );

                  // Decrypt using streams
                  final fileStream = File(entity.path).openRead();
                  final decryptedStream = EncryptionHelper.decryptStream(
                    fileStream,
                    encryptionPassword,
                  );

                  // Write to file
                  final sink = File(outputPath).openWrite();
                  await sink.addStream(decryptedStream);
                  await sink.close();

                  _addLog('✅ 成功: ${path.basename(outputPath)}');
                  successCount++;
                } catch (e) {
                  _addLog('❌ 失败 (${path.basename(entity.path)}): $e');
                  failCount++;
                }
              } else {
                skippedCount++;
              }
            }
          }

          _addLog('--- 完成 ---');
          _addLog('成功: $successCount, 失败: $failCount, 跳过: $skippedCount');
          SmartDialog.showToast('批量解密完成');
        } catch (e) {
          _addLog('❌ 遍历文件夹错误: $e');
        } finally {
          setState(() {
            _isProcessing = false;
          });
        }
      }
    } catch (e) {
      _addLog('❌ 发生错误: $e');
      setState(() {
        _isProcessing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    String singleFileDesc = '';
    if (Platform.isAndroid) {
      singleFileDesc = '保存至 Download/\nWebDAV_X_Decrypted';
    } else if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      singleFileDesc = '保存至 Downloads/\nWebDAV_X_Decrypted';
    } else {
      singleFileDesc = '保存至 Documents/\nDecrypted';
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('本地解密工具'),
        flexibleSpace: AppTheme.glassAppBarFlexibleSpace,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded),
            tooltip: '清空日志',
            onPressed: () {
              setState(() {
                _logs.clear();
              });
            },
          ),
        ],
      ),
      body: AnimatedGradient(
        colors: [
          Colors.blue.shade50,
          Colors.purple.shade50,
          Colors.pink.shade50,
        ],
        child: Column(
          children: [
            SizedBox(
              height: kToolbarHeight + MediaQuery.of(context).padding.top,
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                children: [
                  Expanded(
                    child: _buildActionCard(
                      context,
                      title: '解密单个文件',
                      subtitle: singleFileDesc,
                      icon: Icons.insert_drive_file_rounded,
                      color: Colors.blue,
                      onTap: _isProcessing ? null : _decryptSingleFile,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildActionCard(
                      context,
                      title: '解密文件夹',
                      subtitle: '在原文件夹内解密',
                      icon: Icons.folder_open_rounded,
                      color: Colors.purple,
                      onTap: _isProcessing ? null : _decryptFolder,
                    ),
                  ),
                ],
              ),
            ),
            if (_isProcessing)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.0),
                child: LinearProgressIndicator(),
              ),
            const SizedBox(height: 16),
            Expanded(
              child: Container(
                margin: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.5),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '操作日志',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const Divider(),
                    Expanded(
                      child: _logs.isEmpty
                          ? Center(
                              child: Text(
                                '暂无日志',
                                style: TextStyle(color: Colors.grey.shade500),
                              ),
                            )
                          : ListView.builder(
                              controller: _logScrollController,
                              itemCount: _logs.length,
                              itemBuilder: (context, index) {
                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 2.0,
                                  ),
                                  child: Text(
                                    _logs[index],
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontFamily: 'monospace',
                                      color:
                                          _logs[index].startsWith('❌') ||
                                              _logs[index].startsWith('错误')
                                          ? Colors.red.shade700
                                          : (_logs[index].startsWith('✅')
                                                ? Colors.green.shade700
                                                : Colors.grey.shade800),
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
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required MaterialColor color,
    VoidCallback? onTap,
  }) {
    return Container(
      height: 180,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.2),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: color.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 40, color: color.shade400),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                    height: 1.2,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
