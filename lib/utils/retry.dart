import 'dart:async';

Future<T> retry<T>(
  Future<T> Function() fn, {
  int maxAttempts = 3,
  Duration baseDelay = const Duration(seconds: 1),
  Set<Type>? retryableErrors,
}) async {
  for (int attempt = 1; attempt <= maxAttempts; attempt++) {
    try {
      return await fn();
    } catch (e) {
      if (attempt == maxAttempts) rethrow;
      if (retryableErrors != null && !retryableErrors.any((t) => t.isInstanceOfType(e.runtimeType))) {
        rethrow;
      }
      await Future.delayed(baseDelay * (1 << (attempt - 1)));
    }
  }
  throw StateError('Unreachable');
}
