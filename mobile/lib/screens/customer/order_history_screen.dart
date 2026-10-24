import 'package:flutter/material.dart';
import '../../models/order.dart';
import '../../services/firebase_service.dart';

class OrderHistoryScreen extends StatelessWidget {
  const OrderHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xff087f8c);
    final user = FirebaseService.instance.currentUser;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('My Orders')),
        body: const Center(child: Text('Sign in to view your order history')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Orders'),
      ),
      body: StreamBuilder<List<OrderModel>>(
        stream: FirebaseService.instance.streamUserOrders(user.uid),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting && !snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final orders = snap.data ?? [];

          if (orders.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.receipt_long_outlined, size: 56, color: primary),
                    ),
                    const SizedBox(height: 16),
                    const Text('No Orders Yet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(
                      'Your past water purifier orders and wholesale bulk orders will appear here.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: orders.length,
            separatorBuilder: (_, __) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final order = orders[index];
              return _OrderCard(order: order);
            },
          );
        },
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final OrderModel order;

  const _OrderCard({required this.order});

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'delivered':
        return Colors.green.shade700;
      case 'shipped':
        return Colors.blue.shade700;
      case 'processing':
        return Colors.amber.shade800;
      case 'confirmed':
        return const Color(0xff087f8c);
      case 'cancelled':
        return Colors.red.shade700;
      default:
        return Colors.orange.shade800;
    }
  }

  int _getStatusStep(String status) {
    switch (status.toLowerCase()) {
      case 'pending_payment':
        return 0;
      case 'confirmed':
        return 1;
      case 'processing':
        return 2;
      case 'shipped':
        return 3;
      case 'delivered':
        return 4;
      default:
        return 1;
    }
  }

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xff087f8c);
    final statusColor = _getStatusColor(order.status);
    final currentStep = _getStatusStep(order.status);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Order ID & Status Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '#${order.orderCode ?? "ORD-${order.id.substring(0, order.id.length > 8 ? 8 : order.id.length).toUpperCase()}"}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${order.createdAt.day}/${order.createdAt.month}/${order.createdAt.year} • ${order.items.length} items',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    order.status.replaceAll('_', ' ').toUpperCase(),
                    style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),

            // Stepper Visual Progress
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _StepNode(label: 'Placed', isDone: currentStep >= 0, isCurrent: currentStep == 0),
                _StepLine(isDone: currentStep >= 1),
                _StepNode(label: 'Confirmed', isDone: currentStep >= 1, isCurrent: currentStep == 1),
                _StepLine(isDone: currentStep >= 2),
                _StepNode(label: 'Processing', isDone: currentStep >= 2, isCurrent: currentStep == 2),
                _StepLine(isDone: currentStep >= 3),
                _StepNode(label: 'Delivered', isDone: currentStep >= 4, isCurrent: currentStep >= 4),
              ],
            ),
            const Divider(height: 24),

            // Items List
            ...order.items.map((item) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          '${item.quantity}x ${item.name}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                      Text(
                        '₹${(item.unitPrice * item.quantity).toStringAsFixed(0)}',
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                    ],
                  ),
                )),

            const Divider(height: 20),

            // Order Total
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  order.isDealerOrder ? 'Wholesale Total' : 'Total Amount',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  '₹${order.total.toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: primary),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StepNode extends StatelessWidget {
  final String label;
  final bool isDone;
  final bool isCurrent;

  const _StepNode({required this.label, required this.isDone, required this.isCurrent});

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xff087f8c);
    final color = isDone ? primary : Colors.grey.shade400;

    return Column(
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: isDone ? primary : Colors.transparent,
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 2),
          ),
          child: isDone
              ? const Icon(Icons.check, size: 12, color: Colors.white)
              : null,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 9,
            fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
            color: isDone ? Colors.black87 : Colors.grey,
          ),
        ),
      ],
    );
  }
}

class _StepLine extends StatelessWidget {
  final bool isDone;

  const _StepLine({required this.isDone});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        height: 2,
        color: isDone ? const Color(0xff087f8c) : Colors.grey.shade300,
        margin: const EdgeInsets.only(bottom: 14),
      ),
    );
  }
}
