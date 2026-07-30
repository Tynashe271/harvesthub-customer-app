import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile_app/main.dart';
import 'package:mobile_app/models.dart';

void main() {
  testWidgets('shows Maphric authentication experience', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const MaphricApp());
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Fresh shopping,\nmade local.'), findsOneWidget);
    expect(find.text('Sign up'), findsWidgets);
  });

  test('parses product catalogue fields', () {
    final product = Product.fromJson({
      'id': 7,
      'name': 'Fresh Milk',
      'category_name': 'Dairy',
      'slug': 'fresh-milk',
      'price': '2.50',
      'stock_quantity': 8,
      'image': 'https://example.com/milk.png',
      'description': 'One litre',
      'brand': 'Local',
      'average_rating': 4.5,
    });

    expect(product.price, 2.5);
    expect(product.stock, 8);
    expect(product.rating, 4.5);
  });

  test('parses complete customer order receipt', () {
    final order = CustomerOrder.fromJson({
      'id': 12,
      'total': '10.75',
      'status': 'processing',
      'payment_method': 'EcoCash',
      'payment_status': 'paid',
      'shipping_name': 'Customer',
      'shipping_phone': '0770000000',
      'shipping_address': 'Bradfield',
      'created_at': '2026-07-29T10:00:00Z',
      'updated_at': '2026-07-29T10:05:00Z',
      'items': [
        {'product_name': 'Bread', 'unit_price': '1.25', 'quantity': 2},
      ],
    });

    expect(order.number, 'MAP-000012');
    expect(order.paymentStatus, 'paid');
    expect(order.items.single.quantity, 2);
  });
}
