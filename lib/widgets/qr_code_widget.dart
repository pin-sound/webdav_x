import 'dart:async';

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../theme/app_theme.dart';
import '../utils/app_constants.dart';
import '../utils/encryption_helper.dart';

class QrCodeWidget extends StatefulWidget {
  final String username;
  final String password;
  final String encryptionPassword;

  const QrCodeWidget({
    super.key,
    required this.username,
    required this.password,
    required this.encryptionPassword,
  });

  @override
  State<QrCodeWidget> createState() => _QrCodeWidgetState();
}

class _QrCodeWidgetState extends State<QrCodeWidget> {
  late String _encryptedData;
  bool _isExpired = false;
  Timer? _timer;
  int _remainingSeconds = AppConstants.qrCodeExpirationSeconds;

  @override
  void initState() {
    super.initState();
    _generateQrCode();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _generateQrCode() {
    setState(() {
      _encryptedData = EncryptionHelper.encryptConfig(
        widget.username,
        widget.password,
        widget.encryptionPassword,
      );
      _isExpired = false;
      _remainingSeconds = AppConstants.qrCodeExpirationSeconds;
    });
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          if (_remainingSeconds > 0) {
            _remainingSeconds--;
          } else {
            _isExpired = true;
            timer.cancel();
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          QrImageView(
            data: _encryptedData,
            version: QrVersions.auto,
            size: 250.0,
            backgroundColor: Colors.white,
            // 使用高容错率，允许中间遮挡
            errorCorrectionLevel: QrErrorCorrectLevel.H,
            eyeStyle: QrEyeStyle(
              eyeShape: QrEyeShape.square,
              color: _isExpired ? AppTheme.textLight : AppTheme.primaryBlue,
            ),
            dataModuleStyle: QrDataModuleStyle(
              dataModuleShape: QrDataModuleShape.square,
              color: _isExpired ? AppTheme.textLight : AppTheme.primaryBlue,
            ),
          ),

          // 中间Logo和倒计时
          if (!_isExpired)
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Logo 背景
                  Opacity(
                    opacity: 0.3,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.asset(
                        'assets/icon/app_icon.png',
                        width: 40,
                        height: 40,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(
                            Icons.cloud_sync_rounded,
                            size: 40,
                            color: AppTheme.primaryBlue.withValues(alpha: 0.5),
                          );
                        },
                      ),
                    ),
                  ),
                  // 倒计时文字
                  Text(
                    '$_remainingSeconds',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryBlue,
                    ),
                  ),
                ],
              ),
            ),

          if (_isExpired)
            Positioned.fill(
              child: Container(
                color: Colors.white.withValues(alpha: 0.9),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.refresh,
                        size: 48,
                        color: AppTheme.primaryBlue,
                      ),
                      onPressed: _generateQrCode,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '二维码已失效\n点击刷新',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppTheme.primaryBlue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
