import 'dart:convert';

import 'package:flutter/services.dart';

class TarotCard {
  const TarotCard({
    required this.id,
    required this.title,
    this.number,
    required this.imageAsset,
    required this.symbolism,
    required this.meaning,
    required this.reversed,
  });

  final String id;
  final String title;
  final String? number;
  final String imageAsset;
  final String symbolism;
  final String meaning;
  final String reversed;
}

class TarotDeck {
  TarotDeck({
    required this.id,
    required this.name,
    required this.credit,
    required this.source,
    required this.rights,
    required List<TarotCard> cards,
  }) : cards = List.unmodifiable(cards);

  final String id;
  final String name;
  final String credit;
  final String source;
  final String rights;
  final List<TarotCard> cards;

  (String, String)? familyLesson(TarotCard card) {
    if (DeckCatalog._majorIds.contains(card.id)) {
      return (
        'Major Arcana · ${card.number ?? 'Unnumbered'}',
        'Read this image as a turning point and ask what larger change its central figure or event might represent.',
      );
    }
    final parts = card.id.split('_');
    if (parts.length != 2) return null;
    final marseille = id == 'marseille';
    final family = switch (parts.first) {
      'cups' => (
        'Cups',
        'A cup holds, offers or spills its contents, giving you a way to explore how feelings pass between people.',
      ),
      'swords' => (
        'Swords',
        'Read the blade as a tool of judgment and ask what needs to be separated, questioned or decided.',
      ),
      'wands' => (
        marseille ? 'Batons' : 'Wands',
        'A staff can support a traveler or direct a movement, so look for where effort is being put to work.',
      ),
      'pentacles' => (
        marseille ? 'Coins' : 'Pentacles',
        'Read the disc as a resource and ask who holds, shares or cultivates something of practical value.',
      ),
      _ => null,
    };
    if (family == null) return null;
    final (suit, lesson) = family;
    final rank = parts.last;
    final rankLabel =
        card.number ?? '${rank[0].toUpperCase()}${rank.substring(1)} (court)';
    return ('Minor Arcana · $suit · $rankLabel', lesson);
  }
}

/// Each tradition supplies its own labels, art and guidance for the same tarot identities.
class DeckCatalog {
  static const ids = ['waite_smith', 'marseille', 'celestial'];
  static const _majorIds = {
    'fool',
    'magician',
    'high_priestess',
    'empress',
    'emperor',
    'hierophant',
    'lovers',
    'chariot',
    'strength',
    'hermit',
    'wheel_of_fortune',
    'justice',
    'hanged_man',
    'death',
    'temperance',
    'devil',
    'tower',
    'star',
    'moon',
    'sun',
    'judgement',
    'world',
  };
  static const _suits = ['cups', 'swords', 'wands', 'pentacles'];
  static const _ranks = [
    'ace',
    '2',
    '3',
    '4',
    '5',
    '6',
    '7',
    '8',
    '9',
    '10',
    'page',
    'knight',
    'queen',
    'king',
  ];
  static final _identities = {
    ..._majorIds,
    for (final suit in _suits)
      for (final rank in _ranks) '${suit}_$rank',
  };

  static Future<List<TarotDeck>> load({AssetBundle? bundle}) async {
    final assets = bundle ?? rootBundle;
    return Future.wait(
      ids.map((id) async {
        final path = 'assets/decks/$id';
        final data = jsonDecode(await assets.loadString('$path/catalog.json'));
        if (data is! Map<String, dynamic> ||
            data['id'] != id ||
            data['cards'] is! List) {
          throw FormatException('Invalid deck catalog: $id');
        }
        final cards = <TarotCard>[];
        final missing = {..._identities};
        for (final item in data['cards'] as List) {
          if (item is! Map<String, dynamic> || !missing.remove(item['id'])) {
            throw FormatException('Duplicate or unknown card in $id');
          }
          final image = _text(item, 'image');
          if (!RegExp(r'^[a-zA-Z0-9_-]+\.webp$').hasMatch(image)) {
            throw FormatException('Invalid card image in $id: $image');
          }
          cards.add(
            TarotCard(
              id: _text(item, 'id'),
              title: _text(item, 'title'),
              number: item['number'] as String?,
              imageAsset: '$path/$image',
              symbolism: _text(item, 'symbolism'),
              meaning: _text(item, 'meaning'),
              reversed: _text(item, 'reversed'),
            ),
          );
        }
        if (missing.isNotEmpty) {
          throw FormatException('Missing cards in $id: $missing');
        }
        return TarotDeck(
          id: id,
          name: _text(data, 'name'),
          credit: _text(data, 'credit'),
          source: _text(data, 'source'),
          rights: _text(data, 'rights'),
          cards: cards,
        );
      }),
    );
  }

  static String _text(Map<String, dynamic> data, String key) {
    final value = data[key];
    if (value is! String || value.trim().isEmpty) {
      throw FormatException('Missing $key for ${data['id']}');
    }
    return value;
  }
}
