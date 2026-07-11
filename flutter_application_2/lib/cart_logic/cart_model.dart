import 'package:flutter/foundation.dart';
import '../models/product.dart';

/// One line in the cart: a product plus how many of it are in the cart.
class CartLine {
  CartLine({required this.product, required this.quantity});

  final Product product;
  final int quantity;

  double get lineTotal => product.price * quantity;

  CartLine copyWith({int? quantity}) =>
      CartLine(product: product, quantity: quantity ?? this.quantity);
}

/// ARCHITECTURAL DECISION: We picked ChangeNotifier + provider package for
/// state management. Justification:
/// - The app's needs here are simple, mutable, mostly-local state (a cart)
///   with a handful of listeners (badge, cart screen). Bloc's event/state
///   ceremony and Riverpod's provider graph both add real value at larger
///   scale, but for a single shared piece of mutable state, ChangeNotifier
///   is the least amount of machinery that still gives us: (a) a single
///   source of truth, (b) granular listener rebuilds via
///   Selector/Consumer, and (c) easy testability (see test/cart_test.dart —
///   we test this class with zero widgets involved).
/// - Everything that is actual business logic (totals, discount rules,
///   merge-on-duplicate-add) lives in plain methods on this class. There is
///   no BuildContext anywhere in this file, so every method here is
///   callable and assertable from a plain `test()` block.
class CartModel extends ChangeNotifier {
  final Map<String, CartLine> _lines = {};

  /// Business rule: buying more than 3 units of a single product line earns
  /// a 10% discount on that line.
  static const int discountQuantityThreshold = 3;
  static const double discountRate = 0.10;

  List<CartLine> get lines => List.unmodifiable(_lines.values);

  int get totalItemCount =>
      _lines.values.fold(0, (sum, line) => sum + line.quantity);

  bool get isEmpty => _lines.isEmpty;

  /// Adds [product] to the cart. If it's already present, this increments
  /// the existing line's quantity instead of creating a duplicate entry
  /// (explicit requirement from the task spec).
  void addProduct(Product product, {int quantity = 1}) {
    final existing = _lines[product.id];
    if (existing != null) {
      _lines[product.id] = existing.copyWith(
        quantity: existing.quantity + quantity,
      );
    } else {
      _lines[product.id] = CartLine(product: product, quantity: quantity);
    }
    notifyListeners();
  }

  void removeProduct(String productId) {
    _lines.remove(productId);
    notifyListeners();
  }

  /// Decrements quantity by one; removes the line entirely once it hits 0.
  void decrementProduct(String productId) {
    final existing = _lines[productId];
    if (existing == null) return;
    if (existing.quantity <= 1) {
      _lines.remove(productId);
    } else {
      _lines[productId] = existing.copyWith(quantity: existing.quantity - 1);
    }
    notifyListeners();
  }

  /// Per-line discount amount (0 if the line doesn't qualify).
  double discountForLine(CartLine line) {
    if (line.quantity > discountQuantityThreshold) {
      return line.lineTotal * discountRate;
    }
    return 0;
  }

  double get subtotal =>
      _lines.values.fold(0.0, (sum, line) => sum + line.lineTotal);

  double get totalDiscount =>
      _lines.values.fold(0.0, (sum, line) => sum + discountForLine(line));

  double get total => subtotal - totalDiscount;

  void clear() {
    _lines.clear();
    notifyListeners();
  }
}
