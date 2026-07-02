import '../utils/join_link_utils.dart';
import '../utils/server_config.dart';

class JoinLinkService {
  Future<String> buildJoinLink(String roomCode) async {
    final origin = ServerConfig.originFromUri(Uri.base);
    return JoinLinkUtils.buildJoinUrl(origin, roomCode);
  }
}
