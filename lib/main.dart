import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'screens/game_setup_screen.dart';
import 'screens/join_room_screen.dart';
import 'utils/app_theme.dart';
import 'utils/join_link_utils.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(KalimatApp(
    initialJoinCode: JoinLinkUtils.codeFromUri(Uri.base),
  ));
}

class KalimatApp extends StatelessWidget {
  const KalimatApp({
    super.key,
    this.initialJoinCode,
  });

  final String? initialJoinCode;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'تحدي الكلمات',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.build(),
      locale: const Locale('ar'),
      supportedLocales: const [
        Locale('ar'),
        Locale('en'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: initialJoinCode == null
          ? const GameSetupScreen()
          : JoinRoomScreen(initialRoomCode: initialJoinCode),
    );
  }
}
