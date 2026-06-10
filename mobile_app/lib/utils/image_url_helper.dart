import '../services/api_config.dart';

class ImageUrlHelper {
  static String resolve(dynamic value) {
    final path = _firstPath(value);
    if (path.isEmpty) return '';

    final lower = path.toLowerCase();
    if (lower.startsWith('http://') || lower.startsWith('https://')) {
      final uri = Uri.tryParse(path);
      if (uri != null && uri.path.startsWith('/storage/')) {
        return _apiFileUrl(uri.path.substring('/storage/'.length));
      }
      if (path.startsWith('http://localhost:')) {
        return path.replaceFirst('http://localhost:', 'http://10.0.2.2:');
      }
      return path;
    }

    final cleanPath = path.replaceFirst(RegExp(r'^/+'), '');
    final storagePath = cleanPath.startsWith('storage/')
        ? cleanPath.substring('storage/'.length)
        : cleanPath;

    return _apiFileUrl(storagePath);
  }

  static String _apiFileUrl(String storagePath) {
    final cleanPath = storagePath.replaceFirst(RegExp(r'^/+'), '');
    final base = ApiConfig.baseUrl
        .replaceFirst('http://localhost:', 'http://10.0.2.2:')
        .replaceFirst(RegExp(r'/+$'), '');
    return '$base/files/$cleanPath';
  }

  static String _firstPath(dynamic value) {
    if (value == null) return '';
    if (value is List) {
      for (final item in value) {
        final path = _firstPath(item);
        if (path.isNotEmpty) return path;
      }
      return '';
    }
    final text = value.toString().trim();
    if (text.isEmpty || text == '[]') return '';
    return text;
  }
}
