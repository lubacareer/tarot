import 'dart:convert';

import 'package:arcana_observatory/localized_reading.dart';
import 'package:arcana_observatory/reading.dart';
import 'package:arcana_observatory/strings.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

class _Overlay extends CachingAssetBundle {
  _Overlay(this.data);
  final Map<String, Object> data;
  @override
  Future<ByteData> load(String key) async =>
      ByteData.sublistView(Uint8List.fromList(utf8.encode(jsonEncode(data))));
}

void main() {
  testWidgets(
    'both reading languages translate all spread positions and count grammar',
    (tester) async {
      for (final lang in ['he', 'ru']) {
        late BuildContext context;
        await tester.pumpWidget(
          MaterialApp(
            locale: Locale(lang),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            home: Builder(
              builder: (value) {
                context = value;
                return const SizedBox();
              },
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(
          Directionality.of(context),
          lang == 'he' ? TextDirection.rtl : TextDirection.ltr,
        );
        for (final spread in SpreadType.values) {
          expect(context.tr(spread.title), isNot(spread.title));
          for (final position in spread.positions) {
            expect(context.tr(position.title), isNot(position.title));
            expect(context.tr(position.prompt), isNot(position.prompt));
          }
        }
        expect(
          context.tr('{count} cards', {'count': 1}),
          lang == 'he' ? 'קלף אחד' : '1 карта',
        );
        expect(
          context.tr('{count} cards', {'count': 22}),
          lang == 'he' ? '22 קלפים' : '22 карты',
        );
      }
    },
  );

  test('deck overlays preserve identities and art and reject missing interpretations', () async {
    final cards = [
      const TarotCard(
        id: 'fool',
        title: 'The Fool',
        number: '0',
        imageAsset: 'assets/fool.webp',
        symbolism: 'A cliff',
        meaning: 'Beginning',
        reversed: 'Hesitation',
      ),
    ];
    final base = TarotDeck(
      id: 'waite_smith',
      name: 'Waite',
      credit: 'Smith',
      source: 'source',
      rights: 'PD',
      cards: cards,
    );
    final fields = <String, Object>{
      'title': 'Шут',
      'symbolism': 'Утёс',
      'meaning': 'Начало',
      'reversed': 'Сомнение',
    };
    final overlay = <String, Object>{
      'name': 'Таро Уэйта',
      'credit': 'Смит',
      'rights': 'PD',
      'cards': {'fool': fields},
    };
    final translated = (await localizeDecks(
      [base],
      const Locale('ru'),
      bundle: _Overlay(overlay),
    )).single;
    expect(translated.cards.single.title, 'Шут');
    expect(translated.cards.single.id, cards.single.id);
    expect(translated.cards.single.imageAsset, cards.single.imageAsset);
    expect(translated.cards.single.number, '0');
    expect(base.cards.single.title, 'The Fool');
    fields.remove('reversed');
    await expectLater(
      localizeDecks([base], const Locale('ru'), bundle: _Overlay(overlay)),
      throwsFormatException,
    );
  });
}
