# Califnco Round 1 — Starter Implementation

This is a runnable starter scaffold for the two mandatory assignment tasks. It is not a claim that cloud services have been configured or the app deployed: add your own Firebase/Meta/AI credentials and run the verification checklist.

## Stack
- Android app: Flutter + Firebase Auth + Cloud Firestore + Firebase Messaging
- Admin: React + Vite (deploy to Vercel)
- Automation: n8n self-hosted, Google Sheets, AI caption/image endpoints, Meta Graph API
- Payment: Razorpay test mode only (wire up only after creating a test account)

## 1. Firebase setup
1. Create a Firebase project and Android app in Firebase Console.
2. In `mobile/`, run `flutter create .` if platform folders are absent.
3. Install FlutterFire CLI, then run `flutterfire configure`.
4. Enable Email/Password Authentication and Firestore.
5. Copy `firestore/firestore.rules` into Firebase Rules and publish. Create an admin user and set its `users/{uid}.role` to `admin` manually in the console.
6. Run `flutter pub get` and `flutter run`.

## 2. Flutter
`mobile/pubspec.yaml` declares Firebase packages. `lib/main.dart` includes Firebase initialization, auth gate and product catalog. Additional customer/dealer/admin features are specified in `IMPLEMENTATION_PLAN.md`; connect them to the Firestore schema in `firestore/schema.md` before submission.

## 3. Admin on Vercel
```bash
cd admin
npm install
npm run dev
```
Set Vercel project root to `admin`. Add Firebase web app config as `VITE_FIREBASE_API_KEY`, `VITE_FIREBASE_AUTH_DOMAIN`, `VITE_FIREBASE_PROJECT_ID`, `VITE_FIREBASE_APP_ID`. Deploy with `vercel --prod` or connect the repository in Vercel. Never put service-account keys in frontend env vars.

## 4. n8n automation
1. Start local n8n with Docker: `docker compose up -d` from `automation/`.
2. Open `http://localhost:5678`, create credentials, and import `instagram_daily_workflow.json`.
3. Configure Google Sheets, an image generation endpoint, caption AI, image hosting, and Meta Graph API credentials in n8n. Replace placeholder nodes/URLs. Activate the workflow and verify it runs on schedule.
4. Instagram publishing requires an eligible professional Instagram account connected to a Facebook Page, Meta app setup, publishing permissions and a valid access token. API access/limits may change.

## Cost and limitations
- Firebase Spark is subject to quotas; FCM has no direct charge but depends on project configuration. Avoid Firebase Storage for this assignment if staying on Spark.
- Vercel Hobby is generally for personal/non-commercial projects and subject to platform terms/limits.
- Razorpay test mode does not collect real payments.
- n8n is free to self-host, but a continuously available machine/VPS can cost money. A laptop-hosted workflow only runs while the machine and network are available.
- AI providers, image generation, image hosting and SMS may have quotas, credit requirements or paid tiers. EmailJS or email is easier to demonstrate free than SMS. Do not claim SMS works unless a real provider is configured.
- Do not commit `.env`, access tokens, Firebase service accounts, or Meta secrets.

## Deliverables checklist
See `IMPLEMENTATION_PLAN.md`. Before submission, upload APK/source/admin URL/workflow JSON/demo video to the official form and set shared Drive links to “Anyone with the link can view”.

## Seed demo catalog (admin only)
Do not seed products from the customer app: Firestore rules correctly reserve catalog writes for admins. Instead, from project root install `firebase-admin`, set `GOOGLE_APPLICATION_CREDENTIALS` to a downloaded Firebase service-account JSON path (keep it outside the repo), and run `node scripts/seed-products.mjs`. This creates 54 demo records. The current image URLs are placeholders, not final realistic product photos; replace them with matching images before submission.
# Califncoc
