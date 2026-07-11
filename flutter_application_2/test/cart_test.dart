import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_2/cart_logic/cart_model.dart';
import 'package:flutter_application_2/models/product.dart';

// Note: these tests import CartModel directly and never touch
// BuildContext, a Widget, or pumpWidget — proving the logic layer really
// is decoupled from Flutter's widget tree, as required by the task spec.

void main() {
  const mouse = Product(id: 'p1', name: 'Wireless Mouse', price: 20.0);
  const cable = Product(id: 'p2', name: 'USB-C Cable', price: 10.0);

  group('CartModel', () {
    test('adding the same product twice increments quantity, not duplicates',
        () {
      final cart = CartModel();

      cart.addProduct(mouse);
      cart.addProduct(mouse);

      expect(cart.lines.length, 1);
      expect(cart.lines.first.quantity, 2);
      expect(cart.totalItemCount, 2);
    });

    test('subtotal and total calculation with no discount', () {
      final cart = CartModel();

      cart.addProduct(mouse, quantity: 2); // 2 * 20 = 40
      cart.addProduct(cable, quantity: 1); // 1 * 10 = 10

      expect(cart.subtotal, 50.0);
      expect(cart.totalDiscount, 0.0);
      expect(cart.total, 50.0);
    });

    test('discount applies only once quantity exceeds threshold of 3', () {
      final cart = CartModel();

      // Exactly at the threshold -> no discount yet.
      cart.addProduct(mouse, quantity: 3);
      expect(cart.totalDiscount, 0.0);

      // One more pushes it over the threshold -> discount kicks in.
      cart.addProduct(mouse); // now quantity = 4
      final line = cart.lines.first;
      final expectedLineTotal = 4 * mouse.price; // 80.0
      final expectedDiscount = expectedLineTotal * CartModel.discountRate;

      expect(line.quantity, 4);
      expect(cart.discountForLine(line), expectedDiscount);
      expect(cart.total, expectedLineTotal - expectedDiscount);
    });

    test('decrementing to zero removes the line entirely', () {
      final cart = CartModel();
      cart.addProduct(cable, quantity: 1);

      cart.decrementProduct(cable.id);

      expect(cart.isEmpty, isTrue);
      expect(cart.lines, isEmpty);
    });

    test('removeProduct removes the whole line regardless of quantity', () {
      final cart = CartModel();
      cart.addProduct(mouse, quantity: 5);

      cart.removeProduct(mouse.id);

      expect(cart.isEmpty, isTrue);
    });
  });
}
