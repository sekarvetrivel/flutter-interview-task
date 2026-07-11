import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../cart_logic/cart_model.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Consumer rebuilds this subtree whenever CartModel calls
    // notifyListeners(). All the actual math (subtotal/discount/total) is
    // computed in CartModel, so this widget only displays state.
    return Scaffold(
      appBar: AppBar(title: const Text('Your Cart')),
      body: Consumer<CartModel>(
        builder: (context, cart, _) {
          if (cart.isEmpty) {
            return const Center(child: Text('Your cart is empty'));
          }
          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  itemCount: cart.lines.length,
                  itemBuilder: (context, index) {
                    final line = cart.lines[index];
                    final discount = cart.discountForLine(line);
                    return ListTile(
                      title: Text(line.product.name),
                      subtitle: Text(
                        discount > 0
                            ? 'Qty ${line.quantity} • Bulk discount applied'
                            : 'Qty ${line.quantity}',
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline),
                            onPressed: () => cart
                                .decrementProduct(line.product.id),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline),
                            onPressed: () => cart.addProduct(line.product),
                          ),
                          const SizedBox(width: 8),
                          Text('\$${line.lineTotal.toStringAsFixed(2)}'),
                        ],
                      ),
                    );
                  },
                ),
              ),
              _CartSummary(cart: cart),
            ],
          );
        },
      ),
    );
  }
}

class _CartSummary extends StatelessWidget {
  const _CartSummary({required this.cart});

  final CartModel cart;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _row('Subtotal', cart.subtotal),
          if (cart.totalDiscount > 0)
            _row('Discount', -cart.totalDiscount),
          const Divider(),
          _row('Total', cart.total, bold: true),
        ],
      ),
    );
  }

  Widget _row(String label, double value, {bool bold = false}) {
    final style = TextStyle(
      fontWeight: bold ? FontWeight.bold : FontWeight.normal,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: style),
          Text('\$${value.toStringAsFixed(2)}', style: style),
        ],
      ),
    );
  }
}
