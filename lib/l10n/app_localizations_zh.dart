// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => 'webdav_x';

  @override
  String get welcome => '欢迎使用';

  @override
  String get appSubtitle => '坚果云 WebDAV 同步工具';

  @override
  String get uploadMode => '上传目录';

  @override
  String get uploadModeSubtitle => '选择文件并上传到 WebDAV 文件夹';

  @override
  String get viewMode => '查看目录';

  @override
  String get viewModeSubtitle => '浏览和管理 WebDAV 上的文件';

  @override
  String get settings => '配置';

  @override
  String get showQrCode => '显示配置二维码';

  @override
  String get openDownloadFolder => '打开下载目录';

  @override
  String get pleaseConfigureFirst => '请先配置 WebDAV 设置';

  @override
  String error(String error) {
    return '发生错误: $error';
  }

  @override
  String get languageSettings => '语言设置';

  @override
  String get selectLanguage => '选择语言';

  @override
  String get simplifiedChinese => '简体中文';

  @override
  String get traditionalChinese => '繁體中文';

  @override
  String get english => 'English';

  @override
  String get downloadFolderPath =>
      '文件保存在: /storage/emulated/0/Download/WebDAV_X\\n请使用文件管理器查看';

  @override
  String get cannotOpenFolder => '无法打开文件夹';

  @override
  String get settingsTitle => '配置';

  @override
  String get webdavConfiguration => 'WebDAV 配置';

  @override
  String get account => 'Account';

  @override
  String get accountHint => '输入您的Account';

  @override
  String get password => 'Password';

  @override
  String get passwordHint => '输入您的Password';

  @override
  String get pleaseEnterAccountPassword => '请输入Account和Password';

  @override
  String get accountMustBeEmail => 'Account必须是有效的邮箱格式';

  @override
  String get connectionSuccess => '连接成功！';

  @override
  String get connectionFailed => '连接失败，请检查Account和Password';

  @override
  String validationFailed(String error) {
    return '验证失败: $error';
  }

  @override
  String get settingsSaved => '设置已保存';

  @override
  String get configImported => '配置已导入，请验证并保存';

  @override
  String get scanQrCode => '扫描二维码';

  @override
  String get validating => '验证中...';

  @override
  String get validateConnection => '验证连接';

  @override
  String get saveConfiguration => '保存配置';

  @override
  String get uploadDirectory => '上传目录';

  @override
  String get viewDirectory => '查看目录';

  @override
  String get pathExists => '路径已存在';

  @override
  String cannotAccessFolder(String error) {
    return '无法访问或创建文件夹: $error';
  }

  @override
  String get webdavPath => 'WebDAV 路径';

  @override
  String get folderNameHint => '输入文件夹名称';

  @override
  String get add => '添加';

  @override
  String get addNewPath => '添加新路径';

  @override
  String get noPathsYet => '暂无路径';

  @override
  String get pleaseAddPath => '请在上方添加 WebDAV 路径';

  @override
  String get deleteTooltip => '删除(不会影响到webdav网盘)';

  @override
  String uploadTo(String path) {
    return '上传到: $path';
  }

  @override
  String get selectFiles => '选择文件';

  @override
  String uploadAll(int count) {
    return '上传全部 ($count)';
  }

  @override
  String get clearList => '清空列表';

  @override
  String get readyToUpload => '准备上传';

  @override
  String get clickToSelectFiles => '点击上方按钮选择文件';

  @override
  String size(String size) {
    return '大小: $size';
  }

  @override
  String errorMessage(String message) {
    return '错误: $message';
  }

  @override
  String get editFilename => '编辑文件名';

  @override
  String get upload => '上传';

  @override
  String get remove => '移除';

  @override
  String get filename => '文件名';

  @override
  String get cancel => '取消';

  @override
  String get confirm => '确认';

  @override
  String uploadFailed(String error) {
    return '上传失败: $error';
  }

  @override
  String get noFilesToUpload => '没有待上传的文件';

  @override
  String browseDirectory(String path) {
    return '浏览目录: $path';
  }

  @override
  String get refresh => '刷新';

  @override
  String get loadFailed => '加载失败';

  @override
  String get retry => '重试';

  @override
  String get folderEmpty => '文件夹为空';

  @override
  String get confirmDelete => '确认删除';

  @override
  String confirmDeleteFile(String name) {
    return '确定要删除 \\\"$name\\\" 吗？';
  }

  @override
  String get delete => '删除';

  @override
  String get deleteSuccess => '删除成功';

  @override
  String deleteFailed(String error) {
    return '删除失败: $error';
  }

  @override
  String get cannotGetDownloadDir => '无法获取下载目录';

  @override
  String downloadStarted(String name) {
    return '开始下载: $name';
  }

  @override
  String downloadSuccess(String path) {
    return '下载成功: $path';
  }

  @override
  String downloadFailed(String error) {
    return '下载失败: $error';
  }

  @override
  String get scanConfigQrCode => '扫描配置二维码';

  @override
  String get placeQrInFrame => '将二维码放入框内';

  @override
  String get autoRecognize => '自动识别并导入配置';

  @override
  String get qrCodeExpired => '二维码已失效，请刷新后重试';

  @override
  String get qrCodeInvalid => '二维码格式不正确或已损坏';

  @override
  String get cannotParseQrCode => '无法解析二维码数据';
}

/// The translations for Chinese, as used in Taiwan (`zh_TW`).
class AppLocalizationsZhTw extends AppLocalizationsZh {
  AppLocalizationsZhTw() : super('zh_TW');

