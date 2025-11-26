import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../theme/app_theme.dart';
import '../utils/app_constants.dart';
import '../utils/encryption_helper.dart';

class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen>
    with SingleTickerProviderStateMixin {
  final MobileScannerController _controller = MobileScannerController();
  late AnimationController _animationController;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_isProcessing) return;

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final String? code = barcodes.first.rawValue;
    if (code == null) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      // 尝试解密数据
      final config = EncryptionHelper.decryptConfig(code);

      if (config != null &&
          config.containsKey('username') &&
          config.containsKey('password') &&
          config.containsKey('encryptionPassword')) {
        // 验证时间戳
        if (config.containsKey('timestamp')) {
          final timestamp = config['timestamp'] as int;
          final now = DateTime.now().millisecondsSinceEpoch;
          // 1分钟失效
          if (now - timestamp > AppConstants.qrCodeExpirationSeconds * 1000) {
            _showError('二维码已失效，请刷新后重试');
            // 延迟重置状态，避免重复弹窗
            Future.delayed(const Duration(seconds: 2), () {
              if (mounted) {
                setState(() {
                  _isProcessing = false;
                });
              }
            });
            return;
          }
        }

        // 停止扫描
        _controller.stop();

        // 返回配置数据
        if (mounted) {
          Navigator.pop(context, {
            'username': config['username'],
            'password': config['password'],
            'encryptionPassword': config['encryptionPassword'],
          });
        }
      } else {
        _showError('二维码格式不正确或已损坏');
        // 延迟重置状态，避免重复弹窗
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            setState(() {
              _isProcessing = false;
            });
          }
        });
      }
    } catch (e) {
      _showError('无法解析二维码数据');
      // 延迟重置状态，避免重复弹窗
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
            _isProcessing = false;
          });
        }
      });
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('扫描配置二维码'),
        flexibleSpace: AppTheme.glassAppBarFlexibleSpace,
      ),
      body: Stack(
        children: [
          // Scanner
          MobileScanner(controller: _controller, onDetect: _onDetect),

          // Overlay with cutout
          CustomPaint(
            painter: ScannerOverlayPainter(scanAnimation: _animationController),
            child: Container(),
          ),

          // Instructions
          Positioned(
            bottom: 80,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 32),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                ),
                child: const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.qr_code_scanner_rounded,
                      color: Colors.white,
                      size: 32,
                    ),
                    SizedBox(height: 12),
                    Text(
                      '将二维码放入框内',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 4),
                    Text(
                      '自动识别并导入配置',
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Torch button
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: Center(
              child: IconButton(
                onPressed: () => _controller.toggleTorch(),
                icon: ValueListenableBuilder(
                  valueListenable: _controller,
                  builder: (context, state, child) {
                    final torchState = state.torchState;
                    return Icon(
                      torchState == TorchState.on
                          ? Icons.flash_on
                          : Icons.flash_off,
                      color: Colors.white,
                      size: 32,
                    );
                  },
                ),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.black.withValues(alpha: 0.5),
                  padding: const EdgeInsets.all(16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ScannerOverlayPainter extends CustomPainter {
  final Animation<double> scanAnimation;

  ScannerOverlayPainter({required this.scanAnimation})
    : super(repaint: scanAnimation);

  @override
  void paint(Canvas canvas, Size size) {
    final double scanAreaSize = size.width * 0.7;
    final double left = (size.width - scanAreaSize) / 2;
    final double top = (size.height - scanAreaSize) / 2;
    final Rect scanArea = Rect.fromLTWH(left, top, scanAreaSize, scanAreaSize);

    // Draw dark overlay
    final Paint overlayPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.6);

    canvas.drawPath(
      Path()
        ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
        ..addRRect(RRect.fromRectAndRadius(scanArea, const Radius.circular(20)))
        ..fillType = PathFillType.evenOdd,
      overlayPaint,
    );

    // Draw border
    final Paint borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    final RRect borderRect = RRect.fromRectAndRadius(
      scanArea,
      const Radius.circular(20),
    );
    canvas.drawRRect(borderRect, borderPaint);

    // Draw corner accents
    final Paint accentPaint = Paint()
      ..color = Colors.blue.shade400
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;

    const double cornerLength = 30;
    const double radius = 20;

    final Path path = Path();

    // Top-left
    path.moveTo(left, top + cornerLength);
    path.lineTo(left, top + radius);
    path.arcToPoint(
      Offset(left + radius, top),
      radius: const Radius.circular(radius),
    );
    path.lineTo(left + cornerLength, top);

    // Top-right
    path.moveTo(left + scanAreaSize - cornerLength, top);
    path.lineTo(left + scanAreaSize - radius, top);
    path.arcToPoint(
      Offset(left + scanAreaSize, top + radius),
      radius: const Radius.circular(radius),
    );
    path.lineTo(left + scanAreaSize, top + cornerLength);

    // Bottom-right
    path.moveTo(left + scanAreaSize, top + scanAreaSize - cornerLength);
    path.lineTo(left + scanAreaSize, top + scanAreaSize - radius);
    path.arcToPoint(
      Offset(left + scanAreaSize - radius, top + scanAreaSize),
      radius: const Radius.circular(radius),
    );
    path.lineTo(left + scanAreaSize - cornerLength, top + scanAreaSize);

    // Bottom-left
    path.moveTo(left + cornerLength, top + scanAreaSize);
    path.lineTo(left + radius, top + scanAreaSize);
    path.arcToPoint(
      Offset(left, top + scanAreaSize - radius),
      radius: const Radius.circular(radius),
    );
    path.lineTo(left, top + scanAreaSize - cornerLength);

    canvas.drawPath(path, accentPaint);

    // Draw scanning line
    final double scanLineY = top + (scanAreaSize * scanAnimation.value);

    // Glow effect
    final Paint glowPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.blue.shade400.withValues(alpha: 0),
          Colors.blue.shade400.withValues(alpha: 0.4),
        ],
      ).createShader(Rect.fromLTWH(left, scanLineY - 60, scanAreaSize, 60));

    canvas.drawRect(
      Rect.fromLTWH(left, scanLineY - 60, scanAreaSize, 60),
      glowPaint,
    );

    // Line
    final Paint linePaint = Paint()
      ..color = Colors.blue.shade400
      ..strokeWidth = 2
      ..shader = LinearGradient(
        colors: [
          Colors.blue.shade400.withValues(alpha: 0),
          Colors.blue.shade400,
          Colors.blue.shade400.withValues(alpha: 0),
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromLTWH(left, scanLineY, scanAreaSize, 2));

    canvas.drawRect(Rect.fromLTWH(left, scanLineY, scanAreaSize, 2), linePaint);
  }

  @override
  bool shouldRepaint(covariant ScannerOverlayPainter oldDelegate) {
    return oldDelegate.scanAnimation != scanAnimation;
  }
}
