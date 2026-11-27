import 'package:arcana_observatory/reading.dart';
import 'package:arcana_observatory/ui/library.dart';
import 'package:arcana_observatory/ui/reading_table.dart';
import 'package:arcana_observatory/ui/setup.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

TarotDeck _deck(int size, {String id = 'fixture'}) => TarotDeck(
  id: id,
  name: 'Test deck',
  credit: 'Test artist',
  rights: 'Test rights',
  source: 'Test source',
  cards: [
    for (var i = 0; i < size; i++)
      TarotCard(
        id: 'card-$i',
        title: 'Card $i',
        imageAsset: 'fixture.webp',
        symbolism: 'A star.',
        meaning: 'Hope.',
        reversed: 'Pause.',
      ),
  ],
);

Future<void> _show(WidgetTester tester, Widget body) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(body: SingleChildScrollView(child: body)),
    ),
  );
  await tester.pumpAndSettle();
}

IconButton _button(WidgetTester tester, String tooltip) =>
    tester.widget<IconButton>(
      find.byWidgetPredicate(
        (widget) => widget is IconButton && widget.tooltip == tooltip,
      ),
    );

Future<void> _activateTwice(WidgetTester tester, String tooltip) async {
  final callback = _button(tester, tooltip).onPressed!;
  callback();
  callback();
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
}

void main() {
  for (final (direction, startingPage) in [('Next', 0), ('Previous', 2)]) {
    testWidgets(
      'a queued $direction page cannot move the newly selected deck',
      (tester) async {
        final decks = [_deck(40), _deck(40, id: 'second')];
        await _show(
          tester,
          DeckLibrary(decks: decks, selected: decks.first, onUse: (_) {}),
        );
        for (var page = 0; page < startingPage; page++) {
          _button(tester, 'Next page').onPressed!();
          await tester.pumpAndSettle();
        }
        final queued = _button(tester, '$direction page').onPressed!;
        tester.widgetList<DeckOption>(find.byType(DeckOption)).last.onTap();
        queued();
        await tester.pumpAndSettle();
        expect(find.text('1–12 of 40'), findsOneWidget);
        expect(_button(tester, 'Previous page').onPressed, isNull);
      },
    );
  }

  testWidgets('a queued Next loses its authority after a card is picked', (
    tester,
  ) async {
    final session = ReadingSession.start(_deck(6), SpreadType.three);
    await _show(
      tester,
      ReadingTable(session: session, onNew: () {}, onComplete: () {}),
    );
    final stale = _button(tester, 'Next cards').onPressed!;
    tester.widget<InkWell>(find.byKey(const ValueKey('fan-card-0'))).onTap!();
    stale();
    await tester.pumpAndSettle();
    final reveal = find.byKey(const ValueKey('reveal-card'));
    await tester.ensureVisible(reveal);
    await tester.pumpAndSettle();
    await tester.tap(reveal);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const ValueKey('next-position')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('next-position')));
    await tester.pumpAndSettle();
    expect(find.text('1–5 of 5'), findsOneWidget);
    expect(find.byKey(const ValueKey('fan-card-4')), findsOneWidget);
    expect(_button(tester, 'Next cards').onPressed, isNull);
  });

  testWidgets('two fan Next activations stop on the final partial page', (
    tester,
  ) async {
    final session = ReadingSession.start(_deck(7), SpreadType.one);
    await _show(
      tester,
      ReadingTable(session: session, onNew: () {}, onComplete: () {}),
    );
    await _activateTwice(tester, 'Next cards');
    expect(find.text('6–7 of 7'), findsOneWidget);
    expect(_button(tester, 'Next cards').onPressed, isNull);
    expect(find.byKey(const ValueKey('fan-card-1')), findsOneWidget);
    await _activateTwice(tester, 'Previous cards');
    expect(find.text('1–5 of 7'), findsOneWidget);
    expect(_button(tester, 'Previous cards').onPressed, isNull);
  });

  testWidgets('multiple gallery page activations stay at valid boundaries', (
    tester,
  ) async {
    final deck = _deck(14);
    await _show(
      tester,
      DeckLibrary(decks: [deck], selected: deck, onUse: (_) {}),
    );
    await _activateTwice(tester, 'Next page');
    expect(find.text('13–14 of 14'), findsOneWidget);
    expect(find.text('Card 13'), findsOneWidget);
    expect(_button(tester, 'Next page').onPressed, isNull);
    await _activateTwice(tester, 'Previous page');
    expect(find.text('1–12 of 14'), findsOneWidget);
    expect(_button(tester, 'Previous page').onPressed, isNull);
  });
}
