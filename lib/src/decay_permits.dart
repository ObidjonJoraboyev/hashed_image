import 'dart:async';

/// Process-global limiter on concurrent blur-decay animations.
///
/// At most [maxConcurrent] decay animations run simultaneously; all others
/// queue and are admitted one-by-one as slots free up. Call [reset] (e.g. when
/// a parent list is refreshed) to cancel every pending waiter instantly.
class DecayPermits {
  DecayPermits._();

  /// Maximum simultaneously running decay animations.
  static const int maxConcurrent = 2;

  static int _active = 0;
  static final List<Completer<void>> _waiting = [];

  static Future<void> acquire() async {
    if (_active < maxConcurrent) {
      _active++;
      return;
    }
    final c = Completer<void>();
    _waiting.add(c);
    await c.future;
  }

  static void release() {
    if (_waiting.isNotEmpty) {
      _waiting.removeAt(0).complete();
    } else if (_active > 0) {
      _active--;
    }
  }

  /// Cancels every queued waiter and resets the active count to zero.
  static void reset() {
    for (final c in _waiting) {
      if (!c.isCompleted) c.completeError(StateError('cancelled'));
    }
    _waiting.clear();
    _active = 0;
  }
}
