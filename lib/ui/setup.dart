import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../localized_reading.dart';
import '../reading.dart';
import '../src/card_art_bundle.dart';
import '../strings.dart';
import 'style.dart';

class ReadingSetup extends StatelessWidget {
  const ReadingSetup({
    super.key,
    required this.decks,
    required this.selected,
    required this.spread,
    required this.reversals,
    required this.online,
    required this.question,
    required this.onOnline,
    required this.onDeck,
    required this.onSpread,
    required this.onReversals,
    required this.onStart,
  });
  final List<TarotDeck> decks;
  final TarotDeck selected;
  final SpreadType spread;
  final bool reversals;
  final bool online;
  final TextEditingController question;
  final ValueChanged<bool> onOnline;
  final ValueChanged<TarotDeck> onDeck;
  final ValueChanged<SpreadType> onSpread;
  final ValueChanged<bool> onReversals;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final scale = MediaQuery.textScalerOf(context).scale(16) / 16;
      final compact = box.maxWidth < 730 * scale.clamp(1.0, 1.65);
      final panelWidth = math.min(540.0, box.maxWidth * .45);
      final header = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            header: true,
            child: Text(
              context.tr('Reading table'),
              style: display(compact ? 30 : 50),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            '${context.deckName(selected)} · ${context.tr(spread.title)}',
            style: display(compact ? 17 : 23)
                .copyWith(fontWeight: FontWeight.w400, letterSpacing: 0),
          ),
        ],
      );
      final panel = SkyPanel(
        child: Padding(
          padding: EdgeInsets.all(compact ? 14 : 22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                context.tr('Choose your deck'),
                style: display(compact ? 19 : 23),
              ),
              const SizedBox(height: 11),
              LayoutBuilder(
                builder: (context, inner) {
                  final stacked = compact || inner.maxWidth < 300 * scale;
                  final tiles = [
                    for (final (i, deck) in decks.indexed)
                      DeckOption(
                        key: ValueKey('select-deck-${deck.id}'),
                        deck: deck,
                        selected: selected.id == deck.id,
                        index: i,
                        onTap: () => onDeck(deck),
                        compact: stacked,
                      ),
                  ];
                  return stacked
                      ? Column(
                          children: [
                            for (final (i, tile) in tiles.indexed)
                              Padding(
                                padding: EdgeInsets.only(
                                  bottom: i == tiles.length - 1 ? 0 : 5,
                                ),
                                child: tile,
                              ),
                          ],
                        )
                      : Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final tile in tiles)
                              SizedBox(
                                width: (inner.maxWidth - 16) / 3,
                                child: tile,
                              ),
                          ],
                        );
                },
              ),
              SizedBox(height: compact ? 15 : 22),
              Text(
                context.tr('Choose your spread'),
                style: display(compact ? 19 : 23),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final item in SpreadType.values)
                    ChoiceChip(
                      key: ValueKey('spread-${item.name}'),
                      label: Text(context.tr(item.title)),
                      selected: spread == item,
                      showCheckmark: false,
                      tooltip: context.tr(switch (item) {
                        SpreadType.one =>
                          'One card brings a single question into focus.',
                        SpreadType.three => 'Read three positions together to explore how their meanings relate.',
                        SpreadType.celticCross => 'Explore a question in depth through ten connected positions.',
                      }),
                      onSelected: (_) => onSpread(item),
                      backgroundColor: const Color(0x900c1821),
                      selectedColor: const Color(0xff51405e),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      side: BorderSide(
                        color: spread == item ? accent : line,
                        width: spread == item ? 1.6 : 1,
                      ),
                      labelStyle: TextStyle(
                        color: ivory,
                        fontSize: compact ? 12 : 14,
                        fontWeight: FontWeight.w500,
                      ),
                      labelPadding: EdgeInsets.symmetric(
                        horizontal: compact ? 3 : 4,
                      ),
                      padding: EdgeInsets.symmetric(
                        horizontal: compact ? 3 : 6,
                        vertical: compact ? 1 : 4,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              SwitchListTile.adaptive(
                key: const ValueKey('reversals'),
                value: reversals,
                onChanged: onReversals,
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
                title: Text(
                  context.tr('Include reversed cards'),
                  style: const TextStyle(fontSize: 15),
                ),
              ),
              const Divider(height: 22),
              SwitchListTile.adaptive(
                key: const ValueKey('gemini-reading'),
                value: online,
                onChanged: onOnline,
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
                title: Text(context.tr('Read with Gemini 4 Carbon')),
                subtitle: Text(
                  context.tr(
                    online
                        ? 'Your optional question and revealed cards are sent to Google Gemini.'
                        : 'Offline reading uses the meanings stored on this device.',
                  ),
                ),
              ),
              if (online) ...[
                const SizedBox(height: 10),
                TextField(
                  key: const ValueKey('reading-question'),
                  controller: question,
                  minLines: 1,
                  maxLines: 3,
                  maxLength: 500,
                  textInputAction: TextInputAction.done,
                  decoration: InputDecoration(
                    labelText: context.tr('Your question (optional)'),
                    border: const OutlineInputBorder(),
                  ),
                ),
              ],
              const SizedBox(height: 10),
              KeyedSubtree(
                key: const ValueKey('begin-configured'),
                child: FilledButton(
                  key: const ValueKey('begin-reading'),
                  onPressed: onStart,
                  child: Text(context.tr('Begin reading')),
                ),
              ),
            ],
          ),
        ),
      );
      final fanHeight = compact
          ? math.min(box.maxWidth * .57, 223.0)
          : math.min((box.maxWidth - panelWidth - 24) / 1.56, 440.0);
      final portrait = DeckPortrait(selected, height: fanHeight);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          header,
          SizedBox(height: compact ? 8 : 24),
          if (compact) ...[
            Center(child: portrait),
            const SizedBox(height: 9),
            panel,
          ] else
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(width: panelWidth, child: panel),
                const SizedBox(width: 24),
                Expanded(child: Center(child: portrait)),
              ],
            ),
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
    this.compact = true,
  });
  final TarotDeck deck;
  final bool selected, compact;
  final int index;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final previewId = const [
      'moon',
      'pentacles_ace',
      'wheel_of_fortune',
    ][index % 3];
    final preview = deck.cards.firstWhere(
      (c) => c.id == previewId,
      orElse: () => deck.cards.first,
    );
    final thumb = ClipRRect(
      borderRadius: BorderRadius.circular(5),
      child: Image.asset(
        preview.imageAsset,
        bundle: CardArtBundle.instance,
        excludeFromSemantics: true,
        fit: BoxFit.cover,
        alignment: const Alignment(0, -.36),
        errorBuilder: (_, _, _) => const Center(
          child: Icon(Icons.broken_image_outlined, color: muted),
        ),
      ),
    );
    final name = Text(
      context.deckName(deck),
      textAlign: compact ? TextAlign.start : TextAlign.center,
      style: TextStyle(
        color: ink,
        fontSize: compact ? 14 : 13,
        fontWeight: FontWeight.w500,
      ),
    );
    final check = Icon(
      selected ? Icons.check_circle : Icons.radio_button_unchecked,
      size: 19,
      color: selected ? accent : muted,
    );
    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: selected ? const Color(0xec302a40) : const Color(0xe8101c26),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(9),
          side: BorderSide(
            color: selected ? accent : line,
            width: selected ? 2 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: compact
              ? Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 5,
                  ),
                  child: Row(
                    children: [
                      SizedBox(width: 47, height: 36, child: thumb),
                      const SizedBox(width: 10),
                      Expanded(child: name),
                      const SizedBox(width: 5),
                      check,
                    ],
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.all(4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Stack(
                        children: [
                          AspectRatio(aspectRatio: 1.22, child: thumb),
                          if (selected)
                            PositionedDirectional(
                              top: 3,
                              end: 3,
                              child: DecoratedBox(
                                decoration: const BoxDecoration(
                                  color: night,
                                  shape: BoxShape.circle,
                                ),
                                child: check,
                              ),
                            ),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 8,
                          horizontal: 2,
                        ),
                        child: name,
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}
