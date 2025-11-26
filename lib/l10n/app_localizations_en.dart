// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'webdav_x';

  @override
  String get welcome => 'Welcome';

  @override
  String get appSubtitle => 'Nutstore WebDAV Sync Tool';

  @override
  String get uploadMode => 'Upload Files';

  @override
  String get uploadModeSubtitle => 'Select files and upload to WebDAV folder';

  @override
  String get viewMode => 'View Files';

  @override
  String get viewModeSubtitle => 'Browse and manage files on WebDAV';

  @override
  String get settings => 'Settings';

  @override
  String get showQrCode => 'Show Configuration QR Code';

  @override
  String get openDownloadFolder => 'Open Download Folder';

  @override
  String get pleaseConfigureFirst => 'Please configure WebDAV settings first';

  @override
  String error(String error) {
    return 'Error: $error';
  }

  @override
  String get languageSettings => 'Language Settings';

  @override
  String get selectLanguage => 'Select Language';

  @override
  String get simplifiedChinese => '简体中文';

  @override
  String get traditionalChinese => '繁體中文';

  @override
  String get english => 'English';

  @override
  String get downloadFolderPath =>
      'Files saved at: /storage/emulated/0/Download/WebDAV_X\\nPlease use file manager to view';

  @override
  String get cannotOpenFolder => 'Cannot open folder';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get webdavConfiguration => 'WebDAV Configuration';

  @override
  String get account => 'Account';

  @override
  String get accountHint => 'Enter your Account';

  @override
  String get password => 'Password';

  @override
  String get passwordHint => 'Enter your Password';

  @override
  String get pleaseEnterAccountPassword => 'Please enter Account and Password';

  @override
  String get accountMustBeEmail => 'Account must be a valid email format';

  @override
  String get connectionSuccess => 'Connection successful!';

  @override
  String get connectionFailed =>
      'Connection failed, please check Account and Password';

  @override
  String validationFailed(String error) {
    return 'Validation failed: $error';
  }

  @override
  String get settingsSaved => 'Settings saved';

  @override
  String get configImported =>
      'Configuration imported, please validate and save';

  @override
  String get scanQrCode => 'Scan QR Code';

  @override
  String get validating => 'Validating...';

  @override
  String get validateConnection => 'Validate Connection';

  @override
  String get saveConfiguration => 'Save Configuration';

  @override
  String get uploadDirectory => 'Upload Directory';

  @override
  String get viewDirectory => 'View Directory';

  @override
  String get pathExists => 'Path already exists';

  @override
  String cannotAccessFolder(String error) {
    return 'Cannot access or create folder: $error';
  }

  @override
  String get webdavPath => 'WebDAV Path';

  @override
  String get folderNameHint => 'Enter folder name';

  @override
  String get add => 'Add';

  @override
  String get addNewPath => 'Add New Path';

  @override
  String get noPathsYet => 'No paths yet';

  @override
  String get pleaseAddPath => 'Please add WebDAV path above';

  @override
  String get deleteTooltip => 'Delete (won\'t affect webdav cloud storage)';

  @override
  String uploadTo(String path) {
    return 'Upload to: $path';
  }

  @override
  String get selectFiles => 'Select Files';

  @override
  String uploadAll(int count) {
    return 'Upload All ($count)';
  }

  @override
  String get clearList => 'Clear List';

  @override
  String get readyToUpload => 'Ready to Upload';

  @override
  String get clickToSelectFiles => 'Click the button above to select files';

  @override
  String size(String size) {
    return 'Size: $size';
  }

  @override
  String errorMessage(String message) {
    return 'Error: $message';
  }

  @override
  String get editFilename => 'Edit Filename';

  @override
  String get upload => 'Upload';

  @override
  String get remove => 'Remove';

  @override
  String get filename => 'Filename';

  @override
  String get cancel => 'Cancel';

  @override
  String get confirm => 'Confirm';

  @override
  String uploadFailed(String error) {
    return 'Upload failed: $error';
  }

  @override
  String get noFilesToUpload => 'No files to upload';

  @override
  String browseDirectory(String path) {
    return 'Browse directory: $path';
  }

  @override
  String get refresh => 'Refresh';

  @override
  String get loadFailed => 'Load failed';

  @override
  String get retry => 'Retry';

  @override
  String get folderEmpty => 'Folder is empty';

  @override
  String get confirmDelete => 'Confirm Delete';

  @override
  String confirmDeleteFile(String name) {
    return 'Are you sure you want to delete \\\"$name\\\"?';
  }

  @override
  String get delete => 'Delete';

  @override
  String get deleteSuccess => 'Delete successful';

  @override
  String deleteFailed(String error) {
    return 'Delete failed: $error';
  }

  @override
  String get cannotGetDownloadDir => 'Cannot get download directory';

  @override
  String downloadStarted(String name) {
    return 'Download started: $name';
  }

  @override
  String downloadSuccess(String path) {
    return 'Download successful: $path';
  }

  @override
  String downloadFailed(String error) {
    return 'Download failed: $error';
  }

  @override
  String get scanConfigQrCode => 'Scan Configuration QR Code';

  @override
  String get placeQrInFrame => 'Place QR code in frame';

  @override
  String get autoRecognize => 'Auto-recognize and import configuration';

  @override
  String get qrCodeExpired =>
      'QR code has expired, please refresh and try again';

  @override
  String get qrCodeInvalid => 'QR code format is incorrect or damaged';

  @override
  String get cannotParseQrCode => 'Cannot parse QR code data';
}
