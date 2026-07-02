import 'dart:convert';

import 'package:http/http.dart' as http;

import '../utils/join_link_utils.dart';
import '../utils/server_config.dart';

class JoinLinkService {
  Future<String> buildJoinLink(String roomCode) async {
    final uri = Uri.base;
    final currentOrigin = ServerConfig.originFromUri(uri);

    if (ServerConfig.isProductionWeb || !JoinLinkUtils.isLocalHost(uri.host)) {
      return JoinLinkUtils.buildJoinUrl(currentOrigin, roomCode);
    }

    try {
      final appPort = uri.port == 0 ? 8080 : uri.port;
      final response = await http
          .get(
            Uri.parse(
              '${ServerConfig.serverUrl}/network-info?appPort=$appPort',
            ),
          )
          .timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final baseUrl = data['baseUrl'] as String? ?? currentOrigin;
        return JoinLinkUtils.buildJoinUrl(baseUrl, roomCode);
      }
    } catch (_) {
      // Fall back to the current browser origin below.
    }

    return JoinLinkUtils.buildJoinUrl(currentOrigin, roomCode);
  }
}
