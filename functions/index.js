// ============================================================
// Califnco Firebase Cloud Functions
// Handles: FCM Push Notifications (works in dead/background/foreground state)
//
// Triggers:
//   1. onServiceRequestAssigned — when admin assigns a technician
//   2. onNotificationCreated — generic push for 'notifications' collection
// ============================================================

const { onDocumentWritten } = require('firebase-functions/v2/firestore');
const { onDocumentCreated } = require('firebase-functions/v2/firestore');
const { initializeApp } = require('firebase-admin/app');
const { getFirestore } = require('firebase-admin/firestore');
const { getMessaging } = require('firebase-admin/messaging');

initializeApp();

const db = getFirestore();
const messaging = getMessaging();

// ── HELPER: Send FCM to a specific token ──────────────────────────────────
async function sendFcmToToken(fcmToken, title, body, data = {}) {
  if (!fcmToken) return;
  try {
    const message = {
      token: fcmToken,
      notification: { title, body },
      data: Object.fromEntries(
        Object.entries(data).map(([k, v]) => [k, String(v)])
      ),
      android: {
        priority: 'high',
        notification: {
          channelId: 'califnco_orders',
          sound: 'default',
          priority: 'max',
          visibility: 'public',
          icon: 'ic_launcher',
          color: '#087F8C',
        },
      },
    };
    const response = await messaging.send(message);
    console.log('[FCM] Sent to token ...' + fcmToken.slice(-10) + ' -> ' + response);
  } catch (err) {
    if (
      err.code === 'messaging/registration-token-not-registered' ||
      err.code === 'messaging/invalid-registration-token'
    ) {
      console.warn('[FCM] Stale token, cleaning up: ' + fcmToken.slice(-10));
    } else {
      console.error('[FCM] Send error:', err.message);
    }
  }
}

// ── HELPER: Get FCM token for a Firestore user ────────────────────────────
async function getFcmToken(uid) {
  if (!uid || uid === 'all') return null;
  try {
    const userDoc = await db.collection('users').doc(uid).get();
    return userDoc.exists ? (userDoc.data().fcmToken || null) : null;
  } catch (e) {
    console.warn('[FCM] Could not fetch token for uid:', uid, e.message);
    return null;
  }
}

// ── TRIGGER 1: Service Request Assigned ──────────────────────────────────
// Fires when assignedTechnician field changes on any serviceRequest doc
exports.onServiceRequestAssigned = onDocumentWritten(
  'serviceRequests/{serviceId}',
  async (event) => {
    const before = event.data.before.exists ? event.data.before.data() : null;
    const after = event.data.after.exists ? event.data.after.data() : null;

    if (!after) return;

    const techBefore = (before?.assignedTechnician || '').trim();
    const techAfter = (after.assignedTechnician || '').trim();

    // Only trigger when a technician is newly assigned
    if (!techAfter || techAfter === techBefore) return;

    const customerId = after.customerId || after.userId || null;
    const serviceType = after.serviceType || 'RO Service';
    const serviceId = event.params.serviceId;
    const techPhone = after.technicianPhone || '';

    console.log('[Assign] serviceId=' + serviceId + ' tech="' + techAfter + '" customer=' + customerId);

    // --- Notify CUSTOMER ---
    const customerToken = await getFcmToken(customerId);
    if (customerToken) {
      await sendFcmToToken(
        customerToken,
        'Technician Assigned for Your Service',
        'Engineer ' + techAfter + (techPhone ? ' (' + techPhone + ')' : '') + ' will visit for your ' + serviceType + '. We\'ll be there soon!',
        { type: 'service_assigned', serviceId, technician: techAfter },
      );
    }

    // --- Notify TECHNICIAN (find by name in users collection) ---
    try {
      const techSnap = await db
        .collection('users')
        .where('name', '==', techAfter)
        .where('role', '==', 'technician')
        .limit(1)
        .get();

      if (!techSnap.empty) {
        const techData = techSnap.docs[0].data();
        const techToken = techData.fcmToken || null;
        const customerName = after.customerName || 'Customer';
        const address = after.address || 'Location on file';

        if (techToken) {
          await sendFcmToToken(
            techToken,
            'New Service Job Assigned',
            'New ' + serviceType + ' job for ' + customerName + ' at ' + address.substring(0, 60),
            { type: 'job_assigned', serviceId, serviceType },
          );
        }
      }
    } catch (e) {
      console.warn('[FCM] Technician lookup error:', e.message);
    }
  }
);

// ── TRIGGER 2: Generic Notification Push ─────────────────────────────────
// Fires when any doc is added to 'notifications' collection (from admin panel)
exports.onNotificationCreated = onDocumentCreated(
  'notifications/{notifId}',
  async (event) => {
    const data = event.data.data();
    if (!data) return;

    const userId = data.userId || 'all';
    const title = data.title || 'Califnco';
    const body = data.body || data.message || '';
    const type = data.type || 'general';
    const notifId = event.params.notifId;

    console.log('[Notification] id=' + notifId + ' userId=' + userId + ' type=' + type);

    if (userId === 'all') {
      // Broadcast: send to all users with FCM tokens (batch - first 500)
      try {
        const usersSnap = await db
          .collection('users')
          .where('fcmToken', '!=', '')
          .limit(500)
          .get();

        const sends = usersSnap.docs
          .map((d) => d.data().fcmToken)
          .filter(Boolean)
          .map((token) =>
            sendFcmToToken(token, title, body, { type, notifId })
          );
        await Promise.allSettled(sends);
        console.log('[Broadcast] Sent to ' + sends.length + ' devices');
      } catch (e) {
        console.error('[Broadcast] Error:', e.message);
      }
    } else {
      // Targeted: send to specific user
      const token = await getFcmToken(userId);
      if (token) {
        await sendFcmToToken(token, title, body, { type, notifId, userId });
      }
    }
  }
);
