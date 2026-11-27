import 'dart:async';
import 'dart:convert';

import 'package:arcana_observatory/language_picker.dart';
import 'package:arcana_observatory/main.dart';
import 'package:arcana_observatory/reading.dart';
import 'package:arcana_observatory/ui/observatory.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

class _DelayedPreference implements LanguagePreferences {
  final initial = Completer<String?>();
  @override
  Future<String?> read() => initial.future;
  @override
  Future<void> write(String value) async {}
}

void main() {
  testWidgets('startup waits for the saved language before opening the table', (
    tester,
  ) async {
    final preference = _DelayedPreference();
    await tester.pumpWidget(
      ObservatoryApp(preferences: preference, loadDecks: () async => []),
    );
    await tester.pump();
    expect(find.byType(Observatory), findsNothing);
    preference.initial.complete('en');
    await tester.pumpAndSettle();
    expect(
      Localizations.localeOf(tester.element(find.byType(Observatory))),
      const Locale('en'),
    );
  });

  testWidgets('a slow catalog cannot restore an earlier language choice', (
    tester,
  ) async {
    final release = Completer<void>();
    var requested = 0;
    await tester.pumpWidget(
      ObservatoryApp(
        preferences: _DelayedPreference()..initial.complete('en'),
        loadDecks: () async => [],
      ),
    );
    await tester.pumpAndSettle();
    final table = find.byType(Observatory);
    final controller = tester
        .element(table)
        .getInheritedWidgetOfExactType<LanguageScope>()!
        .notifier!;
    Locale displayed() => Localizations.localeOf(tester.element(table));
    expect(displayed(), const Locale('en'));
    for (final id in DeckCatalog.ids) {
      final asset = 'assets/decks/$id/ru.json';
      rootBundle.evict(asset);
      addTearDown(() => rootBundle.evict(asset));
    }
    tester.binding.defaultBinaryMessenger.setMockMessageHandler(
      'flutter/assets',
      (message) async {
        final path = utf8.decode(Uint8List.sublistView(message!));
        if (!path.endsWith('/ru.json')) return null;
        requested++;
        await release.future;
        return ByteData.sublistView(
          utf8.encode(
            jsonEncode({
              'name': 'Таро',
              'credit': 'Автор',
              'rights': 'Права',
              'cards': {},
            }),
          ),
        );
      },
    );
    await controller.select(const Locale('ru'));
    await tester.pump();
    expect(requested, DeckCatalog.ids.length);
    await controller.select(const Locale('en'));
    await tester.pump();
    await tester.pump();
    release.complete();
    await tester.pumpAndSettle();
    expect(displayed(), const Locale('en'));
  });
}
