import 'package:flutter_test/flutter_test.dart';
import 'package:sms_forwarder/main.dart';

void main() {
  testWidgets('App should load', (WidgetTester tester) async {
    await tester.pumpWidget(const SmsForwarderApp());
    expect(find.text('sms'), findsOneWidget);
  });
}
