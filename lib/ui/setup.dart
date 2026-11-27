import 'package:flutter/material.dart';

import '../reading.dart';
import 'style.dart';

class ReadingSetup extends StatelessWidget {
  const ReadingSetup({
    super.key,
    required this.decks,
    required this.selected,
    required this.spread,
    required this.reversals,
    required this.onDeck,
    required this.onSpread,
    required this.onReversals,
    required this.onStart,
  });
  final List<TarotDeck> decks;
  final TarotDeck selected;
  final SpreadType spread;
  final bool reversals;
  final ValueChanged<TarotDeck> onDeck;
  final ValueChanged<SpreadType> onSpread;
  final ValueChanged<bool> onReversals;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final narrow = constraints.maxWidth < 720;
      final header = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            selected.name.toUpperCase(),
            style: const TextStyle(
              color: brass,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 2.2,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'The reading table',
            style: display(narrow ? 43 : 58, color: ivory),
          ),
          const SizedBox(height: 10),
          Text(
            '${spread.title}  ·  ${reversals ? 'Upright & reversed' : 'Upright cards'}',
            style: const TextStyle(color: Color(0xffe0e4d9), fontSize: 15),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            key: const ValueKey('begin-reading'),
            onPressed: onStart,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xffe5c99a),
              foregroundColor: night,
            ),
            icon: const Icon(Icons.auto_awesome, size: 17),
            label: const Text('Begin reading'),
          ),
        ],
      );
      final deckRow = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Choose your deck', style: display(32)),
          const SizedBox(height: 13),
          LayoutBuilder(
            builder: (context, box) {
              final cards = [
                for (final (index, deck) in decks.indexed)
                  DeckOption(
                    key: ValueKey('select-deck-${deck.id}'),
                    deck: deck,
                    selected: selected.id == deck.id,
                    index: index,
                    onTap: () => onDeck(deck),
                  ),
              ];
              final count = box.maxWidth < 470
                  ? 1
                  : box.maxWidth < 650
                  ? 2
                  : 3;
              return Wrap(
                runSpacing: 10,
                spacing: 10,
                children: [
                  for (final card in cards)
                    SizedBox(
                      width: (box.maxWidth - 10 * (count - 1)) / count,
                      child: card,
                    ),
                ],
              );
            },
          ),
        ],
      );
      final controls = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Choose your spread', style: display(32)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              for (final v in SpreadType.values)
                ChoiceChip(
                  key: ValueKey('spread-${v.name}'),
                  selected: spread == v,
                  avatar: Icon(switch (v) {
                    SpreadType.one => Icons.crop_portrait,
                    SpreadType.three => Icons.view_week_outlined,
                    SpreadType.celticCross => Icons.dashboard_outlined,
                  }, size: 17),
                  label: Text(v.title),
                  onSelected: (_) => onSpread(v),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(switch (spread) {
            SpreadType.one => 'One card brings a single question into focus.',
            SpreadType.three => 'Read three positions together to explore how their meanings relate.',
            SpreadType.celticCross =>
              'Explore a question in depth through ten connected positions.',
          }, style: const TextStyle(color: muted, height: 1.5)),
          const SizedBox(height: 9),
          SwitchListTile.adaptive(
            key: const ValueKey('reversals'),
            value: reversals,
            onChanged: onReversals,
            contentPadding: EdgeInsets.zero,
            title: const Text('Include reversed cards'),
            subtitle: const Text(
              'A card can appear upside down with its own interpretation.',
            ),
          ),
        ],
      );
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SkyPanel(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: narrow ? 22 : 40,
                vertical: narrow ? 23 : 25,
              ),
              child: narrow
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        header,
                        Center(child: DeckPortrait(selected, height: 160)),
                      ],
                    )
                  : Row(
                      children: [
                        Expanded(child: header),
                        Expanded(
                          child: Center(
                            child: DeckPortrait(selected, height: 265),
                          ),
                        ),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 24),
          deckRow,
          const SizedBox(height: 22),
          const Divider(height: 1),
          const SizedBox(height: 20),
          controls,
          if (narrow) ...[
            const SizedBox(height: 12),
            FilledButton.icon(
              key: const ValueKey('begin-configured'),
              onPressed: onStart,
              icon: const Icon(Icons.auto_awesome, size: 17),
              label: const Text('Begin this spread'),
            ),
          ],
        ],
      );
    },
  );
}

class DeckOption extends StatelessWidget {
  const DeckOption({
    super.key,
    required this.deck,
    required this.selected,
    required this.index,
    required this.onTap,
  });
  final TarotDeck deck;
  final bool selected;
  final int index;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tone = const [
      Color(0xff5d5142),
      Color(0xff67514c),
      Color(0xff304956),
    ][index % 3];
    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: selected ? const Color(0xfff1ecdd) : ivory,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(
            color: selected ? accent : line,
            width: selected ? 1.6 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(9),
            child: Row(
              children: [
                ExcludeSemantics(
                  child: Container(
                    height: 73,
                    width: 58,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: tone,
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Transform.rotate(
                      angle: -.06,
                      child: SizedBox(
                        height: 60,
                        child: CardArt(deck.cards[17 % deck.cards.length]),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(deck.name, style: display(22)),
                      const SizedBox(height: 4),
                      Text(
                        '${deck.cards.length} cards',
                        style: const TextStyle(fontSize: 12, color: muted),
                      ),
                    ],
                  ),
                ),
                Icon(
                  selected ? Icons.check_circle : Icons.circle_outlined,
                  size: 17,
                  color: selected ? accent : line,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
