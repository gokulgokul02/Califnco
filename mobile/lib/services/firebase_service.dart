// ============================================================
// Califnco Firebase Service
// Handles: Auth (Customer / Dealer / Admin), Firestore CRUD,
//          FCM Push Notifications
//
// Auth Roles:
//   customer — default after email sign-up
//   dealer   — submits GSTIN application, pending → approved by admin
//   admin    — set manually in Firestore users/{uid}.role = 'admin'
//
// FCM Setup:
//   • Token saved to users/{uid}.fcmToken on every login
//   • Background handler registered in main() via onBackgroundMessage
//   • Foreground messages handled via onMessage stream
// ============================================================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import '../models/dealer.dart';
import '../models/order.dart';
import '../models/product.dart';
import '../models/service_request.dart';
import '../models/user_profile.dart';
import 'mock_data.dart';
import 'notification_service.dart';

// ── FCM background handler — must be top-level (not inside class) ────────
// This runs even when the app is fully killed (dead state).
// For data-only messages, we show a local notification manually.
// For notification messages, Android FCM SDK shows it automatically.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Firebase is already initialised by the time this runs
  debugPrint('[FCM Background] title=${message.notification?.title} '
      'body=${message.notification?.body} data=${message.data}');

  // If the FCM message is a data-only message (no notification payload),
  // show it as a local notification so the user sees it in the status bar.
  if (message.notification == null && message.data.isNotEmpty) {
    final title = message.data['title'] ?? 'Califnco';
    final body = message.data['body'] ?? message.data['message'] ?? '';
    if (body.isNotEmpty) {
      await NotificationService.instance.showSystemNotification(
        title: title,
        body: body,
        payload: message.data['type'],
      );
    }
  }
}

class FirebaseService {
  static final FirebaseService instance = FirebaseService._();
  FirebaseService._();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;

  static final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();

  static final Set<String> _recentAlertKeys = {};

