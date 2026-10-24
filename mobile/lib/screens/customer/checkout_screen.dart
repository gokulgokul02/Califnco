import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../../services/cart_service.dart';
import '../../services/email_service.dart';
import '../../services/firebase_service.dart';
import '../../services/sms_service.dart';
import '../../services/location_service.dart';
import '../../services/razorpay_service.dart';
import '../../widgets/map_location_picker.dart';
import '../../widgets/success_popup.dart';
import 'order_history_screen.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _cityCtrl = TextEditingController(text: 'Chennai');
  final _stateCtrl = TextEditingController(text: 'Tamil Nadu');
  final _pincodeCtrl = TextEditingController(text: '600001');

  bool _isProcessing = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final user = FirebaseService.instance.currentUser;
    if (user != null) {
      _nameCtrl.text = user.displayName ?? '';
      _loadSavedProfile(user.uid);
    }

    // Initialize Razorpay Callbacks
    RazorpayService.instance.initialize(
      onSuccess: _handleRazorpaySuccess,
      onError: _handleRazorpayError,
      onWallet: _handleRazorpayWallet,
    );
  }

  Future<void> _loadSavedProfile(String uid) async {
    final profile = await FirebaseService.instance.getUserProfile(uid);
    if (profile != null && mounted) {
      setState(() {
        if (_nameCtrl.text.isEmpty) _nameCtrl.text = profile.name;
        if (profile.phone.isNotEmpty) _phoneCtrl.text = profile.phone;
        if (profile.address.isNotEmpty) _addressCtrl.text = profile.address;
      });
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    _cityCtrl.dispose();
    _stateCtrl.dispose();
    _pincodeCtrl.dispose();
    RazorpayService.instance.dispose();
    super.dispose();
  }

  void _handleRazorpaySuccess(PaymentSuccessResponse response) async {
    await _finalizeOrder(
      paymentMethod: 'razorpay_test',
      paymentStatus: 'paid',
      razorpayPaymentId: response.paymentId ?? 'rzp_test_success',
    );
  }

  void _handleRazorpayError(PaymentFailureResponse response) {
    setState(() {
      _isProcessing = false;
      _errorMessage = 'Razorpay Error: ${response.message ?? "Payment cancelled"}';
    });
  }

  void _handleRazorpayWallet(ExternalWalletResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('External wallet chosen: ${response.walletName}')),
    );
  }

  Future<void> _finalizeOrder({
    required String paymentMethod,
    required String paymentStatus,
    String? razorpayPaymentId,
  }) async {
    final cart = CartService.instance;
    final fullAddress = '${_addressCtrl.text.trim()}, ${_cityCtrl.text.trim()}, ${_stateCtrl.text.trim()} - ${_pincodeCtrl.text.trim()}';

    try {
      final orderId = await FirebaseService.instance.createOrder(
        items: cart.toOrderItems(),
        subtotal: cart.subtotal,
        tax: cart.tax,
        discount: cart.discount,
        total: cart.grandTotal,
        shippingAddress: fullAddress,
        customerPhone: _phoneCtrl.text.trim(),
        customerName: _nameCtrl.text.trim(),
        paymentMethod: paymentMethod,
        paymentStatus: paymentStatus,
        razorpayPaymentId: razorpayPaymentId,
        isDealer: cart.isDealer,
      );

      // Asynchronously trigger order confirmation email via EmailJS
      final userEmail = FirebaseService.instance.currentUser?.email ?? '';
      final formattedCode = 'ORD-${orderId.substring(0, orderId.length > 8 ? 8 : orderId.length).toUpperCase()}';
      if (userEmail.isNotEmpty) {
        final itemsSummary = cart.items
            .map((i) => '${i.quantity}x ${i.product.name}')
            .join(', ');
        EmailService.instance.sendOrderConfirmation(
          toEmail: userEmail,
          toName: _nameCtrl.text.trim(),
          orderId: formattedCode,
          orderTotal: cart.grandTotal,
          orderItems: itemsSummary,
          deliveryAddress: fullAddress,
          paymentMethod: paymentMethod,
        );
      }

      // Asynchronously trigger order confirmation SMS via TextBee
      final customerPhone = _phoneCtrl.text.trim();
      if (customerPhone.isNotEmpty) {
        SmsService.instance.sendOrderConfirmationSms(
          phone: customerPhone,
          customerName: _nameCtrl.text.trim(),
          orderId: formattedCode,
          totalAmount: cart.grandTotal,
        );
      }

      cart.clearCart();

      if (mounted) {
        CalifncoSuccessDialog.show(
          context,
          title: 'Order Confirmed! 🎉',
          subtitle: 'Thank you! Your Califnco water purifier order has been received and verified.',
          referenceId: '#ORD-${orderId.substring(0, orderId.length > 8 ? 8 : orderId.length).toUpperCase()}',
          referenceLabel: 'Order ID',
          details: [
            SuccessPopupItem(
              icon: Icons.person_outline,
              label: 'Recipient',
              value: _nameCtrl.text.trim(),
            ),
            SuccessPopupItem(
              icon: Icons.location_on_outlined,
              label: 'Delivery To',
              value: '${_cityCtrl.text.trim()} - ${_pincodeCtrl.text.trim()}',
            ),
            SuccessPopupItem(
              icon: Icons.payment_outlined,
              label: 'Payment',
              value: razorpayPaymentId != null ? 'Razorpay (Verified)' : 'Standard Checkout',
            ),
            SuccessPopupItem(
              icon: Icons.local_shipping_outlined,
              label: 'Dispatch',
              value: 'Expected within 24-48 hrs',
            ),
          ],
          primaryButtonText: 'View in Order History',
          onPrimaryPressed: () {
            Navigator.pop(context); // Close dialog
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const OrderHistoryScreen()),
            );
          },
          secondaryButtonText: 'Back to Home',
          onSecondaryPressed: () {
            Navigator.pop(context);
            Navigator.pop(context);
          },
        );
      }
    } catch (e) {
      setState(() {
        _isProcessing = false;
        _errorMessage = 'Order creation failed: $e';
      });
    }
  }

  Future<void> _fetchGPSLocation() async {
    // Show loading dialog with circular indicator and logo inside
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => PopScope(
        canPop: false,
        child: Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 86,
                  height: 86,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      const SizedBox(
                        width: 86,
                        height: 86,
                        child: CircularProgressIndicator(
                          strokeWidth: 3.5,
                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xff087f8c)),
                          backgroundColor: Color(0x22087f8c),
                        ),
                      ),
                      Container(
                        width: 54,
                        height: 54,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: Padding(
                            padding: const EdgeInsets.all(6.0),
                            child: Image.asset(
                              'assets/logo.png',
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) => const Icon(
                                Icons.water_drop,
                                color: Color(0xff087f8c),
                                size: 28,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Detecting GPS Location',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xff087f8c),
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Fetching your current address & coordinates...',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      final loc = await LocationService.instance.getCurrentLocation();
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        if (loc != null) {
          setState(() {
            _addressCtrl.text = loc.formattedAddress;
            if (loc.city.isNotEmpty) _cityCtrl.text = loc.city;
            if (loc.state.isNotEmpty) _stateCtrl.text = loc.state;
            if (loc.postalCode.isNotEmpty) _pincodeCtrl.text = loc.postalCode;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Delivery address updated from GPS!'),
              backgroundColor: Color(0xff087f8c),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not fetch location. Please check GPS permissions.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to fetch GPS: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _submitCheckout() async {
    if (!_formKey.currentState!.validate()) return;

    final cart = CartService.instance;
    if (cart.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cart is empty')));
      return;
    }

    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    final user = FirebaseService.instance.currentUser;
    final paymentSettings = await FirebaseService.instance.getPaymentSettings();
    final activeMode = paymentSettings['activeMode'] as String? ?? 'test';
    final activeKey = activeMode == 'live'
        ? (paymentSettings['liveKeyId'] as String? ?? '')
        : (paymentSettings['testKeyId'] as String? ?? 'rzp_test_1DP5mmOlF5G5ag');

    RazorpayService.instance.openCheckout(
      amount: cart.grandTotal,
      customerName: _nameCtrl.text.trim(),
      customerPhone: _phoneCtrl.text.trim(),
      customerEmail: user?.email ?? 'customer@califnco.com',
      keyId: activeKey.isNotEmpty ? activeKey : 'rzp_test_1DP5mmOlF5G5ag',
    );
  }

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xff087f8c);
    final cart = CartService.instance;

    return Scaffold(
      appBar: AppBar(title: const Text('Checkout & Delivery')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Delivery Address Form
              Card(
                elevation: 1.5,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.location_on, color: primary),
                          SizedBox(width: 8),
                          Text('Shipping Address', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        ],
                      ),
                      const Divider(height: 20),
                      TextFormField(
                        controller: _nameCtrl,
                        decoration: const InputDecoration(labelText: 'Receiver Name *', border: OutlineInputBorder()),
                        validator: (v) => v!.isEmpty ? 'Enter name' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _phoneCtrl,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(labelText: 'Contact Phone Number *', border: OutlineInputBorder()),
                        validator: (v) => v!.length < 10 ? 'Enter valid phone' : null,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Delivery Address *',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87),
                          ),
                          Row(
                            children: [
                              TextButton.icon(
                                style: TextButton.styleFrom(
                                  visualDensity: VisualDensity.compact,
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                ),
                                icon: const Icon(Icons.my_location, size: 16, color: primary),
                                label: const Text('GPS', style: TextStyle(fontSize: 12, color: primary)),
                                onPressed: _fetchGPSLocation,
                              ),
                              TextButton.icon(
                                style: TextButton.styleFrom(
                                  visualDensity: VisualDensity.compact,
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                ),
                                icon: const Icon(Icons.map, size: 16, color: primary),
                                label: const Text('Pin on Map', style: TextStyle(fontSize: 12, color: primary)),
                                onPressed: () async {
                                  final currentCtx = context;
                                  final loc = await MapLocationPickerModal.show(currentCtx);
                                  if (loc != null && mounted) {
                                    setState(() {
                                      _addressCtrl.text = loc.formattedAddress;
                                      if (loc.city.isNotEmpty) _cityCtrl.text = loc.city;
                                      if (loc.state.isNotEmpty) _stateCtrl.text = loc.state;
                                      if (loc.postalCode.isNotEmpty) _pincodeCtrl.text = loc.postalCode;
                                    });
                                  }
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      TextFormField(
                        controller: _addressCtrl,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          hintText: 'House / Flat / Street Address *',
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) => v!.isEmpty ? 'Enter street address' : null,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _cityCtrl,
                              decoration: const InputDecoration(labelText: 'City *', border: OutlineInputBorder()),
                              validator: (v) => v!.isEmpty ? 'Enter city' : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _pincodeCtrl,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(labelText: 'PIN Code *', border: OutlineInputBorder()),
                              validator: (v) => v!.length != 6 ? '6-digits' : null,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Payment Method Card (Razorpay Gateway)
              Card(
                elevation: 1.5,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.payment, color: primary),
                              SizedBox(width: 8),
                              Text('Payment Method', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.shield_outlined, size: 13, color: primary),
                                SizedBox(width: 4),
                                Text(
                                  '100% Secure',
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: primary),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 20),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: primary.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: primary.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: primary.withValues(alpha: 0.12),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.lock_outline, color: primary, size: 22),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Razorpay Payment Gateway',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    'UPI (GPay / PhonePe / Paytm), Cards, NetBanking',
                                    style: TextStyle(fontSize: 12, color: Colors.black54),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.check_circle, color: primary, size: 22),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              if (_errorMessage != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Text(_errorMessage!, style: TextStyle(color: Colors.red.shade900)),
                ),
              ],

              const SizedBox(height: 24),

              // Total & Pay Button
              SizedBox(
                height: 52,
                child: FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: primary),
                  onPressed: _isProcessing ? null : _submitCheckout,
                  child: _isProcessing
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          'Pay ₹${cart.grandTotal.toStringAsFixed(2)} & Place Order',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
