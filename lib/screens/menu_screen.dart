import 'dart:io' show Directory;
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:open_file_manager/open_file_manager.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webdav_x/utils/app_constants.dart';

import '../l10n/app_localizations.dart';
import '../main.dart';
import '../services/language_service.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import '../utils/page_transitions.dart';
import '../utils/url_helper.dart';
import '../widgets/animated_gradient.dart';
import '../widgets/qr_code_widget.dart';
import 'decryption_screen.dart';
import 'home_screen.dart';
import 'settings_screen.dart';

extension C on Color {
  Color withOpacity1(double opacity) {
    assert(opacity >= 0.0 && opacity <= 1.0);
    return withAlpha((255.0 * opacity).round());
  }
}

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  final _storageService = StorageService();
  bool _isConfigured = false;
  String? _username;
  String? _password;
  String? _encryptionPassword;

  @override
  void initState() {
    super.initState();
    _loadConfigStatus();
  }

  Future<void> _loadConfigStatus() async {
    final isConfigured = await _storageService.isConfigured();
    final username = await _storageService.getUsername();
    final password = await _storageService.getPassword();
    final encryptionPassword = await _storageService.getEncryptionPassword();

    if (mounted) {
      setState(() {
        _isConfigured = isConfigured;
        _username = username;
        _password = password;
        _encryptionPassword = encryptionPassword;
      });
    }
  }

  void _showQrCode() {
    if (_username != null && _password != null && _encryptionPassword != null) {
      SmartDialog.show(
        builder: (context) => QrCodeWidget(
          username: _username!,
          password: _password!,
          encryptionPassword: _encryptionPassword!,
        ),
        maskColor: Colors.black.withOpacity1(0.5),
        clickMaskDismiss: true,
        alignment: Alignment.center,
        usePenetrate: false,
      );
    }
  }

  void _showLanguageDialog() {
    final languageService = LanguageService();
    final supportedLocales = languageService.getSupportedLocales();
    final currentLocale = Localizations.localeOf(context);

    SmartDialog.show(
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.selectLanguage),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: supportedLocales.map((locale) {
            final isSelected =
                locale.languageCode == currentLocale.languageCode &&
                locale.countryCode == currentLocale.countryCode;

            return ListTile(
              title: Text(
                languageService.getLocaleName(locale),
                style: TextStyle(
                  color: isSelected ? Theme.of(context).primaryColor : null,
                  fontWeight: isSelected ? FontWeight.bold : null,
                ),
              ),
              trailing: isSelected
                  ? Icon(
                      Icons.check_rounded,
                      color: Theme.of(context).primaryColor,
                    )
                  : null,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              tileColor: isSelected
                  ? Theme.of(context).primaryColor.withValues(alpha: 0.1)
                  : null,
              onTap: () {
                MyApp.setLocale(context, locale);
                SmartDialog.dismiss();
              },
            );
          }).toList(),
        ),
      ),
      maskColor: Colors.black.withOpacity1(0.5),
      clickMaskDismiss: true,
      alignment: Alignment.center,
    );
  }

  Future<void> _openDownloadFolder() async {
    try {
      String? downloadPath;

      if (Platform.isAndroid) {
        // Try to use the public Download directory
        final directory = Directory('/storage/emulated/0/Download');
        if (await directory.exists()) {
          downloadPath = '${directory.path}/WebDAV_X';
        } else {
          // Fallback to app-specific external storage
          final extDir = await getExternalStorageDirectory();
          if (extDir != null) {
            downloadPath = '${extDir.path}/Download';
          }
        }

        openFileManager(
          androidConfig: AndroidConfig(
            folderType: AndroidFolderType.other,
            folderPath: downloadPath,
          ),
        );
      } else if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
        final downloadDir = await getDownloadsDirectory();
        if (downloadDir != null) {
          downloadPath = '${downloadDir.path}${Platform.pathSeparator}WebDAV_X';
          final directory = Directory(downloadPath);
          if (!await directory.exists()) {
            await directory.create(recursive: true);
          }
          final uri = Uri.directory(downloadPath);
          if (!await launchUrl(uri)) {
            throw '无法打开文件夹';
          }
        } else {
          throw '无法获取下载目录';
        }
      } else if (Platform.isIOS) {
        final docsDir = await getApplicationDocumentsDirectory();
        downloadPath = '${docsDir.path}/Downloads';
        final directory = Directory(downloadPath);
        if (!await directory.exists()) {
          await directory.create(recursive: true);
        }
        await openFileManager(iosConfig: IosConfig(folderPath: downloadPath));
      }
    } catch (e) {
      if (mounted) {
        SmartDialog.showToast('无法打开下载目录: $e');
      }
    }
  }

  Future<void> _clearAllData() async {
    SmartDialog.show(
      builder: (context) {
        return AlertDialog(
          title: const Text('清除所有数据'),
          content: const Text('这将清除所有 WebDAV 配置、保存的路径和凭据。\n此操作无法撤销。'),
          actions: [
            TextButton(
              onPressed: () => SmartDialog.dismiss(),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () async {
                SmartDialog.dismiss();
                await _storageService.clearAll();
                if (mounted) {
                  SmartDialog.showToast(
                    '所有数据已清除',
                    displayTime: const Duration(seconds: 2),
                  );
                  // Reload config status
                  _loadConfigStatus();
                }
              },
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red.shade400,
              ),
              child: const Text('确认清除'),
            ),
          ],
        );
      },
      maskColor: Colors.black.withOpacity1(0.5),
      clickMaskDismiss: true,
      alignment: Alignment.center,
    );
  }

  bool get _isMobile {
    if (kIsWeb) return false;
    return Platform.isAndroid || Platform.isIOS;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        flexibleSpace: AppTheme.glassAppBarFlexibleSpace,
        actions: [
          // 1. Decryption Tool (Prominent)

          // 2. Settings
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () async {
              await Navigator.push(
                context,
                PageTransitions.defaultTransition(const SettingsScreen()),
              );
              // 重新加载状态 (无论是否保存，都刷新一下以防万一)
              if (mounted) {
                _loadConfigStatus();
              }
            },
            tooltip:
                AppLocalizations.of(context)?.settings ?? AppConstants.noI18n,
          ),

          // 3. More Actions Menu
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded),
            tooltip: '更多',
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            onSelected: (value) {
              switch (value) {
                case 'qr':
                  _showQrCode();
                  break;
                case 'folder':
                  _openDownloadFolder();
                  break;
                case 'language':
                  _showLanguageDialog();
                  break;
                case 'clear':
                  _clearAllData();
                  break;
                case 'decrypt':
                  Navigator.push(
                    context,
                    PageTransitions.defaultTransition(const DecryptionScreen()),
                  );
                  break;
                case 'about':
                  openUrl('https://github.com/KineticSketch');
                  break;
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              if (_isConfigured)
                PopupMenuItem<String>(
                  value: 'qr',
                  child: ListTile(
                    leading: const Icon(Icons.qr_code_2_rounded),
                    title: Text(
                      AppLocalizations.of(context)?.showQrCode ??
                          AppConstants.noI18n,
                    ),
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                  ),
                ),
              if (_isConfigured)
                PopupMenuItem<String>(
                  value: 'folder',
                  child: ListTile(
                    leading: const Icon(Icons.folder_open_rounded),
                    title: Text(
                      AppLocalizations.of(context)?.openDownloadFolder ??
                          AppConstants.noI18n,
                    ),
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                  ),
                ),
              PopupMenuItem<String>(
                value: 'language',
                child: ListTile(
                  leading: const Icon(Icons.language_rounded),
                  title: Text(
                    AppLocalizations.of(context)?.languageSettings ??
                        AppConstants.noI18n,
                  ),
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                ),
              ),
              if (_isConfigured)
                PopupMenuItem<String>(
                  value: 'decrypt',
                  child: ListTile(
                    leading: const Icon(Icons.lock_open_rounded),
                    title: const Text('本地解密工具'),
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                  ),
                ),
              const PopupMenuDivider(),
              PopupMenuItem<String>(
                value: 'about',
                child: ListTile(
                  leading: const Icon(Icons.info_outline_rounded),
                  title: const Text('关于'),
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  onTap: () {
                    openUrl('https://github.com/KineticSketch');
                  },
                ),
              ),
              if (_isConfigured) ...[
                const PopupMenuDivider(),
                PopupMenuItem<String>(
                  value: 'clear',
                  child: ListTile(
                    leading: Icon(
                      Icons.delete_sweep_rounded,
                      color: Colors.red.shade400,
                    ),
                    title: Text(
                      '清除所有配置数据',
                      style: TextStyle(color: Colors.red.shade400),
                    ),
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
      body: AnimatedGradient(
        colors: [
          Colors.blue.shade50,
          Colors.purple.shade50,
          Colors.pink.shade50,
        ],
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            _isMobile ? 16.0 : 24.0,
            kToolbarHeight + MediaQuery.of(context).padding.top + 16,
            _isMobile ? 16.0 : 24.0,
            _isMobile ? 16.0 : 24.0,
          ),
          children: [
            _buildWelcomeHeader(),
            const SizedBox(height: 32),
            _buildMenuItem(
              context,
              icon: Icons.cloud_upload_rounded,
              title:
                  AppLocalizations.of(context)?.uploadMode ??
                  AppConstants.noI18n,
              subtitle:
                  AppLocalizations.of(context)?.uploadModeSubtitle ??
                  AppConstants.noI18n,
              gradientColors: [Colors.blue.shade400, Colors.cyan.shade300],
              onTap: () => _handleNavigation(context, AppMode.upload),
            ),
            const SizedBox(height: 20),
            _buildMenuItem(
              context,
              icon: Icons.folder_open_rounded,
              title:
                  AppLocalizations.of(context)?.viewMode ?? AppConstants.noI18n,
              subtitle:
                  AppLocalizations.of(context)?.viewModeSubtitle ??
                  AppConstants.noI18n,
              gradientColors: [Colors.orange.shade400, Colors.pink.shade300],
              onTap: () => _handleNavigation(context, AppMode.view),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeHeader() {
    return Container(
      padding: EdgeInsets.symmetric(
        vertical: _isMobile ? 10 : 20,
        horizontal: _isMobile ? 4 : 16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue.shade400, Colors.purple.shade400],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.cloud_sync_rounded,
                  size: _isMobile ? 28 : 32,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context)?.welcome ??
                          AppConstants.noI18n,
                      style: TextStyle(
                        fontSize: _isMobile ? 24 : 28,
                        fontWeight: FontWeight.bold,
                        foreground: Paint()
                          ..shader = LinearGradient(
                            colors: [
                              Colors.blue.shade700,
                              Colors.purple.shade600,
                            ],
                          ).createShader(const Rect.fromLTWH(0, 0, 200, 70)),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      AppLocalizations.of(context)?.appSubtitle ??
                          AppConstants.noI18n,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required List<Color> gradientColors,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: gradientColors[0].withValues(alpha: 0.4),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          splashColor: Colors.white.withValues(alpha: 0.3),
          highlightColor: Colors.white.withValues(alpha: 0.1),
          child: Container(
            padding: EdgeInsets.all(_isMobile ? 16.0 : 24.0),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(_isMobile ? 12 : 16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.3),
                      width: 1.5,
                    ),
                  ),
                  child: Icon(
                    icon,
                    size: _isMobile ? 32 : 40,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: _isMobile ? 18 : 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 18,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleNavigation(BuildContext context, AppMode mode) async {
    final storageService = StorageService();

    try {
      final isConfigured = await storageService.isConfigured();

      if (!isConfigured) {
        SmartDialog.showToast(
          '请先配置 WebDAV 设置',
          displayTime: const Duration(seconds: 1),
        );
        if (context.mounted) {
          Navigator.push(
            context,
            PageTransitions.defaultTransition(const SettingsScreen()),
          );
        }
        return;
      }

      if (context.mounted) {
        Navigator.push(
          context,
          PageTransitions.defaultTransition(HomeScreen(mode: mode)),
        );
      }
    } catch (e) {
      SmartDialog.showToast(
        '发生错误: $e',
        displayTime: const Duration(seconds: 1),
      );
    }
  }
}
