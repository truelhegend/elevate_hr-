import 'package:flutter_test/flutter_test.dart';
import 'package:elevate_hr/main.dart';

void main() {
  testWidgets('App should render', (WidgetTester tester) async {
    await tester.pumpWidget(const ElevateHRApp());
    expect(find.byType(ElevateHRApp), findsOneWidget);
  });
}
