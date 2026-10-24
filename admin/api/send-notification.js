// Vercel Serverless Function — FCM v1 Push Notification Proxy
// POST /api/send-notification
// Body: { token, title, body, data }
//
// Uses Firebase Admin SDK with Service Account credentials stored in
// Vercel environment variable FIREBASE_SERVICE_ACCOUNT_JSON
// (paste the entire contents of the downloaded service account JSON)

import { initializeApp, getApps, cert } from 'firebase-admin/app';
import { getMessaging } from 'firebase-admin/messaging';

// Initialize Firebase Admin once (Vercel keeps functions warm)
if (!getApps().length) {
  const serviceAccount = JSON.parse(
    process.env.FIREBASE_SERVICE_ACCOUNT_JSON || '{}'
  );
  initializeApp({ credential: cert(serviceAccount) });
}

export default async function handler(req, res) {
  // CORS headers (admin panel is on same domain, but just in case)
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type');

  if (req.method === 'OPTIONS') {
    return res.status(200).end();
  }

  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method not allowed' });
  }

  const { token, title, body, data = {} } = req.body || {};

  if (!token || !title) {
    return res.status(400).json({ error: 'token and title are required' });
  }

  try {
    const messaging = getMessaging();
    const response = await messaging.send({
      token,
      notification: { title, body: body || '' },
      data: Object.fromEntries(
        Object.entries({ ...data, title, body: body || '' }).map(([k, v]) => [k, String(v)])
      ),
      android: {
        priority: 'high',
        notification: {
          channelId: 'califnco_orders',
          sound: 'default',
          priority: 'max',
          visibility: 'public',
          color: '#087F8C',
        },
      },
    });

    return res.status(200).json({ success: true, messageId: response });
  } catch (err) {
    console.error('[FCM] Send error:', err.message);
    // Return 200 so admin doesn't crash — notification failure is non-critical
    return res.status(200).json({ success: false, error: err.message });
  }
}