  static void showInAppAlert(String title, String body, {String? type}) {
    final cleanTitle = title.trim();
    final cleanBody = body.trim();
    if (cleanTitle.isEmpty && cleanBody.isEmpty) return;

    final dedupKey = '${cleanTitle.toLowerCase()}|${cleanBody.toLowerCase()}';
    if (_recentAlertKeys.contains(dedupKey)) {
      debugPrint('[InAppAlert Dedup] Skipping duplicate: $dedupKey');
      return; // Skip duplicate notification when app is in foreground
    }
    _recentAlertKeys.add(dedupKey);
    Future.delayed(const Duration(seconds: 15), () {
      _recentAlertKeys.remove(dedupKey);
    });

    scaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(12),
        backgroundColor: const Color(0xff087f8c),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Row(
          children: [
            const Icon(Icons.notifications_active, color: Colors.white, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(cleanTitle, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                  Text(cleanBody, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  // ── Convenience getters ──────────────────────────────────────────────────
  User? get currentUser => _auth.currentUser;
  String? get currentUid => _auth.currentUser?.uid;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // ─────────────────────────────────────────────────────────────────────────
  // AUTH — EMAIL + PASSWORD
  // ─────────────────────────────────────────────────────────────────────────

  /// Sign in (customer, dealer, or admin — role determined from Firestore)
  Future<Map<String, dynamic>> signIn(String email, String password) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final uid = cred.user!.uid;

    // Fetch role from Firestore
    final doc = await _db.collection('users').doc(uid).get();
    final role = doc.data()?['role'] as String? ?? 'customer';

    // Save FCM token on every login
    await _saveFcmToken(uid);

    return {
      'user': cred.user,
      'role': role,
      'profile': doc.data(),
    };
  }

  /// Register a new customer account
  Future<UserCredential> registerCustomer({
    required String email,
    required String password,
    required String name,
    required String phone,
    String? referralCodeUsed,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final user = cred.user!;
    await user.updateDisplayName(name);

    // Generate unique referral code: CALIF + first 5 chars of uid
    final refCode =
        'CALIF${user.uid.substring(0, user.uid.length > 5 ? 5 : user.uid.length).toUpperCase()}';

    // Apply referral credit if a valid code was entered
    double referralCredits = 0;
    if (referralCodeUsed != null && referralCodeUsed.trim().isNotEmpty) {
      // Check the code exists
      final refSnap = await _db
          .collection('users')
          .where('referralCode', isEqualTo: referralCodeUsed.trim().toUpperCase())
          .limit(1)
          .get();
      if (refSnap.docs.isNotEmpty) {
        referralCredits = 200.0;
        // Credit the referrer with ₹150
        final referrerId = refSnap.docs.first.id;
        await _db.collection('users').doc(referrerId).update({
          'referralCredits': FieldValue.increment(150),
          'referralCount': FieldValue.increment(1),
        });

        // Record real referral transaction for audit
        await _db.collection('referrals').add({
          'referrerId': referrerId,
          'referredUserId': user.uid,
          'referredUserName': name,
          'referralCode': referralCodeUsed.trim().toUpperCase(),
          'bonusToNewUser': 200.0,
          'bonusToReferrer': 150.0,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    }

    await _db.collection('users').doc(user.uid).set({
      'name': name,
      'email': email.trim(),
      'phone': phone,
      'role': 'customer',
      'referralCode': refCode,
      'referralCredits': referralCredits,
      'referralCount': 0,
      'referralCodeUsed': referralCodeUsed ?? '',
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await _saveFcmToken(user.uid);
    return cred;
  }

  /// Dealer registers — creates a user with role 'dealer' + pending application
  Future<UserCredential> registerDealer({
    required String email,
    required String password,
    required String name,
    required String phone,
    required String businessName,
    required String gstin,
    required String address,
    required String city,
    required String state,
    required String pincode,
    int yearsInBusiness = 1,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final user = cred.user!;
    await user.updateDisplayName(name);

    // Create user doc with dealer role
    await _db.collection('users').doc(user.uid).set({
      'name': name,
      'email': email.trim(),
      'phone': phone,
      'role': 'dealer',
      'dealerStatus': 'pending',
      'businessName': businessName,
      'createdAt': FieldValue.serverTimestamp(),
    });

    // Create dealer application document
    await _db.collection('dealers').doc(user.uid).set({
      'userId': user.uid,
      'businessName': businessName,
      'contactPerson': name,
      'email': email.trim(),
      'phone': phone,
      'gstin': gstin.toUpperCase(),
      'address': address,
      'city': city,
      'state': state,
      'pincode': pincode,
      'yearsInBusiness': yearsInBusiness,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });

    await _saveFcmToken(user.uid);
    return cred;
  }

  /// Sign out current user
  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// Send password reset email
  Future<void> sendPasswordReset(String email) async {
    await _auth.sendPasswordResetEmail(email: email.trim());
  }

  /// Get role of currently signed-in user
  Future<String> getCurrentRole() async {
    final uid = currentUid;
    if (uid == null) return 'guest';
    try {
      final doc = await _db.collection('users').doc(uid).get();
      return doc.data()?['role'] as String? ?? 'customer';
    } catch (_) {
      return 'customer';
    }
  }

  /// Get role + dealerStatus + technicianStatus together (used by AuthGate for approval checks)
  Future<Map<String, String>> getFullProfile() async {
    final uid = currentUid;
    if (uid == null) return {'role': 'guest', 'dealerStatus': '', 'technicianStatus': ''};
    try {
      final doc = await _db.collection('users').doc(uid).get();
      final data = doc.data() ?? {};
      var role = (data['role'] as String?) ?? 'customer';
      var dealerStatus = (data['dealerStatus'] as String?) ?? '';
      var technicianStatus = (data['technicianStatus'] as String?) ?? '';

      // Fallback check in dealers collection if missing in user doc
      if (role == 'dealer' && dealerStatus.isEmpty) {
        try {
          final dDoc = await _db.collection('dealers').doc(uid).get();
          if (dDoc.exists) {
            dealerStatus = (dDoc.data()?['status'] as String?) ?? 'pending';
          }
        } catch (_) {}
      }

      // Fallback check in technicianApplications collection if missing in user doc
      if (role == 'technician' && technicianStatus.isEmpty) {
        try {
          final tDoc = await _db.collection('technicianApplications').doc(uid).get();
          if (tDoc.exists) {
            technicianStatus = (tDoc.data()?['status'] as String?) ?? 'pending';
          }
        } catch (_) {}
      }

      return {
        'role': role,
        'dealerStatus': dealerStatus,
        'technicianStatus': technicianStatus,
      };
    } catch (_) {
      return {'role': 'customer', 'dealerStatus': '', 'technicianStatus': ''};
    }
  }


  // ─────────────────────────────────────────────────────────────────────────
  // USER PROFILE
  // ─────────────────────────────────────────────────────────────────────────

  Future<UserProfile?> getUserProfile(String uid) async {
    try {
      final doc = await _db.collection('users').doc(uid).get();
      if (doc.exists && doc.data() != null) {
        return UserProfile.fromFirestore(uid, doc.data()!);
      }
    } catch (e) {
      debugPrint('Error getting user profile: $e');
    }
    return null;
  }

  Stream<UserProfile?> streamUserProfile(String uid) {
    return _db.collection('users').doc(uid).snapshots().asyncMap((doc) async {
      if (!doc.exists || doc.data() == null) return null;
      final data = Map<String, dynamic>.from(doc.data()!);

      // Merge dealer details if user is dealer and fields missing
      if (data['role'] == 'dealer') {
        try {
          final dealerDoc = await _db.collection('dealers').doc(uid).get();
          if (dealerDoc.exists && dealerDoc.data() != null) {
            final dData = dealerDoc.data()!;
            data['businessName'] ??= dData['businessName'];
            data['gstin'] ??= dData['gstin'];
            data['contactPerson'] ??= dData['contactPerson'];
            data['phone'] ??= dData['phone'];
            data['address'] ??= '${dData['address'] ?? ''}, ${dData['city'] ?? ''} - ${dData['pincode'] ?? ''}';
            data['city'] ??= dData['city'];
            data['state'] ??= dData['state'];
            data['pincode'] ??= dData['pincode'];
            data['dealerStatus'] ??= dData['status'];
          }
        } catch (_) {}
      } else if (data['role'] == 'technician') {
        try {
          final techDoc = await _db.collection('technicianApplications').doc(uid).get();
          if (techDoc.exists && techDoc.data() != null) {
            final tData = techDoc.data()!;
            data['specialization'] ??= tData['primarySkill'];
            data['city'] ??= tData['city'];
            data['serviceArea'] ??= tData['serviceArea'];
            data['yearsExperience'] ??= tData['yearsExperience'];
            data['technicianStatus'] ??= tData['status'];
          }
        } catch (_) {}
      }

      return UserProfile.fromFirestore(uid, data);
    });
  }

  Future<void> updateProfile({
    required String uid,
    String? name,
    String? phone,
    String? address,
  }) async {
    final updates = <String, dynamic>{};
    if (name != null) updates['name'] = name;
    if (phone != null) updates['phone'] = phone;
    if (address != null) updates['address'] = address;
    if (updates.isNotEmpty) {
      await _db.collection('users').doc(uid).update(updates);
      if (name != null) await currentUser?.updateDisplayName(name);
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // PRODUCTS
  // ─────────────────────────────────────────────────────────────────────────

  Stream<List<Product>> streamProducts() {
    return _db
        .collection('products')
        .where('active', isEqualTo: true)
        .snapshots()
        .map((snap) {
      if (snap.docs.isEmpty) return MockCatalogData.products;
      return snap.docs
          .map((doc) => Product.fromFirestore(doc.id, doc.data()))
          .toList();
    }).handleError((_) => MockCatalogData.products);
  }

  Stream<List<String>> streamCategories() {
    return _db.collection('categories').snapshots().map((snap) {
      if (snap.docs.isEmpty) return <String>[];
      final list = snap.docs
          .map((d) => (d.data()['name'] as String?) ?? '')
          .where((s) => s.isNotEmpty)
          .toList();
      list.sort();
      return list;
    }).handleError((_) => <String>[]);
  }

  Future<void> seed54ProductsToFirestore() async {
    final batch = _db.batch();
    for (final p in MockCatalogData.products) {
      final ref = _db.collection('products').doc(p.id);
      batch.set(ref, p.toMap(), SetOptions(merge: true));
    }
    await batch.commit();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // ORDERS
  // ─────────────────────────────────────────────────────────────────────────

  Future<String> createOrder({
    required List<OrderItem> items,
    required double subtotal,
    required double tax,
    required double discount,
    required double total,
    required String shippingAddress,
    required String customerPhone,
    required String customerName,
    required String paymentMethod,
    required String paymentStatus,
    String? razorpayPaymentId,
    bool isDealer = false,
  }) async {
    final uid = currentUid ?? 'guest';
    final docRef = _db.collection('orders').doc();
    final orderCode = 'ORD-${docRef.id.substring(0, docRef.id.length > 8 ? 8 : docRef.id.length).toUpperCase()}';
    final data = {
      'orderId': docRef.id,
      'orderCode': orderCode,
      'customerId': uid,
      'dealerId': isDealer ? uid : null,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'shippingAddress': shippingAddress,
      'items': items.map((i) => i.toMap()).toList(),
      'subtotal': subtotal,
      'tax': tax,
      'discount': discount,
      'total': total,
      'status': (paymentStatus == 'paid' || paymentStatus == 'test_success')
          ? 'confirmed'
          : 'pending_payment',
      'paymentStatus': paymentStatus,
      'paymentMethod': paymentMethod,
      'razorpayPaymentId': razorpayPaymentId,
      'isDealerOrder': isDealer,
      'createdAt': FieldValue.serverTimestamp(),
    };
    await docRef.set(data);
    return docRef.id;
  }

  Stream<List<OrderModel>> streamUserOrders(String uid) {
    return _db
        .collection('orders')
        .where('customerId', isEqualTo: uid)
        .snapshots()
        .map((snap) {
      final list = snap.docs
          .map((d) => OrderModel.fromFirestore(d.id, d.data()))
          .toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    }).handleError((_) => <OrderModel>[]);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // DEALER MANAGEMENT
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> submitDealerApplication({
    required String businessName,
    required String contactPerson,
    required String email,
    required String phone,
    required String gstin,
    required String address,
    required String city,
    required String state,
    required String pincode,
    required int yearsInBusiness,
  }) async {
    final uid = currentUser!.uid;

    await _db.collection('dealers').doc(uid).set({
      'userId': uid,
      'businessName': businessName,
      'contactPerson': contactPerson,
      'email': email,
      'phone': phone,
      'gstin': gstin.toUpperCase(),
      'address': address,
      'city': city,
      'state': state,
      'pincode': pincode,
      'yearsInBusiness': yearsInBusiness,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await _db.collection('users').doc(uid).set({
      'role': 'dealer',
      'dealerStatus': 'pending',
      'name': businessName,
      'businessName': businessName,
      'contactPerson': contactPerson,
      'email': email,
      'phone': phone,
      'gstin': gstin.toUpperCase(),
      'address': '$address, $city, $state - $pincode',
      'city': city,
      'state': state,
      'pincode': pincode,
    }, SetOptions(merge: true));
  }

  Stream<DealerApplication?> streamDealerStatus(String uid) {
    return _db.collection('dealers').doc(uid).snapshots().map((doc) {
      if (doc.exists && doc.data() != null) {
        return DealerApplication.fromFirestore(doc.id, doc.data()!);
      }
      return null;
    });
  }

  // ─────────────────────────────────────────────────────────────────────────
  // TECHNICIAN MANAGEMENT
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> submitTechnicianApplication({
    required String name,
    required String phone,
    required String email,
    required String city,
    required String area,
    required int yearsExperience,
    required String specialization,
  }) async {
    final uid = currentUser!.uid;

    // Write to `technicianApplications` — admin panel streams this collection
    await _db.collection('technicianApplications').doc(uid).set({
      'userId': uid,
      'name': name,
      'phone': phone,
      'email': email,
      'city': city,
      'serviceArea': area,         // field admin panel expects
      'primarySkill': specialization, // field admin panel expects
      'yearsExperience': yearsExperience,
      'certifications': [],          // can be populated later
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    // Also write role=pending to users collection
    await _db.collection('users').doc(uid).set({
      'role': 'technician',
      'technicianStatus': 'pending',
      'name': name,
      'phone': phone,
    }, SetOptions(merge: true));
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> streamTechnicianProfile(String uid) {
    return _db.collection('technicians').doc(uid).snapshots();
  }

  Future<void> updateServiceByTechnician({
    required String serviceId,
    required String status,
    String? resolutionNotes,
  }) async {
    final data = <String, dynamic>{
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (resolutionNotes != null && resolutionNotes.isNotEmpty) {
      data['resolutionNotes'] = resolutionNotes;
    }
    await _db.collection('serviceRequests').doc(serviceId).update(data);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // DYNAMIC PAYMENT SETTINGS (Admin configurable Live & Test Razorpay keys)
  // ─────────────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getPaymentSettings() async {
    try {
      final doc = await _db.collection('settings').doc('payment').get();
      if (doc.exists && doc.data() != null) {
        return doc.data()!;
      }
    } catch (_) {}
    return {
      'mode': 'test',
      'keyId': 'rzp_test_1DP5mmOlF5G5ag',
    };
  }

  // ─────────────────────────────────────────────────────────────────────────
  // SERVICE REQUESTS
  // ─────────────────────────────────────────────────────────────────────────

  Future<String> submitServiceRequest({
    required String serviceType,
    required String purifierModel,
    required String issueDescription,
    required String address,
    required DateTime preferredDate,
    required String timeSlot,
    required String customerName,
    required String customerPhone,
  }) async {
    final uid = currentUid ?? 'guest';
    final ref = await _db.collection('serviceRequests').add({
      'customerId': uid,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'serviceType': serviceType,
      'purifierModel': purifierModel,
      'productName': purifierModel,
      'issue': issueDescription,
      'issueDescription': issueDescription,
      'address': address,
      'preferredDate': preferredDate,
      'timeSlot': timeSlot,
      'status': 'open',
      'createdAt': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  Stream<List<ServiceRequest>> streamUserServiceRequests(String uid) {
    return _db
        .collection('serviceRequests')
        .where('customerId', isEqualTo: uid)
        .snapshots()
        .map((snap) {
      final list = snap.docs
          .map((d) => ServiceRequest.fromFirestore(d.id, d.data()))
          .toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    }).handleError((_) => <ServiceRequest>[]);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // FCM — PUSH NOTIFICATIONS
  // ─────────────────────────────────────────────────────────────────────────

  /// Call once from main() after Firebase.initializeApp()
  static void registerBackgroundHandler() {
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  }

  bool _fcmListenersAttached = false;

  /// Request permission + save FCM token. Call after sign-in.
  Future<String?> setupFCM() async {
    try {
      final settings = await _fcm.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional) {
        final token = await _fcm.getToken();
        debugPrint('[FCM] Token: $token');

        if (token != null && currentUid != null) {
          await _saveFcmToken(currentUid!, token: token);
        }

        // Enable system foreground notification presentation (heads-up banner, badge, sound)
        await _fcm.setForegroundNotificationPresentationOptions(
          alert: true,
          badge: true,
          sound: true,
        );

        if (!_fcmListenersAttached) {
          _fcmListenersAttached = true;

          // Listen for token refresh
          _fcm.onTokenRefresh.listen((newToken) async {
            if (currentUid != null) {
              await _saveFcmToken(currentUid!, token: newToken);
            }
          });

          // Handle foreground messages — trigger system notification drawer banner + in-app alert
          FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
            final title = message.notification?.title ?? message.data['title'] ?? 'Califnco';
            final body = message.notification?.body ?? message.data['message'] ?? message.data['body'] ?? '';
            
            if (title.isNotEmpty || body.isNotEmpty) {
              // 1. Show real Android system notification in notification tray / heads-up banner
              await NotificationService.instance.showSystemNotification(
                title: title,
                body: body,
                payload: message.data['type'],
              );

              // 2. Also display in-app floating snackbar
              showInAppAlert(title, body, type: message.data['type']);
            }
          });

          // Handle notification tap when app is in background
          FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
            debugPrint('[FCM Tap] data=${message.data}');
          });
        }

        // Also always listen to Firestore notifications collection as real-time listener
        _listenToFirestoreNotifications();

        return token;
      }
    } catch (e) {
      debugPrint('[FCM] Setup error: $e');
    }
    _listenToFirestoreNotifications();
    return null;
  }

  bool _listeningNotifications = false;
  void _listenToFirestoreNotifications() {
    if (_listeningNotifications) return;
    _listeningNotifications = true;
    final uid = currentUid;
    final startTime = Timestamp.now();
    _db.collection('notifications')
        .where('createdAt', isGreaterThanOrEqualTo: startTime)
        .snapshots()
        .listen((snap) {
      for (final change in snap.docChanges) {
        if (change.type == DocumentChangeType.added) {
          final data = change.doc.data();
          if (data == null) continue;
          final targetUser = data['userId'] as String? ?? 'all';
          if (targetUser == 'all' || targetUser == uid) {
            final title = data['title'] as String? ?? 'Califnco Alert';
            final body = (data['body'] ?? data['message'] ?? '') as String;
            
            // Trigger system notification tray alert
            NotificationService.instance.showSystemNotification(
              title: title,
              body: body,
              payload: data['type'],
            );
            
            // Trigger in-app alert
            showInAppAlert(title, body, type: data['type']);
          }
        }
      }
    }, onError: (e) {
      debugPrint('Notification stream note: $e');
    });
  }

  Future<void> _saveFcmToken(String uid, {String? token}) async {
    try {
      final t = token ?? await _fcm.getToken();
      if (t == null) return;
      await _db.collection('users').doc(uid).set({
        'fcmToken': t,
        'lastFcmUpdate': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('[FCM] Token save error: $e');
    }
  }
}
