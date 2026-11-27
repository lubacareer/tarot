import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../reading.dart';
import 'style.dart';

class ReadingTable extends StatefulWidget {
  const ReadingTable({super.key, required this.session, required this.onNew});
  final ReadingSession session;
  final VoidCallback onNew;
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
  Widget build(BuildContext context) {
    final draws = session.draws;
    final unseen = draws.isNotEmpty && !draws.last.isRevealed;
    final index = inspected ?? (draws.length - 1);
    final DrawnCard? viewing = index >= 0 && !next ? draws[index] : null;
    final choosing = viewing == null;
    final spread = session.spread;
    final position = choosing
        ? spread.positions[draws.length]
        : viewing.position;
    final number = choosing ? draws.length + 1 : index + 1;
    final narrow = MediaQuery.sizeOf(context).width < 840;
    final heading = choosing
        ? 'Choose a card'
        : !viewing.isRevealed
        ? 'Turn your card'
        : viewing.card.title;
    final stage = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'POSITION $number OF ${spread.positions.length}  ·  ${position.title.toUpperCase()}',
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
                tooltip: 'Previous cards',
                color: brass,
                disabledColor: Colors.white24,
                onPressed: offset == 0
                    ? null
                    : () => setState(() => offset = math.max(0, offset - 5)),
                icon: const Icon(Icons.chevron_left),
              ),
              Flexible(
                child: Text(
                  '${offset + 1}–${math.min(offset + 5, session.remainingCount)} of ${session.remainingCount}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: ivory),
                ),
              ),
              IconButton(
                tooltip: 'Next cards',
                color: brass,
                disabledColor: Colors.white24,
                onPressed: offset + 5 >= session.remainingCount
                    ? null
                    : () => setState(() => offset += 5),
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
                  ? CardArt(viewing.card, reversed: viewing.isReversed)
                  : const CardBack(),
            ),
          ),
          const SizedBox(height: 14),
          if (!viewing.isRevealed)
            FilledButton.icon(
              key: const ValueKey('reveal-card'),
              style: FilledButton.styleFrom(
                backgroundColor: brass,
                foregroundColor: night,
              ),
              onPressed: () => setState(() => session.reveal(index)),
              icon: const Icon(Icons.flip, size: 18),
              label: const Text('Reveal card'),
            )
          else
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  viewing.isReversed ? 'Reversed' : 'Upright',
                  style: const TextStyle(
                    color: brass,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                IconButton(
                  tooltip: 'Enlarge card',
                  icon: const Icon(Icons.zoom_in, color: brass),
                  onPressed: () => showDialog<void>(
                    context: context,
                    builder: (_) => _CardViewer(draw: viewing),
                  ),
                ),
              ],
            ),
        ],
      ],
    );
    final info = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          session.complete ? 'Reading complete' : 'Position guide',
          style: smallCaps,
        ),
        const SizedBox(height: 6),
        Text(position.title, style: display(35)),
        const SizedBox(height: 10),
        Text(
          position.prompt,
          style: const TextStyle(fontSize: 16, height: 1.45),
        ),
        const SizedBox(height: 16),
        const Divider(height: 1),
        const SizedBox(height: 16),
        if (viewing != null && viewing.isRevealed) ...[
          if (session.deck.familyLesson(viewing.card) case final family?)
            _Lesson(family.$1, family.$2),
          _Lesson('Look at the image', viewing.card.symbolism),
          _Lesson(
            'Card meaning',
            viewing.isReversed ? viewing.card.reversed : viewing.card.meaning,
          ),
          _Lesson(
            'Read the position',
            'What detail in ${viewing.card.title} connects its meaning to “${position.title}” in your reading?',
          ),
          if (session.complete) ...[
            _Lesson(
              'Closing reflection',
              spread == SpreadType.one
                  ? 'What is one small action this card invites you to try?'
                  : 'Which two cards seem to speak to each other? Use their positions to explain the connection, then name one action to take.',
            ),
            OutlinedButton(
              key: const ValueKey('new-reading'),
              onPressed: widget.onNew,
              child: const Text('New reading'),
            ),
          ] else
            FilledButton(
              onPressed: () => _showStage(() {
                inspected = null;
                next = !unseen;
              }),
              key: const ValueKey('next-position'),
              child: Text(unseen ? 'Return to drawn card' : 'Choose next card'),
            ),
        ] else
          _Lesson(
            choosing ? 'Draw from the deck' : 'Before you reveal',
            choosing
                ? 'Select a face-down card from the shuffled deck for this position.'
                : 'Hold the position’s question in mind, then turn the card to explore its imagery.',
          ),
      ],
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
                Text(spread.title, style: display(36)),
                const SizedBox(height: 4),
                Text(session.deck.name, style: const TextStyle(color: muted)),
              ],
            ),
            if (!session.complete)
              TextButton.icon(
                onPressed: widget.onNew,
                icon: const Icon(Icons.restart_alt),
                label: const Text('Start again'),
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
          Text('Spread layout', style: display(29)),
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
          style: const TextStyle(color: night, fontWeight: FontWeight.w700),
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
                        message: 'Draw card ${offset + i + 1}',
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            key: ValueKey('fan-card-$i'),
                            onTap: () => onPick(offset + i),
                            focusColor: brass.withValues(alpha: .8),
                            borderRadius: BorderRadius.circular(6),
                            child: Semantics(
                              button: true,
                              label: 'Draw face-down card ${offset + i + 1}',
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
          alignment: Alignment.centerLeft,
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
                label: Text('${i + 1}. ${p.title}'),
                tooltip: i < session.draws.length && session.draws[i].isRevealed
                    ? session.draws[i].card.title
                    : p.title,
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
      return Tooltip(
        message: '${draw.position.title} · ${draw.card.title}',
        child: InkWell(
          onTap: () => onSelect(index),
          child: CardArt(draw.card, reversed: draw.isReversed),
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
  const _CardViewer({required this.draw});
  final DrawnCard draw;
  @override
  State<_CardViewer> createState() => _CardViewerState();
}

class _CardViewerState extends State<_CardViewer> {
  final transform = TransformationController();
  final viewportKey = GlobalKey();

  void _zoomIn() {
    final viewport = viewportKey.currentContext!.size!;
    final center = viewport.center(Offset.zero);
    final point = transform.toScene(center);
    final scale = (transform.value.getMaxScaleOnAxis() * 1.5).clamp(1.0, 4.0);
    transform.value = Matrix4.diagonal3Values(scale, scale, 1)
      ..setTranslationRaw(
        center.dx - point.dx * scale,
        center.dy - point.dy * scale,
        0,
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
                  child: Text(widget.draw.card.title, style: display(25)),
                ),
                IconButton(
                  tooltip: 'Close',
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
                      widget.draw.card,
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
                  tooltip: 'Reset zoom',
                  icon: const Icon(Icons.zoom_out_map),
                  onPressed: () => transform.value = Matrix4.identity(),
                ),
                IconButton(
                  tooltip: 'Zoom in',
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
