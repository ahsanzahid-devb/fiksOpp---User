import 'dart:convert';

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

  StripeServiceNew({
    required PaymentSetting paymentSetting,
    required num totalAmount,
    required Function(Map<String, dynamic>) onComplete,
  }) {
    this.paymentSetting = paymentSetting;
    this.totalAmount = totalAmount;
    this.onComplete = onComplete;
  }

  //StripPayment
  Future<dynamic> stripePay() async {
    String stripePaymentKey = '';
    String stripeURL = '';
    String stripePaymentPublishKey = '';

    if (paymentSetting.isTest == 1) {
      stripePaymentKey = paymentSetting.testValue!.stripeKey.validate();
      stripeURL = paymentSetting.testValue!.stripeUrl.validate();
      stripePaymentPublishKey = paymentSetting.testValue!.stripePublickey.validate();
    } else {
      stripePaymentKey = paymentSetting.liveValue!.stripeKey!;
      stripeURL = paymentSetting.liveValue!.stripeUrl!;
      stripePaymentPublishKey = paymentSetting.liveValue!.stripePublickey!;
    }
    if (stripePaymentKey.isEmpty || stripeURL.isEmpty || stripePaymentPublishKey.isEmpty) throw language.accessDeniedContactYourAdmin;

    Stripe.merchantIdentifier = 'merchant.flutter.stripe.test';
    Stripe.publishableKey = stripePaymentPublishKey;

    Stripe.instance.applySettings().catchError((e) {
      toast(e.toString(), print: true);

      throw e.toString();
    });

    // Ensure the Stripe URL has the correct endpoint
    // If it's just the base URL, append the payment_intents endpoint
    String finalStripeURL = stripeURL;
    if (stripeURL.endsWith('api.stripe.com') || stripeURL.endsWith('api.stripe.com/')) {
      finalStripeURL = stripeURL.endsWith('/') 
          ? '${stripeURL}v1/payment_intents' 
          : '$stripeURL/v1/payment_intents';
    }

    Request request = http.Request(HttpMethodType.POST.name, Uri.parse(finalStripeURL));

    request.bodyFields = {
      'amount': '${(totalAmount * 100).toInt()}',
      'currency': await isIqonicProduct ? STRIPE_CURRENCY_CODE : '${appConfigurationStore.currencyCode}',
      'description': 'Name: ${appStore.userFullName} - Email: ${appStore.userEmail}',
    };

    request.headers.addAll(buildHeaderForStripe(stripePaymentKey));

    log('URL: ${request.url}');
    log('Header: ${request.headers}');
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

        SetupPaymentSheetParameters setupPaymentSheetParameters = SetupPaymentSheetParameters(
          paymentIntentClientSecret: res.clientSecret.validate(),
          style: appThemeMode,
          appearance: PaymentSheetAppearance(colors: PaymentSheetAppearanceColors(primary: primaryColor)),
          applePay: PaymentSheetApplePay(merchantCountryCode: STRIPE_MERCHANT_COUNTRY_CODE),
          googlePay: PaymentSheetGooglePay(merchantCountryCode: STRIPE_MERCHANT_COUNTRY_CODE, testEnv: paymentSetting.isTest == 1),
          merchantDisplayName: APP_NAME,
          customerId: appStore.userId.toString(),
          // customerEphemeralKeySecret: isAndroid ? res.id.validate() : null,
          setupIntentClientSecret: res.clientSecret.validate(),
          billingDetails: BillingDetails(name: appStore.userFullName, email: appStore.userEmail),
        );

        await Stripe.instance.initPaymentSheet(paymentSheetParameters: setupPaymentSheetParameters);
        await Stripe.instance.presentPaymentSheet();
        
        onComplete.call({
          'transaction_id': res.id,
        });
        appStore.setLoading(false);
      } else {
        appStore.setLoading(false);
        final errorBody = response.body;
        log('Stripe API Error: $errorBody');
        throw errorBody.isNotEmpty ? errorBody : errorSomethingWentWrong;
      }
    } catch (e) {
      appStore.setLoading(false);
      log('Stripe Payment Error: $e');
      
      // Don't show error toast if user canceled the payment
      final errorString = e.toString();
      if (errorString.contains('Canceled') || errorString.contains('canceled')) {
        // User canceled - this is normal, don't show error
        log('User canceled Stripe payment');
      } else {
        // Real error - show toast
        toast(e.toString(), print: true);
      }
      throw e.toString();
    }
  }
}
