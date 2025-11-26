import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('zh'),
    Locale('zh', 'TW'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'webdav_x'**
  String get appTitle;

  /// No description provided for @welcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome'**
  String get welcome;

  /// No description provided for @appSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Nutstore WebDAV Sync Tool'**
  String get appSubtitle;

  /// No description provided for @uploadMode.
  ///
  /// In en, this message translates to:
  /// **'Upload Files'**
  String get uploadMode;

  /// No description provided for @uploadModeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Select files and upload to WebDAV folder'**
  String get uploadModeSubtitle;

  /// No description provided for @viewMode.
  ///
  /// In en, this message translates to:
  /// **'View Files'**
  String get viewMode;

  /// No description provided for @viewModeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Browse and manage files on WebDAV'**
  String get viewModeSubtitle;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @showQrCode.
  ///
  /// In en, this message translates to:
  /// **'Show Configuration QR Code'**
  String get showQrCode;

  /// No description provided for @openDownloadFolder.
  ///
  /// In en, this message translates to:
  /// **'Open Download Folder'**
  String get openDownloadFolder;

  /// No description provided for @pleaseConfigureFirst.
  ///
  /// In en, this message translates to:
  /// **'Please configure WebDAV settings first'**
  String get pleaseConfigureFirst;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String error(String error);

  /// No description provided for @languageSettings.
  ///
  /// In en, this message translates to:
  /// **'Language Settings'**
  String get languageSettings;

  /// No description provided for @selectLanguage.
  ///
  /// In en, this message translates to:
  /// **'Select Language'**
  String get selectLanguage;

  /// No description provided for @simplifiedChinese.
  ///
  /// In en, this message translates to:
  /// **'简体中文'**
  String get simplifiedChinese;

  /// No description provided for @traditionalChinese.
  ///
  /// In en, this message translates to:
  /// **'繁體中文'**
  String get traditionalChinese;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @downloadFolderPath.
  ///
  /// In en, this message translates to:
  /// **'Files saved at: /storage/emulated/0/Download/WebDAV_X\\nPlease use file manager to view'**
  String get downloadFolderPath;

  /// No description provided for @cannotOpenFolder.
  ///
  /// In en, this message translates to:
  /// **'Cannot open folder'**
  String get cannotOpenFolder;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @webdavConfiguration.
  ///
  /// In en, this message translates to:
  /// **'WebDAV Configuration'**
  String get webdavConfiguration;

  /// No description provided for @account.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get account;

  /// No description provided for @accountHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your Account'**
  String get accountHint;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @passwordHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your Password'**
  String get passwordHint;

  /// No description provided for @pleaseEnterAccountPassword.
  ///
  /// In en, this message translates to:
  /// **'Please enter Account and Password'**
  String get pleaseEnterAccountPassword;

  /// No description provided for @accountMustBeEmail.
  ///
  /// In en, this message translates to:
  /// **'Account must be a valid email format'**
  String get accountMustBeEmail;

  /// No description provided for @connectionSuccess.
  ///
  /// In en, this message translates to:
  /// **'Connection successful!'**
  String get connectionSuccess;

  /// No description provided for @connectionFailed.
  ///
  /// In en, this message translates to:
  /// **'Connection failed, please check Account and Password'**
  String get connectionFailed;

  /// No description provided for @validationFailed.
  ///
  /// In en, this message translates to:
  /// **'Validation failed: {error}'**
  String validationFailed(String error);

  /// No description provided for @settingsSaved.
  ///
  /// In en, this message translates to:
  /// **'Settings saved'**
  String get settingsSaved;

  /// No description provided for @configImported.
  ///
  /// In en, this message translates to:
  /// **'Configuration imported, please validate and save'**
  String get configImported;

  /// No description provided for @scanQrCode.
  ///
  /// In en, this message translates to:
  /// **'Scan QR Code'**
  String get scanQrCode;

  /// No description provided for @validating.
  ///
  /// In en, this message translates to:
  /// **'Validating...'**
  String get validating;

  /// No description provided for @validateConnection.
  ///
  /// In en, this message translates to:
  /// **'Validate Connection'**
  String get validateConnection;

  /// No description provided for @saveConfiguration.
  ///
  /// In en, this message translates to:
  /// **'Save Configuration'**
  String get saveConfiguration;

  /// No description provided for @uploadDirectory.
  ///
  /// In en, this message translates to:
  /// **'Upload Directory'**
  String get uploadDirectory;

  /// No description provided for @viewDirectory.
  ///
  /// In en, this message translates to:
  /// **'View Directory'**
  String get viewDirectory;

  /// No description provided for @pathExists.
  ///
  /// In en, this message translates to:
  /// **'Path already exists'**
  String get pathExists;

  /// No description provided for @cannotAccessFolder.
  ///
  /// In en, this message translates to:
  /// **'Cannot access or create folder: {error}'**
  String cannotAccessFolder(String error);

  /// No description provided for @webdavPath.
  ///
  /// In en, this message translates to:
  /// **'WebDAV Path'**
  String get webdavPath;

  /// No description provided for @folderNameHint.
  ///
  /// In en, this message translates to:
  /// **'Enter folder name'**
  String get folderNameHint;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @addNewPath.
  ///
  /// In en, this message translates to:
  /// **'Add New Path'**
  String get addNewPath;

  /// No description provided for @noPathsYet.
  ///
  /// In en, this message translates to:
  /// **'No paths yet'**
  String get noPathsYet;

  /// No description provided for @pleaseAddPath.
  ///
  /// In en, this message translates to:
  /// **'Please add WebDAV path above'**
  String get pleaseAddPath;

  /// No description provided for @deleteTooltip.
  ///
  /// In en, this message translates to:
  /// **'Delete (won\'t affect webdav cloud storage)'**
  String get deleteTooltip;

  /// No description provided for @uploadTo.
  ///
  /// In en, this message translates to:
  /// **'Upload to: {path}'**
  String uploadTo(String path);

  /// No description provided for @selectFiles.
  ///
  /// In en, this message translates to:
  /// **'Select Files'**
  String get selectFiles;

  /// No description provided for @uploadAll.
  ///
  /// In en, this message translates to:
  /// **'Upload All ({count})'**
  String uploadAll(int count);

  /// No description provided for @clearList.
  ///
  /// In en, this message translates to:
  /// **'Clear List'**
  String get clearList;

  /// No description provided for @readyToUpload.
  ///
  /// In en, this message translates to:
  /// **'Ready to Upload'**
  String get readyToUpload;

  /// No description provided for @clickToSelectFiles.
  ///
  /// In en, this message translates to:
  /// **'Click the button above to select files'**
  String get clickToSelectFiles;

  /// No description provided for @size.
  ///
  /// In en, this message translates to:
  /// **'Size: {size}'**
  String size(String size);

  /// No description provided for @errorMessage.
  ///
  /// In en, this message translates to:
  /// **'Error: {message}'**
  String errorMessage(String message);

  /// No description provided for @editFilename.
  ///
  /// In en, this message translates to:
  /// **'Edit Filename'**
  String get editFilename;

  /// No description provided for @upload.
  ///
  /// In en, this message translates to:
  /// **'Upload'**
  String get upload;

  /// No description provided for @remove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remove;

  /// No description provided for @filename.
  ///
  /// In en, this message translates to:
  /// **'Filename'**
  String get filename;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @uploadFailed.
  ///
  /// In en, this message translates to:
  /// **'Upload failed: {error}'**
  String uploadFailed(String error);

  /// No description provided for @noFilesToUpload.
  ///
  /// In en, this message translates to:
  /// **'No files to upload'**
  String get noFilesToUpload;

  /// No description provided for @browseDirectory.
  ///
  /// In en, this message translates to:
  /// **'Browse directory: {path}'**
  String browseDirectory(String path);

  /// No description provided for @refresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// No description provided for @loadFailed.
  ///
  /// In en, this message translates to:
  /// **'Load failed'**
  String get loadFailed;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @folderEmpty.
  ///
  /// In en, this message translates to:
  /// **'Folder is empty'**
  String get folderEmpty;

  /// No description provided for @confirmDelete.
  ///
  /// In en, this message translates to:
  /// **'Confirm Delete'**
  String get confirmDelete;

  /// No description provided for @confirmDeleteFile.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete \\\"{name}\\\"?'**
  String confirmDeleteFile(String name);

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @deleteSuccess.
  ///
  /// In en, this message translates to:
  /// **'Delete successful'**
  String get deleteSuccess;

  /// No description provided for @deleteFailed.
  ///
  /// In en, this message translates to:
  /// **'Delete failed: {error}'**
  String deleteFailed(String error);

  /// No description provided for @cannotGetDownloadDir.
  ///
  /// In en, this message translates to:
  /// **'Cannot get download directory'**
  String get cannotGetDownloadDir;

  /// No description provided for @downloadStarted.
  ///
  /// In en, this message translates to:
  /// **'Download started: {name}'**
  String downloadStarted(String name);

  /// No description provided for @downloadSuccess.
  ///
  /// In en, this message translates to:
  /// **'Download successful: {path}'**
  String downloadSuccess(String path);

  /// No description provided for @downloadFailed.
  ///
  /// In en, this message translates to:
  /// **'Download failed: {error}'**
  String downloadFailed(String error);

  /// No description provided for @scanConfigQrCode.
  ///
  /// In en, this message translates to:
  /// **'Scan Configuration QR Code'**
  String get scanConfigQrCode;

  /// No description provided for @placeQrInFrame.
  ///
  /// In en, this message translates to:
  /// **'Place QR code in frame'**
  String get placeQrInFrame;

  /// No description provided for @autoRecognize.
  ///
  /// In en, this message translates to:
  /// **'Auto-recognize and import configuration'**
  String get autoRecognize;

  /// No description provided for @qrCodeExpired.
  ///
  /// In en, this message translates to:
  /// **'QR code has expired, please refresh and try again'**
  String get qrCodeExpired;

  /// No description provided for @qrCodeInvalid.
  ///
  /// In en, this message translates to:
  /// **'QR code format is incorrect or damaged'**
  String get qrCodeInvalid;

  /// No description provided for @cannotParseQrCode.
  ///
  /// In en, this message translates to:
  /// **'Cannot parse QR code data'**
  String get cannotParseQrCode;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when language+country codes are specified.
  switch (locale.languageCode) {
    case 'zh':
      {
        switch (locale.countryCode) {
          case 'TW':
            return AppLocalizationsZhTw();
        }
        break;
      }
  }

  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
