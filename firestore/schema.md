# Firestore schema

- `users/{uid}`: `{name,email,phone,role:'customer'|'dealer'|'admin',createdAt}`. User registration must never accept a client-selected admin role.
- `products/{productId}`: `{name,category,description,price,wholesalePrice,stock,active,imageUrl,createdAt}`. Replace demo placeholders with real product images whose labels match.
- `categories/{categoryId}`: `{id,name,slug,description,active,createdAt}`. Product equipment categories collection.
- `orders/{orderId}`: `{customerId|dealerId,items:[{productId,name,unitPrice,quantity}],total,status,paymentStatus,orderType,createdAt}`. In production, compute prices and totals in a trusted backend/Cloud Function; do not trust client totals.
- `dealers/{uid}`: `{businessName,email,phone,address,status:'pending'|'approved'|'rejected',createdAt}`.
- `serviceRequests/{id}`: `{customerId,productName,issue,address,preferredDate,status:'open'|'scheduled'|'in_progress'|'resolved',createdAt}`.
- `fcmTokens/{uid}/tokens/{tokenId}`: token records written by signed-in user; send notifications from trusted backend only.

## Security note
The rules below are a minimum demo baseline, not a complete production authorization system. Firestore rules cannot safely verify an arbitrary client's order totals. Use a trusted backend for payment/order finalization before any real deployment.
