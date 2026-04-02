import 'dart:async';

import 'package:fiksOpp/screens/auth/set_password_from_reset_screen.dart';
import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';

/// Cold-start link captured before [runApp] (see [main]).
class PendingDeepLink {
  static Uri? initialUri;
}

/// Password reset deep links: `fiksopp://password/reset?token=...&email=...`
/// or `https://fiksopp.com/.../reset-password?...` (after Android App Links / iOS associated domains).
class DeepLinkCoordinator {
  DeepLinkCoordinator._();

  static StreamSubscription<Uri>? _sub;

  /// Pass [AppLinks].uriLinkStream from a library that depends on `app_links` (e.g. [main]).
  static void startForegroundSubscription(Stream<Uri> uriStream) {
    _sub ??= uriStream.listen(_handleUri);
  }

  static void dispose() {
    _sub?.cancel();
    _sub = null;
  }

  /// Call after first navigation (e.g. from Splash) when [navigatorKey] is ready.
  static void consumeInitialUriIfAny() {
    final uri = PendingDeepLink.initialUri;
    PendingDeepLink.initialUri = null;
    if (uri != null) {
      _handleUri(uri);
    }
  }

  static void _handleUri(Uri uri) {
    if (!_isPasswordResetLink(uri)) return;
    final token = uri.queryParameters['token']?.trim() ??
        uri.queryParameters['reset_token']?.trim() ??
        '';
    if (token.isEmpty) return;

    final email = uri.queryParameters['email']?.trim();

    void push() {
      final nav = navigatorKey.currentState;
      if (nav == null) return;
      nav.push(
        MaterialPageRoute<void>(
          builder: (_) => SetPasswordFromResetScreen(
            resetToken: token,
            prefilledEmail: email,
          ),
        ),
      );
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future<void>.delayed(const Duration(milliseconds: 400), push);
    });
  }

  static bool _isPasswordResetLink(Uri uri) {
    final path = uri.path.toLowerCase();
    if (path.contains('reset-password') ||
        path.contains('password/reset') ||
        path.contains('forgot-password')) {
      return true;
    }
    if (uri.queryParameters.containsKey('token') ||
        uri.queryParameters.containsKey('reset_token')) {
      return true;
    }
    return false;
  }
}
