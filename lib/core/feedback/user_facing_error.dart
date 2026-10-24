import 'dart:io';

/// An error whose [message] is already written for the user and is shown as-is.
class UserMessageError implements Exception {
  const UserMessageError(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Maps technical failures to short messages safe to show users.
abstract final class UserFacingError {
  static String from(Object error) {
    if (error is UserMessageError) return error.message;
    if (error is SocketException) {
      return 'Unable to connect. Please check your internet connection and try again.';
    }
    final raw = error.toString().replaceFirst(RegExp(r'^Exception:\s*'), '').trim();
    final lower = raw.toLowerCase();

    if (lower.contains('socket') ||
        lower.contains('network') ||
        lower.contains('connection refused') ||
        lower.contains('failed host lookup') ||
        lower.contains('connection reset')) {
      return 'Unable to connect. Please check your internet connection and try again.';
    }
    if (lower.contains('timed out') || lower.contains('timeout')) {
      return 'The request took too long. Please try again.';
    }
    if (lower.contains('token') ||
        lower.contains('unauthenticated') ||
        lower.contains('unauthorized') ||
        lower.contains('not authenticated') ||
        lower.contains('session')) {
      return 'Your session has expired. Please sign in again.';
    }
    if (lower.contains('sqlstate') || lower.contains('integrity constraint') || lower.contains('duplicate')) {
      return 'Unable to save this information. Please check the details and try again.';
    }
    if (lower.contains('validation')) {
      return 'Some information needs your attention. Please check the highlighted fields.';
    }
    if (lower.contains('not found') || lower.contains('404')) {
      return 'We could not find that information.';
    }
    if (RegExp(r'request failed \(\d+\)').hasMatch(lower) || lower.contains('server error') || lower.contains('500')) {
      return 'Something went wrong on our side. Please try again in a moment.';
    }
    if (lower.contains('invalid response') || lower.contains('base_url')) {
      return 'Something went wrong. Please try again.';
    }

    // Hide stack traces, SQL, and long technical payloads.
    if (raw.length > 140 || raw.contains('\n') || raw.contains('Exception')) {
      return 'Something went wrong. Please try again.';
    }
    if (raw.isEmpty) {
      return 'Something went wrong. Please try again.';
    }
    return raw;
  }
}
