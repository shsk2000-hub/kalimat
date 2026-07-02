import 'package:flutter/foundation.dart';

import 'join_link_utils.dart';

abstract final class ServerConfig {
  static const int devApiPort = 3000;
  static const String apiBaseUrl = String.fromEnvironment('API_BASE_URL');

  static String get serverUrl {
    if (apiBaseUrl.isNotEmpty) {
      return apiBaseUrl;
    }

    if (kIsWeb) {
      final uri = Uri.base;
      final host = uri.host.isEmpty ? 'localhost' : uri.host;
      final scheme = uri.scheme.isEmpty ? 'http' : uri.scheme;

      if (isProductionWeb) {
        return originFromUri(uri);
      }

      return '$scheme://$host:$devApiPort';
    }

    return 'http://localhost:$devApiPort';
  }

  static bool get isProductionWeb {
    if (!kIsWeb) {
      return false;
    }
    return !JoinLinkUtils.isLocalHost(Uri.base.host);
  }

  static String originFromUri(Uri uri) {
    final port = uri.port;
    final host = uri.host.isEmpty ? 'localhost' : uri.host;
    final scheme = uri.scheme.isEmpty ? 'http' : uri.scheme;
    final defaultPort = scheme == 'https' ? 443 : 80;
    final portSuffix = port == 0 || port == defaultPort ? '' : ':$port';
    return '$scheme://$host$portSuffix';
  }
}
