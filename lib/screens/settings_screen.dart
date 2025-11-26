import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';

import '../services/storage_service.dart';
import '../services/webdav_service.dart';
import '../theme/app_theme.dart';
import '../widgets/animated_gradient.dart';
import 'qr_scanner_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _encryptionPasswordController = TextEditingController();
  final _storageService = StorageService();
  final _webdavService = WebDavService();

  bool _obscurePassword = true;
  bool _obscureEncryptionPassword = true;
  bool _isLoading = true;
  String? _validationMessage;
  bool? _isValid;

  @override
  void initState() {
    super.initState();
    _loadCredentials();
  }

  Future<void> _loadCredentials() async {
    final username = await _storageService.getUsername();
    final password = await _storageService.getPassword();
    final encryptionPassword = await _storageService.getEncryptionPassword();

    if (mounted) {
      setState(() {
        if (username != null) {
          _usernameController.text = username;
        }
        if (password != null) {
          _passwordController.text = password;
        }
        if (encryptionPassword != null) {
          _encryptionPasswordController.text = encryptionPassword;
        }
        _isLoading = false;
      });
    }
  }

  Future<bool> _validateConnection() async {
    if (_usernameController.text.isEmpty || _passwordController.text.isEmpty) {
      setState(() {
        _validationMessage = '请输入Account和Password';
        _isValid = false;
      });
      return false;
    }

    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(_usernameController.text)) {
      setState(() {
        _validationMessage = 'Account必须是有效的邮箱格式';
        _isValid = false;
      });
      return false;
    }

    setState(() {
      _validationMessage = null;
      _isValid = null;
    });

    try {
      _webdavService.initialize(
        _usernameController.text,
        _passwordController.text,
        '', // Validate against root
      );

      final isValid = await _webdavService.validateConnection();

      setState(() {
        _isValid = isValid;
        _validationMessage = isValid ? '连接成功！' : '连接失败，请检查Account和Password';
      });
      return isValid;
    } catch (e) {
      setState(() {
        _isValid = false;
        _validationMessage = '验证失败: $e';
      });
      return false;
    }
  }

  Future<void> _saveCredentials() async {
    final isValid = await _validateConnection();
    if (!isValid) return;

    final encryptionPassword = _encryptionPasswordController.text;
    if (encryptionPassword.length < 6) {
      setState(() {
        _validationMessage = '加密密码长度不能少于6位';
        _isValid = false;
      });
      return;
    }
    if (!RegExp(
      r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\W).+$',
    ).hasMatch(encryptionPassword)) {
      setState(() {
        _validationMessage = '加密密码必须包含大小写字母和特殊符号';
        _isValid = false;
      });
      return;
    }

    final oldUsername = await _storageService.getUsername();
    final newUsername = _usernameController.text;

    if (oldUsername != null && oldUsername != newUsername) {
      await _storageService.clearAll();
    }

    await _storageService.saveCredentials(
      _usernameController.text,
      _passwordController.text,
      _encryptionPasswordController.text,
    );
    await _storageService.setConfigured(true);

    if (mounted) {
      SmartDialog.showToast('设置已保存', displayTime: const Duration(seconds: 1));
    }
  }

  Future<void> _scanQrCode() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const QrScannerScreen()),
    );

    if (result != null && result is Map<String, dynamic>) {
      setState(() {
        _usernameController.text = result['username'] ?? '';
        _passwordController.text = result['password'] ?? '';
        _encryptionPasswordController.text = result['encryptionPassword'] ?? '';
      });

      SmartDialog.showToast(
        '配置已导入，请验证并保存',
        displayTime: const Duration(seconds: 2),
      );
    }
  }

  bool get _isMobile {
    if (kIsWeb) return false;
    return Platform.isAndroid || Platform.isIOS;
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _encryptionPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('配置'),
        flexibleSpace: AppTheme.glassAppBarFlexibleSpace,
        actions: [
          if (_isMobile)
            IconButton(
              icon: const Icon(Icons.qr_code_scanner_rounded),
              onPressed: _scanQrCode,
              tooltip: '扫描二维码',
            ),
        ],
      ),
      body: SizedBox.expand(
        child: Stack(
          children: [
            Positioned.fill(
              child: AnimatedGradient(
                colors: [
                  Colors.purple.shade50,
                  Colors.pink.shade50,
                  Colors.blue.shade50,
                ],
              ),
            ),
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(
                      _isMobile ? 16.0 : 24.0,
                      kToolbarHeight + MediaQuery.of(context).padding.top + 24,
                      _isMobile ? 16.0 : 24.0,
                      _isMobile ? 16.0 : 24.0,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.95),
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.purple.withValues(alpha: 0.15),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          padding: EdgeInsets.all(_isMobile ? 20.0 : 28.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                '配置',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  foreground: Paint()
                                    ..shader =
                                        LinearGradient(
                                          colors: [
                                            Colors.deepPurple.shade600,
                                            Colors.purple.shade400,
                                          ],
                                        ).createShader(
                                          const Rect.fromLTWH(0, 0, 200, 70),
                                        ),
                                ),
                              ),
                              const SizedBox(height: 24),

                              // Username Field
                              TextField(
                                controller: _usernameController,
                                decoration: InputDecoration(
                                  labelText: 'Account',
                                  hintText: '输入您的Account',
                                  filled: true,
                                  fillColor: Colors.grey.shade50,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide.none,
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(
                                      color: Colors.grey.shade200,
                                      width: 2,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(
                                      color: Colors.deepPurple.shade300,
                                      width: 2,
                                    ),
                                  ),
                                  prefixIcon: Icon(
                                    Icons.email_outlined,
                                    color: Colors.deepPurple.shade400,
                                  ),
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: _isMobile ? 14 : 18,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),

                              // Password Field
                              TextField(
                                controller: _passwordController,
                                obscureText: _obscurePassword,
                                decoration: InputDecoration(
                                  labelText: 'Password',
                                  hintText: '输入您的Password',
                                  filled: true,
                                  fillColor: Colors.grey.shade50,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide.none,
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(
                                      color: Colors.grey.shade200,
                                      width: 2,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(
                                      color: Colors.deepPurple.shade300,
                                      width: 2,
                                    ),
                                  ),
                                  prefixIcon: Icon(
                                    Icons.lock_outline,
                                    color: Colors.deepPurple.shade400,
                                  ),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscurePassword
                                          ? Icons.visibility_outlined
                                          : Icons.visibility_off_outlined,
                                      color: Colors.grey.shade600,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _obscurePassword = !_obscurePassword;
                                      });
                                    },
                                  ),
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: _isMobile ? 14 : 18,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),

                              // Encryption Password Field
                              TextField(
                                controller: _encryptionPasswordController,
                                obscureText: _obscureEncryptionPassword,
                                decoration: InputDecoration(
                                  labelText: '用于加密文件密码，一定一定要记住，否则无法解开上传的加密文件',
                                  labelStyle: TextStyle(color: Colors.red),
                                  hintText: '用于加密文件的密码 (6+位, 大小写+符号)',
                                  filled: true,
                                  fillColor: Colors.grey.shade50,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide.none,
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(
                                      color: Colors.grey.shade200,
                                      width: 2,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(
                                      color: Colors.deepPurple.shade300,
                                      width: 2,
                                    ),
                                  ),
                                  prefixIcon: Icon(
                                    Icons.vpn_key_outlined,
                                    color: Colors.deepPurple.shade400,
                                  ),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscureEncryptionPassword
                                          ? Icons.visibility_outlined
                                          : Icons.visibility_off_outlined,
                                      color: Colors.grey.shade600,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _obscureEncryptionPassword =
                                            !_obscureEncryptionPassword;
                                      });
                                    },
                                  ),
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: _isMobile ? 14 : 18,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),

                              // Validation Message
                              if (_validationMessage != null)
                                Container(
                                  margin: const EdgeInsets.only(bottom: 20),
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: _isValid == true
                                          ? [
                                              Colors.green.shade50,
                                              Colors.green.shade100,
                                            ]
                                          : [
                                              Colors.red.shade50,
                                              Colors.red.shade100,
                                            ],
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: _isValid == true
                                          ? Colors.green.shade300
                                          : Colors.red.shade300,
                                      width: 2,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: _isValid == true
                                              ? Colors.green
                                              : Colors.red,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          _isValid == true
                                              ? Icons.check_rounded
                                              : Icons.close_rounded,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          _validationMessage!,
                                          style: TextStyle(
                                            color: _isValid == true
                                                ? Colors.green.shade800
                                                : Colors.red.shade800,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 15,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                              // Save Button
                              Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.deepPurple.shade500,
                                      Colors.purple.shade500,
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.deepPurple.withValues(
                                        alpha: 0.4,
                                      ),
                                      blurRadius: 16,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: ElevatedButton.icon(
                                  onPressed: _saveCredentials,
                                  icon: Icon(
                                    Icons.save_rounded,
                                    size: _isMobile ? 22 : 24,
                                  ),
                                  label: Text(
                                    '保存并应用',
                                    style: TextStyle(
                                      fontSize: _isMobile ? 16 : 18,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    foregroundColor: Colors.white,
                                    shadowColor: Colors.transparent,
                                    padding: EdgeInsets.symmetric(
                                      vertical: _isMobile ? 16 : 20,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
