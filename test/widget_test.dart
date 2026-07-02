import 'package:flutter_test/flutter_test.dart';

import 'package:word_challenge_solo/main.dart';

void main() {
  testWidgets('App launches home screen', (WidgetTester tester) async {
    await tester.pumpWidget(const WordChallengeSoloApp());

    expect(find.text('Word Challenge Solo'), findsOneWidget);
    expect(find.text('Start Game'), findsOneWidget);
  });
}
