import 'package:flutter/foundation.dart';
import '../models/product.dart';
import '../models/order.dart';

class CartItem {
  final Product product;
  int quantity;

  CartItem({required this.product, this.quantity = 1});

  double getUnitPrice({bool isDealer = false}) {
    return isDealer ? product.wholesalePrice : product.price;
  }

  double getTotalPrice({bool isDealer = false}) {
    return getUnitPrice(isDealer: isDealer) * quantity;
  }
}

class CartService extends ChangeNotifier {
  static final CartService instance = CartService._();
  CartService._();

  final Map<String, CartItem> _items = {};
  bool _isDealer = false;

  bool get isDealer => _isDealer;
  List<CartItem> get items => _items.values.toList();
  int get itemCount => _items.values.fold(0, (sum, i) => sum + i.quantity);
  bool get isEmpty => _items.isEmpty;

  void setDealerMode(bool isDealer) {
    _isDealer = isDealer;
    notifyListeners();
  }

  int getQuantity(String productId) {
    return _items[productId]?.quantity ?? 0;
  }

  void addToCart(Product product, {int qty = 1}) {
    if (_items.containsKey(product.id)) {
      _items[product.id]!.quantity += qty;
    } else {
      _items[product.id] = CartItem(product: product, quantity: qty);
    }
    notifyListeners();
  }

  void updateQuantity(String productId, int quantity) {
    if (quantity <= 0) {
      _items.remove(productId);
    } else if (_items.containsKey(productId)) {
      _items[productId]!.quantity = quantity;
    }
    notifyListeners();
  }

  void removeFromCart(String productId) {
    _items.remove(productId);
    notifyListeners();
  }

  void clearCart() {
    _items.clear();
    notifyListeners();
  }

  double get subtotal {
    return _items.values.fold(
      0.0,
      (sum, item) => sum + item.getTotalPrice(isDealer: _isDealer),
    );
  }

  /// Bulk volume discount:
  /// For regular customers: 5% discount on cart over ₹25,000
  /// For wholesale dealers: Extra 5% off if 10+ items, extra 10% off if 25+ items
  double get discount {
    if (_isDealer) {
      if (itemCount >= 25) {
        return subtotal * 0.10; // 10% bulk dealer discount
      } else if (itemCount >= 10) {
        return subtotal * 0.05; // 5% bulk dealer discount
      }
      return 0.0;
    } else {
      if (subtotal >= 25000) {
        return subtotal * 0.05;
      }
      return 0.0;
    }
  }

  /// 18% GST standard on water purifiers and electronic appliances in India
  double get tax {
    final taxable = subtotal - discount;
    return taxable * 0.18;
  }

  double get shipping {
    if (subtotal > 999 || _items.isEmpty) return 0.0;
    return 150.0;
  }

  double get grandTotal {
    return (subtotal - discount) + tax + shipping;
  }

  List<OrderItem> toOrderItems() {
    return _items.values.map((item) {
      return OrderItem(
        productId: item.product.id,
        name: item.product.name,
        unitPrice: item.getUnitPrice(isDealer: _isDealer),
        quantity: item.quantity,
        imageUrl: item.product.imageUrl,
      );
    }).toList();
  }
}
