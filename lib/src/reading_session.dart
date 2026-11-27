import 'dart:collection';
import 'dart:math';

import 'deck.dart';
import 'spread.dart';

class DrawnCard {
  DrawnCard._(this.card, this.position, this.isReversed);
  final TarotCard card;
  final SpreadPosition position;
  final bool isReversed;
  bool _isRevealed = false;
  bool get isRevealed => _isRevealed;
}

class ReadingSession {
  ReadingSession._(this.deck, this.spread, this.reversals, this._random)
    : _remaining = List.of(deck.cards)..shuffle(_random);

  factory ReadingSession.start(
    TarotDeck deck,
    SpreadType spread, {
    bool reversals = false,
    Random? random,
  }) {
    if (deck.cards.length < spread.positions.length) {
      throw ArgumentError('Deck has too few cards for ${spread.title}');
    }
    return ReadingSession._(deck, spread, reversals, random ?? Random());
  }

  final TarotDeck deck;
  final SpreadType spread;
  final bool reversals;
  final Random _random;
  final List<TarotCard> _remaining;
  final List<DrawnCard> _draws = [];
  UnmodifiableListView<DrawnCard> get draws => UnmodifiableListView(_draws);
  int get remainingCount => _remaining.length;
  bool get complete =>
      _draws.length == spread.positions.length && _draws.last.isRevealed;

  DrawnCard pick(int fanIndex) {
    if (_draws.length == spread.positions.length ||
        (_draws.isNotEmpty && !_draws.last.isRevealed)) {
      throw StateError('No open position for a new card');
    }
    final drawn = DrawnCard._(
      _remaining.removeAt(fanIndex),
      spread.positions[_draws.length],
      reversals && _random.nextBool(),
    );
    _draws.add(drawn);
    return drawn;
  }

  void reveal(int index) => _draws[index]._isRevealed = true;
}
