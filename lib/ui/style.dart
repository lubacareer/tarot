import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../reading.dart';
import '../src/card_art_bundle.dart';

const paper = Color(0xff071019);
const ivory = Color(0xfffcfbff);
const ink = Color(0xfff5f4fc);
const muted = Color(0xffc7cbd9);
const line = Color(0xff596471);
const night = Color(0xff0a1821);
const brass = Color(0xffdcc18a);
const accent = Color(0xffd3b2ff);
const mint = Color(0xff77efc8);

ThemeData observatoryTheme() {
  const scheme = ColorScheme.dark(
    primary: mint,
    onPrimary: night,
    secondary: accent,
    onSecondary: night,
    surface: Color(0xff14212c),
    onSurface: ink,
    onSurfaceVariant: muted,
    outline: line,
  );
  return ThemeData(
    colorScheme: scheme,
    scaffoldBackgroundColor: paper,
    fontFamily: 'Rubik',
    brightness: Brightness.dark,
    useMaterial3: true,
    dividerColor: line,
    focusColor: accent.withValues(alpha: .48),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        foregroundColor: night,
        backgroundColor: mint,
        padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 13),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        textStyle: const TextStyle(
          fontFamily: 'Rubik',
          fontWeight: FontWeight.w700,
          fontSize: 16,
        ),
      ),
    ),
    dialogTheme: const DialogThemeData(backgroundColor: Color(0xff11202b)),
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
        color: const Color(0xff23283d),
        borderRadius: BorderRadius.circular(6),
      ),
      textStyle: const TextStyle(fontFamily: 'Rubik', color: ink),
    ),
  );
}

TextStyle display(double size, {Color color = ink}) => TextStyle(
  fontFamily: 'Rubik',
  fontSize: size,
  height: 1.13,
  fontWeight: FontWeight.w600,
  letterSpacing: -.5,
  color: color,
  shadows: const [Shadow(color: Color(0x80040914), blurRadius: 8)],
);
const smallCaps = TextStyle(
  fontSize: 12,
  height: 1.4,
  fontWeight: FontWeight.w600,
  letterSpacing: .6,
  color: accent,
);

class ObservatorySky extends StatelessWidget {
  const ObservatorySky({super.key, required this.compact});
  final bool compact;
  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          'assets/visuals/observatory.webp',
          fit: BoxFit.cover,
          alignment: compact ? const Alignment(.6, -.8) : Alignment.center,
        ),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0x3a020913), Color(0x15030a14), Color(0x33010b15)],
            ),
          ),
        ),
      ],
    ),
  );
}

class SkyPanel extends StatelessWidget {
  const SkyPanel({super.key, required this.child, this.radius = 15});
  final Widget child;
  final double radius;
  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(radius),
    child: BackdropFilter(
      filter: ui.ImageFilter.blur(sigmaX: 7, sigmaY: 7),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xe70c1b25), Color(0xe622202f), Color(0xe1122730)],
          ),
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(color: const Color(0xff697486), width: 1),
        ),
        child: child,
      ),
    ),
  );
}

class ObservatoryMark extends StatelessWidget {
  const ObservatoryMark({super.key, this.size = 40});
  final double size;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: size * 1.35,
    height: size,
    child: CustomPaint(painter: const _MarkPainter()),
  );
}

class _MarkPainter extends CustomPainter {
  const _MarkPainter();
  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    canvas.translate(center.dx, center.dy);
    canvas.scale(size.height / 40);
    final paint = Paint()
      ..color = ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1
      ..isAntiAlias = true;
    canvas.save();
    canvas.rotate(-.4);
    canvas.drawArc(
      const Rect.fromLTWH(-24, -9, 48, 18),
      .26,
      math.pi * 1.75,
      false,
      paint,
    );
    canvas.restore();
    canvas.save();
    canvas.rotate(-.93);
    canvas.drawArc(
      const Rect.fromLTWH(-18, -10, 36, 20),
      .6,
      math.pi * 1.63,
      false,
      paint,
    );
    canvas.restore();
    paint.style = PaintingStyle.fill;
    final star = Path();
    for (var i = 0; i < 16; i++) {
      final a = i * math.pi / 8 - math.pi / 2;
      final d = i.isOdd ? 2.8 : (i % 4 == 0 ? 13.0 : 6.6);
      final x = math.cos(a) * d, y = math.sin(a) * d;
      if (i == 0) {
        star.moveTo(x, y);
      } else {
        star.lineTo(x, y);
      }
    }
    canvas.drawPath(star..close(), paint);
    for (final point in const [
      Offset(-18, 11),
      Offset(20, -8),
      Offset(5, -16),
    ]) {
      canvas.drawCircle(point, 1.7, paint);
    }
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
            color: const Color(0xff13121a),
            border: Border.all(color: brass, width: 1.5),
            borderRadius: BorderRadius.circular(9),
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
              borderRadius: BorderRadius.circular(6),
              child: RotatedBox(
                quarterTurns: reversed ? 2 : 0,
                child: Image.asset(
                  card.imageAsset,
                  bundle: CardArtBundle.instance,
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
  const DeckPortrait(this.deck, {super.key, this.height = 330});
  final TarotDeck deck;
  final double height;
  @override
  Widget build(BuildContext context) {
    if (deck.cards.isEmpty) return const SizedBox.shrink();
    TarotCard pick(String id, int fallback) => deck.cards.firstWhere(
      (card) => card.id == id,
      orElse: () => deck.cards[fallback % deck.cards.length],
    );
    final celestial = deck.id == 'celestial';
    final cards = [
      pick('moon', 18),
      pick(celestial ? 'pentacles_ace' : 'sun', 19),
      pick(celestial ? 'wheel_of_fortune' : 'star', 17),
    ];
    return ExcludeSemantics(
      child: SizedBox(
        height: height,
        width: height * 1.54,
        child: Stack(
          alignment: Alignment.center,
          children: [
            for (final (i, card) in cards.indexed)
              Transform.translate(
                offset: Offset(
                  (i == 2
                          ? 0
                          : i == 0
                          ? -.43
                          : .43) *
                      height,
                  i == 2 ? -height * .04 : height * .055,
                ),
                child: Transform.rotate(
                  angle: i == 0
                      ? -.17
                      : i == 1
                      ? .17
                      : 0,
                  child: SizedBox(
                    height: height * (i == 2 ? .88 : .80),
                    child: CardArt(card),
                  ),
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
        color: const Color(0xff211d38),
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