  @override
  String get appTitle => 'webdav_x';

  @override
  String get welcome => '歡迎使用';

  @override
  String get appSubtitle => '堅果雲 WebDAV 同步工具';

  @override
  String get uploadMode => '上傳目錄';

  @override
  String get uploadModeSubtitle => '選擇檔案並上傳到 WebDAV 資料夾';

  @override
  String get viewMode => '查看目錄';

  @override
  String get viewModeSubtitle => '瀏覽和管理 WebDAV 上的檔案';

  @override
  String get settings => '配置';

  @override
  String get showQrCode => '顯示配置二維碼';

  @override
  String get openDownloadFolder => '打開下載目錄';

  @override
  String get pleaseConfigureFirst => '請先配置 WebDAV 設定';

  @override
  String error(String error) {
    return '發生錯誤: $error';
  }

  @override
  String get languageSettings => '語言設定';

  @override
  String get selectLanguage => '選擇語言';

  @override
  String get simplifiedChinese => '简体中文';

  @override
  String get traditionalChinese => '繁體中文';

  @override
  String get english => 'English';

  @override
  String get downloadFolderPath =>
      '檔案儲存在: /storage/emulated/0/Download/WebDAV_X\\n請使用檔案管理器查看';

  @override
  String get cannotOpenFolder => '無法打開資料夾';

  @override
  String get settingsTitle => '配置';

  @override
  String get webdavConfiguration => 'WebDAV 配置';

  @override
  String get account => 'Account';

  @override
  String get accountHint => '輸入您的Account';

  @override
  String get password => 'Password';

  @override
  String get passwordHint => '輸入您的Password';

  @override
  String get pleaseEnterAccountPassword => '請輸入Account和Password';

  @override
  String get accountMustBeEmail => 'Account必須是有效的郵箱格式';

  @override
  String get connectionSuccess => '連接成功！';

  @override
  String get connectionFailed => '連接失敗，請檢查Account和Password';

  @override
  String validationFailed(String error) {
    return '驗證失敗: $error';
  }

  @override
  String get settingsSaved => '設定已儲存';

  @override
  String get configImported => '配置已導入，請驗證並儲存';

  @override
  String get scanQrCode => '掃描二維碼';

  @override
  String get validating => '驗證中...';

  @override
  String get validateConnection => '驗證連接';

  @override
  String get saveConfiguration => '儲存配置';

  @override
  String get uploadDirectory => '上傳目錄';

  @override
  String get viewDirectory => '查看目錄';

  @override
  String get pathExists => '路徑已存在';

  @override
  String cannotAccessFolder(String error) {
    return '無法訪問或創建資料夾: $error';
  }

  @override
  String get webdavPath => 'WebDAV 路徑';

  @override
  String get folderNameHint => '輸入資料夾名稱';

  @override
  String get add => '添加';

  @override
  String get addNewPath => '添加新路徑';

  @override
  String get noPathsYet => '暫無路徑';

  @override
  String get pleaseAddPath => '請在上方添加 WebDAV 路徑';

  @override
  String get deleteTooltip => '刪除(不會影響到webdav網盤)';

  @override
  String uploadTo(String path) {
    return '上傳到: $path';
  }

  @override
  String get selectFiles => '選擇檔案';

  @override
  String uploadAll(int count) {
    return '上傳全部 ($count)';
  }

  @override
  String get clearList => '清空列表';

  @override
  String get readyToUpload => '準備上傳';

  @override
  String get clickToSelectFiles => '點擊上方按鈕選擇檔案';

  @override
  String size(String size) {
    return '大小: $size';
  }

  @override
  String errorMessage(String message) {
    return '錯誤: $message';
  }

  @override
  String get editFilename => '編輯檔案名';

  @override
  String get upload => '上傳';

  @override
  String get remove => '移除';

  @override
  String get filename => '檔案名';

  @override
  String get cancel => '取消';

  @override
  String get confirm => '確認';

  @override
  String uploadFailed(String error) {
    return '上傳失敗: $error';
  }

  @override
  String get noFilesToUpload => '沒有待上傳的檔案';

  @override
  String browseDirectory(String path) {
    return '瀏覽目錄: $path';
  }

  @override
  String get refresh => '刷新';

  @override
  String get loadFailed => '加載失敗';

  @override
  String get retry => '重試';

  @override
  String get folderEmpty => '資料夾為空';

  @override
  String get confirmDelete => '確認刪除';

  @override
  String confirmDeleteFile(String name) {
    return '確定要刪除 \\\"$name\\\" 嗎？';
  }

  @override
  String get delete => '刪除';

  @override
  String get deleteSuccess => '刪除成功';

  @override
  String deleteFailed(String error) {
    return '刪除失敗: $error';
  }

  @override
  String get cannotGetDownloadDir => '無法獲取下載目錄';

  @override
  String downloadStarted(String name) {
    return '開始下載: $name';
  }

  @override
  String downloadSuccess(String path) {
    return '下載成功: $path';
  }

  @override
  String downloadFailed(String error) {
    return '下載失敗: $error';
  }

  @override
  String get scanConfigQrCode => '掃描配置二維碼';

  @override
  String get placeQrInFrame => '將二維碼放入框內';

  @override
  String get autoRecognize => '自動識別並導入配置';

  @override
  String get qrCodeExpired => '二維碼已失效，請刷新後重試';

  @override
  String get qrCodeInvalid => '二維碼格式不正確或已損壞';

  @override
  String get cannotParseQrCode => '無法解析二維碼數據';
}
