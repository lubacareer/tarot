import 'package:arcana_observatory/reading.dart';
import 'package:arcana_observatory/ui/library.dart';
import 'package:arcana_observatory/ui/reading_table.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'classification uses each catalog’s numbers, ranks and suit names',
    () async {
      final [waite, marseille, celestial] = await DeckCatalog.load();
      String label(TarotDeck deck, String id) => deck
          .familyLesson(deck.cards.singleWhere((card) => card.id == id))!
          .$1;
      expect(label(marseille, 'fool'), 'Major Arcana · Unnumbered');
      expect(label(waite, 'fool'), 'Major Arcana · 0');
      expect(label(marseille, 'justice'), 'Major Arcana · VIII');
      expect(label(waite, 'justice'), 'Major Arcana · XI');
      expect(label(marseille, 'strength'), 'Major Arcana · XI');
      expect(label(celestial, 'strength'), 'Major Arcana · VIII');
      expect(label(marseille, 'wands_3'), 'Minor Arcana · Batons · 3');
      expect(label(celestial, 'wands_3'), 'Minor Arcana · Wands · III');
      expect(
        label(marseille, 'pentacles_queen'),
        'Minor Arcana · Coins · Queen (court)',
      );
      expect(
        label(waite, 'pentacles_page'),
        'Minor Arcana · Pentacles · Page (court)',
      );
      for (final deck in [waite, marseille, celestial]) {
        for (final card in deck.cards) {
          expect(deck.familyLesson(card)!.$2, isNotEmpty, reason: card.id);
        }
      }
    },
  );

  testWidgets(
    'the same family lesson is visible in the library and after reveal',
    (tester) async {
      final decks = (await tester.runAsync(DeckCatalog.load))!;
      final source = decks.singleWhere((item) => item.id == 'marseille');
      final card = source.cards.singleWhere(
        (item) => item.id == 'pentacles_queen',
      );
      final deck = TarotDeck(
        id: source.id,
        name: source.name,
        credit: source.credit,
        source: source.source,
        rights: source.rights,
        cards: [card],
      );
      const label = 'Minor Arcana · Coins · Queen (court)';
      final lesson = deck.familyLesson(card)!.$2;
      Widget host(Widget child) => MaterialApp(
        home: Scaffold(body: SingleChildScrollView(child: child)),
      );
      await tester.pumpWidget(
        host(DeckLibrary(decks: [deck], selected: deck, onUse: (_) {})),
      );
      await tester.pumpAndSettle();
      final thumbnail = find.text(card.title);
      await tester.ensureVisible(thumbnail);
      await tester.tap(thumbnail);
      await tester.pumpAndSettle();
      expect(find.text(label), findsOneWidget);
      expect(find.text(lesson), findsOneWidget);
      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();
      final session = ReadingSession.start(deck, SpreadType.one)..pick(0);
      await tester.pumpWidget(
        host(ReadingTable(session: session, onNew: () {})),
      );
      await tester.pumpAndSettle();
      expect(find.text(label), findsNothing);
      final reveal = find.text('Reveal card');
      await tester.ensureVisible(reveal);
      await tester.tap(reveal);
      await tester.pumpAndSettle();
      expect(find.text(label), findsOneWidget);
      expect(find.text(lesson), findsOneWidget);
    },
  );
}
