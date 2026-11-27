import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../reading.dart';
import '../strings.dart';
import '../localized_reading.dart';
import 'style.dart';

class ReadingTable extends StatefulWidget {
  const ReadingTable({
    super.key,
    required this.session,
    required this.onNew,
    required this.onComplete,
  });
  final ReadingSession session;
  final VoidCallback onNew;
  final VoidCallback onComplete;
  @override
  State<ReadingTable> createState() => _ReadingTableState();
}

class _ReadingTableState extends State<ReadingTable> {
  int offset = 0;
  int? inspected;
  bool next = false;
  ReadingSession get session => widget.session;
  Duration get duration => MediaQuery.disableAnimationsOf(context)
      ? Duration.zero
      : const Duration(milliseconds: 420);
  void _showStage(VoidCallback update) {
    setState(update);
    Scrollable.ensureVisible(
      context,
      duration: duration,
      curve: Curves.easeOut,
    );
  }

  void _pick(int index) {
    if (session.complete ||
        (session.draws.isNotEmpty && !session.draws.last.isRevealed)) {
      return;
    }
    setState(() {
      session.pick(index);
      inspected = null;
      offset = 0;
      next = false;
    });
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, size) => _layout(context, size.maxWidth),
  );

  Widget _layout(BuildContext context, double width) {
    final draws = session.draws;
    final renderedOffset = offset;
    final renderedCount = session.remainingCount;
    void turnPage(int target) {
      if (offset != renderedOffset ||
          session.remainingCount != renderedCount ||
          target < 0 ||
          target >= session.remainingCount) {
        return;
      }
      setState(() => offset = target);
    }

    final nextOffset = offset + 5;
    final previousOffset = math.max(0, offset - 5);
    final unseen = draws.isNotEmpty && !draws.last.isRevealed;
    final index = inspected ?? (draws.length - 1);
    final DrawnCard? viewing = index >= 0 && !next ? draws[index] : null;
    final choosing = viewing == null;
    final card = viewing == null
        ? null
        : context.cardText(session.deck, viewing.card);
    final spread = session.spread;
    final position = choosing
        ? spread.positions[draws.length]
        : viewing.position;
    final number = choosing ? draws.length + 1 : index + 1;
    final narrow = width < 780;
    final heading = choosing
        ? context.tr('Choose a card')
        : !viewing.isRevealed
        ? context.tr('Turn your card')
        : card!.title;
    final stage = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          context.tr('Position {number} of {total} · {position}', {
            'number': number,
            'total': spread.positions.length,
            'position': context.tr(position.title),
          }).toUpperCase(),
          textAlign: TextAlign.center,
          style: smallCaps.copyWith(color: brass),
        ),
        const SizedBox(height: 7),
        Semantics(
          header: true,
          liveRegion: true,
          child: Text(
            heading,
            style: display(narrow ? 36 : 44, color: ivory),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 18),
        if (choosing) ...[
          _Fan(
            offset: offset,
            count: session.remainingCount,
            onPick: _pick,
            duration: duration,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                tooltip: context.tr('Previous cards'),
                color: brass,
                disabledColor: Colors.white24,
                onPressed: offset == 0 ? null : () => turnPage(previousOffset),
                icon: const Icon(Icons.chevron_left),
              ),
              Flexible(
                child: Text(
                  context.tr('{start}–{end} of {total}', {
                    'start': offset + 1,
                    'end': math.min(nextOffset, session.remainingCount),
                    'total': session.remainingCount,
                  }),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: ivory),
                ),
              ),
              IconButton(
                tooltip: context.tr('Next cards'),
                color: brass,
                disabledColor: Colors.white24,
                onPressed: nextOffset >= session.remainingCount
                    ? null
                    : () => turnPage(nextOffset),
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
        ] else ...[
          TweenAnimationBuilder<double>(
            key: ValueKey('${viewing.card.id}-${viewing.isRevealed}'),
            duration: duration,
            tween: Tween(begin: 0, end: 1),
            builder: (context, t, child) => Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..setEntry(3, 2, .001)
                ..rotateY((1 - t) * 1.15),
              child: child,
            ),
            child: SizedBox(
              height: narrow ? 184 : 219,
              child: viewing.isRevealed
                  ? CardArt(
                      card!,
                      key: const ValueKey('revealed-stage-card'),
                      reversed: viewing.isReversed,
                    )
                  : const CardBack(),
            ),
          ),
          const SizedBox(height: 14),
          if (!viewing.isRevealed)
            FilledButton.icon(
              key: const ValueKey('reveal-card'),
              style: FilledButton.styleFrom(
                backgroundColor: mint,
                foregroundColor: night,
              ),
              onPressed: () {
                setState(() => session.reveal(index));
                if (session.complete) widget.onComplete();
              },
              icon: const Icon(Icons.flip, size: 18),
              label: Text(context.tr('Reveal card')),
            )
          else
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  context.tr(viewing.isReversed ? 'Reversed' : 'Upright'),
                  style: const TextStyle(
                    color: brass,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                IconButton(
                  tooltip: context.tr('Enlarge card'),
                  icon: const Icon(Icons.zoom_in, color: brass),
                  onPressed: () => showDialog<void>(
                    context: context,
                    builder: (_) =>
                        _CardViewer(draw: viewing, deck: session.deck),
                  ),
                ),
              ],
            ),
        ],
      ],
    );
    final info = SkyPanel(
      child: Padding(
        padding: const EdgeInsets.all(21),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.tr(
                session.complete ? 'Reading complete' : 'Position guide',
              ),
              style: smallCaps,
            ),
            const SizedBox(height: 6),
            Text(context.tr(position.title), style: display(35)),
            const SizedBox(height: 10),
            Text(
              context.tr(position.prompt),
              style: const TextStyle(fontSize: 16, height: 1.45),
            ),
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 16),
            if (viewing != null && viewing.isRevealed) ...[
              if (context.familyText(session.deck, viewing.card)
                  case final family?)
                _Lesson(family.$1, family.$2),
              _Lesson(context.tr('Look at the image'), card!.symbolism),
              _Lesson(
                context.tr('Card meaning'),
                viewing.isReversed ? card.reversed : card.meaning,
              ),
              _Lesson(
                context.tr('Read the position'),
                context.tr(
                  'What detail in {card} connects its meaning to “{position}” in your reading?',
                  {'card': card.title, 'position': context.tr(position.title)},
                ),
              ),
              if (session.complete) ...[
                _Lesson(
                  context.tr('Closing reflection'),
                  context.tr(
                    spread == SpreadType.one
                        ? 'What is one small action this card invites you to try?'
                        : 'Which two cards seem to speak to each other? Use their positions to explain the connection, then name one action to take.',
                  ),
                ),
                OutlinedButton(
                  key: const ValueKey('new-reading'),
                  onPressed: widget.onNew,
                  child: Text(context.tr('New reading')),
                ),
              ] else
                FilledButton(
                  onPressed: () => _showStage(() {
                    inspected = null;
                    next = !unseen;
                  }),
                  key: const ValueKey('next-position'),
                  child: Text(
                    context.tr(
                      unseen ? 'Return to drawn card' : 'Choose next card',
                    ),
                  ),
                ),
            ] else
              _Lesson(
                context.tr(
                  choosing ? 'Draw from the deck' : 'Before you reveal',
                ),
                context.tr(
                  choosing
                      ? 'Select a face-down card from the shuffled deck for this position.'
                      : 'Hold the position’s question in mind, then turn the card to explore its imagery.',
                ),
              ),
          ],
        ),
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 14,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(context.tr(spread.title), style: display(36)),
                const SizedBox(height: 4),
                Text(
                  context.deckName(session.deck),
                  style: const TextStyle(color: muted),
                ),
              ],
            ),
            if (!session.complete)
              TextButton.icon(
                onPressed: widget.onNew,
                icon: const Icon(Icons.restart_alt),
                label: Text(context.tr('Start again')),
              ),
          ],
        ),
        const SizedBox(height: 16),
        if (narrow) ...[
          SkyPanel(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 23),
              child: stage,
            ),
          ),
          const SizedBox(height: 20),
          info,
        ] else
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 6,
                child: SkyPanel(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 28,
                    ),
                    child: stage,
                  ),
                ),
              ),
              const SizedBox(width: 28),
              Expanded(flex: 5, child: info),
            ],
          ),
        if (spread.positions.length > 1) ...[
          const SizedBox(height: 22),
          const Divider(),
          const SizedBox(height: 10),
          Text(context.tr('Spread layout'), style: display(29)),
          const SizedBox(height: 9),
          _SpreadLayout(
            session: session,
            current: number - 1,
            onSelect: (i) => _showStage(() {
              inspected = i;
              next = false;
            }),
          ),
        ],
      ],
    );
  }
}

