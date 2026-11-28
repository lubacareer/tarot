import 'dart:async';

import 'package:flutter/foundation.dart';

import 'reading.dart';
import 'src/interpretation_client.dart';
export 'src/interpretation_client.dart' hide newReadingId;

class _Attempt {
  _Attempt(this.request, this.deadline);
  final InterpretationRequest request;
  final DateTime deadline;
  Interpretation? result;
  String? error;
  Timer? timer;
  bool posted = false, accepted = false, disconnected = false, busy = false;
  int generation = 0, delaySeconds = 2;

  void pause() {
    timer?.cancel();
    generation++;
    busy = false;
    request.cancelTransport();
  }
}

/// A reading owns one attempt per reveal and language. Backgrounding cancels
/// local requests and timers; the Worker's job can finish independently.
class ReadingInterpretations extends ChangeNotifier {
  ReadingInterpretations({
    required this.session,
    required this.client,
    String question = '',
    this.online = true,
    this.now = DateTime.now,
  }) : question = question.trim();
  final ReadingSession session;
  final InterpretationClient client;
  final String question;
  final bool online;
  final DateTime Function() now;
  final String _id = newReadingId();
  final _attempts = <(int, String), _Attempt>{};
  bool _disposed = false, _foreground = true;

  Interpretation? result(int index, String language) =>
      _attempts[(index, language)]?.result;
  String? error(int index, String language) =>
      _attempts[(index, language)]?.error;
  bool reconnecting(int index, String language) =>
      _attempts[(index, language)]?.disconnected == true;
  bool loading(int index, String language) {
    final attempt = _attempts[(index, language)];
    return attempt != null && attempt.result == null && attempt.error == null;
  }

  void load(int index, String language, {bool retry = false}) {
    final key = (index, language);
    final previous = _attempts[key];
    if (_disposed ||
        !online ||
        index < 0 ||
        index >= session.draws.length ||
        !session.draws[index].isRevealed) {
      return;
    }
    if (previous != null) {
      if (!retry ||
          previous.error == null ||
          previous.error == 'check_again' ||
          previous.error == 'expired') {
        return;
      }
      previous.pause();
    }
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
    final attempt = _Attempt(request, now().add(const Duration(minutes: 4)));
    _attempts[key] = attempt;
    notifyListeners();
    if (_foreground) unawaited(_fetch(attempt, submit: true));
  }

  /// Outside the automatic reconnection window, check only the existing job.
  void checkAgain(int index, String language) {
    final attempt = _attempts[(index, language)];
    if (_disposed || !_foreground || attempt?.error != 'check_again') return;
    attempt!.error = null;
    notifyListeners();
    unawaited(_fetch(attempt, submit: false));
  }

  void setForeground(bool foreground) {
    if (_disposed || _foreground == foreground) return;
    _foreground = foreground;
    for (final attempt in _attempts.values) {
      if (attempt.result != null || attempt.error != null) continue;
      if (foreground) {
        unawaited(_fetch(attempt, submit: !attempt.posted));
      } else {
        attempt.pause();
      }
    }
  }

  Future<void> _fetch(_Attempt attempt, {required bool submit}) async {
    if (_disposed || !_foreground || attempt.busy) return;
    final generation = attempt.generation;
    attempt.busy = true;
    if (submit) attempt.posted = true;
    bool resubmit = false;
    try {
      final reply = await (submit
          ? client.interpret(attempt.request)
          : client.status(attempt.request));
      if (generation != attempt.generation) return;
      attempt.accepted = true;
      attempt.disconnected = false;
      attempt.result = reply;
    } on Exception catch (error) {
      if (generation != attempt.generation) return;
      final code = error is InterpretationException
          ? error.code
          : 'disconnected';
      switch (code) {
        case 'disconnected':
          attempt.disconnected = true;
        case 'not_found':
          // A dropped POST may never have arrived. Re-submit only after a
          // confirmed miss, with identical input and the same idempotency key.
          resubmit = !attempt.accepted && now().isBefore(attempt.deadline);
          if (!resubmit) attempt.error = 'expired';
        default:
          attempt.error = code;
      }
    } finally {
      if (generation == attempt.generation) {
        attempt.busy = false;
      }
    }
    if (_disposed || generation != attempt.generation) return;
    if (resubmit) {
      unawaited(_fetch(attempt, submit: true));
    } else if (attempt.result == null && attempt.error == null) {
      _schedule(attempt);
    }
    notifyListeners();
  }

  void _schedule(_Attempt attempt) {
    final remaining = attempt.deadline.difference(now());
    final interval = Duration(seconds: attempt.delaySeconds);
    attempt.delaySeconds = (attempt.delaySeconds * 2).clamp(2, 8);
    if (remaining <= Duration.zero) {
      attempt.error = 'check_again';
    } else if (remaining <= interval) {
      attempt.timer = Timer(remaining, () {
        attempt.error = 'check_again';
        notifyListeners();
      });
    } else {
      attempt.timer = Timer(
        interval,
        () => unawaited(_fetch(attempt, submit: false)),
      );
    }
  }

  @override
  void dispose() {
    _disposed = true;
    for (final attempt in _attempts.values) {
      attempt.pause();
    }
    super.dispose();
  }
}
