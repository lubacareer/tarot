import 'package:arcana_observatory/main.dart';
import 'package:arcana_observatory/reading.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fixture_interpretations.dart';

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
  await tester.pumpWidget(
    const ObservatoryApp(
      interpretationClient: fixtureInterpretations,
      loadDecks: _fixture,
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Finder _key(String id) => find.byKey(ValueKey(id));

void main() {
  for (final command in ['Reset zoom', 'Zoom in']) {
    testWidgets(
      '$command overrides a pinched card still moving under inertia',
      (tester) async {
        await _open(tester);
        await _tap(tester, _key('begin-reading'));
        await _tap(tester, _key('fan-card-0'));
        await _tap(tester, _key('reveal-card'));
        await _tap(tester, find.byTooltip('Enlarge card'));
        final viewer = find.byType(InteractiveViewer);
        final controller = tester
            .widget<InteractiveViewer>(viewer)
            .transformationController!;
        final focal = tester.getSize(viewer).center(Offset.zero);
        final detector = tester
            .widgetList<GestureDetector>(
              find.descendant(
                of: viewer,
                matching: find.byType(GestureDetector),
              ),
            )
            .singleWhere((it) => it.onScaleUpdate != null);
        detector.onScaleStart!(ScaleStartDetails(focalPoint: focal));
        detector.onScaleUpdate!(
          ScaleUpdateDetails(focalPoint: focal, scale: 1.5, pointerCount: 2),
        );
        detector.onScaleEnd!(ScaleEndDetails(scaleVelocity: 4));
        await tester.pump();
        final start = controller.value.getMaxScaleOnAxis();
        await tester.pump(const Duration(milliseconds: 20));
        final moving = controller.value.getMaxScaleOnAxis();
        expect(moving, greaterThan(start));
        final focus = controller.toScene(focal);
        await tester.tap(find.byTooltip(command));
        await tester.pumpAndSettle();
        final result = tester
            .widget<InteractiveViewer>(viewer)
            .transformationController!;
        final expectedScale = command == 'Reset zoom'
            ? 1.0
            : (moving * 1.5).clamp(1.0, 4.0);
        expect(result.value.getMaxScaleOnAxis(), closeTo(expectedScale, .001));
        expect(
          (result.toScene(focal) - (command == 'Reset zoom' ? focal : focus))
              .distance,
          lessThan(.001),
        );
      },
    );
  }

  testWidgets(
    'Android Back exits immediately after the final card is revealed',
    (tester) async {
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
      await _tap(tester, _key('begin-reading'));
      await _tap(tester, _key('fan-card-0'));
      await _tap(tester, _key('reveal-card'));
      expect(find.text('Reading complete'), findsOneWidget);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(systemPops, 1);
      expect(find.text('Leave this reading?'), findsNothing);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.android),
  );

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
