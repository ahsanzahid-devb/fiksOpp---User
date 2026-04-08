import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:http/http.dart' as http;
import 'package:http/http.dart';
import 'package:nb_utils/nb_utils.dart';
import '../../main.dart';
import '../model/payment_gateway_response.dart';
import '../model/stripe_pay_model.dart';
import '../network/network_utils.dart';
import '../utils/colors.dart';
import '../utils/common.dart';
import '../utils/configs.dart';

class StripeServiceNew {
  late PaymentSetting paymentSetting;
  num totalAmount = 0;
  late Function(Map<String, dynamic>) onComplete;

  static final MethodChannel _stripeIosWindowChannel = MethodChannel(
    'fiksopp/stripe_ios',
  );

  static Future<void> _syncStripeIosPresentationWindow() async {
    if (kIsWeb) return;
    if (!Platform.isIOS) return;
    Object? lastError;
    for (var i = 0; i < 6; i++) {
      try {
        await _stripeIosWindowChannel.invokeMethod<void>(
          'syncPresentationWindow',
        );
        return;
      } catch (e) {
        lastError = e;
        await Future<void>.delayed(const Duration(milliseconds: 80));
      }
    }
    log('[Stripe] iOS window sync channel failed after retries: $lastError');
  }

  static Future<void> _logStripeIosPresenterDiagnostics() async {
    if (kIsWeb || !Platform.isIOS) return;
    try {
      final m = await _stripeIosWindowChannel
          .invokeMethod<Map<dynamic, dynamic>>('diagnoseStripePresenter');
      if (m != null) {
        log('[Stripe] iOS presenter diagnostics: ${jsonEncode(m)}');
      }
    } catch (e) {
      log('[Stripe] diagnoseStripePresenter failed: $e');
    }
  }

