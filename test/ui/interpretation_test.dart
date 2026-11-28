import 'dart:async';

import 'package:arcana_observatory/interpretation.dart';
import 'package:arcana_observatory/main.dart';
import 'package:arcana_observatory/reading.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fixture_interpretations.dart';

class _RecordingClient extends FixtureInterpretationClient {
  final calls = <InterpretationRequest>[];
  final checks = <InterpretationRequest>[];
  final pending = <Completer<Interpretation>>[];
  final checked = Completer<Interpretation>();
  @override
  Future<Interpretation> status(InterpretationRequest request) {
    checks.add(request);
    return checked.future;
  }

  @override
  Future<Interpretation> interpret(InterpretationRequest request) {
    calls.add(request);
    final reply = Completer<Interpretation>();
    pending.add(reply);
    return reply.future;
  }
}

Future<void> _open(WidgetTester tester, InterpretationClient client) async {
  final decks = (await tester.runAsync(DeckCatalog.load))!;
  await tester.pumpWidget(
    ObservatoryApp(loadDecks: () async => decks, interpretationClient: client),
  );
  await tester.pumpAndSettle();
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Finder _key(String name) => find.byKey(ValueKey(name));

void main() {
  testWidgets(
    'a paused reading resumes the same job and keeps the card on screen',
    (tester) async {
      final client = _RecordingClient();
      await _open(tester, client);
      await _tap(tester, _key('begin-reading'));
      await _tap(tester, _key('fan-card-0'));
      await _tap(tester, _key('reveal-card'));
      client.pending.single.completeError(
        const InterpretationException('disconnected'),
      );
      await tester.pumpAndSettle();
      expect(find.text('Reconnecting to your reading…'), findsOneWidget);
      expect(find.text('Try again'), findsNothing);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump(const Duration(seconds: 10));
      expect(client.checks, isEmpty);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      expect(client.checks.single.token, client.calls.single.token);
      client.checked.complete(
        const Interpretation(card: 'The original reading'),
      );
      await tester.pumpAndSettle();
      expect(find.text('The original reading'), findsOneWidget);
      expect(_key('revealed-stage-card'), findsOneWidget);
      expect(client.calls, hasLength(1));
    },
  );

  testWidgets(
    'only reveals send the question and whole-spread synthesis stays visible',
    (tester) async {
      final client = _RecordingClient();
      await _open(tester, client);
      expect(tester.widget<TextField>(_key('reading-question')).maxLength, 500);
      await tester.enterText(_key('reading-question'), 'Where should I focus?');
      await _tap(tester, _key('spread-three'));
      await _tap(tester, _key('begin-reading'));
      for (int i = 0; i < 3; i++) {
        await _tap(tester, _key('fan-card-0'));
        expect(client.calls, hasLength(i));
        await _tap(tester, _key('reveal-card'));
        expect(client.calls, hasLength(i + 1));
        expect(client.calls.last.question, 'Where should I focus?');
        expect(client.calls.last.cards, hasLength(i + 1));
        if (i < 2) await _tap(tester, _key('next-position'));
      }
      client.pending.first.complete(
        const Interpretation(card: 'First insight'),
      );
      client.pending[1].complete(const Interpretation(card: 'Second insight'));
      client.pending.last.complete(
        const Interpretation(
          card: 'Third insight',
          synthesis: 'One shared thread',
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Third insight'), findsOneWidget);
      expect(find.text('One shared thread'), findsOneWidget);
      await _tap(tester, find.text('1. Past'));
      expect(find.text('First insight'), findsOneWidget);
      expect(find.text('One shared thread'), findsOneWidget);
      expect(client.calls, hasLength(3));
    },
  );

  testWidgets(
    'single-card reading gives one integrated interpretation and one explicit retry',
    (tester) async {
      final client = _RecordingClient();
      await _open(tester, client);
      await _tap(tester, _key('begin-reading'));
      await _tap(tester, _key('fan-card-0'));
      await _tap(tester, _key('reveal-card'));
      client.pending.single.completeError(
        const InterpretationException('unavailable'),
      );
      await tester.pumpAndSettle();
      expect(find.text('Card meaning'), findsOneWidget);
      await _tap(tester, find.text('Try again'));
      expect(client.calls, hasLength(2));
      client.pending.last.complete(
        const Interpretation(card: 'One integrated reading'),
      );
      await tester.pumpAndSettle();
      expect(find.text('One integrated reading'), findsOneWidget);
      expect(find.text('Try again'), findsNothing);
    },
  );

  testWidgets(
    'offline mode retains bundled meanings without sending the question',
    (tester) async {
      final client = _RecordingClient();
      await _open(tester, client);
      await tester.enterText(_key('reading-question'), 'Personal question');
      await _tap(tester, _key('gemini-reading'));
      await _tap(tester, _key('begin-reading'));
      await _tap(tester, _key('fan-card-0'));
      await _tap(tester, _key('reveal-card'));
      expect(find.text('Card meaning'), findsOneWidget);
      expect(find.text('Closing reflection'), findsOneWidget);
      expect(client.calls, isEmpty);
    },
  );
}
