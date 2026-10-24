# Califnco Water Purifiers - Round 1 Technical Assignment

> Candidate submission for Califnco Software Developer Hiring - Round 1
> Deadline: 25 October 2026, 11:59 PM IST

---

## Project Structure

```
califnco/
├── mobile/              # Flutter Android App (Task 1 — 75 pts)
├── admin/               # React Admin Dashboard (Vercel-deployed)
├── automation/          # n8n Instagram + WhatsApp workflow (Task 2 — 25 pts)
├── firestore/           # Firestore security rules + indexes
├── scripts/             # Firestore seed scripts
└── SUBMISSION.md        # This file
```

---

## Task 1: Water Purifier E-Commerce App (75 pts)

### Flutter Android App — Features Implemented

| Feature | Status | Location |
|---|---|---|
| 50+ Products with categories, search, zoom | Done | catalog_screen.dart |
| Product detail with specs | Done | product_detail_screen.dart |
| Shopping cart + GST breakdown | Done | cart_screen.dart |
| Checkout with Razorpay test mode | Done | checkout_screen.dart |
| Order history + visual stepper | Done | order_history_screen.dart |
| Service booking (AC, repair, etc.) | Done | service_booking_screen.dart |
| User profile + referral system | Done | profile_screen.dart |
| Dark mode toggle | Done | services/theme_service.dart |
| Dealer login + wholesale pricing | Done | screens/dealer/dealer_dashboard_screen.dart |
| Dealer GSTIN registration | Done | screens/auth/dealer_register_screen.dart |
| Bulk order with tier discounts (10+, 25+) | Done | services/cart_service.dart |
| Firebase Auth (email + Google) | Done | services/firebase_service.dart |
| Firestore real-time sync | Done | firebase_service.dart |
| FCM push notifications | Done | firebase_service.dart |
| Razorpay test mode payment | Done | services/razorpay_service.dart |
| Pinch-to-zoom image viewer | Done | screens/common/image_zoom_dialog.dart |
| Referral code sharing | Done | profile_screen.dart |
| Mock data fallback (54 products) | Done | services/mock_data.dart |

### Admin Web Dashboard — Features Implemented

| Feature | Status |
|---|---|
| KPI cards (Revenue, Orders, Dealers, Tickets) | Done |
| Real-time order management (approve/reject/status) | Done |
| Dealer application approve / reject | Done |
| Service request management | Done |
| Product management | Done |
| Search / filter | Done |
| Interactive Demo Mode (no Firebase needed) | Done |
| Vercel deployment ready (vercel.json) | Done |
| Responsive UI | Done |

---

## Task 2: AI Instagram Automation (25 pts)

Tool stack: n8n + Meta Graph API + Google Gemini + Stable Diffusion XL (HuggingFace) + ImgBB + Google Sheets

### Workflow: automation/instagram_daily_workflow.json

Daily flow (10 AM IST, automatic):

```
Schedule Trigger (10 AM)
   -> Read Product from Google Sheets
   -> Select today's product (round-robin by day)
   -> [Parallel]
       -> Gemini 1.5 Flash: Generate caption + hashtags
       -> SDXL (HuggingFace): Generate AI product image
   -> ImgBB: Upload image -> Get public URL
   -> Merge caption + image URL
   -> Instagram Graph API: Create media container
   -> Instagram Graph API: Publish post
   -> Log result to Google Sheets (PublishLog tab)
```

### Required API Keys (all free tier)

| Service | How to get |
|---|---|
| Gemini API | ai.google.dev — 15 req/min free |
| HuggingFace | huggingface.co/settings/tokens — free |
| ImgBB | api.imgbb.com — free |
| Meta Graph API | developers.facebook.com — Instagram Business required |

---

## Bonus Features Implemented (+15 pts)

| Bonus Feature | Status | Notes |
|---|---|---|
| Dark mode | Done | System-aware + toggle in profile |
| Pinch-to-zoom (image zoom) | Done | All product images |
| Referral system | Done | Unique code, Rs.150 credits on share |
| WhatsApp Status automation | Note included | Sticky note in n8n workflow with WAHA API setup |
| Animations | Done | Hero transitions, slide animations |

---

## Setup Guide

### Admin Dashboard (Vercel Deploy)

1. Push the admin/ folder to GitHub
2. Import on Vercel, select admin/ as root
3. Add env variables in Vercel Settings:
   - VITE_FIREBASE_API_KEY
   - VITE_FIREBASE_AUTH_DOMAIN
   - VITE_FIREBASE_PROJECT_ID
   - VITE_FIREBASE_APP_ID
4. Deploy — Demo Mode works without Firebase for evaluator preview

### Mobile App (Android)

```bash
cd mobile
flutter pub get
flutter run
```

For Firebase: add google-services.json from Firebase Console -> Project Settings -> Android app.

### n8n Automation

```bash
cd automation

# Option A: Docker
cp .env.example .env
docker compose up -d

# Option B: No Docker (local Node.js)
npx n8n start
```

Then open http://localhost:5678, import instagram_daily_workflow.json, configure credentials, and activate.

### Firestore Seed (54 Demo Products)

```bash
cd scripts
node seed-products.mjs
```

---

## Test Credentials (Demo Mode)

| Role | Email | Password |
|---|---|---|
| Customer | demo@califnco.com | Demo@1234 |
| Dealer | dealer@califnco.com | Demo@1234 |
| Admin | admin@califnco.com | Admin@1234 |

Razorpay Test Card: 4111 1111 1111 1111 | Expiry: any future | CVV: any 3 digits

---

## Tech Stack

| Layer | Technology |
|---|---|
| Mobile | Flutter 3.x + Dart |
| State Management | ChangeNotifier + ListenableBuilder |
| Backend | Firebase (Auth + Firestore + FCM) |
| Payments | Razorpay test mode |
| Admin Panel | React 18 + Vite 6 + Firebase Web SDK |
| Deployment | Vercel |
| Automation | n8n self-hosted |
| AI Caption | Google Gemini 1.5 Flash |
| AI Image | Stable Diffusion XL (HuggingFace) |
| Image Hosting | ImgBB free |
| Social | Meta Graph API (Instagram) |
| Logging | Google Sheets |
