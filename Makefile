generate-app-icons:
	@echo "生成应用图标..."
	@echo "详情: https://pub.dev/packages/flutter_launcher_icons#2-run-the-package"
	dart run flutter_launcher_icons
	@echo "生成完成"

generate-i18n:
	@echo "生成国际化..."
	flutter gen-l10n
	
generate-name:
	@echo "生成应用名"
	dart run names_launcher:change
	
# ---------------------------------------------------------------------
build-apk:
	@echo "编译APK..."
	flutter build apk --release --no-tree-shake-icons
	mv build/app/outputs/flutter-apk/app-release.apk .release/android.apk
	@echo "编译完成"

build-all-apk:
	@echo "编译多平台Apk..."
	flutter build apk --split-per-abi --release --no-tree-shake-icons
	mv build/app/outputs/flutter-apk/app-arm64-v8a-release.apk .release/android-arm64-v8a.apk
	mv build/app/outputs/flutter-apk/app-armeabi-v7a-release.apk .release/android-armeabi-v7a.apk
	mv build/app/outputs/flutter-apk/app-x86_64-release.apk .release/android-x86_64.apk
	@echo "编译完成"

build-ios:
	@echo "编译未签名IPA..."
	flutter build ios --release --no-codesign
	@echo "编译完成"

build-windows-exe:
	@echo "编译EXE..."
	flutter build windows --release
	cd script && flutter pub get && dart index.dart && ./enigmavbconsole.exe pack.evb
