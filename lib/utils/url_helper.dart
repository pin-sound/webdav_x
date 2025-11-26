import 'package:url_launcher/url_launcher.dart';

/// Opens a URL in an external application
Future<void> openUrl(String url) async {
  final uri = Uri.parse(url);
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  } else {
    print('无法打开链接: $url');
  }
}
