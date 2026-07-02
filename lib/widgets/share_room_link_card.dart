import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../services/join_link_service.dart';
import '../utils/app_theme.dart';

class ShareRoomLinkCard extends StatefulWidget {
  const ShareRoomLinkCard({
    super.key,
    required this.roomCode,
  });

  final String roomCode;

  @override
  State<ShareRoomLinkCard> createState() => _ShareRoomLinkCardState();
}

class _ShareRoomLinkCardState extends State<ShareRoomLinkCard> {
  final _joinLinkService = JoinLinkService();
  late Future<String> _joinLinkFuture;

  @override
  void initState() {
    super.initState();
    _joinLinkFuture = _joinLinkService.buildJoinLink(widget.roomCode);
  }

  Future<void> _copyLink(String link) async {
    await Clipboard.setData(ClipboardData(text: link));
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'تم نسخ رابط الانضمام',
          textAlign: TextAlign.right,
        ),
      ),
    );
  }

  Future<void> _shareLink(String link) async {
    await Share.share(
      'انضم إلى لعبة تحدي الكلمات عبر هذا الرابط:\n$link',
      subject: 'دعوة للانضمام - تحدي الكلمات',
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: _joinLinkFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        final link = snapshot.data ?? '';
        if (link.isEmpty) {
          return const SizedBox.shrink();
        }

        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: AppTheme.cardBorder),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'رابط الانضمام للجوال',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'امسح رمز QR أو شارك الرابط — يعمل من أي شبكة إنترنت',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
                ),
                const SizedBox(height: 16),
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.cardBorder),
                    ),
                    child: QrImageView(
                      data: link,
                      size: 180,
                      backgroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SelectableText(
                  link,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppTheme.primaryBlue,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _copyLink(link),
                        icon: const Icon(Icons.copy, size: 18),
                        label: const Text('نسخ الرابط'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () => _shareLink(link),
                        icon: const Icon(Icons.share, size: 18),
                        label: const Text('مشاركة'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
