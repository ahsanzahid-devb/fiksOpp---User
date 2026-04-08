import 'dart:async';
import 'dart:io';

/// Phone Auth on iOS fetches reCAPTCHA config from Identity Toolkit; this
/// fails with [FirebaseAuthException] `network-request-failed` when offline.
Future<bool> canReachIdentityToolkitHost({
  Duration timeout = const Duration(seconds: 4),
}) async {
  try {
    final list = await InternetAddress.lookup(
      'identitytoolkit.googleapis.com',
    ).timeout(timeout);
    return list.isNotEmpty;
  } on SocketException {
    return false;
  } on TimeoutException {
    return false;
  } catch (_) {
    return false;
  }
}

/// Shown before [FirebaseAuth.verifyPhoneNumber] when DNS fails (offline / blocked).
const String kPhoneAuthNeedsInternetMessage =
    'Cannot reach Google sign-in services. Use Wi‑Fi or cellular data, turn off '
    'flight mode, and ensure VPNs or firewalls are not blocking googleapis.com.';
