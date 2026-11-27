import 'package:arcana_observatory/main.dart';
import 'package:arcana_observatory/reading.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<List<TarotDeck>> _loadDecks() async => [
  TarotDeck(
    id: 'fixture',
    name: 'Test Tarot',
    credit: 'Artist',
    source: 'Source',
    rights: 'CC0',
    cards: [
      for (var i = 0; i < 78; i++)
        TarotCard(
          id: 'card-$i',
          title: 'Card $i',
          imageAsset: 'missing-fixture.png',
          symbolism: 'A star.',
          meaning: 'Consider the light.',
          reversed: 'Look inward.',
        ),
    ],
  ),
];

void main() {
  testWidgets('a reader can draw, reveal and interpret a single card', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1200, 850);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const ObservatoryApp(loadDecks: _loadDecks));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Begin reading'));
    await tester.tap(find.text('Begin reading'));
    await tester.pumpAndSettle();
    expect(find.text('Choose a card'), findsOneWidget);
    await tester.ensureVisible(find.byKey(const ValueKey('fan-card-0')));
    await tester.tap(find.byKey(const ValueKey('fan-card-0')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Reveal card'));
    await tester.tap(find.text('Reveal card'));
    await tester.pumpAndSettle();
    expect(find.text('Card meaning'), findsOneWidget);
    expect(find.text('Reading complete'), findsOneWidget);
    await tester.tap(find.byTooltip('Enlarge card'));
    await tester.pumpAndSettle();
    expect(find.byType(InteractiveViewer), findsOneWidget);
  });

  testWidgets('phone navigation opens the library and guide', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(360, 710);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const ObservatoryApp(loadDecks: _loadDecks));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('begin-configured')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('nav-library')));
    await tester.pumpAndSettle();
    expect(find.text('Card gallery'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('nav-guide')));
    await tester.pumpAndSettle();
    expect(find.text('Ask a question'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the gallery pager fits a compact phone with large text', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 640);
    tester.platformDispatcher.textScaleFactorTestValue = 2.0;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpWidget(const ObservatoryApp(loadDecks: _loadDecks));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('nav-library')));
    await tester.pumpAndSettle();
    final forward = find.byTooltip('Next page');
    await tester.ensureVisible(forward);
    await tester.tap(forward);
    await tester.pumpAndSettle();
    expect(find.text('13–24 of 78'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'a reading retains its place when consulting the guide and rotating',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 844);
      addTearDown(tester.view.reset);
      await tester.pumpWidget(const ObservatoryApp(loadDecks: _loadDecks));
      await tester.pumpAndSettle();
      Future<void> tapKey(String key) async {
        final control = find.byKey(ValueKey(key));
        await tester.ensureVisible(control);
        await tester.pumpAndSettle();
        await tester.tap(control);
        await tester.pumpAndSettle();
      }

      await tapKey('spread-three');
      await tapKey('begin-configured');
      await tapKey('fan-card-0');
      await tapKey('reveal-card');
      await tapKey('next-position');
      await tapKey('nav-guide');
      tester.view.physicalSize = const Size(844, 390);
      await tester.pumpAndSettle();
      await tapKey('nav-table');
      expect(find.text('Choose a card'), findsOneWidget);
      expect(find.textContaining('POSITION 2 OF 3'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
