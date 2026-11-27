import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data' show BytesBuilder;

import 'package:flutter/foundation.dart';

import 'reading.dart';

class Interpretation {
  const Interpretation({required this.card, this.synthesis});
  final String card;
  final String? synthesis;
}

class InterpretationRequest {
  const InterpretationRequest({
    required this.sessionId,
    required this.language,
    required this.deckId,
    required this.spreadId,
    required this.question,
    required this.cards,
  });
  final String sessionId, language, deckId, spreadId, question;
  final List<Map<String, Object>> cards;

  Map<String, Object> toJson() => {
    'sessionId': sessionId,
    'language': language,
    'deckId': deckId,
    'spreadId': spreadId,
    'question': question,
    'cards': cards,
  };
}

class InterpretationException implements Exception {
  const InterpretationException(this.code);
  final String code;
}

/// The apps know the public service origin. Only the Worker talks to Google.
class InterpretationClient {
  const InterpretationClient({
    this.baseUrl = const String.fromEnvironment(
      'ARCANA_SERVICE_URL',
      defaultValue:
          'https://arcana-observatory-readings.lubacareer.workers.dev',
    ),
  });
  final String baseUrl;

  Future<Interpretation> interpret(InterpretationRequest request) async {
    final origin = Uri.tryParse(baseUrl);
    if (origin == null ||
        !origin.hasAuthority ||
        origin.userInfo.isNotEmpty ||
        (origin.scheme != 'https' &&
            !(origin.scheme == 'http' &&
                ['127.0.0.1', 'localhost', '::1'].contains(origin.host)))) {
      throw const InterpretationException('unavailable');
    }
    final http = HttpClient()..connectionTimeout = const Duration(seconds: 12);
    try {
      return await _post(
        http,
        origin.resolve('/v1/interpret'),
        request,
      ).timeout(const Duration(seconds: 105));
    } on InterpretationException {
      rethrow;
    } on Exception {
      throw const InterpretationException('unavailable');
    } finally {
      http.close(force: true);
    }
  }

  Future<Interpretation> _post(
    HttpClient client,
    Uri uri,
    InterpretationRequest reading,
  ) async {
    final req = await client.postUrl(uri);
    req.followRedirects = false;
    req.headers.contentType = ContentType.json;
    req.write(jsonEncode(reading.toJson()));
    final response = await req.close();
    final bytes = BytesBuilder(copy: false);
    await for (final part in response) {
      if (bytes.length + part.length > 65536) {
        throw const InterpretationException('unavailable');
      }
      bytes.add(part);
    }
    final data = jsonDecode(utf8.decode(bytes.takeBytes()));
    if (response.statusCode != HttpStatus.ok) {
      final error = data is Map ? data['error'] : null;
      if (response.statusCode == HttpStatus.tooManyRequests &&
          (error == 'quota' || error == 'rate_limit')) {
        throw InterpretationException(error as String);
      }
      throw const InterpretationException('unavailable');
    }
    if (data is! Map ||
        data['card'] is! String ||
        (data['card'] as String).trim().isEmpty) {
      throw const InterpretationException('unavailable');
    }
    final total = SpreadType.values.byName(reading.spreadId).positions.length;
    final needsSynthesis = total > 1 && reading.cards.length == total;
    final synthesis = data['synthesis'];
    if (needsSynthesis
        ? synthesis is! String || synthesis.trim().isEmpty
        : synthesis != null) {
      throw const InterpretationException('unavailable');
    }
    return Interpretation(
      card: (data['card'] as String).trim(),
      synthesis: (synthesis as String?)?.trim(),
    );
  }
}

/// A reading owns its requests. Navigation and rebuilds can ask for the same
/// card freely; late replies update only their original reading and language.
class ReadingInterpretations extends ChangeNotifier {
  ReadingInterpretations({
    required this.session,
    required this.client,
    String question = '',
    this.online = true,
  }) : question = question.trim();
  final ReadingSession session;
  final InterpretationClient client;
  final String question;
  final bool online;
  final String _id = _sessionId();
  final _results = <(int, String), Interpretation>{};
  final _errors = <(int, String), String>{};
  final _pending = <(int, String)>{};
  bool _disposed = false;

  Interpretation? result(int index, String language) =>
      _results[(index, language)];
  String? error(int index, String language) => _errors[(index, language)];
  bool loading(int index, String language) =>
      _pending.contains((index, language));

  void load(int index, String language, {bool retry = false}) {
    final key = (index, language);
    if (_disposed ||
        !online ||
        index < 0 ||
        index >= session.draws.length ||
        !session.draws[index].isRevealed ||
        _results.containsKey(key) ||
        (_errors.containsKey(key) && !retry) ||
        !_pending.add(key)) {
      return;
    }
    _errors.remove(key);
    final request = InterpretationRequest(
      sessionId: _id,
      language: language,
      deckId: session.deck.id,
      spreadId: session.spread.name,
      question: question,
      cards: [
        for (final draw in session.draws.take(index + 1))
          {'id': draw.card.id, 'reversed': draw.isReversed},
      ],
    );
    notifyListeners();
    unawaited(_fetch(key, request));
  }

  Future<void> _fetch((int, String) key, InterpretationRequest request) async {
    try {
      final value = await client.interpret(request);
      if (!_disposed) _results[key] = value;
    } catch (error) {
      if (!_disposed) {
        _errors[key] = error is InterpretationException
            ? error.code
            : 'unavailable';
      }
    } finally {
      _pending.remove(key);
      if (!_disposed) notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  static String _sessionId() {
    final random = Random.secure();
    final bytes = List.generate(16, (_) => random.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
  }
}
