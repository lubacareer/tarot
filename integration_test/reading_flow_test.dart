import 'package:arcana_observatory/main.dart' as app;
import 'package:arcana_observatory/language_picker.dart';
import 'package:arcana_observatory/localized_reading.dart';
import 'package:arcana_observatory/strings.dart';
import 'package:arcana_observatory/ui/reading_table.dart';
import 'package:arcana_observatory/ui/style.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

class _TestPreferences implements LanguagePreferences {
  String language = 'en';
  @override
  Future<String?> read() async => language;
  @override
  Future<void> write(String value) async => language = value;
}

Future<void> _tapControl(WidgetTester tester, String key) async {
  final control = find.byKey(ValueKey(key));
  // Preference I/O and loading the saved language can finish between frames.
  final deadline = tester.binding.clock.fromNowBy(const Duration(seconds: 10));
  while (control.evaluate().isEmpty &&
      tester.binding.clock.now().isBefore(deadline)) {
    await tester.pump(const Duration(milliseconds: 100));
  }
  expect(control, findsOneWidget, reason: 'The $key control did not appear.');
  await tester.ensureVisible(control);
  await tester.pumpAndSettle();
  await tester.tap(control);
  await tester.pumpAndSettle();
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('complete a Celtic Cross from bundled art', (tester) async {
    app.main();
    await tester.pumpAndSettle();
    Future<void> tapControl(String key) => _tapControl(tester, key);

    await tapControl('select-deck-celestial');
    await tapControl('spread-celticCross');
    await tapControl('begin-reading');
    final table = find.byType(ReadingTable);
    final deck = tester.widget<ReadingTable>(table).session.deck;
    expect(deck.id, 'celestial');
    expect(find.text(tester.element(table).deckName(deck)), findsOneWidget);
    for (var index = 0; index < 10; index++) {
      await tapControl('fan-card-0');
      await tapControl('reveal-card');
      final stage = find.byKey(const ValueKey('revealed-stage-card'));
      expect(stage, findsOneWidget);
      final failedArt = find.descendant(
        of: stage,
        matching: find.byIcon(Icons.broken_image_outlined),
      );
      final decodedArt = find.descendant(
        of: stage,
        matching: find.byWidgetPredicate(
          (widget) => widget is RawImage && widget.image != null,
        ),
      );
      final deadline = tester.binding.clock.fromNowBy(
        const Duration(seconds: 10),
      );
      while (decodedArt.evaluate().isEmpty &&
          failedArt.evaluate().isEmpty &&
          tester.binding.clock.now().isBefore(deadline)) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(
        failedArt,
        findsNothing,
        reason: 'Broken artwork at position ${index + 1}',
      );
      expect(
        decodedArt,
        findsOneWidget,
        reason: 'Artwork did not decode at position ${index + 1}',
      );
      if (index < 9) await tapControl('next-position');
    }
    expect(
      find.text(tester.element(table).tr('Reading complete')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'changing language and viewport preserves the revealed card and position',
    (tester) async {
      runApp(app.ObservatoryApp(preferences: _TestPreferences()));
      await tester.pumpAndSettle();
      await _tapControl(tester, 'spread-three');
      await _tapControl(tester, 'begin-reading');
      await _tapControl(tester, 'fan-card-0');
      await _tapControl(tester, 'reveal-card');
      final stage = find.byKey(const ValueKey('revealed-stage-card'));
      final original = tester.widget<CardArt>(stage).card;
      final table = find.byType(ReadingTable);
      final session = tester.widget<ReadingTable>(table).session;
      for (final language in ['he', 'ru']) {
        await _tapControl(tester, 'language-picker');
        await _tapControl(tester, 'language-$language');
        final timeout = tester.binding.clock.fromNowBy(
          const Duration(seconds: 10),
        );
        while (Localizations.localeOf(tester.element(table)).languageCode !=
                language &&
            tester.binding.clock.now().isBefore(timeout)) {
          await tester.pump(const Duration(milliseconds: 100));
        }
        expect(
          Localizations.localeOf(tester.element(table)).languageCode,
          language,
        );
        expect(
          Directionality.of(tester.element(table)),
          language == 'he' ? TextDirection.rtl : TextDirection.ltr,
        );
        final translated = tester.widget<CardArt>(stage).card;
        expect(translated.id, original.id);
        expect(translated.imageAsset, original.imageAsset);
        expect(translated.meaning, isNot(original.meaning));
        expect(find.text(translated.meaning), findsOneWidget);
        expect(tester.widget<ReadingTable>(table).session, same(session));
        expect(session.draws.single.position, session.spread.positions.first);
      }
      final width =
          tester.view.physicalSize.width / tester.view.devicePixelRatio;
      await tester.binding.setSurfaceSize(
        width > 700 ? const Size(390, 750) : const Size(960, 660),
      );
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpAndSettle();
      expect(tester.widget<CardArt>(stage).card.id, original.id);
      expect(tester.widget<ReadingTable>(table).session.draws.length, 1);
      expect(tester.takeException(), isNull);
    },
  );
}
