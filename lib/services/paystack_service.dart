import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

import '../model/payment_gateway_response.dart';

class PayStackService {
  late BuildContext ctx;
  num totalAmount = 0;
  int bookingId = 0;
  late Function(Map<String, dynamic>) onComplete;
  late Function(bool) loderOnOFF;
  PaymentSetting? currentPaymentMethod;

  init(
      {required BuildContext context,
      required PaymentSetting currentPaymentMethod,
      required num totalAmount,
      required int bookingId,
      required Function(Map<String, dynamic>) onComplete,
      required Function(bool) loderOnOFF}) {
    ctx = context;
    this.totalAmount = totalAmount;
    this.bookingId = bookingId;
    this.onComplete = onComplete;
    this.loderOnOFF = loderOnOFF;
    this.currentPaymentMethod = currentPaymentMethod;
  }

  Future checkout() async {
    loderOnOFF(true);
    Fluttertoast.showToast(
        msg:
            'PayStack payment is currently unavailable. Please use another payment method.');
    loderOnOFF(false);
    return;
  }
}
