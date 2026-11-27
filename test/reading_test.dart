import 'dart:math';

import 'package:arcana_observatory/reading.dart';
import 'package:flutter_test/flutter_test.dart';

TarotDeck sampleDeck() => TarotDeck(
  id: 'test',
  name: 'Test deck',
  credit: 'Credit',
  source: 'Source',
  rights: 'Rights',
  cards: List.generate(
    78,
    (index) => TarotCard(
      id: 'c$index',
      title: 'Card $index',
      imageAsset: 'card$index.webp',
      symbolism: 'A star.',
      meaning: 'Growth.',
      reversed: 'Pause.',
    ),
  ),
);

void main() {
  for (final spread in SpreadType.values) {
    test('draws and reveals every position of ${spread.name} exactly once', () {
      final deck = sampleDeck();
      final session = ReadingSession.start(deck, spread, random: Random(7));
      final seen = <String>{};
      for (final position in spread.positions) {
        final drawn = session.pick(session.remainingCount - 1);
        expect(seen.add(drawn.card.id), isTrue);
        expect(drawn.position, position);
        expect(drawn.isReversed, isFalse);
        expect(drawn.isRevealed, isFalse);
        expect(() => session.pick(0), throwsStateError);
        session.reveal(session.draws.length - 1);
        session.reveal(session.draws.length - 1);
        expect(session.draws.last.isRevealed, isTrue);
      }
      expect(session.complete, isTrue);
      expect(() => session.pick(0), throwsStateError);
      expect(session.remainingCount, 78 - spread.positions.length);
      expect(deck.cards.length, 78);
    });
  }
  test('shuffle is repeatable with a seed and supports both orientations', () {
    List<(String, bool)> deal() {
      final session = ReadingSession.start(
        sampleDeck(),
        SpreadType.celticCross,
        reversals: true,
        random: Random(32),
      );
      for (var i = 0; i < 10; i++) {
        session.pick(0);
        session.reveal(i);
      }
      return [for (final d in session.draws) (d.card.id, d.isReversed)];
    }

    expect(deal(), deal());
    expect(deal().map((entry) => entry.$2).toSet(), {true, false});
  });
  test('rejects invalid choices without consuming a card', () {
    final session = ReadingSession.start(sampleDeck(), SpreadType.one);
    expect(() => session.pick(78), throwsRangeError);
    expect(() => session.reveal(0), throwsRangeError);
    expect(session.remainingCount, 78);
  });
}
