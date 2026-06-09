import '../services/api_config.dart';

class ImageUrlHelper {
  static String resolve(dynamic value) {
    final path = _firstPath(value);
    if (path.isEmpty) return '';

    final lower = path.toLowerCase();
    if (lower.startsWith('http://') || lower.startsWith('https://')) {
      return path.replaceFirst('http://localhost:', 'http://10.0.2.2:');
    }

    final apiUri = Uri.parse(ApiConfig.baseUrl);
    final backendBase = '${apiUri.scheme}://${apiUri.host}'
        '${apiUri.hasPort ? ':${apiUri.port}' : ''}';
    final normalizedBase =
        backendBase.replaceFirst('http://localhost:', 'http://10.0.2.2:');
    final cleanPath = path.replaceFirst(RegExp(r'^/+'), '');
    final storagePath =
        cleanPath.startsWith('storage/') ? cleanPath : 'storage/$cleanPath';

    return '$normalizedBase/$storagePath';
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
