import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:arcana_observatory/interpretation.dart';
import 'package:arcana_observatory/reading.dart';
import 'package:flutter_test/flutter_test.dart';

class _Fake extends InterpretationClient {
  final calls = <InterpretationRequest>[];
  final replies = <Completer<Interpretation>>[];
  @override
  Future<Interpretation> interpret(InterpretationRequest request) {
    calls.add(request);
    replies.add(Completer<Interpretation>());
    return replies.last.future;
  }
}

void main() {
  test(
    'official builds have an HTTPS reading service without a build override',
    () {
      expect(Uri.parse(const InterpretationClient().baseUrl).scheme, 'https');
      expect(Uri.parse(const InterpretationClient().baseUrl).host, isNotEmpty);
    },
  );
  final deck = TarotDeck(
    id: 'celestial',
    name: 'Celestial',
    credit: '',
    rights: '',
    source: '',
    cards: [
      for (final id in ['star', 'world', 'strength'])
        TarotCard(
          id: id,
          title: id,
          imageAsset: '',
          symbolism: '',
          meaning: '',
          reversed: '',
        ),
    ],
  );
  test(
    'only revealed cards in the visible prefix are sent, once per language',
    () async {
      final client = _Fake();
      final session = ReadingSession.start(
        deck,
        SpreadType.three,
        reversals: true,
      );
      final state = ReadingInterpretations(
        session: session,
        client: client,
        question: '  What can I change? ',
      );
      final first = session.pick(0);
      state.load(0, 'en');
      expect(client.calls, isEmpty);
      session.reveal(0);
      state.load(0, 'en');
      state.load(0, 'en');
      state.load(0, 'he');
      expect(client.calls, hasLength(2));
      expect(client.calls.first.cards, [
        {'id': first.card.id, 'reversed': first.isReversed},
      ]);
      expect(client.calls.first.question, 'What can I change?');
      expect(client.calls.last.sessionId, client.calls.first.sessionId);
      client.replies[1].complete(const Interpretation(card: 'קלף'));
      client.replies.first.complete(const Interpretation(card: 'Card'));
      await Future<void>.delayed(Duration.zero);
      state.load(0, 'en');
      expect(client.calls, hasLength(2));
      expect(state.result(0, 'he')?.card, 'קלף');
      final second = session.pick(0);
      session.reveal(1);
      state.load(1, 'en');
      expect(client.calls.last.cards.map((v) => v['id']), [
        first.card.id,
        second.card.id,
      ]);
      state.dispose();
      client.replies.last.complete(const Interpretation(card: 'Late reply'));
      await Future<void>.delayed(Duration.zero);
    },
  );

  test(
    'offline never calls the provider, quota errors retry only explicitly',
    () async {
      final session = ReadingSession.start(deck, SpreadType.one)
        ..pick(0)
        ..reveal(0);
      final client = _Fake();
      final offline = ReadingInterpretations(
        session: session,
        client: client,
        online: false,
      );
      offline.load(0, 'ru');
      expect(client.calls, isEmpty);
      offline.dispose();
      final online = ReadingInterpretations(session: session, client: client);
      online.load(0, 'ru');
      client.replies.single.completeError(
        const InterpretationException('quota'),
      );
      await Future<void>.delayed(Duration.zero);
      expect(online.error(0, 'ru'), 'quota');
      online.load(0, 'ru');
      expect(client.calls, hasLength(1));
      online.load(0, 'ru', retry: true);
      expect(client.calls, hasLength(2));
      client.replies.last.complete(const Interpretation(card: 'Карта'));
      await Future<void>.delayed(Duration.zero);
      expect(online.error(0, 'ru'), isNull);
      expect(online.result(0, 'ru')?.card, 'Карта');
      online.dispose();
    },
  );

  group('HTTP error handling', () {
    final request = InterpretationRequest(
      sessionId: 'a',
      language: 'en',
      deckId: 'celestial',
      spreadId: 'three',
      question: '',
      cards: [
        for (final id in ['star', 'world', 'strength'])
          {'id': id, 'reversed': false},
      ],
    );
    late HttpServer server;
    late InterpretationClient client;
    setUp(() async {
      server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(() => server.close(force: true));
      client = InterpretationClient(baseUrl: 'http://127.0.0.1:${server.port}');
    });
    Future<void> expectError(String code) => expectLater(
      client.interpret(request),
      throwsA(
        isA<InterpretationException>().having((e) => e.code, 'code', code),
      ),
    );

    for (final (status, body, code) in [
      (400, '{"error":"invalid_request"}', 'invalid_request'),
      (400, '{"error":"quota"}', 'unavailable'),
      (413, '{"error":"invalid_request"}', 'invalid_request'),
      (429, '{"error":"quota"}', 'quota'),
      (429, '{"error":"rate_limit"}', 'rate_limit'),
      (429, '{"error":"unknown"}', 'unavailable'),
      (503, '{"error":"invalid_request"}', 'unavailable'),
      (503, 'temporarily offline', 'unavailable'),
      (200, '{"card":"Star","synthesis":null}', 'unavailable'),
      (200, '{"synthesis":"Complete"}', 'unavailable'),
    ]) {
      test('$status $body maps to $code', () async {
        server.listen((incoming) async {
          await incoming.drain<void>();
          incoming.response.statusCode = status;
          incoming.response.write(body);
          await incoming.response.close();
        });
        await expectError(code);
      });
    }

    test(
      'a 303 redirect is rejected without contacting its destination',
      () async {
        final paths = <String>[];
        server.listen((incoming) async {
          paths.add(incoming.uri.path);
          await incoming.drain<void>();
          if (incoming.uri.path == '/v1/interpret') {
            incoming.response.statusCode = HttpStatus.seeOther;
            incoming.response.headers.set(
              HttpHeaders.locationHeader,
              '/redirected',
            );
          } else {
            incoming.response.write('{"card":"Star","synthesis":"Complete"}');
          }
          await incoming.response.close();
        });
        await expectError('unavailable');
        expect(paths, ['/v1/interpret']);
      },
    );

    test('a valid JSON response of 65,537 bytes is rejected', () async {
      server.listen((incoming) async {
        await incoming.drain<void>();
        incoming.response.write(
          '{"card":"Star","synthesis":"Complete"}'.padRight(65537),
        );
        await incoming.response.close();
      });
      await expectError('unavailable');
    });
  });

  test(
    'HTTP sends the reading to the service and parses the final synthesis',
    () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(() => server.close(force: true));
      final request = InterpretationRequest(
        sessionId: 'a',
        language: 'ru',
        deckId: 'celestial',
        spreadId: 'three',
        question: '',
        cards: [
          for (final id in ['star', 'world', 'strength'])
            {'id': id, 'reversed': false},
        ],
      );
      final client = InterpretationClient(
        baseUrl: 'http://127.0.0.1:${server.port}',
      );
      final pending = client.interpret(request);
      final received = await server.first;
      expect(received.uri.path, '/v1/interpret');
      expect(received.headers.value('x-goog-api-key'), isNull);
      expect(
        jsonDecode(await utf8.decoder.bind(received).join()),
        request.toJson(),
      );
      received.response.headers.contentType = ContentType.json;
      received.response.write(
        jsonEncode({'card': 'Карта', 'synthesis': 'Весь расклад'}),
      );
      await received.response.close();
      final value = await pending;
      expect(value.card, 'Карта');
      expect(value.synthesis, 'Весь расклад');
    },
  );
}
