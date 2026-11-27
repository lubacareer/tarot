import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../reading.dart';

const paper = Color(0xfff7f3eb);
const ivory = Color(0xfffffcf4);
const ink = Color(0xff252c32);
const muted = Color(0xff595c5b);
const line = Color(0xffd8d3c7);
const night = Color(0xff122d34);
const brass = Color(0xffd7b77c);
const accent = Color(0xff885126);

ThemeData observatoryTheme() {
  final scheme = ColorScheme.fromSeed(seedColor: night, surface: paper);
  return ThemeData(
    colorScheme: scheme.copyWith(
      primary: night,
      onPrimary: ivory,
      onSurface: ink,
    ),
    scaffoldBackgroundColor: paper,
    fontFamily: 'DM Sans',
    useMaterial3: true,
    dividerColor: line,
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
        textStyle: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          fontFamily: 'DM Sans',
        ),
      ),
    ),
  );
}

TextStyle display(double size, {Color color = ink}) => TextStyle(
  fontFamily: 'Cormorant Garamond',
  fontFamilyFallback: const ['Georgia', 'serif'],
  fontSize: size,
  height: 1.03,
  fontWeight: FontWeight.w600,
  color: color,
);

const smallCaps = TextStyle(
  fontSize: 11,
  height: 1.4,
  fontWeight: FontWeight.w700,
  letterSpacing: 1.6,
  color: accent,
);

class SkyPanel extends StatelessWidget {
  const SkyPanel({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(15),
    child: DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xff11272e), Color(0xff20474b), Color(0xff11292f)],
        ),
      ),
      child: CustomPaint(painter: const _SkyPainter(), child: child),
    ),
  );
}

// A fixed astronomical chart keeps the reading table sharp at every window size.
class _SkyPainter extends CustomPainter {
  const _SkyPainter();
  @override
  void paint(Canvas canvas, Size size) {
    final random = math.Random(1922);
    final dot = Paint();
    for (int i = 0; i < size.width * size.height / 1250; i++) {
      final point = Offset(
        random.nextDouble() * size.width,
        random.nextDouble() * size.height,
      );
      dot.color = brass.withValues(alpha: .13 + random.nextDouble() * .37);
      canvas.drawCircle(point, .3 + random.nextDouble() * .85, dot);
      if (i % 27 == 0) {
        canvas.drawLine(
          point - const Offset(3, 0),
          point + const Offset(3, 0),
          dot,
        );
        canvas.drawLine(
          point - const Offset(0, 3),
          point + const Offset(0, 3),
          dot,
        );
      }
    }
    final center = Offset(size.width * .77, size.height * .54);
    final radius = math.min(size.width * .44, size.height * .72);
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = .8
      ..color = brass.withValues(alpha: .30);
    for (final scale in [.57, .77, .91, .95, 1.0, 1.17]) {
      canvas.drawCircle(center, radius * scale, stroke);
    }
    for (var i = 0; i < 120; i++) {
      final angle = i * math.pi / 60;
      final radial = Offset(math.cos(angle), math.sin(angle));
      canvas.drawLine(
        center + radial * radius * (i % 10 == 0 ? .91 : .97),
        center + radial * radius,
        stroke,
      );
    }
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(-.53);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset.zero,
        width: radius * 2.75,
        height: radius * .89,
      ),
      stroke,
    );
    canvas.rotate(1.5);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset.zero,
        width: radius * 2.35,
        height: radius * 1.05,
      ),
      stroke,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_SkyPainter oldDelegate) => false;
}

class ObservatoryMark extends StatelessWidget {
  const ObservatoryMark({super.key, this.size = 38});
  final double size;
  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: size,
    child: CustomPaint(painter: const _MarkPainter()),
  );
}

class _MarkPainter extends CustomPainter {
  const _MarkPainter();
  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final r = size.width / 2;
    final paint = Paint()..color = night;
    canvas.drawCircle(center, r, paint);
    paint
      ..color = brass
      ..style = PaintingStyle.stroke
      ..strokeWidth = .8;
    canvas.drawCircle(center, r * .76, paint);
    canvas.drawCircle(center, r * .52, paint);
    final star = Path();
    for (int i = 0; i < 16; i++) {
      final theta = -math.pi / 2 + math.pi * i / 8;
      final distance =
          r *
          (i.isOdd
              ? .16
              : i % 4 == 0
              ? .91
              : .50);
      final p = center + Offset(math.cos(theta), math.sin(theta)) * distance;
      if (i == 0) {
        star.moveTo(p.dx, p.dy);
      } else {
        star.lineTo(p.dx, p.dy);
      }
    }
    canvas.drawPath(star..close(), paint..style = PaintingStyle.fill);
  }

  @override
  bool shouldRepaint(_MarkPainter oldDelegate) => false;
}

class CardArt extends StatelessWidget {
  const CardArt(this.card, {super.key, this.reversed = false});
  final TarotCard card;
  final bool reversed;
  @override
  Widget build(BuildContext context) => Semantics(
    image: true,
    label: card.title,
    child: ExcludeSemantics(
      child: AspectRatio(
        aspectRatio: .585,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: ivory,
            borderRadius: BorderRadius.circular(5),
            boxShadow: const [
              BoxShadow(
                color: Color(0x4d000000),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(3),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: RotatedBox(
                quarterTurns: reversed ? 2 : 0,
                child: Image.asset(
                  card.imageAsset,
                  fit: BoxFit.contain,
                  excludeFromSemantics: true,
                  errorBuilder: (_, _, _) => const Center(
                    child: Icon(Icons.broken_image_outlined, color: muted),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class DeckPortrait extends StatelessWidget {
  const DeckPortrait(this.deck, {super.key, this.height = 210});
  final TarotDeck deck;
  final double height;
  @override
  Widget build(BuildContext context) {
    if (deck.cards.isEmpty) return const SizedBox.shrink();
    TarotCard pick(String name, int fallback) => deck.cards.firstWhere(
      (card) => card.title.toLowerCase().contains(name),
      orElse: () => deck.cards[fallback % deck.cards.length],
    );
    final cards = [pick('moon', 18), pick('sun', 19), pick('star', 17)];
    return ExcludeSemantics(
      child: SizedBox(
        height: height,
        width: height * 1.45,
        child: Stack(
          alignment: Alignment.center,
          children: [
            for (final (i, card) in cards.indexed)
              Transform.translate(
                offset: Offset(
                  (i == 2
                          ? 0
                          : i == 0
                          ? -.31
                          : .31) *
                      height,
                  (i == 2 ? -.005 : .065) * height,
                ),
                child: Transform.rotate(
                  angle: i == 0
                      ? -.235
                      : i == 1
                      ? .235
                      : -.025,
                  child: SizedBox(height: height * .83, child: CardArt(card)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class CardBack extends StatelessWidget {
  const CardBack({super.key});
  @override
  Widget build(BuildContext context) => AspectRatio(
    aspectRatio: .585,
    child: DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xff223e49),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: brass, width: 2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x66000000),
            blurRadius: 7,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border.all(color: brass.withValues(alpha: .65)),
            borderRadius: BorderRadius.circular(3),
          ),
          child: Center(
            child: LayoutBuilder(
              builder: (context, constraints) => ObservatoryMark(
                size: math.min(44, constraints.maxWidth * .69),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
