import 'package:arcana_observatory/main.dart' as app;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('complete a Celtic Cross from bundled art', (tester) async {
    app.main();
    await tester.pumpAndSettle();
    Future<void> tapControl(String key) async {
      final control = find.byKey(ValueKey(key));
      await tester.ensureVisible(control);
      await tester.pumpAndSettle();
      await tester.tap(control);
      await tester.pumpAndSettle();
    }

    await tapControl('select-deck-celestial');
    await tapControl('spread-celticCross');
    await tapControl('begin-reading');
    for (var index = 0; index < 10; index++) {
      await tapControl('fan-card-0');
      await tapControl('reveal-card');
      if (index < 9) await tapControl('next-position');
    }
    expect(find.text('Reading complete'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
