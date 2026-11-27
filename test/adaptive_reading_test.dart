import 'package:arcana_observatory/main.dart';
import 'package:arcana_observatory/reading.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fixture_interpretations.dart';

void main() {
  testWidgets('a large-text reading survives a resize and app backgrounding', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(360, 740);
    final dispatcher = tester.platformDispatcher;
    dispatcher.textScaleFactorTestValue = 1.8;
    dispatcher.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(
      disableAnimations: true,
    );
    addTearDown(tester.view.reset);
    addTearDown(dispatcher.clearTextScaleFactorTestValue);
    addTearDown(dispatcher.clearAccessibilityFeaturesTestValue);
    // Large catalog JSON is decoded on a worker isolate outside the fake clock.
    final decks = (await tester.runAsync(DeckCatalog.load))!;
    await tester.pumpWidget(
      ObservatoryApp(
        interpretationClient: fixtureInterpretations,
        loadDecks: () async => decks,
      ),
    );
    await tester.pumpAndSettle();
    Future<void> tap(String id) async {
      final item = find.byKey(ValueKey(id));
      await tester.ensureVisible(item);
      await tester.tap(item);
      await tester.pumpAndSettle();
    }

    await tap('spread-three');
    await tap('begin-reading');
    await tap('fan-card-1');
    await tap('reveal-card');
    expect(find.text('Card meaning'), findsOneWidget);
    final before = decks.first.cards.singleWhere(
      (card) => find.text(card.title).evaluate().isNotEmpty,
    );
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.view.physicalSize = const Size(1000, 700);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(find.text('Card meaning'), findsOneWidget);
    expect(find.text(before.title), findsWidgets);
    await tap('next-position');
    await tap('fan-card-0');
    await tap('reveal-card');
    expect(find.text('Card meaning'), findsOneWidget);
    expect(find.text('Reading complete'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
