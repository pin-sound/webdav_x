import 'dart:io';

import 'package:chinese_font_library/chinese_font_library.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:screen_retriever/screen_retriever.dart';
import 'package:window_manager/window_manager.dart';

import 'l10n/app_localizations.dart';
import 'screens/menu_screen.dart';
import 'services/background_service.dart';
import 'services/language_service.dart';
import 'theme/app_theme.dart';
import 'utils/app_constants.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (Platform.isAndroid) {
    await initializeService();
  }

  // 仅在移动平台强制竖屏
  if (Platform.isAndroid || Platform.isIOS) {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

  // 仅在 Windows、macOS 或 Linux 桌面平台上初始化窗口管理器
  if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
    await windowManager.ensureInitialized();

    // 获取主屏幕尺寸
    Display primaryDisplay = await screenRetriever.getPrimaryDisplay();
    double width = primaryDisplay.size.width * 0.7;
    double height = primaryDisplay.size.height * 0.7;

    WindowOptions windowOptions = WindowOptions(
      size: Size(width, height),
      minimumSize: const Size(440, 700),
      center: true,
      title: AppConstants.appName,
    );

    await windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();

  // Static method to update locale from anywhere in the app
  static void setLocale(BuildContext context, Locale locale) {
    final state = context.findAncestorStateOfType<_MyAppState>();
    state?.setLocale(locale);
  }
}

class _MyAppState extends State<MyApp> {
  final _languageService = LanguageService();
  Locale? _locale;

  @override
  void initState() {
    super.initState();
    _loadSavedLocale();
  }

  Future<void> _loadSavedLocale() async {
    final savedLocale = await _languageService.getSavedLocale();
    if (savedLocale != null && mounted) {
      setState(() {
        _locale = savedLocale;
      });
    }
  }

  void setLocale(Locale locale) {
    setState(() {
      _locale = locale;
    });
    _languageService.saveLocale(locale);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      theme: AppTheme.lightTheme.useSystemChineseFont(Brightness.light),
      locale: _locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('zh'), // Simplified Chinese
        Locale('zh', 'TW'), // Traditional Chinese
        Locale('en'), // English
      ],
      home: const MenuScreen(),
      debugShowCheckedModeBanner: false,
      builder: FlutterSmartDialog.init(),
    );
  }
}
