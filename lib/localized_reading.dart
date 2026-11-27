import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'reading.dart';
import 'strings.dart';

class _CardWords {
  const _CardWords(this.title, this.symbolism, this.meaning, this.reversed);
  final String title, symbolism, meaning, reversed;
}

String _required(Map<String, dynamic> data, String field, String location) {
  final value = data[field];
  if (value is! String || value.trim().isEmpty) {
    throw FormatException('Missing $field in $location');
  }
  return value;
}

class _DeckWords {
  const _DeckWords(this.name, this.credit, this.rights, this.cards);
  final String name, credit, rights;
  final Map<String, _CardWords> cards;

  static Future<_DeckWords> load(
    AssetBundle bundle,
    String id,
    String lang,
  ) async {
    final path = 'assets/decks/$id/$lang.json';
    final data = jsonDecode(await bundle.loadString(path));
    if (data is! Map<String, dynamic> ||
        data['cards'] is! Map<String, dynamic>) {
      throw FormatException('Invalid translated catalog in $path');
    }
    final cards = <String, _CardWords>{};
    for (final entry in (data['cards'] as Map<String, dynamic>).entries) {
      final fields = entry.value;
      final location = '$path (${entry.key})';
      if (fields is! Map<String, dynamic>) {
        throw FormatException('Invalid card in $location');
      }
      cards[entry.key] = _CardWords(
        _required(fields, 'title', location),
        _required(fields, 'symbolism', location),
        _required(fields, 'meaning', location),
        _required(fields, 'reversed', location),
      );
    }
    return _DeckWords(
      _required(data, 'name', path),
      _required(data, 'credit', path),
      _required(data, 'rights', path),
      cards,
    );
  }
}

/// A locale changes the text shown for a reading, independently of its shuffled cards.
class ReadingText {
  ReadingText._(this._decks);
  final Map<String, _DeckWords> _decks;
  final _localizedDecks = Expando<TarotDeck>();
  static const delegate = _ReadingDelegate();

  static Future<ReadingText> _load(
    Iterable<String> ids,
    Locale locale,
    AssetBundle assets,
  ) async {
    if (locale.languageCode == 'en') return ReadingText._({});
    final entries = await Future.wait(
      ids.map(
        (id) async => MapEntry(
          id,
          await _DeckWords.load(assets, id, locale.languageCode),
        ),
      ),
    );
    return ReadingText._(Map.fromEntries(entries));
  }

  TarotCard _card(TarotDeck deck, TarotCard card) {
    final overlay = _decks[deck.id];
    if (overlay == null) return card;
    final words = overlay.cards[card.id];
    if (words == null) {
      throw FormatException('Missing translation for ${deck.id}/${card.id}');
    }
    return TarotCard(
      id: card.id,
      title: words.title,
      number: card.number,
      imageAsset: card.imageAsset,
      symbolism: words.symbolism,
      meaning: words.meaning,
      reversed: words.reversed,
    );
  }

  TarotDeck _deck(TarotDeck deck) {
    final words = _decks[deck.id];
    if (words == null) return deck;
    return _localizedDecks[deck] ??= TarotDeck(
      id: deck.id,
      name: words.name,
      credit: words.credit,
      source: deck.source,
      rights: words.rights,
      cards: [for (final card in deck.cards) _card(deck, card)],
    );
  }
}

class _ReadingDelegate extends LocalizationsDelegate<ReadingText> {
  const _ReadingDelegate();
  @override
  bool isSupported(Locale locale) =>
      const {'en', 'he', 'ru'}.contains(locale.languageCode);
  @override
  Future<ReadingText> load(Locale locale) =>
      ReadingText._load(DeckCatalog.ids, locale, rootBundle);
  @override
  bool shouldReload(_ReadingDelegate old) => false;
}

Future<List<TarotDeck>> localizeDecks(
  List<TarotDeck> base,
  Locale locale, {
  AssetBundle? bundle,
}) async {
  final text = await ReadingText._load(
    base.map((d) => d.id),
    locale,
    bundle ?? rootBundle,
  );
  return base.map(text._deck).toList(growable: false);
}

extension LocalizedReading on BuildContext {
  ReadingText? get _reading => Localizations.of<ReadingText>(this, ReadingText);
  String deckName(TarotDeck deck) =>
      _reading?._decks[deck.id]?.name ?? deck.name;
  TarotDeck deckText(TarotDeck deck) => _reading?._deck(deck) ?? deck;
  TarotCard cardText(TarotDeck deck, TarotCard card) =>
      _reading?._card(deck, card) ?? card;

  (String, String)? familyText(TarotDeck deck, TarotCard card) {
    final family = deck.familyLesson(card);
    if (family == null) return null;
    final (label, lesson) = family;
    final parts = label.split(' · ');
    if (parts.length == 2) {
      return (
        tr('Major Arcana · {number}', {
          'number': card.number ?? tr('Unnumbered'),
        }),
        tr(lesson),
      );
    }
    final rank =
        card.number ??
        tr('{rank} (court)', {'rank': tr(parts.last.split(' (').first)});
    return (
      tr('Minor Arcana · {suit} · {rank}', {
        'suit': tr(parts[1]),
        'rank': rank,
      }),
      tr(lesson),
    );
  }
}
