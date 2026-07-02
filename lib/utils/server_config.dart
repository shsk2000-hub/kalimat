abstract final class ServerConfig {
  static String originFromUri(Uri uri) {
    final port = uri.port;
    final host = uri.host.isEmpty ? 'localhost' : uri.host;
    final scheme = uri.scheme.isEmpty ? 'http' : uri.scheme;
    final defaultPort = scheme == 'https' ? 443 : 80;
    final portSuffix = port == 0 || port == defaultPort ? '' : ':$port';
    return '$scheme://$host$portSuffix';
  }
}
