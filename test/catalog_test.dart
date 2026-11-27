import 'package:arcana_observatory/reading.dart';
import 'package:arcana_observatory/src/card_art_bundle.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'every deck has the complete tarot identities, usable art, and lessons',
    () async {
      final decks = await DeckCatalog.load();
      expect(decks.map((d) => d.id), ['waite_smith', 'marseille', 'celestial']);
      final art = <String>{};
      for (final deck in decks) {
        expect(deck.cards.length, 78);
        expect(
          deck.cards.map((c) => c.id).toSet(),
          decks.first.cards.map((c) => c.id).toSet(),
        );
        for (final card in deck.cards) {
          expect(art.add(card.imageAsset), isTrue);
          final bytes = await CardArtBundle.instance.load(card.imageAsset);
          expect(
            String.fromCharCodes(
              bytes.buffer.asUint8List(bytes.offsetInBytes + 8, 4),
            ),
            'WEBP',
            reason: card.imageAsset,
          );
          expect(card.symbolism.trim(), isNotEmpty);
          expect(card.meaning.trim(), isNotEmpty);
          expect(card.reversed.trim(), isNotEmpty);
        }
        for (final spread in SpreadType.values) {
          final reading = ReadingSession.start(deck, spread);
          for (var index = 0; index < spread.positions.length; index++) {
            reading.pick(0);
            reading.reveal(index);
          }
          expect(reading.complete, isTrue);
        }
      }
      expect(art.length, 234);
    },
  );
}
