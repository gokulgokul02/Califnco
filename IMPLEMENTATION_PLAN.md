# Implementation plan mapped to assignment scoring

## P0 — required before submission
1. Customer: product catalog of 50+ products with matching images; product detail; cart; checkout; order history; profile; service booking; FCM.
2. Dealer: separate role after login; dealer sees wholesale price; bulk order and order history.
3. Admin web: order list/status updates; dealer approval/rejection; service desk. Deploy live to Vercel.
4. Firestore Auth/queries/rules. Verify customer cannot read admin-only records or write their own role.
5. Razorpay test-mode checkout (or clearly demonstrate order placement with test-payment status if credentials cannot be obtained).
6. n8n schedule: read one product/day from Google Sheets; generate image; upload public image URL; generate caption/hashtags; publish to Instagram Graph API; record status/error.

## P1 — polish
- Loading/empty/error states; form validation; product image zoom; animations; dark mode.
- Map/address picker using OpenStreetMap/Leaflet or a simple address form. Do not use Google Maps if avoiding billing setup.
- Email notification using EmailJS or a free SMTP service. SMS is not guaranteed free.

## P2 — bonus
- WhatsApp Status via WAHA. This is unofficial WhatsApp Web automation and may break or violate platform terms; use only a secondary number and local Docker as the assignment suggests. Do not use a personal primary account.
- Referral system.

## Suggested demo order (5–7 minutes)
1. Customer login, browse catalog, add items, checkout, order history.
2. Dealer login, wholesale pricing, bulk order.
3. Admin dashboard: approve dealer, update order, service request.
4. Show FCM notification and Razorpay test transaction.
5. Show n8n execution history, generated image/caption, Instagram post URL.
6. Show live Vercel URL and APK.