  static Future<void> _awaitUiSettledAfterGlobalLoader() async {
    final completer = Completer<void>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future<void>.delayed(const Duration(milliseconds: 320), () {
        if (!completer.isCompleted) completer.complete();
      });
    });
    await completer.future;
  }

  StripeServiceNew({
    required PaymentSetting paymentSetting,
    required num totalAmount,
    required Function(Map<String, dynamic>) onComplete,
  }) {
    this.paymentSetting = paymentSetting;
    this.totalAmount = totalAmount;
    this.onComplete = onComplete;
  }

  Future<dynamic> stripePay({bool Function()? isMounted}) async {
    String stripePaymentKey = '';
    String stripeURL = '';
    String stripePaymentPublishKey = '';

    if (paymentSetting.isTest == 1) {
      stripePaymentKey = paymentSetting.testValue!.stripeKey.validate();
      stripeURL = paymentSetting.testValue!.stripeUrl.validate();
      stripePaymentPublishKey =
          paymentSetting.testValue!.stripePublickey.validate();
    } else {
      stripePaymentKey = paymentSetting.liveValue!.stripeKey!;
      stripeURL = paymentSetting.liveValue!.stripeUrl!;
      stripePaymentPublishKey = paymentSetting.liveValue!.stripePublickey!;
    }
    if (stripePaymentKey.isEmpty ||
        stripeURL.isEmpty ||
        stripePaymentPublishKey.isEmpty)
      throw language.accessDeniedContactYourAdmin;

    Stripe.publishableKey = stripePaymentPublishKey;
    // Deep link for 3DS / redirect payment methods (must match iOS/Android URL scheme).
    Stripe.urlScheme = 'fiksopp';

    try {
      await Stripe.instance.applySettings();
    } catch (e, stack) {
      log('[Stripe] applySettings failed: $e');
      log('[Stripe] Stack: $stack');
      toast(e.toString(), print: true);
      rethrow;
    }

    final pk = Stripe.publishableKey;
    final masked = pk.isEmpty
        ? '(empty)'
        : '${pk.substring(0, pk.length.clamp(0, 16))}…(len=${pk.length})';
    log('[Stripe] publishableKey (masked): $masked');

    String finalStripeURL = stripeURL;
    if (stripeURL.endsWith('api.stripe.com') ||
        stripeURL.endsWith('api.stripe.com/')) {
      finalStripeURL = stripeURL.endsWith('/')
          ? '${stripeURL}v1/payment_intents'
          : '$stripeURL/v1/payment_intents';
    }

    Request request = http.Request(
      HttpMethodType.POST.name,
      Uri.parse(finalStripeURL),
    );

    request.bodyFields = {
      'amount': '${(totalAmount * 100).toInt()}',
      'currency': paymentGatewayCurrencyCode(),
      'description':
          'Name: ${appStore.userFullName} - Email: ${appStore.userEmail}',
      'payment_method_types[]': 'card',
    };

    request.headers.addAll(buildHeaderForStripe(stripePaymentKey));

    log('URL: ${request.url}');
    final safe = Map<String, String>.from(request.headers);
    safe.removeWhere((k, _) => k.toLowerCase() == 'authorization');
    log('[Stripe] Headers (authorization redacted): $safe');
    log('Request: ${request.bodyFields}');

    appStore.setLoading(true);
    try {
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      log('Stripe API Response Status: ${response.statusCode}');
      log('Stripe API Response Body: ${response.body}');

      if (response.statusCode.isSuccessful()) {
        StripePayModel res = StripePayModel.fromJson(jsonDecode(response.body));

        if (res.clientSecret.validate().isEmpty) {
          appStore.setLoading(false);
          throw 'Failed to get payment intent from Stripe';
        }

        appStore.setLoading(false);
        await _awaitUiSettledAfterGlobalLoader();

        final merchantName =
            APP_NAME.trim().isEmpty ? 'Fiksopp' : APP_NAME.trim();
        final setupPaymentSheetParameters = SetupPaymentSheetParameters(
          paymentIntentClientSecret: res.clientSecret.validate(),
          // System avoids mismatch with forced app [ThemeMode] and matches Stripe defaults.
          style: ThemeMode.system,
          appearance: PaymentSheetAppearance(
            colors: PaymentSheetAppearanceColors(primary: primaryColor),
          ),
          merchantDisplayName: merchantName,
          returnURL: 'fiksopp://stripe-pay',
          billingDetails: BillingDetails(
            name: appStore.userFullName,
            email: appStore.userEmail,
          ),
        );

        try {
          log('[Stripe] initPaymentSheet…');
          await Stripe.instance.initPaymentSheet(
            paymentSheetParameters: setupPaymentSheetParameters,
          );
          log('[Stripe] initPaymentSheet done');

          final mounted = isMounted?.call() ?? true;
          log('[Stripe] About to present — caller mounted: $mounted');
          if (!mounted) {
            log('[Stripe] Skipping presentPaymentSheet — widget not mounted');
            throw 'Payment screen was closed before checkout could open.';
          }

          final root = navigatorKey.currentContext;
          log('[Stripe] presentPaymentSheet… rootContext=${root != null}');
          await _syncStripeIosPresentationWindow();
          await _logStripeIosPresenterDiagnostics();
          await Stripe.instance.presentPaymentSheet();
          log(
            '[Stripe] presentPaymentSheet returned (sheet completed, cancelled, or failed)',
          );
        } on StripeException catch (e, stack) {
          log('[Stripe] StripeException code: ${e.error.code}');
          log(
            '[Stripe] StripeException message: ${e.error.localizedMessage}',
          );
          log('[Stripe] StripeException type: ${e.error.type}');
          log(
            '[Stripe] StripeException declineCode: ${e.error.declineCode}',
          );
          log('[Stripe] Stack: $stack');
          if (e.error.code == FailureCode.Canceled) {
            log('User canceled Stripe payment');
          } else {
            final msg =
                e.error.localizedMessage ?? e.error.message ?? e.toString();
            toast(msg, print: true);
          }
          rethrow;
        } catch (e, stack) {
          log('[Stripe] Checkout error (init/present): $e');
          log('[Stripe] Stack: $stack');
          final msg = e.toString();
          if (!msg.contains('closed before checkout')) {
            toast(msg, print: true);
          }
          rethrow;
        }

        onComplete.call({'transaction_id': res.id});
      } else {
        appStore.setLoading(false);
        final errorBody = response.body;
        log('Stripe API Error: $errorBody');
        String message =
            errorBody.isNotEmpty ? errorBody : errorSomethingWentWrong;
        try {
          final decoded = jsonDecode(errorBody);
          if (decoded is Map &&
              decoded['error'] is Map &&
              decoded['error']['message'] is String) {
            message = decoded['error']['message'] as String;
          }
        } catch (_) {}
        throw message;
      }
    } catch (e) {
      appStore.setLoading(false);
      if (e is StripeException) {
        throw e.toString();
      }

      log('Stripe Payment Error: $e');
      final errorString = e.toString();
      if (errorString.contains('Canceled') ||
          errorString.contains('canceled')) {
        log('User canceled Stripe payment');
      } else {
        toast(e.toString(), print: true);
      }
      throw e.toString();
    }
  }
}
