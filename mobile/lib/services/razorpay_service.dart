import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

class RazorpayService {
  static final RazorpayService instance = RazorpayService._();
  RazorpayService._();

  Razorpay? _razorpay;
  Function(PaymentSuccessResponse)? _onSuccess;
  Function(PaymentFailureResponse)? _onError;
  Function(ExternalWalletResponse)? _onWallet;

  void initialize({
    required Function(PaymentSuccessResponse) onSuccess,
    required Function(PaymentFailureResponse) onError,
    Function(ExternalWalletResponse)? onWallet,
  }) {
    _onSuccess = onSuccess;
    _onError = onError;
    _onWallet = onWallet;

    _razorpay = Razorpay();
    _razorpay!.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay!.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay!.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    _onSuccess?.call(response);
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    _onError?.call(response);
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    _onWallet?.call(response);
  }

  void openCheckout({
    required double amount,
    required String customerName,
    required String customerPhone,
    required String customerEmail,
    String? keyId,
  }) {
    // Standard default Razorpay Test Key ID if none provided
    final testKey = keyId != null && keyId.isNotEmpty
        ? keyId
        : 'rzp_test_1DP5mmOlF5G5ag';

    final options = {
      'key': testKey,
      'amount': (amount * 100).round(), // In paise
      'name': 'Califnco Water Purifiers',
      'description': 'Order Payment (Test Mode)',
      'prefill': {
        'contact': customerPhone.isNotEmpty ? customerPhone : '9876543210',
        'email': customerEmail.isNotEmpty ? customerEmail : 'customer@califnco.com',
        'name': customerName.isNotEmpty ? customerName : 'Valued Customer',
      },
      'theme': {
        'color': '#087f8c',
      },
      'modal': {
        'confirm_close': true,
      }
    };

    try {
      _razorpay?.open(options);
    } catch (e) {
      debugPrint('Razorpay open failed: $e');
    }
  }

  void dispose() {
    _razorpay?.clear();
  }
}
