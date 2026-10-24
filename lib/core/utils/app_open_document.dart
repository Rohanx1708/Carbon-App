import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:attendance/core/feedback/app_feedback.dart';
import 'package:attendance/core/feedback/user_facing_error.dart';
import 'package:attendance/services/app_config.dart';

/// Opens a document / file URL in the system browser or viewer.
abstract final class AppOpenDocument {
  /// Turns API paths like `/storage/...` into an absolute URL.
  static Uri? resolveUri(String? raw) {
    final s = raw?.trim() ?? '';
    if (s.isEmpty) return null;
    final parsed = Uri.tryParse(s);
    if (parsed == null) return null;
    if (parsed.hasScheme) return parsed;
    final base = AppConfig.baseUrl.trim();
    if (base.isEmpty) return null;
    return Uri.parse(base).resolve(s.startsWith('/') ? s.substring(1) : s);
  }

  static Future<void> open(BuildContext context, String? rawUrl) async {
    final uri = resolveUri(rawUrl);
    if (uri == null) {
      AppFeedback.error(context, UserMessageError('This file has no openable link'));
      return;
    }
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok && context.mounted) {
        AppFeedback.error(context, UserMessageError('Could not open this file'));
      }
    } catch (e) {
      if (context.mounted) AppFeedback.error(context, e);
    }
  }
}
