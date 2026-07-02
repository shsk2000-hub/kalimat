import 'package:flutter_test/flutter_test.dart';

import 'package:kalimat/main.dart';

void main() {
  testWidgets('App launches Arabic game setup screen', (WidgetTester tester) async {
    await tester.pumpWidget(const KalimatApp());
    await tester.pumpAndSettle();

    expect(find.text('بيانات اللعبة'), findsOneWidget);
    expect(find.text('اسم اللاعب'), findsOneWidget);
    expect(find.text('اللعبة: تحدي الكلمات'), findsOneWidget);
    expect(find.text('عنوان الجولة'), findsOneWidget);
    expect(find.text('مدة الجولة'), findsOneWidget);
    expect(find.text('عدد الجولات'), findsOneWidget);
    expect(find.text('إنشاء الغرفة'), findsOneWidget);
    expect(find.text('انضمام لغرفة'), findsOneWidget);
  });

  testWidgets('Join link opens join screen with room code', (WidgetTester tester) async {
    await tester.pumpWidget(const KalimatApp(initialJoinCode: '2646'));
    await tester.pumpAndSettle();

    expect(find.text('انضمام لغرفة'), findsOneWidget);
    expect(find.textContaining('2646'), findsWidgets);
  });
}
