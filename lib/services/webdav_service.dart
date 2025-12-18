import 'dart:convert';

import 'package:webdav_client/webdav_client.dart' as webdav;
import 'package:http/http.dart' as http;

class WebDavService {
  webdav.Client? _client;
  String? _baseUrl;
  String? _username;
  String? _password;

  /// Initialize WebDAV client with credentials and path
  void initialize(String username, String password, String path) {
    final baseUrl = 'https://dav.jianguoyun.com/dav/$path';
    _baseUrl = baseUrl;
    _username = username;
    _password = password;

    _client = webdav.newClient(
      baseUrl,
      user: username,
      password: password,
      debug: false,
    );
  }

  /// Validate connection to WebDAV server
  Future<bool> validateConnection() async {
    if (_client == null) {
      throw Exception('WebDAV client not initialized');
    }

    try {
      // Try to ping the server
      await _client!.ping();
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Check if client is initialized
  bool get isInitialized => _client != null;

  /// Ensure a directory exists, create if not
  Future<void> _ensureDirectoryRecursive(String path) async {
    if (_client == null) {
      throw Exception('WebDAV client not initialized');
    }

    final parts = path.split('/').where((s) => s.isNotEmpty).toList();
    var currentPath = '';

    for (final part in parts) {
      currentPath = currentPath.isEmpty ? part : '$currentPath/$part';
      try {
        // Try to read the directory to check if it exists
        await _client!.readDir('/$currentPath');
      } catch (e) {
        // If read fails (likely 404), try to create it
        try {
          await _client!.mkdir('/$currentPath');
        } catch (e) {
          // If mkdir fails and it's not because it already exists, rethrow
          // (Some servers might return error if it exists but readDir failed for other reasons)
          // But usually 404 is what we expect here.
          if (!e.toString().contains('405')) {
            // 405 Method Not Allowed often means it exists
            throw Exception('Failed to create directory $currentPath: $e');
          }
        }
      }
    }
  }

  /// Ensure a directory exists, create if not
  Future<void> ensureDirectory(String path) async {
    await _ensureDirectoryRecursive(path);
  }

  /// List files in a directory
  Future<List<webdav.File>> listFiles(String path) async {
    if (_client == null) {
      throw Exception('WebDAV client not initialized');
    }

    try {
      return await _client!.readDir('/$path');
    } catch (e) {
      throw Exception('Failed to list files: $e');
    }
  }

  /// Delete a file or directory
  Future<void> deleteFile(String path) async {
    if (_client == null) {
      throw Exception('WebDAV client not initialized');
    }

    try {
      await _client!.removeAll('/$path');
    } catch (e) {
      throw Exception('Failed to delete: $e');
    }
  }

  /// Upload a stream of data to WebDAV server
  Future<void> uploadStream(
    Stream<List<int>> stream,
    String remoteName,
    int? length,
  ) async {
    if (_client == null ||
        _baseUrl == null ||
        _username == null ||
        _password == null) {
      throw Exception('WebDAV client not initialized');
    }

    // Robust approach: Use standard 'http' package with credentials.
    // Ensure remoteName is encoded to handle spaces and special characters
    final encodedName = Uri.encodeComponent(remoteName);

    // We assume _baseUrl is already a valid URI string (or at least the path part should be encoded if it wasn't)
    // But to be safe, let's construct it carefully.
    // If _baseUrl ends with /, remove it to avoid double slash with /$encodedName
    final baseUrl = _baseUrl!.endsWith('/')
        ? _baseUrl!.substring(0, _baseUrl!.length - 1)
        : _baseUrl!;

    final uri = Uri.parse('$baseUrl/$encodedName');

    // Use custom StreamRequest to handle backpressure correctly
    final request = StreamRequest('PUT', uri, stream);

    // Add Auth headers
    final auth = 'Basic ${base64Encode(utf8.encode('$_username:$_password'))}';
    request.headers['Authorization'] = auth;

    if (length != null) {
      request.contentLength = length;
    }

    final response = await http.Response.fromStream(await request.send());

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Upload failed with status: ${response.statusCode}');
    }
  }

  /// Download a file as a stream
  Future<Stream<List<int>>> downloadStream(String remoteName) async {
    if (_client == null ||
        _baseUrl == null ||
        _username == null ||
        _password == null) {
      throw Exception('WebDAV client not initialized');
    }

    final encodedName = Uri.encodeComponent(remoteName);
    final baseUrl = _baseUrl!.endsWith('/')
        ? _baseUrl!.substring(0, _baseUrl!.length - 1)
        : _baseUrl!;

    final uri = Uri.parse('$baseUrl/$encodedName');
    final request = http.Request('GET', uri);

    final auth = 'Basic ${base64Encode(utf8.encode('$_username:$_password'))}';
    request.headers['Authorization'] = auth;

    final response = await request.send(); // Returns StreamedResponse

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Download failed with status: ${response.statusCode}');
    }

    return response.stream;
  }
}

class StreamRequest extends http.BaseRequest {
  final Stream<List<int>> _stream;

  StreamRequest(String method, Uri url, this._stream) : super(method, url);

  @override
  http.ByteStream finalize() {
    super.finalize();
    return http.ByteStream(_stream);
  }
}