class _Lesson extends StatelessWidget {
  const _Lesson(this.title, this.body);
  final String title, body;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 13),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(color: ink, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 3),
        Text(body, style: const TextStyle(color: muted, height: 1.5)),
      ],
    ),
  );
}

class _Fan extends StatelessWidget {
  const _Fan({
    required this.offset,
    required this.count,
    required this.onPick,
    required this.duration,
  });
  final int offset, count;
  final ValueChanged<int> onPick;
  final Duration duration;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final shown = math.min(5, count - offset);
      final width = math.min(69.0, box.maxWidth / 6.2);
      return SizedBox(
        height: width * 2,
        child: TweenAnimationBuilder<double>(
          key: ValueKey('$offset-$count'),
          tween: Tween(begin: 0, end: 1),
          duration: duration,
          curve: Curves.easeOutCubic,
          builder: (context, t, _) => Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < shown; i++)
                Transform.translate(
                  offset: Offset(
                    (i - (shown - 1) / 2) * width * (t - 1) * .65,
                    (i - (shown - 1) / 2).abs() * 3,
                  ),
                  child: Transform.rotate(
                    angle: (i - (shown - 1) / 2) * .055 * t,
                    child: SizedBox(
                      width: width,
                      child: Tooltip(
                        message: context.tr('Draw card {number}', {
                          'number': offset + i + 1,
                        }),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            key: ValueKey('fan-card-$i'),
                            onTap: () => onPick(offset + i),
                            focusColor: brass.withValues(alpha: .8),
                            borderRadius: BorderRadius.circular(6),
                            child: Semantics(
                              button: true,
                              label: context.tr(
                                'Draw face-down card {number}',
                                {'number': offset + i + 1},
                              ),
                              child: const Padding(
                                padding: EdgeInsets.all(3),
                                child: CardBack(),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    },
  );
}

class _SpreadLayout extends StatelessWidget {
  const _SpreadLayout({
    required this.session,
    required this.current,
    required this.onSelect,
  });
  final ReadingSession session;
  final int current;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final cross = session.spread == SpreadType.celticCross;
    final placements = cross
        ? const [
            Offset(.34, .5),
            Offset(.34, .53),
            Offset(.34, .19),
            Offset(.34, .81),
            Offset(.12, .5),
            Offset(.57, .5),
            Offset(.84, .85),
            Offset(.84, .62),
            Offset(.84, .38),
            Offset(.84, .15),
          ]
        : const [Offset(.2, .5), Offset(.5, .5), Offset(.8, .5)];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 610),
            child: SkyPanel(
              child: AspectRatio(
                aspectRatio: cross ? 1.55 : 3.5,
                child: LayoutBuilder(
                  builder: (context, box) {
                    final cardHeight = box.maxHeight * (cross ? .225 : .82);
                    final cardWidth = cardHeight * .585;
                    return Stack(
                      children: [
                        for (final (i, at) in placements.indexed)
                          Positioned(
                            left: box.maxWidth * at.dx - cardWidth / 2,
                            top: box.maxHeight * at.dy - cardHeight / 2,
                            width: cardWidth,
                            height: cardHeight,
                            child: Transform.rotate(
                              angle: cross && i == 1 ? math.pi / 2 : 0,
                              child: _PlacementCard(
                                session: session,
                                index: i,
                                current: current == i,
                                onSelect: onSelect,
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 4,
          children: [
            for (final (i, p) in session.spread.positions.indexed)
              ActionChip(
                label: Text('${i + 1}. ${context.tr(p.title)}'),
                tooltip: i < session.draws.length && session.draws[i].isRevealed
                    ? context
                          .cardText(session.deck, session.draws[i].card)
                          .title
                    : context.tr(p.title),
                onPressed:
                    i < session.draws.length && session.draws[i].isRevealed
                    ? () => onSelect(i)
                    : null,
              ),
          ],
        ),
      ],
    );
  }
}

class _PlacementCard extends StatelessWidget {
  const _PlacementCard({
    required this.session,
    required this.index,
    required this.current,
    required this.onSelect,
  });
  final ReadingSession session;
  final int index;
  final bool current;
  final ValueChanged<int> onSelect;
  @override
  Widget build(BuildContext context) {
    final draw = index < session.draws.length ? session.draws[index] : null;
    if (draw != null && draw.isRevealed) {
      final card = context.cardText(session.deck, draw.card);
      return Tooltip(
        message: '${context.tr(draw.position.title)} · ${card.title}',
        child: InkWell(
          onTap: () => onSelect(index),
          child: CardArt(card, reversed: draw.isReversed),
        ),
      );
    }
    if (draw != null) return const CardBack();
    return ExcludeSemantics(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: night.withValues(alpha: .87),
          border: Border.all(color: brass.withValues(alpha: current ? 1 : .47)),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Center(
          child: Text('${index + 1}', style: smallCaps.copyWith(color: brass)),
        ),
      ),
    );
  }
}

class _CardViewer extends StatefulWidget {
  const _CardViewer({required this.draw, required this.deck});
  final TarotDeck deck;
  final DrawnCard draw;
  @override
  State<_CardViewer> createState() => _CardViewerState();
}

class _CardViewerState extends State<_CardViewer> {
  final transform = TransformationController();
  GlobalKey viewportKey = GlobalKey();

  void _setZoom(Matrix4 target) {
    // Dispose the old viewer's pinch and pan animation controllers before
    // setting the shared transform. A pending fling could otherwise overwrite it.
    final replacement = GlobalKey();
    setState(() => viewportKey = replacement);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && viewportKey == replacement) transform.value = target;
    });
  }

  void _zoomIn() {
    final viewport = viewportKey.currentContext?.size;
    if (viewport == null) return;
    final center = viewport.center(Offset.zero);
    final point = transform.toScene(center);
    final scale = (transform.value.getMaxScaleOnAxis() * 1.5).clamp(1.0, 4.0);
    _setZoom(
      Matrix4.diagonal3Values(scale, scale, 1)..setTranslationRaw(
        center.dx - point.dx * scale,
        center.dy - point.dy * scale,
        0,
      ),
    );
  }

  @override
  void dispose() {
    transform.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Dialog(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 660),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    context.cardText(widget.deck, widget.draw.card).title,
                    style: display(25),
                  ),
                ),
                IconButton(
                  tooltip: context.tr('Close'),
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Flexible(
              child: InteractiveViewer(
                key: viewportKey,
                transformationController: transform,
                minScale: 1,
                maxScale: 4,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(5),
                    child: CardArt(
                      context.cardText(widget.deck, widget.draw.card),
                      reversed: widget.draw.isReversed,
                    ),
                  ),
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  tooltip: context.tr('Reset zoom'),
                  icon: const Icon(Icons.zoom_out_map),
                  onPressed: () => _setZoom(Matrix4.identity()),
                ),
                IconButton(
                  tooltip: context.tr('Zoom in'),
                  icon: const Icon(Icons.zoom_in),
                  onPressed: _zoomIn,
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}
