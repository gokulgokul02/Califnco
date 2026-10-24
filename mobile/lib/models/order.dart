class OrderItem {
  final String productId;
  final String name;
  final double unitPrice;
  final int quantity;
  final String? imageUrl;

  const OrderItem({
    required this.productId,
    required this.name,
    required this.unitPrice,
    required this.quantity,
    this.imageUrl,
  });

  factory OrderItem.fromMap(Map<String, dynamic> map) {
    return OrderItem(
      productId: map['productId'] ?? '',
      name: map['name'] ?? '',
      unitPrice: (map['unitPrice'] as num?)?.toDouble() ?? 0.0,
      quantity: (map['quantity'] as num?)?.toInt() ?? 1,
      imageUrl: map['imageUrl'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'name': name,
      'unitPrice': unitPrice,
      'quantity': quantity,
      if (imageUrl != null) 'imageUrl': imageUrl,
    };
  }
}

class OrderModel {
  final String id;
  final String? orderCode;
  final String customerId;
  final String? customerName;
  final String? customerPhone;
  final String? shippingAddress;
  final List<OrderItem> items;
  final double subtotal;
  final double tax;
  final double discount;
  final double total;
  final String status; // pending_payment, confirmed, processing, shipped, delivered, cancelled
  final String paymentStatus; // pending, paid, test_success, failed
  final String? paymentMethod; // razorpay_test, test_direct, cod
  final String? razorpayPaymentId;
  final DateTime createdAt;
  final bool isDealerOrder;

  const OrderModel({
    required this.id,
    this.orderCode,
    required this.customerId,
    this.customerName,
    this.customerPhone,
    this.shippingAddress,
    required this.items,
    required this.subtotal,
    this.tax = 0.0,
    this.discount = 0.0,
    required this.total,
    required this.status,
    required this.paymentStatus,
    this.paymentMethod,
    this.razorpayPaymentId,
    required this.createdAt,
    this.isDealerOrder = false,
  });

  factory OrderModel.fromFirestore(String id, Map<String, dynamic> data) {
    final rawItems = data['items'] as List<dynamic>? ?? [];
    final code = data['orderCode'] as String? ??
        data['orderNumber'] as String? ??
        'ORD-${id.substring(0, id.length > 8 ? 8 : id.length).toUpperCase()}';
    return OrderModel(
      id: id,
      orderCode: code,
      customerId: data['customerId'] ?? data['dealerId'] ?? '',
      customerName: data['customerName'],
      customerPhone: data['customerPhone'],
      shippingAddress: data['shippingAddress'] ?? data['address'],
      items: rawItems.map((i) => OrderItem.fromMap(Map<String, dynamic>.from(i))).toList(),
      subtotal: (data['subtotal'] as num?)?.toDouble() ?? (data['total'] as num?)?.toDouble() ?? 0.0,
      tax: (data['tax'] as num?)?.toDouble() ?? 0.0,
      discount: (data['discount'] as num?)?.toDouble() ?? 0.0,
      total: (data['total'] as num?)?.toDouble() ?? 0.0,
      status: data['status'] ?? 'pending_payment',
      paymentStatus: data['paymentStatus'] ?? 'pending',
      paymentMethod: data['paymentMethod'] ?? 'razorpay_test',
      razorpayPaymentId: data['razorpayPaymentId'],
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] is DateTime
              ? data['createdAt']
              : (data['createdAt'] as dynamic).toDate())
          : DateTime.now(),
      isDealerOrder: data['isDealerOrder'] ?? (data['dealerId'] != null),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'orderCode': orderCode,
      'customerId': customerId,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'shippingAddress': shippingAddress,
      'items': items.map((i) => i.toMap()).toList(),
      'subtotal': subtotal,
      'tax': tax,
      'discount': discount,
      'total': total,
      'status': status,
      'paymentStatus': paymentStatus,
      'paymentMethod': paymentMethod,
      'razorpayPaymentId': razorpayPaymentId,
      'createdAt': createdAt,
      'isDealerOrder': isDealerOrder,
    };
  }
}
