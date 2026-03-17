import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:jg_business/features/main/presentation/screens/home_screen.dart';

void main() {
  testWidgets('home mockup renders summary cards', (WidgetTester tester) async {
    await tester.pumpWidget(
      const GetMaterialApp(
        home: HomeScreen(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('おはようございます、\nAlex'), findsOneWidget);
    expect(find.text('次の面談'), findsOneWidget);
    expect(find.text('記録待ち'), findsNothing);
  });
}
