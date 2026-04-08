import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Structured logs for phone auth debugging (filter: `FirebaseAuth|`).
void logFirebaseAuthException(String tag, FirebaseAuthException e) {
  debugPrint('[FirebaseAuth|$tag] code=${e.code}');
  debugPrint('[FirebaseAuth|$tag] message=${e.message}');
  debugPrint(
      '[FirebaseAuth|$tag] email=${e.email} phoneNumber=${e.phoneNumber}');
}

/// Firebase sometimes fires two failures for one [verifyPhoneNumber] call:
/// - [internal-error] right after [too-many-requests]/[quota-exceeded]
/// - a second [internal-error] with the same generic message
/// Suppress the extra snackbar so the user sees one clear message.
bool shouldSuppressRedundantPhoneAuthFailure({
  required FirebaseAuthException current,
  required String? previousCode,
  required DateTime? previousFailureTime,
  Duration window = const Duration(seconds: 5),
}) {
  if (previousFailureTime == null || previousCode == null) return false;
  if (current.code != 'internal-error') return false;
  final age = DateTime.now().difference(previousFailureTime);
  if (age >= window) return false;
  if (previousCode == 'too-many-requests' || previousCode == 'quota-exceeded') {
    return true;
  }
  if (previousCode == 'internal-error') {
    return true;
  }
  return false;
}

String userFacingFirebaseAuthMessage(FirebaseAuthException e) {
  switch (e.code) {
    case 'internal-error':
      return 'Phone verification failed (internal-error). This is usually app or '
          'Firebase setup—not the phone number. On iOS: Firebase Console → Project '
          'settings → your iOS app → check APNs auth key and bundle ID match this '
          'build; complete any browser/reCAPTCHA step; try disabling App Check '
          'enforcement for debug. Also wait if Firebase recently rate-limited this '
          'device. See Firebase Authentication troubleshooting for Phone.';
    case 'invalid-app-credential':
      return 'App check failed (APNs / Play integrity / SHA-1). '
          'Code: invalid-app-credential';
    case 'missing-app-credential':
      return 'App verification token missing. On iOS enable push for this app '
          'and APNs key in Firebase. Code: missing-app-credential';
    case 'notification-not-forwarded':
      return 'Push setup issue: notifications must reach Firebase Auth. '
          'Update the app or check Firebase iOS settings. Code: notification-not-forwarded';
    case 'invalid-phone-number':
      return 'Invalid phone number for this country code.';
    case 'invalid-verification-code':
      return ''; // Caller uses language string
    case 'session-expired':
      return 'This code expired. Tap send again for a new SMS. Code: session-expired';
    case 'quota-exceeded':
    case 'too-many-requests':
      final detail = e.message?.trim();
      if (detail != null &&
          detail.isNotEmpty &&
          !detail.toLowerCase().contains('too many')) {
        return '$detail Wait 30–60 minutes or use another phone number.';
      }
      return 'Too many verification attempts—Firebase temporarily blocked this device. '
          'Wait 30–60 minutes, try another number, or use email sign-up. (${e.code})';
    case 'network-request-failed':
      return 'No connection to Google (phone verification). Turn on Wi‑Fi or '
          'cellular, disable flight mode, and try again. VPNs or firewalls '
          'that block googleapis.com can cause this. (${e.code})';
    case 'captcha-check-failed':
      return 'Verification check failed. Try again or update the app. (${e.code})';
    default:
      final m = e.message?.trim();
      if (m != null &&
          m.isNotEmpty &&
          !m.toLowerCase().contains('internal error has occurred')) {
        return m;
      }
      return 'Phone verification failed (${e.code}). '
          'If this persists, contact support with this code.';
  }
}
