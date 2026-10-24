import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// TextBee SMS Service — Califnco Water Purifiers
/// Free SMS Gateway via https://textbee.dev
///
/// Sends automated transaction SMS to customers for:
/// • Order Placed & Payment Confirmed
/// • Service Booking Confirmed
/// • Field Technician Dispatched
class SmsService {
  static final SmsService instance = SmsService._();
  SmsService._();

  // ── Configured TextBee credentials ───────────────────────────────────────
  static const String _apiKey = 'txb_EPlUiwIwLJRopu1TYS5F4XSzT3ws2EzN';
  static const String _deviceId = '6adb5893a4996b8ebf62b942';

  static const String _textbeeUrl =
      'https://api.textbee.dev/api/v1/gateway/send-sms';

  /// Format Indian/international phone numbers into E.164 (+91XXXXXXXXXX)
  static String formatPhoneNumber(String phone) {
    String clean = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    if (clean.startsWith('+')) {
      return clean;
    }
    if (clean.startsWith('91') && clean.length == 12) {
      return '+$clean';
    }
    if (clean.length == 10) {
      return '+91$clean';
    }
    return '+$clean';
  }

  /// Core sender
  Future<bool> sendSms({
    required String phone,
    required String message,
  }) async {
    if (_apiKey.isEmpty || _apiKey == 'YOUR_TEXTBEE_API_KEY') {
      debugPrint('[TextBee SMS] Skipped — API key not configured. Target: $phone, msg: $message');
      return true; // Don't crash app flow
    }

    final formattedPhone = formatPhoneNumber(phone);

    try {
      final payload = <String, dynamic>{
        'recipients': [formattedPhone],
        'message': message,
      };

      if (_deviceId.isNotEmpty) {
        payload['deviceId'] = _deviceId;
      }

      final response = await http.post(
        Uri.parse(_textbeeUrl),
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': _apiKey,
        },
        body: jsonEncode(payload),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        debugPrint('[TextBee SMS] Sent successfully to $formattedPhone');
        return true;
      } else {
        debugPrint('[TextBee SMS] Error ${response.statusCode}: ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('[TextBee SMS] Exception: $e');
      return false;
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // ORDER CONFIRMATION SMS
  // ─────────────────────────────────────────────────────────────────────────
  Future<bool> sendOrderConfirmationSms({
    required String phone,
    required String customerName,
    required String orderId,
    required double totalAmount,
  }) {
    final msg = 'Hello $customerName! Your Califnco Water Purifier order #$orderId '
        'of ₹${totalAmount.toStringAsFixed(0)} is confirmed. '
        'We are preparing your delivery. Tracking available in Califnco App. Thank you!';
    return sendSms(phone: phone, message: msg);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // SERVICE BOOKING CONFIRMATION SMS
  // ─────────────────────────────────────────────────────────────────────────
  Future<bool> sendServiceBookingSms({
    required String phone,
    required String customerName,
    required String ticketId,
    required String serviceType,
    required String preferredDate,
    required String timeSlot,
  }) {
    final msg = 'Hi $customerName, Califnco service ticket #$ticketId for $serviceType '
        'is scheduled on $preferredDate ($timeSlot). '
        'A certified RO engineer will visit your address. Support: +91 9361156175.';
    return sendSms(phone: phone, message: msg);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // TECHNICIAN ASSIGNED SMS
  // ─────────────────────────────────────────────────────────────────────────
  Future<bool> sendTechnicianAssignedSms({
    required String phone,
    required String customerName,
    required String technicianName,
    required String technicianPhone,
    required String serviceType,
  }) {
    final msg = 'Update from Califnco: Engineer $technicianName ($technicianPhone) '
        'has been assigned for your $serviceType. '
        'They will contact you prior to arrival.';
    return sendSms(phone: phone, message: msg);
  }
}
