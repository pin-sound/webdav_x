import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:permission_handler/permission_handler.dart';

import '../services/storage_service.dart';
import '../services/webdav_service.dart';
import '../theme/app_theme.dart';
import '../utils/page_transitions.dart';
import '../widgets/animated_gradient.dart';
import 'file_browser_screen.dart';
import 'settings_screen.dart';
import 'upload_screen.dart';

enum AppMode { upload, view }

class HomeScreen extends StatefulWidget {
  final AppMode mode;
  const HomeScreen({super.key, this.mode = AppMode.upload});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _storageService = StorageService();
  final _pathController = TextEditingController();
  final _pathFocusNode = FocusNode();
  List<String> _paths = [];
  bool _isLoading = true;
  final _webdavService = WebDavService();

  @override
  void initState() {
    super.initState();
    _loadPaths();
    if (widget.mode == AppMode.view) _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    if (!Platform.isAndroid) return;

    final dontAskAgain = await _storageService
        .getDontAskNotificationPermission();
    if (dontAskAgain == true) return;

    final status = await Permission.notification.status;

    if (status.isDenied && mounted) {
      final result = await showDialog<String>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('需要通知权限'),
            content: const Text('为了在后台下载文件时显示进度通知，需要授予通知权限。'),
            actions: <Widget>[
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop('never'),
                    child: const Text('不再提醒'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop('later'),
                    child: const Text('稍后'),
                  ),
                ],
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop('grant'),
                child: const Text('授予权限'),
              ),
            ],
          );
        },
      );

      if (result == 'grant') {
        await openAppSettings();
      } else if (result == 'never') {
        await _storageService.setDontAskNotificationPermission(true);
      }
    } else if (status.isPermanentlyDenied && mounted) {
      final result = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('需要通知权限'),
            content: const Text('通知权限已被永久拒绝，请在系统设置中手动开启。'),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('取消'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('打开设置'),
              ),
            ],
          );
        },
      );

      if (result == true) {
        await openAppSettings();
      }
    }
  }

  Future<void> _loadPaths() async {
    final paths = await _storageService.getPaths();
    setState(() {
      _paths = paths;
      _isLoading = false;
    });
  }

  Future<void> _addPath() async {
    final path = _pathController.text.trim();
    if (path.isEmpty) {
      return;
    }

    if (_paths.contains(path)) {
      SmartDialog.showToast('路径已存在', displayTime: const Duration(seconds: 1));
      return;
    }

    SmartDialog.showLoading(msg: '正在验证路径...');

    try {
      final username = await _storageService.getUsername();
      final password = await _storageService.getPassword();

      if (username == null || password == null) {
        SmartDialog.dismiss();
        SmartDialog.showToast('请先配置 WebDAV 设置');
        return;
      }

      // Initialize and check path
      _webdavService.initialize(username, password, '');
      // Try to list or create the directory to validate it
      await _webdavService.ensureDirectory(path);

      await _storageService.addPath(path);
      _pathController.clear();
      await _loadPaths();

      SmartDialog.dismiss();
      SmartDialog.showToast('添加成功');
    } catch (e) {
      SmartDialog.dismiss();
      SmartDialog.showToast(
        '路径无效或无法访问: $e',
        displayTime: const Duration(seconds: 3),
      );
    }
  }

  Future<void> _removePath(String path) async {
    await _storageService.removePath(path);
    await _loadPaths();
  }

  Future<void> _navigateToPath(String path) async {
    _pathFocusNode.unfocus();
    if (_isMobile) {
      await Future.delayed(const Duration(milliseconds: 100));
    }

    final username = await _storageService.getUsername();
    final password = await _storageService.getPassword();

    if (username == null || password == null) {
      if (mounted) {
        SmartDialog.showToast(
          '请先配置 WebDAV 设置',
          displayTime: const Duration(seconds: 1),
        );
        _navigateToSettings();
      }
      return;
    }

    if (mounted) {
      if (widget.mode == AppMode.upload) {
        Navigator.push(
          context,
          PageTransitions.defaultTransition(UploadScreen(path: path)),
        );
      } else {
        Navigator.push(
          context,
          PageTransitions.defaultTransition(FileBrowserScreen(path: path)),
        );
      }
    }
  }

  Future<void> _navigateToSettings() async {
    await Navigator.push(
      context,
      PageTransitions.defaultTransition(const SettingsScreen()),
    );
  }

  bool get _isMobile {
    if (kIsWeb) return false;
    return Platform.isAndroid || Platform.isIOS;
  }

  Widget _buildPathInput() {
    return TextField(
      controller: _pathController,
      focusNode: _pathFocusNode,
      decoration: InputDecoration(
        labelText: 'WebDAV 路径',
        hintText: '输入文件夹名称',
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300, width: 1.0),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.blue.shade400, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
      onSubmitted: (_) => _addPath(),
    );
  }

  Widget _buildAddButton() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade400, Colors.purple.shade400],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _addPath,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            child: Row(
              mainAxisAlignment: _isMobile
                  ? MainAxisAlignment.center
                  : MainAxisAlignment.start,
              children: const [
                Icon(Icons.add, color: Colors.white),
                SizedBox(width: 8),
                Text(
                  '添加',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _pathController.dispose();
    _pathFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isUploadMode = widget.mode == AppMode.upload;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(isUploadMode ? '上传目录' : '查看目录'),
        flexibleSpace: AppTheme.glassAppBarFlexibleSpace,
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
              : CustomScrollView(
                  slivers: [
                    // Add Path Section - ONLY for Upload Mode
                    if (widget.mode == AppMode.upload)
                      SliverToBoxAdapter(
                        child: Container(
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
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.add_circle_outline,
                                    color: Colors.blue.shade600,
                                    size: 24,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '添加新路径',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey.shade800,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              _isMobile
                                  ? Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        _buildPathInput(),
                                        const SizedBox(height: 16),
                                        _buildAddButton(),
                                      ],
                                    )
                                  : Row(
                                      children: [
                                        Expanded(child: _buildPathInput()),
                                        const SizedBox(width: 12),
                                        _buildAddButton(),
                                      ],
                                    ),
                            ],
                          ),
                        ),
                      ),

                    if (widget.mode == AppMode.view)
                      const SliverToBoxAdapter(child: SizedBox(height: 12)),

                    // Path List Section
                    if (_paths.isEmpty)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(
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
                                '暂无路径',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey.shade800,
                                ),
                              ),
                              if (widget.mode == AppMode.upload) ...[
                                const SizedBox(height: 8),
                                Text(
                                  '请添加 WebDAV 路径',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      )
                    else
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate((
                            context,
                            index,
                          ) {
                            final path = _paths[index];
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
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () => _navigateToPath(path),
                                  borderRadius: BorderRadius.circular(16),
                                  hoverColor: Colors.blue.withValues(
                                    alpha: 0.04,
                                  ),
                                  splashColor: Colors.blue.withValues(
                                    alpha: 0.1,
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [
                                                Colors.blue.shade100,
                                                Colors.purple.shade100,
                                              ],
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          child: Icon(
                                            Icons.folder_rounded,
                                            color: Colors.blue.shade600,
                                            size: 28,
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                path,
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16,
                                                  color: Colors.grey.shade800,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                'https://dav.jianguoyun.com/dav/$path',
                                                style: TextStyle(
                                                  color: Colors.grey.shade500,
                                                  fontSize: 12,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                          ),
                                        ),
                                        if (widget.mode == AppMode.upload)
                                          IconButton(
                                            icon: Icon(
                                              Icons.delete_outline_rounded,
                                              color: Colors.grey.shade400,
                                            ),
                                            onPressed: () => _removePath(path),
                                            tooltip: '删除(不会影响到网盘)',
                                          )
                                        else
                                          Icon(
                                            Icons.arrow_forward_ios_rounded,
                                            size: 18,
                                            color: Colors.grey.shade400,
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }, childCount: _paths.length),
                        ),
                      ),
                  ],
                ),
        ),
      ),
    );
  }
}
