import 'package:flutter/material.dart';
import '../../widgets/safe_product_image.dart';
import '../../services/cart_service.dart';
import 'checkout_screen.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xff087f8c);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Shopping Cart'),
        actions: [
          ListenableBuilder(
            listenable: CartService.instance,
            builder: (context, _) {
              if (CartService.instance.isEmpty) return const SizedBox.shrink();
              return TextButton.icon(
                icon: const Icon(Icons.delete_sweep, size: 18),
                label: const Text('Clear'),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Clear Cart?'),
                      content: const Text('Are you sure you want to remove all items from your cart?'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                        FilledButton(
                          onPressed: () {
                            CartService.instance.clearCart();
                            Navigator.pop(ctx);
                          },
                          child: const Text('Clear'),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: CartService.instance,
        builder: (context, _) {
          final cart = CartService.instance;
          final isDealer = cart.isDealer;

          if (cart.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.remove_shopping_cart_outlined, size: 64, color: primary),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Your Cart is Empty',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Explore our 50+ water purifiers, commercial RO units, filters, and booster pumps.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      style: FilledButton.styleFrom(backgroundColor: primary),
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Browse Purifiers Catalog'),
                    ),
                  ],
                ),
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Dealer Wholesale Notice Banner
                if (isDealer)
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.amber.shade300),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.storefront, color: Colors.amber.shade900),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Dealer wholesale pricing applied.\nBulk discounts: 10+ items = 5% off | 25+ items = 10% off',
                            style: TextStyle(color: Colors.amber.shade900, fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Cart Items List
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: cart.items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final item = cart.items[index];
                    final p = item.product;
                    final unitPrice = item.getUnitPrice(isDealer: isDealer);

                    return Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 1.5,
                      child: Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: Row(
                          children: [
                            SafeProductImage(
                              imageUrl: p.imageUrl,
                              width: 70,
                              height: 70,
                              fit: BoxFit.cover,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    p.name,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '₹${unitPrice.toStringAsFixed(0)} each',
                                    style: const TextStyle(color: primary, fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            ),
                            // Stepper Controls
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  iconSize: 18,
                                  icon: const Icon(Icons.remove_circle_outline),
                                  onPressed: () => cart.updateQuantity(p.id, item.quantity - 1),
                                ),
                                Text(
                                  '${item.quantity}',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                                IconButton(
                                  iconSize: 18,
                                  icon: const Icon(Icons.add_circle_outline),
                                  onPressed: () => cart.updateQuantity(p.id, item.quantity + 1),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 20),

                // Bill Breakdown Card
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 1,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text('Order Summary', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                        const Divider(height: 20),
                        _BillRow(label: 'Items Subtotal (${cart.itemCount} items)', value: '₹${cart.subtotal.toStringAsFixed(2)}'),
                        if (cart.discount > 0)
                          _BillRow(
                            label: isDealer ? 'Dealer Bulk Tier Discount' : 'Promotional Discount',
                            value: '- ₹${cart.discount.toStringAsFixed(2)}',
                            color: Colors.green.shade700,
                          ),
                        _BillRow(label: 'GST (18% Standard)', value: '₹${cart.tax.toStringAsFixed(2)}'),
                        _BillRow(
                          label: 'Shipping / Delivery',
                          value: cart.shipping == 0 ? 'FREE' : '₹${cart.shipping.toStringAsFixed(2)}',
                          color: cart.shipping == 0 ? Colors.green.shade700 : null,
                        ),
                        const Divider(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Grand Total', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                            Text(
                              '₹${cart.grandTotal.toStringAsFixed(2)}',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: primary),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Checkout Button
                SizedBox(
                  height: 52,
                  child: FilledButton(
                    style: FilledButton.styleFrom(backgroundColor: primary),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const CheckoutScreen()),
                      );
                    },
                    child: Text(
                      'Proceed to Checkout (₹${cart.grandTotal.toStringAsFixed(0)})',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _BillRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;

  const _BillRow({required this.label, required this.value, this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[700], fontSize: 13)),
          Text(
            value,
            style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
