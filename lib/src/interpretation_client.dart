import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data' show BytesBuilder;

import '../reading.dart';

class Interpretation {
  const Interpretation({required this.card, this.synthesis});
  final String card;
  final String? synthesis;
}

String newReadingId() {
  final random = Random.secure();
  final bytes = List.generate(16, (_) => random.nextInt(256));
  bytes[6] = (bytes[6] & 0x0f) | 0x40;
  bytes[8] = (bytes[8] & 0x3f) | 0x80;
  final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
}

class InterpretationRequest {
  InterpretationRequest({
    required this.sessionId,
    required this.language,
    required this.deckId,
    required this.spreadId,
    required this.question,
    required this.cards,
  });
  final String sessionId, language, deckId, spreadId, question;
  final List<Map<String, Object>> cards;
  final String token = newReadingId();
  HttpClient? _connection;

  Map<String, Object> toJson() => {
    'sessionId': sessionId,
    'language': language,
    'deckId': deckId,
    'spreadId': spreadId,
    'question': question,
    'cards': cards,
  };

  /// Stop local I/O without cancelling a job already accepted by the Worker.
  void cancelTransport() => _connection?.close(force: true);
}

class InterpretationException implements Exception {
  const InterpretationException(this.code);
  final String code;
}

/// Only the Worker talks to Google. A null reply means the job is still pending.
class InterpretationClient {
  const InterpretationClient({
    this.baseUrl = const String.fromEnvironment(
      'ARCANA_SERVICE_URL',
      defaultValue:
          'https://arcana-observatory-readings.lubacareer.workers.dev',
    ),
  });
  final String baseUrl;

  Future<Interpretation?> interpret(InterpretationRequest request) =>
      _exchange(request, submit: true);

  Future<Interpretation?> status(InterpretationRequest request) =>
      _exchange(request, submit: false);

  Future<Interpretation?> _exchange(
    InterpretationRequest request, {
    required bool submit,
  }) async {
    final origin = Uri.tryParse(baseUrl);
    if (origin == null ||
        !origin.hasAuthority ||
        origin.userInfo.isNotEmpty ||
        (origin.scheme != 'https' &&
            !(origin.scheme == 'http' &&
                ['127.0.0.1', 'localhost', '::1'].contains(origin.host)))) {
      throw const InterpretationException('unavailable');
    }
    final http = HttpClient()..connectionTimeout = const Duration(seconds: 10);
    request._connection = http;
    try {
      final path = submit ? '/v1/interpret' : '/v1/interpret/status';
      return await _send(
        http,
        origin.resolve(path),
        request,
        submit,
      ).timeout(const Duration(seconds: 15));
    } on InterpretationException {
      rethrow;
    } on Exception {
      throw const InterpretationException('disconnected');
    } finally {
      http.close(force: true);
      if (identical(request._connection, http)) request._connection = null;
    }
  }

  Future<Interpretation?> _send(
    HttpClient http,
    Uri uri,
    InterpretationRequest reading,
    bool submit,
  ) async {
    final req = await http.openUrl(submit ? 'POST' : 'GET', uri);
    req.followRedirects = false;
    req.headers.set('X-Reading-Token', reading.token);
    if (submit) {
      req.headers.contentType = ContentType.json;
      req.write(jsonEncode(reading.toJson()));
    }
    final response = await req.close();
    final bytes = BytesBuilder(copy: false);
    await for (final part in response) {
      if (bytes.length + part.length > 65536) {
        throw const InterpretationException('disconnected');
      }
      bytes.add(part);
    }
    final data = jsonDecode(utf8.decode(bytes.takeBytes()));
    if (data is! Map) throw const InterpretationException('disconnected');
    final status = response.statusCode;
    if (status == HttpStatus.accepted && data['status'] == 'pending') {
      return null;
    }
    if (status != HttpStatus.ok) {
      final error = data['error'];
      if (error == 'invalid_request' &&
          const {
            HttpStatus.badRequest,
            HttpStatus.conflict,
            HttpStatus.requestEntityTooLarge,
            HttpStatus.unsupportedMediaType,
          }.contains(status)) {
        throw const InterpretationException('invalid_request');
      }
      if (status == HttpStatus.tooManyRequests &&
          (error == 'quota' || error == 'rate_limit')) {
        throw InterpretationException(error as String);
      }
      if (!submit && status == HttpStatus.notFound && error == 'not_found') {
        throw const InterpretationException('not_found');
      }
      // An intermediary can return the very same HTTP status as a stored
      // provider failure. Only the Worker's explicit marker permits a new job.
      if (response.headers.value('X-Reading-State') == 'terminal' &&
          ((status == HttpStatus.gatewayTimeout && error == 'timeout') ||
              (status == HttpStatus.serviceUnavailable &&
                  error == 'unavailable'))) {
        throw InterpretationException(error as String);
      }
      throw const InterpretationException('disconnected');
    }
    final card = data['card'];
    if (card is! String || card.trim().isEmpty) {
      throw const InterpretationException('disconnected');
    }
    final total = SpreadType.values.byName(reading.spreadId).positions.length;
    final needsSynthesis = total > 1 && reading.cards.length == total;
    final synthesis = data['synthesis'];
    if (needsSynthesis
        ? synthesis is! String || synthesis.trim().isEmpty
        : synthesis != null) {
      throw const InterpretationException('disconnected');
    }
    return Interpretation(
      card: card.trim(),
      synthesis: (synthesis as String?)?.trim(),
    );
  }
}
