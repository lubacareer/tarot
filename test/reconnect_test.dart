import 'dart:async';

import 'package:arcana_observatory/interpretation.dart';
import 'package:arcana_observatory/reading.dart';
import 'package:flutter_test/flutter_test.dart';

class _Service extends InterpretationClient {
  final posts = <InterpretationRequest>[];
  final gets = <InterpretationRequest>[];
  final posted = <Completer<Interpretation?>>[];
  final fetched = <Completer<Interpretation?>>[];

  @override
  Future<Interpretation?> interpret(InterpretationRequest request) {
    posts.add(request);
    posted.add(Completer<Interpretation?>());
    return posted.last.future;
  }

  @override
  Future<Interpretation?> status(InterpretationRequest request) {
    gets.add(request);
    fetched.add(Completer<Interpretation?>());
    return fetched.last.future;
  }
}

ReadingInterpretations _reading(WidgetTester tester, _Service service) {
  final deck = TarotDeck(
    id: 'celestial',
    name: 'Celestial',
    credit: '',
    rights: '',
    source: '',
    cards: [
      TarotCard(
        id: 'star',
        title: 'Star',
        imageAsset: '',
        symbolism: '',
        meaning: '',
        reversed: '',
      ),
    ],
  );
  final session = ReadingSession.start(deck, SpreadType.one)
    ..pick(0)
    ..reveal(0);
  final readings = ReadingInterpretations(
    session: session,
    client: service,
    now: tester.binding.clock.now,
  );
  addTearDown(readings.dispose);
  readings.load(0, 'en');
  return readings;
}

void main() {
  testWidgets(
    'foreground polling backs off and resumes immediately with the same token',
    (tester) async {
      final service = _Service();
      final state = _reading(tester, service);
      service.posted.single.complete(null);
      await tester.pump();
      for (final seconds in [2, 4, 8, 8]) {
        final previous = service.gets.length;
        await tester.pump(Duration(seconds: seconds - 1));
        expect(service.gets, hasLength(previous));
        await tester.pump(const Duration(seconds: 1));
        expect(service.gets, hasLength(previous + 1));
        service.fetched.last.complete(null);
        await tester.pump();
      }
      state.setForeground(false);
      await tester.pump(const Duration(seconds: 50));
      expect(service.gets, hasLength(4));
      state.setForeground(true);
      expect(service.gets, hasLength(5));
      service.fetched.last.complete(const Interpretation(card: 'Recovered'));
      await tester.pump();
      expect(state.result(0, 'en')?.card, 'Recovered');
      expect(service.posts, hasLength(1));
      expect(service.gets.map((request) => request.token).toSet(), {
        service.posts.single.token,
      });
    },
  );

  testWidgets(
    'ambiguous POST checks before resubmitting identical bytes and token',
    (tester) async {
      final service = _Service();
      final state = _reading(tester, service);
      service.posted.single.completeError(
        const InterpretationException('disconnected'),
      );
      await tester.pump();
      expect(state.reconnecting(0, 'en'), isTrue);
      await tester.pump(const Duration(seconds: 2));
      expect(service.posts, hasLength(1));
      service.fetched.single.completeError(
        const InterpretationException('not_found'),
      );
      await tester.pump();
      expect(service.posts, hasLength(2));
      expect(service.posts.last, same(service.posts.first));
      service.posted.last.complete(null);
      await tester.pump();
      await tester.pump(const Duration(seconds: 4));
      service.fetched.last.completeError(
        const InterpretationException('not_found'),
      );
      await tester.pump();
      expect(state.error(0, 'en'), 'expired');
      expect(service.posts, hasLength(2));
    },
  );

  testWidgets(
    'after four minutes Check again only checks the original attempt',
    (tester) async {
      final service = _Service();
      final state = _reading(tester, service);
      service.posted.single.completeError(
        const InterpretationException('disconnected'),
      );
      await tester.pump();
      state.setForeground(false);
      await tester.pump(const Duration(minutes: 5));
      state.setForeground(true);
      expect(service.fetched, hasLength(1));
      service.fetched.single.completeError(
        const InterpretationException('disconnected'),
      );
      await tester.pump();
      expect(state.error(0, 'en'), 'check_again');
      await tester.pump(const Duration(minutes: 1));
      expect(service.gets, hasLength(1));
      state.checkAgain(0, 'en');
      service.fetched.last.completeError(
        const InterpretationException('not_found'),
      );
      await tester.pump();
      expect(state.error(0, 'en'), 'expired');
      expect(service.posts, hasLength(1));
      expect(service.gets.last.token, service.posts.single.token);
    },
  );

  testWidgets(
    'pause cancels an in-flight POST; late replies cannot replace a recovered result',
    (tester) async {
      final service = _Service();
      final state = _reading(tester, service);
      state.setForeground(false);
      state.setForeground(true);
      expect(service.gets, hasLength(1));
      service.fetched.single.complete(
        const Interpretation(card: 'Saved result'),
      );
      await tester.pump();
      service.posted.single.completeError(
        const InterpretationException('timeout'),
      );
      await tester.pump();
      expect(state.result(0, 'en')?.card, 'Saved result');
      expect(state.error(0, 'en'), isNull);
      state.load(0, 'ru');
      expect(service.posts.last.token, isNot(service.posts.first.token));
      service.posted.last.completeError(
        const InterpretationException('timeout'),
      );
      await tester.pump();
      final prior = service.posts.last.token;
      state.load(0, 'ru', retry: true);
      expect(service.posts.last.token, isNot(prior));
    },
  );
}
