import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fiksOpp/utils/firebase_auth_phone_utils.dart';

/// Regression / documentation tests for Firebase Phone Auth helpers.
/// Does not call Firebase — only pure Dart logic.
void main() {
  group('shouldSuppressRedundantPhoneAuthFailure', () {
    test('suppresses internal-error after too-many-requests within window', () {
      final t = DateTime.now();
      expect(
        shouldSuppressRedundantPhoneAuthFailure(
          current: FirebaseAuthException(code: 'internal-error'),
          previousCode: 'too-many-requests',
          previousFailureTime: t,
        ),
        true,
      );
    });

    test('does not suppress internal-error when previous failure is too old', () {
      final t = DateTime.now().subtract(const Duration(seconds: 10));
      expect(
        shouldSuppressRedundantPhoneAuthFailure(
          current: FirebaseAuthException(code: 'internal-error'),
          previousCode: 'too-many-requests',
          previousFailureTime: t,
        ),
        false,
      );
    });
  });

  test(
      'userFacingFirebaseAuthMessage internal-error hints iOS APNs when message is generic',
      () {
    final e = FirebaseAuthException(
      code: 'internal-error',
      message:
          'An internal error has occurred, print and inspect the error details for more information.',
    );
    final msg = userFacingFirebaseAuthMessage(e);
    expect(msg.toLowerCase(), contains('apns'));
  });

  test('firebasePhoneAuthE164 strips leading 0 from national number', () {
    // Pakistan example: 317... after stripping leading 0 from 0317...
    final e164 = firebasePhoneAuthE164(
      countryCallingCodeDigits: '92',
      localNumberRaw: '03174869556',
    );
    expect(e164, '+923174869556');
  });
}
