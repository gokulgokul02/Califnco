// ============================================================
// EmailJS Service — Califnco Water Purifiers
// Free tier: 200 emails/month, no server required
//
// Setup steps:
//   1. Go to https://www.emailjs.com and create a free account
//   2. Add an Email Service (Gmail or Outlook)
//   3. Create an Email Template using the template IDs below
//   4. Copy your Public Key from Account → API Keys
//   5. Replace the placeholder values below with your real keys
//
// Templates to create in EmailJS dashboard:
//   • ORDER_CONFIRMATION_TEMPLATE_ID:
//       Subject: "Your Califnco Order #{{order_id}} is Confirmed!"
//       Variables: to_email, to_name, order_id, order_total,
//                  order_items, delivery_address, payment_method
//   • SERVICE_BOOKING_TEMPLATE_ID:
//       Subject: "Service Booking Confirmed — {{service_type}}"
//       Variables: to_email, to_name, service_type, preferred_date,
//                  time_slot, address, ticket_id
//   • DEALER_STATUS_TEMPLATE_ID:
//       Subject: "Your Califnco Dealer Application — {{status}}"
//       Variables: to_email, to_name, business_name, status, message
// ============================================================

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class EmailService {
  static final EmailService instance = EmailService._();
  EmailService._();

  // ── Configured real EmailJS credentials ──────────────────────────────────
  static const String _publicKey = 'Zr-AMtlqa6CM3htX3';
  static const String _serviceId = 'service_ypmbi0t';
  static const String _orderTemplateId = 'template_c7o77v8';
  static const String _serviceTemplateId = 'template_c7o77v8';
  static const String _dealerTemplateId = 'template_c7o77v8';

  static const String _emailJsUrl =
      'https://api.emailjs.com/api/v1.0/email/send';

  // ── Internal sender ───────────────────────────────────────────────────────
  Future<bool> _send(String templateId, Map<String, dynamic> params) async {
    // If credentials not configured, skip silently in debug
    if (_publicKey.isEmpty || _publicKey == 'YOUR_EMAILJS_PUBLIC_KEY') {
      debugPrint('[EmailJS] Skipped — public key not configured.');
      return true;
    }

    try {
      final body = {
        'service_id': _serviceId,
        'template_id': templateId,
        'user_id': _publicKey,
        'template_params': params,
      };

      final res = await http.post(
        Uri.parse(_emailJsUrl),
        headers: {
          'Content-Type': 'application/json',
          'origin': 'http://localhost',
        },
        body: jsonEncode(body),
      );

      if (res.statusCode == 200) {
        debugPrint('[EmailJS] Sent: $templateId → ${params['to_email']}');
        return true;
      } else {
        debugPrint('[EmailJS] Error ${res.statusCode}: ${res.body}');
        return false;
      }
    } catch (e) {
      debugPrint('[EmailJS] Exception: $e');
      return false;
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // ORDER CONFIRMATION EMAIL
  // Called after successful Razorpay payment or test checkout
  // ─────────────────────────────────────────────────────────────────────────
  Future<bool> sendOrderConfirmation({
    required String toEmail,
    required String toName,
    required String orderId,
    required double orderTotal,
    required String orderItems,      // e.g. "2x AquaPure RO, 1x UV Guard"
    required String deliveryAddress,
    required String paymentMethod,
  }) {
    return _send(_orderTemplateId, {
      'to_email': toEmail,
      'to_name': toName,
      'order_id': orderId,
      'order_total': '₹${orderTotal.toStringAsFixed(2)}',
      'order_items': orderItems,
      'delivery_address': deliveryAddress,
      'payment_method': paymentMethod,
      'company_name': 'Califnco Water Purifiers',
      'support_email': 'support@califnco.com',
      'support_phone': '+91 98765 43210',
    });
  }

  // ─────────────────────────────────────────────────────────────────────────
  // SERVICE BOOKING CONFIRMATION EMAIL
  // Called after service request is submitted
  // ─────────────────────────────────────────────────────────────────────────
  Future<bool> sendServiceBookingConfirmation({
    required String toEmail,
    required String toName,
    required String ticketId,
    required String serviceType,
    required String preferredDate,
    required String timeSlot,
    required String address,
  }) {
    return _send(_serviceTemplateId, {
      'to_email': toEmail,
      'to_name': toName,
      'ticket_id': ticketId,
      'service_type': serviceType,
      'preferred_date': preferredDate,
      'time_slot': timeSlot,
      'address': address,
      'company_name': 'Califnco Water Purifiers',
      'support_email': 'support@califnco.com',
      'support_phone': '+91 98765 43210',
    });
  }

  // ─────────────────────────────────────────────────────────────────────────
  // DEALER APPROVAL / REJECTION EMAIL
  // Called from admin panel when approving or rejecting a dealer
  // ─────────────────────────────────────────────────────────────────────────
  Future<bool> sendDealerStatusEmail({
    required String toEmail,
    required String toName,
    required String businessName,
    required String status,         // 'approved' or 'rejected'
    String? adminMessage,
  }) {
    final isApproved = status == 'approved';
    return _send(_dealerTemplateId, {
      'to_email': toEmail,
      'to_name': toName,
      'business_name': businessName,
      'status': isApproved ? 'APPROVED ✅' : 'REJECTED ❌',
      'status_message': isApproved
          ? 'Congratulations! Your dealer account is now active. '
            'You can now log in and access wholesale pricing.'
          : 'We regret to inform you that your application was not approved at this time.',
      'admin_note': adminMessage ?? '',
      'company_name': 'Califnco Water Purifiers',
      'support_email': 'support@califnco.com',
    });
  }
}
