import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../reading.dart';
import 'setup.dart';
import 'style.dart';

class DeckLibrary extends StatefulWidget {
  const DeckLibrary({
    super.key,
    required this.decks,
    required this.selected,
    required this.onUse,
  });
  final List<TarotDeck> decks;
  final TarotDeck selected;
  final ValueChanged<TarotDeck> onUse;
  @override
  State<DeckLibrary> createState() => _DeckLibraryState();
}

class _DeckLibraryState extends State<DeckLibrary> {
  late TarotDeck deck = widget.selected;
  int first = 0;
  static const pageSize = 12;

  Future<void> _inspect(TarotCard card) => showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(card.title, style: display(30)),
      content: SizedBox(
        width: 450,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: SizedBox(height: 210, child: CardArt(card))),
              const SizedBox(height: 15),
              for (final (title, text) in [
                ('Symbolism', card.symbolism),
                ('Upright', card.meaning),
                ('Reversed', card.reversed),
              ]) ...[
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 3),
                Text(text, style: const TextStyle(height: 1.45)),
                const SizedBox(height: 10),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final columns = math
          .max(1, (constraints.maxWidth / 250).floor())
          .clamp(1, 3);
      final end = math.min(first + pageSize, deck.cards.length);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Deck library', style: display(44)),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: [
              for (final (index, item) in widget.decks.indexed)
                SizedBox(
                  width: (constraints.maxWidth - (columns - 1) * 10) / columns,
                  child: DeckOption(
                    index: index,
                    deck: item,
                    selected: deck.id == item.id,
                    onTap: () => setState(() {
                      deck = item;
                      first = 0;
                    }),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 24),
          Text(deck.name, style: display(33)),
          const SizedBox(height: 7),
          Text(deck.credit, style: const TextStyle(height: 1.5)),
          const SizedBox(height: 3),
          Text(deck.rights, style: const TextStyle(color: muted, height: 1.5)),
          const SizedBox(height: 4),
          SelectableText(
            deck.source,
            style: const TextStyle(fontSize: 12, color: muted),
          ),
          const SizedBox(height: 10),
          FilledButton.icon(
            onPressed: () => widget.onUse(deck),
            label: const Text('Use this deck'),
            icon: const Icon(Icons.style_outlined, size: 17),
          ),
          const SizedBox(height: 18),
          const Divider(),
          const SizedBox(height: 7),
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 18,
            children: [
              Text('Card gallery', style: display(29)),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: 'Previous page',
                    onPressed: first == 0
                        ? null
                        : () => setState(() => first -= pageSize),
                    icon: const Icon(Icons.chevron_left),
                  ),
                  Text(
                    '${first + 1}–$end of ${deck.cards.length}',
                    style: const TextStyle(color: muted),
                  ),
                  IconButton(
                    tooltip: 'Next page',
                    onPressed: end >= deck.cards.length
                        ? null
                        : () => setState(() => first += pageSize),
                    icon: const Icon(Icons.chevron_right),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          LayoutBuilder(
            builder: (context, box) {
              final count = math
                  .max(2, (box.maxWidth / 118).floor())
                  .clamp(2, 8);
              return Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (final card in deck.cards.sublist(first, end))
                    SizedBox(
                      width: (box.maxWidth - (count - 1) * 10) / count,
                      child: Material(
                        color: ivory,
                        shape: RoundedRectangleBorder(
                          side: const BorderSide(color: line),
                          borderRadius: BorderRadius.circular(7),
                        ),
                        child: InkWell(
                          onTap: () => _inspect(card),
                          child: Padding(
                            padding: const EdgeInsets.all(7),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                ExcludeSemantics(child: CardArt(card)),
                                const SizedBox(height: 7),
                                Text(
                                  card.title,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      );
    },
  );
}

class FieldGuide extends StatelessWidget {
  const FieldGuide({super.key});

  static const lessons = <(String, String)>[
    (
      'Ask a question',
      'Frame a question that leaves room for reflection. “What could help me approach this decision?” gives each card a role in exploring your choices.',
    ),
    (
      'Notice the picture',
      'Name one visible detail before opening the meaning. Notice where a figure looks, what they carry, or how a repeated suit fills the card. In The Star, vessels pouring water can bring renewal to mind.',
    ),
    (
      'Read the position',
      'A spread gives each card a job. In the Past position, The Star might recall a time when hope returned. In the Present position, the same image can invite you to notice what sustains you today.',
    ),
    (
      'Explore a reversal',
      'Enable reversed cards to include upside-down draws. Compare the upright idea with the reversed interpretation. Consider whether the image suggests a delay, a private experience, or a different direction.',
    ),
    (
      'Connect your cards',
      'Read the cards in spread order. Look for a shared color, suit, gesture, or idea. Describe how that thread changes from one position to the next and name one small action you want to try.',
    ),
  ];

  Future<void> _license(BuildContext context, String asset) async {
    final title = asset == 'LICENSE' ? 'Software license' : 'Artwork credits';
    late String text;
    try {
      text = await rootBundle.loadString(asset);
    } on FlutterError {
      text = 'This license file could not be opened.';
    }
    if (!context.mounted) return;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: SizedBox(
          width: 550,
          child: SingleChildScrollView(child: SelectableText(text)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.topLeft,
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 850),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Field guide', style: display(44)),
          const SizedBox(height: 8),
          const Text(
            'Learn to connect the imagery, position, and meaning of each card.',
            style: TextStyle(color: muted, fontSize: 16),
          ),
          const SizedBox(height: 16),
          for (final (i, lesson) in lessons.indexed)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: ivory,
                border: Border.all(color: line),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ExpansionTile(
                key: PageStorageKey(lesson.$1),
                initiallyExpanded: i == 0,
                shape: const RoundedRectangleBorder(),
                collapsedShape: const RoundedRectangleBorder(),
                leading: Icon(
                  [
                    Icons.question_mark,
                    Icons.visibility_outlined,
                    Icons.dashboard_outlined,
                    Icons.flip,
                    Icons.hub_outlined,
                  ][i],
                  color: accent,
                ),
                title: Text(
                  lesson.$1,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                childrenPadding: const EdgeInsets.fromLTRB(18, 0, 18, 17),
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      lesson.$2,
                      style: const TextStyle(height: 1.55),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 18),
          Text('Credits & licenses', style: display(28)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            children: [
              TextButton(
                onPressed: () => _license(context, 'ARTWORK-LICENSE.md'),
                child: const Text('Artwork credits'),
              ),
              TextButton(
                onPressed: () => _license(context, 'LICENSE'),
                child: const Text('Software license'),
              ),
              TextButton(
                onPressed: () => showLicensePage(
                  context: context,
                  applicationName: 'Arcana Observatory',
                ),
                child: const Text('Open-source libraries'),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}
