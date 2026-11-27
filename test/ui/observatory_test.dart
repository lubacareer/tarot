import 'package:arcana_observatory/main.dart';
import 'package:arcana_observatory/reading.dart';
import 'package:arcana_observatory/strings.dart';
import 'package:arcana_observatory/ui/observatory.dart';
import 'package:arcana_observatory/ui/reading_table.dart';
import 'package:arcana_observatory/ui/setup.dart';
import 'package:arcana_observatory/ui/style.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fixture_interpretations.dart';

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
  testWidgets('Begin reading uses the deck selected before the next frame', (
    tester,
  ) async {
    final first = (await _loadDecks()).single;
    final second = TarotDeck(
      id: 'second',
      name: 'Second deck',
      credit: first.credit,
      source: first.source,
      rights: first.rights,
      cards: first.cards,
    );
    await tester.pumpWidget(
      ObservatoryApp(
        interpretationClient: fixtureInterpretations,
        loadDecks: () async => [first, second],
      ),
    );
    await tester.pumpAndSettle();
    final begin = tester
        .widget<FilledButton>(find.byKey(const ValueKey('begin-reading')))
        .onPressed!;
    tester
        .widget<DeckOption>(find.byKey(const ValueKey('select-deck-second')))
        .onTap();
    begin();
    await tester.pumpAndSettle();
    expect(
      tester.widget<ReadingTable>(find.byType(ReadingTable)).session.deck,
      same(second),
    );
  });

  for (final language in ['he', 'ru']) {
    testWidgets(
      'compact $language layouts support 180 percent text across pages',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(360, 740);
        tester.platformDispatcher.textScaleFactorTestValue = 1.8;
        addTearDown(tester.view.reset);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        await tester.pumpWidget(
          MaterialApp(
            locale: Locale(language),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            theme: observatoryTheme(),
            home: const Observatory(
              interpretationClient: fixtureInterpretations,
              loadDecks: _loadDecks,
            ),
          ),
        );
        await tester.pumpAndSettle();
        final context = tester.element(find.byType(Observatory));
        expect(
          Directionality.of(context),
          language == 'he' ? TextDirection.rtl : TextDirection.ltr,
        );
        expect(find.text(context.tr('Choose your deck')), findsOneWidget);
        for (final (tab, heading) in [
          ('library', 'Card gallery'),
          ('guide', 'Read the position'),
          ('table', 'Choose your spread'),
        ]) {
          await tester.tap(find.byKey(ValueKey('nav-$tab')));
          await tester.pumpAndSettle();
          expect(find.text(context.tr(heading)), findsOneWidget);
        }
        expect(tester.takeException(), isNull);
      },
    );
  }
  testWidgets('Tab and Enter can begin a reading without a pointer', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1200, 800);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      const ObservatoryApp(
        interpretationClient: fixtureInterpretations,
        loadDecks: _loadDecks,
      ),
    );
    await tester.pumpAndSettle();
    const key = ValueKey('begin-reading');
    bool focused() =>
        FocusManager.instance.primaryFocus?.context
            ?.findAncestorWidgetOfExactType<FilledButton>()
            ?.key ==
        key;
    for (int i = 0; i < 30 && !focused(); i++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();
    }
    expect(focused(), isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(find.text('Choose a card'), findsOneWidget);
  });

  testWidgets(
    'observatory layout places the deck fan beside desktop controls and above phone controls',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(1180, 760);
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        const ObservatoryApp(
          interpretationClient: fixtureInterpretations,
          loadDecks: _loadDecks,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('observatory-sky')), findsOneWidget);
      final fan = find.byType(DeckPortrait);
      final start = find.byKey(const ValueKey('begin-reading'));
      expect(
        tester.getRect(fan).left,
        greaterThan(tester.getRect(start).right),
      );
      tester.view.physicalSize = const Size(390, 820);
      await tester.pumpAndSettle();
      expect(
        tester.getRect(fan).bottom,
        lessThanOrEqualTo(tester.getRect(start).top),
      );
    },
  );

  testWidgets('a reader can draw, reveal and interpret a single card', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1200, 850);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      const ObservatoryApp(
        interpretationClient: fixtureInterpretations,
        loadDecks: _loadDecks,
      ),
    );
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
    await tester.pumpWidget(
      const ObservatoryApp(
        interpretationClient: fixtureInterpretations,
        loadDecks: _loadDecks,
      ),
    );
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
    await tester.pumpWidget(
      const ObservatoryApp(
        interpretationClient: fixtureInterpretations,
        loadDecks: _loadDecks,
      ),
    );
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
      await tester.pumpWidget(
        const ObservatoryApp(
          interpretationClient: fixtureInterpretations,
          loadDecks: _loadDecks,
        ),
      );
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
