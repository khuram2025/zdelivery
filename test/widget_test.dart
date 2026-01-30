import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zdelivery/main.dart';

void main() {
  testWidgets('App launches successfully', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: ZDeliveryApp()));
    await tester.pump();

    // Verify the app launches
    expect(find.byType(ZDeliveryApp), findsOneWidget);
  });
}
