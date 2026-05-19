import 'package:facebook_app_events/facebook_app_events.dart';
import 'package:flutter/foundation.dart';

/// Centralized Meta / Facebook App Events tracking.
///
/// Goals:
///   • One place to call from screens — no SDK imports leak into UI code.
///   • Every SDK call is wrapped: a tracking failure must NEVER crash the app.
///   • Standard Meta event names (`fb_mobile_*`) are used so Events Manager,
///     Ads Manager and AEM (Aggregated Event Measurement) recognise them.
///   • No PII (email/phone/name) is sent to Meta. Only IDs and non-sensitive
///     campaign-relevant parameters.
///
/// Initialise once from `main()` BEFORE `runApp()`.
class FacebookEventsService {
  FacebookEventsService._();
  static final FacebookEventsService instance = FacebookEventsService._();

  final FacebookAppEvents _fb = FacebookAppEvents();
  bool _initialised = false;

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

  /// Idempotent. Safe to call from `main()`.
  Future<void> initialize() async {
    if (_initialised) return;
    try {
      // Required for iOS 14+ ATT compliance & accurate web→app attribution.
      // No-op on Android.
      await _fb.setAdvertiserTracking(enabled: true);
      await _fb.setAutoLogAppEventsEnabled(true);
      _initialised = true;
      _debug('Meta SDK initialized; auto app event logging enabled');
      _debug('Automatic first app launch / install attribution enabled');
    } catch (e, st) {
      _error('initialize failed', e, st);
    }
  }

  /// Call when a verified user signs in / out so Meta can deduplicate
  /// the same person across devices. We hash externally on the server in
  /// production; for testing we just send the raw user id (non-PII).
  Future<void> setUserId(String? userId) async {
    try {
      if (userId == null || userId.isEmpty) {
        await _fb.clearUserID();
      } else {
        await _fb.setUserID(userId);
      }
    } catch (e, st) {
      _error('setUserId failed', e, st);
    }
  }

  // ---------------------------------------------------------------------------
  // Standard events
  // ---------------------------------------------------------------------------

  /// fb_mobile_activate_app — fired on every cold start / app open.
  ///
  /// We disable manual app open event logging because only first-install /
  /// first-launch tracking should be reported.
  Future<void> logAppOpen() => _safe('logAppOpen', () async {
        _debug('Manual fb_mobile_activate_app logging disabled');
      });

  /// fb_mobile_login — successful authentication (email/phone/social).
  Future<void> logLoginSuccess({String? method}) =>
      _safe('logLoginSuccess', () async {
        _debug('Manual fb_mobile_login logging disabled');
      });

  /// fb_mobile_complete_registration — new account created.
  Future<void> logSignUpSuccess({String? method}) =>
      _safe('logSignUpSuccess', () async {
        _debug('Manual fb_mobile_complete_registration logging disabled');
      });

  /// fb_mobile_search — generic search. The flight-style helpers below
  /// are thin wrappers that delegate here, so the service stays
  /// domain-agnostic and reusable.
  Future<void> logSearch({
    required String searchString,
    Map<String, Object?> extra = const {},
  }) =>
      _safe('logSearch', () async {
        _debug('Manual fb_mobile_search logging disabled');
      });

  /// fb_mobile_content_view — user opened a detail page (service / flight / item).
  Future<void> logContentView({
    required String contentId,
    String? contentType,
    String? contentName,
    double? price,
    String currency = 'USD',
    Map<String, Object?> extra = const {},
  }) =>
      _safe('logContentView', () async {
        _debug('Manual fb_mobile_content_view logging disabled');
      });

  /// fb_mobile_initiated_checkout — user started the booking / checkout flow.
  Future<void> logStartBooking({
    required String contentId,
    double? amount,
    String currency = 'USD',
    int numItems = 1,
    Map<String, Object?> extra = const {},
  }) =>
      _safe('logStartBooking', () async {
        _debug('Manual fb_mobile_initiated_checkout logging disabled');
      });

  /// Custom — booking created in our backend (before / independent of payment).
  /// Useful for funnels that pay later (cash on delivery / pay-on-arrival).
  Future<void> logBookingCompleted({
    required String bookingId,
    double? amount,
    String currency = 'USD',
    Map<String, Object?> extra = const {},
  }) =>
      _safe('logBookingCompleted', () async {
        _debug('Manual booking_completed logging disabled');
      });

  /// fb_mobile_purchase — money has actually been collected.
  /// This is the conversion event most ad campaigns optimise toward.
  Future<void> logPaymentSuccess({
    required double amount,
    String currency = 'USD',
    String? bookingId,
    String? paymentMethod,
    Map<String, Object?> extra = const {},
  }) =>
      _safe('logPaymentSuccess', () async {
        _debug('Manual fb_mobile_purchase logging disabled');
      });

  // ---------------------------------------------------------------------------
  // Domain-specific helpers (flight-style names kept for the spec).
  // They delegate to the generic helpers above so existing service-booking
  // call sites can use the matching domain method without duplication.
  // ---------------------------------------------------------------------------

  Future<void> logSearchFlight({
    String? fromCity,
    String? toCity,
    String? departureDate,
    String? jetSize,
    int? passengers,
  }) =>
      logSearch(
        searchString: [fromCity, toCity].whereType<String>().join(' → '),
        extra: {
          'from_city': fromCity,
          'to_city': toCity,
          'departure_date': departureDate,
          'jet_size': jetSize,
          'passengers': passengers,
        },
      );

  Future<void> logViewFlightDetails({
    required String flightId,
    String? fromCity,
    String? toCity,
    String? departureDate,
    String? jetSize,
    double? price,
    String currency = 'USD',
  }) =>
      logContentView(
        contentId: flightId,
        contentType: 'flight',
        contentName: '${fromCity ?? ''}→${toCity ?? ''}',
        price: price,
        currency: currency,
        extra: {
          'flight_id': flightId,
          'from_city': fromCity,
          'to_city': toCity,
          'departure_date': departureDate,
          'jet_size': jetSize,
        },
      );

  // ---------------------------------------------------------------------------
  // Internals
  // ---------------------------------------------------------------------------

  Future<void> _safe(String tag, Future<void> Function() fn) async {
    if (!_initialised) {
      // Lazy-init so a missed `initialize()` call still works (silently).
      await initialize();
    }
    try {
      await fn();
      _debug(tag);
    } catch (e, st) {
      _error('$tag failed', e, st);
    }
  }

  void _debug(String msg) {
    if (kDebugMode) {
      // ignore: avoid_print
      print('[FBEvents] $msg');
    }
  }

  void _error(String msg, Object e, StackTrace st) {
    if (kDebugMode) {
      // ignore: avoid_print
      print('[FBEvents] $msg: $e\n$st');
    }
  }
}
