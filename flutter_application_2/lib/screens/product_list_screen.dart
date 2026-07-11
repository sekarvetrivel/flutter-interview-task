import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../cart_logic/cart_model.dart';
import '../models/product.dart';
import 'cart_screen.dart';

const _catalog = [
  Product(id: 'p1', name: 'Wireless Mouse', price: 19.99),
  Product(id: 'p2', name: 'Mechanical Keyboard', price: 59.99),
  Product(id: 'p3', name: 'USB-C Cable', price: 7.99),
  Product(id: 'p4', name: 'Laptop Stand', price: 29.99),
];

class ProductListScreen extends StatelessWidget {
  const ProductListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Products'),
        actions: [_CartBadgeButton()],
      ),
      body: ListView.builder(
        itemCount: _catalog.length,
        itemBuilder: (context, index) {
          final product = _catalog[index];
          return ListTile(
            title: Text(product.name),
            subtitle: Text('\$${product.price.toStringAsFixed(2)}'),
            trailing: ElevatedButton(
              onPressed: () {
                // context.read: we want to call a method, not rebuild this
                // widget when the cart changes.
                context.read<CartModel>().addProduct(product);
              },
              child: const Text('Add'),
            ),
          );
        },
      ),
    );
  }
}

/// Small widget so only the badge count rebuilds when the cart changes,
/// instead of the whole ProductListScreen (or the whole AppBar).
class _CartBadgeButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // context.select rebuilds this widget ONLY when totalItemCount changes,
    // not on every CartModel notifyListeners() call.
    final itemCount = context.select<CartModel, int>((c) => c.totalItemCount);

    return IconButton(
      icon: Badge(
        label: Text('$itemCount'),
        isLabelVisible: itemCount > 0,
        child: const Icon(Icons.shopping_cart),
      ),
      onPressed: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const CartScreen()),
        );
      },
    );
  }
}
