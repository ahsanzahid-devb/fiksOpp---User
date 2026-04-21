import 'dart:developer' as developer;

import 'package:country_picker/country_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Digits-only national number from [Country.fullExampleWithPlusSign] when set
/// (strips calling code once). Otherwise uses [Country.example] digits only.
String? _phoneAuthNationalDigitsSample(Country country) {
  final cc = country.phoneCode.replaceAll(RegExp(r'[^0-9]'), '');
  final full = country.fullExampleWithPlusSign;
  if (full != null && full.isNotEmpty) {
    final all = full.replaceAll(RegExp(r'[^0-9]'), '');
    if (cc.isNotEmpty && all.startsWith(cc) && all.length > cc.length) {
      return all.substring(cc.length);
    }
  }
  final ex = country.example.replaceAll(RegExp(r'[^0-9]'), '');
  return ex.isEmpty ? null : ex;
}

/// Expected length of the **national** part (what the user types beside the
/// country code), derived from the country picker’s official example for **all**
/// countries. Strips one national trunk `0` so Pakistan is 10 (e.g. `3012345678`),
/// not 11.
///
/// Use for [TextField.maxLength] and submit validation.
int phoneAuthExpectedLocalDigitLength(Country country) {
  var sample = _phoneAuthNationalDigitsSample(country);
  if (sample == null || sample.isEmpty) {
    return _phoneAuthFallbackLocalDigitLength(country);
  }
  if (sample.startsWith('0') && sample.length > 1) {
    sample = sample.substring(1);
  }
  final n = sample.length;
  if (n < 6) {
    return _phoneAuthFallbackLocalDigitLength(country);
  }
  return n.clamp(6, 15);
}

int _phoneAuthFallbackLocalDigitLength(Country country) {
  final cc = country.phoneCode.replaceAll(RegExp(r'[^0-9]'), '');
  if (cc.isEmpty) return 15;
  return (15 - cc.length).clamp(6, 15);
}

/// E.164 for [FirebaseAuth.verifyPhoneNumber]: `+[countryCode][national digits]`.
///
/// Strips one leading `0` from the local part when present (national trunk prefix;
/// e.g. Pakistan `0317…` → `317…` → `+92317…`, not invalid `+920317…`).
String firebasePhoneAuthE164({
  required String countryCallingCodeDigits,
  required String localNumberRaw,
}) {
  final cc = countryCallingCodeDigits.replaceAll(RegExp(r'\D'), '');
  var national = localNumberRaw.replaceAll(RegExp(r'\D'), '');
  if (national.startsWith('0') && national.length > 1) {
    national = national.substring(1);
  }
  return '+$cc$national';
}

/// Structured logs for phone auth debugging (filter: `FirebaseAuth|`).
void logFirebaseAuthException(String tag, FirebaseAuthException e) {
  debugPrint('[FirebaseAuth|$tag] code=${e.code}');
  debugPrint('[FirebaseAuth|$tag] message=${e.message}');
  debugPrint(
      '[FirebaseAuth|$tag] email=${e.email} phoneNumber=${e.phoneNumber}');
  final tenant = e.tenantId;
  if (tenant != null && tenant.isNotEmpty) {
    debugPrint('[FirebaseAuth|$tag] tenantId=$tenant');
  }
  final cred = e.credential;
  if (cred != null) {
    debugPrint('[FirebaseAuth|$tag] credentialProvider=${cred.providerId}');
  }
  logPhoneAuthFailureDiagnostics(tag: tag, e: e);
}

/// Extra context before calling [FirebaseAuth.verifyPhoneNumber].
/// Filter logs: `[PhoneAuth|preVerify]`.
void logPhoneAuthPreVerifyContext({
  required String phoneE164,
  String? countryIso,
  String? dialCode,
  int? localNumberLength,
}) {
  final mode = kReleaseMode
      ? 'release'
      : kProfileMode
          ? 'profile'
          : 'debug';
  final buf = StringBuffer('[PhoneAuth|preVerify]')
    ..write(' buildMode=$mode')
    ..write(' platform=$defaultTargetPlatform')
    ..write(' phoneE164=$phoneE164');
  if (countryIso != null) buf.write(' countryIso=$countryIso');
  if (dialCode != null) buf.write(' dialCode=$dialCode');
  if (localNumberLength != null) {
    buf.write(' localNumberLength=$localNumberLength');
  }
  debugPrint(buf.toString());
  developer.log(buf.toString(), name: 'PhoneAuth.preVerify');
}

/// After any [FirebaseAuthException] from phone auth — runbook for iOS
/// [internal-error] and other hard failures. Filter: `PhoneAuth.runbook`.
void logPhoneAuthFailureDiagnostics({
  required String tag,
  required FirebaseAuthException e,
}) {
  final summary = firebaseAuthExceptionSummary(e);
  developer.log(
    'failure tag=$tag $summary',
    name: 'PhoneAuth.failure',
  );

  if (defaultTargetPlatform == TargetPlatform.iOS) {
    developer.log(
      'iOS checklist (App Store Connect does NOT configure Firebase Phone Auth): '
      'match Firebase Console iOS app bundle ID to Xcode; upload APNs Auth Key in '
      'Firebase Project settings → Cloud Messaging; enable Push capability; '
      'debug uses aps-environment=development entitlements, release uses production — '
      'both need the key in Firebase; disable App Check debug enforcement or register '
      'debug token; test on a physical device.',
      name: 'PhoneAuth.runbook',
    );
    if (e.code == 'internal-error' || e.code == 'missing-app-credential') {
      debugPrint(
        '[PhoneAuth|runbook] iOS ${e.code}: see logs named PhoneAuth.runbook + '
        'Firebase project fiksopp-bb927 → iOS app → APNs',
      );
    }
  }
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

/// Exact Firebase error for debugging / snackbars (code + server message).
String firebaseAuthExceptionSummary(FirebaseAuthException e) {
  final m = e.message?.trim();
  if (m != null && m.isNotEmpty) {
    return '${e.code}: $m';
  }
  return '${e.code} (no message from Firebase)';
}

String userFacingFirebaseAuthMessage(FirebaseAuthException e) {
  switch (e.code) {
    case 'internal-error':
      // Show the real SDK error; e.email / e.phoneNumber are often null here by design.
      final summary = firebaseAuthExceptionSummary(e);
      final m = e.message?.toLowerCase() ?? '';
      if (m.contains('internal error has occurred')) {
        return '$summary · iOS: APNs key + bundle ID in Firebase; try App Check off for debug.';
      }
      return summary;
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
