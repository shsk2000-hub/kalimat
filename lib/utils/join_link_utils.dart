abstract final class JoinLinkUtils {
  static const joinQueryKey = 'join';

  static String? codeFromUri(Uri uri) {
    final code = uri.queryParameters[joinQueryKey]?.trim();
    if (code == null || code.length < 4) {
      return null;
    }
    return code;
  }

  static bool isLocalHost(String host) {
    return host == 'localhost' || host == '127.0.0.1' || host == '0.0.0.0';
  }

  static String buildJoinUrl(String origin, String roomCode) {
    final base = origin.endsWith('/')
        ? origin.substring(0, origin.length - 1)
        : origin;
    return '$base/?$joinQueryKey=$roomCode';
  }
}
