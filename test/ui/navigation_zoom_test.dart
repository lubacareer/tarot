import 'package:arcana_observatory/main.dart';
import 'package:arcana_observatory/reading.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

Future<List<TarotDeck>> _fixture() async => [
  TarotDeck(
    id: 'test',
    name: 'Test deck',
    credit: 'Test',
    source: 'Test',
    rights: 'Test',
    cards: const [
      TarotCard(
        id: 'star',
        title: 'The Star',
        imageAsset: 'assets/decks/waite_smith/star.webp',
        symbolism: 'Two streams.',
        meaning: 'Renewal.',
        reversed: 'Pause.',
      ),
    ],
  ),
];

Future<void> _open(WidgetTester tester) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(1080, 600);
  addTearDown(tester.view.reset);
  await tester.pumpWidget(const ObservatoryApp(loadDecks: _fixture));
  await tester.pumpAndSettle();
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Finder _key(String id) => find.byKey(ValueKey(id));

void main() {
  testWidgets('Android Back returns to the reading and confirms a live exit', (
    tester,
  ) async {
    await _open(tester);
    var systemPops = 0;
    final messenger = tester.binding.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'SystemNavigator.pop') systemPops++;
      return null;
    });
    addTearDown(
      () => messenger.setMockMethodCallHandler(SystemChannels.platform, null),
    );

    Future<void> back() async {
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
    }

    await back();
    expect(systemPops, 1, reason: 'Back from the setup screen exits normally');
    await _tap(tester, _key('begin-reading'));
    await _tap(tester, _key('fan-card-0'));
    for (final destination in ['nav-library', 'nav-guide']) {
      await _tap(tester, _key(destination));
      await back();
      expect(_key('reveal-card'), findsOneWidget);
      expect(systemPops, 1);
    }
    await back();
    expect(find.text('Leave this reading?'), findsOneWidget);
    await back();
    expect(find.text('Leave this reading?'), findsNothing);
    expect(_key('reveal-card'), findsOneWidget);
    expect(systemPops, 1);
    await back();
    await _tap(tester, find.text('Exit app'));
    expect(systemPops, 2);
  }, variant: TargetPlatformVariant.only(TargetPlatform.android));

  testWidgets('zoom keeps the point at the center fixed after a pan', (
    tester,
  ) async {
    await _open(tester);
    await _tap(tester, _key('begin-reading'));
    await _tap(tester, _key('fan-card-0'));
    await _tap(tester, _key('reveal-card'));
    await _tap(tester, find.byTooltip('Enlarge card'));
    final widget = find.byType(InteractiveViewer);
    final controller = tester
        .widget<InteractiveViewer>(widget)
        .transformationController!;
    final center = tester.getSize(widget).center(Offset.zero);
    controller.value = Matrix4.diagonal3Values(2, 2, 1)
      ..setTranslationRaw(-70, -40, 0);
    await tester.pumpAndSettle();
    final focus = controller.toScene(center);
    await _tap(tester, find.byTooltip('Zoom in'));
    expect(controller.value.getMaxScaleOnAxis(), closeTo(3, .001));
    expect((controller.toScene(center) - focus).distance, lessThan(.001));
    await _tap(tester, find.byTooltip('Reset zoom'));
    expect(controller.toScene(center), center);
  });
}
