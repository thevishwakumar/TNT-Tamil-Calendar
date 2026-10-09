import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// High-Reliability Network Resilience Helper for 1,000+ Concurrent Users
/// Coordinates:
/// - Request timeouts (prevents hanging connection threads)
/// - Bounded exponential backoff with full randomized jitter (prevents thundering herd)
/// - Transient-only failure filtering (safe idempotent operations only)
class TNTResilience {
  static final Random _random = Random();

  /// Execute an idempotent read or safe operation with bounded jittered retries
  static Future<T> retry<T>({
    required Future<T> Function() operation,
    int maxRetries = 2,
    Duration initialDelay = const Duration(milliseconds: 250),
    Duration timeout = const Duration(seconds: 10),
    String? operationName,
  }) async {
    int attempts = 0;
    while (true) {
      try {
        attempts++;
        return await operation().timeout(timeout, onTimeout: () {
          throw TimeoutException('Request timed out after ${timeout.inSeconds}s', timeout);
        });
      } catch (e) {
        final isLastAttempt = attempts > maxRetries;
        if (isLastAttempt || !_isTransientError(e)) {
          rethrow;
        }

        // Exponential backoff with full random jitter:
        // delay = initialDelay * 2^(attempts-1) * (0.5 to 1.5)
        final backoffMultiplier = pow(2, attempts - 1).toDouble();
        final baseDelayMs = (initialDelay.inMilliseconds * backoffMultiplier).round();
        final jitter = 0.5 + _random.nextDouble(); // 0.5 to 1.5
        final jitteredDelayMs = (baseDelayMs * jitter).round();

        if (kDebugMode && operationName != null) {
          debugPrint('[TNTResilience] Transient error in $operationName: $e. Retrying in ${jitteredDelayMs}ms (Attempt $attempts/$maxRetries)...');
        }

        await Future.delayed(Duration(milliseconds: jitteredDelayMs));
      }
    }
  }

  /// Determines if an error is a transient network or server load error
  static bool _isTransientError(dynamic e) {
    if (e is TimeoutException) return true;
    if (e is SocketException) return true;

    final errStr = e.toString().toLowerCase();
    if (errStr.contains('socketexception') ||
        errStr.contains('clientexception') ||
        errStr.contains('connection timed out') ||
        errStr.contains('connection closed') ||
        errStr.contains('connection reset') ||
        errStr.contains('broken pipe') ||
        errStr.contains('network is unreachable')) {
      return true;
    }

    if (e is PostgrestException) {
      final code = e.code;
      // 502 Bad Gateway, 503 Service Unavailable, 504 Gateway Timeout, 429 Too Many Requests
      if (code == '502' || code == '503' || code == '504' || code == '429' || code == 'PGRST000') {
        return true;
      }
    }

    return false;
  }
}
