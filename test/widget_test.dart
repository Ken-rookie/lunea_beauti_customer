import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lunea_beauti_customer/main.dart';
import 'package:lunea_beauti_customer/models/product.dart';
import 'package:lunea_beauti_customer/screens/order_screens.dart';
import 'package:lunea_beauti_customer/screens/product_screens.dart';
import 'package:lunea_beauti_customer/services/shop_store.dart';

void main() {
  test('category image mapping recognizes database category names', () {
    expect(categoryImageUrl('Face Makeup'), productCategories['Face']);
    expect(categoryImageUrl('Eye Makeup'), productCategories['Eyes']);
    expect(categoryImageUrl('Lip Makeup'), productCategories['Lips']);
    expect(categoryImageUrl('Cheeks'), productCategories['Cheeks']);
  });

  test('cart totals, favorites, and local order placement work', () {
    final store = ShopStore();
    final product = sampleProducts.first;

    store.addToCart(product, quantity: 2);
    store.toggleFavorite(product);

    expect(store.cartCount, 2);
    expect(store.subtotal, product.currentPrice * 2);
    expect(store.shipping, 0);
    expect(store.isFavorite(product), isTrue);

    final order = store.placeOrder();

    expect(order.total, product.currentPrice * 2);
    expect(order.items.single.quantity, 2);
    expect(store.cartCount, 0);
    expect(store.orders, contains(order));
  });

  testWidgets('product details keeps purchase actions reachable', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final store = ShopStore();
    await tester.pumpWidget(
      MaterialApp(
        home: ProductDetailsScreen(
          product: sampleProducts.first,
          store: store,
          onViewCart: () {},
          onCheckout: () {},
        ),
      ),
    );

    expect(find.text('Add to Bag'), findsOneWidget);
    expect(find.text('Buy Now'), findsOneWidget);
    await tester.tap(find.text('Add to Bag'));
    await tester.pump();
    expect(store.cartCount, 1);
  });

  testWidgets('cart keeps checkout summary visible on a phone viewport', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final store = ShopStore()..addToCart(sampleProducts.first);
    await tester.pumpWidget(
      MaterialApp(
        home: CartScreen(store: store, onContinueShopping: () {}),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Proceed to Checkout'), findsOneWidget);
    expect(find.text('Total'), findsOneWidget);
  });

  testWidgets('order confirmation fits a short phone viewport', (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final store = ShopStore();
    final order = ShopOrder(
      number: 'LB-123',
      date: DateTime(2026, 10, 18),
      status: 'Processing',
      total: 499,
      items: const [],
    );
    await tester.pumpWidget(
      MaterialApp(
        home: OrderSuccessScreen(store: store, order: order),
      ),
    );

    expect(find.text('View Order'), findsOneWidget);
    expect(find.text('Continue Shopping'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('checkout offers PayMongo and cash on delivery', (tester) async {
    final store = ShopStore()..addToCart(sampleProducts.first);

    await tester.pumpWidget(MaterialApp(home: CheckoutScreen(store: store)));
    await tester.pumpAndSettle();

    expect(find.text('PayMongo'), findsOneWidget);
    expect(find.text('Cash on Delivery'), findsOneWidget);
    expect(
      find.text('QRPH, GCash, Maya, debit or credit card'),
      findsOneWidget,
    );
    expect(find.text('GCash'), findsNothing);
    expect(find.text('Maya'), findsNothing);
  });

  testWidgets('welcome screen opens the login screen', (tester) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const LuneaBeautiApp());

    expect(find.bySemanticsLabel('Get Started'), findsOneWidget);
    expect(find.text('Get Started    →'), findsNothing);
    expect(find.byType(FilledButton), findsNothing);
    await tester.tap(find.bySemanticsLabel('Get Started'));
    await tester.pumpAndSettle();
    expect(find.text('Welcome Back'), findsOneWidget);
  });

  testWidgets('login link remains visible on a wide browser viewport', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(626, 879);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const LuneaBeautiApp());

    expect(tester.widget<Image>(find.byType(Image)).fit, BoxFit.contain);
    final loginLink = find.bySemanticsLabel('Already have an account? Log In');
    expect(loginLink, findsOneWidget);
    expect(tester.getRect(loginLink).bottom, lessThan(879));

    await tester.tap(loginLink);
    await tester.pumpAndSettle();
    expect(find.text('Welcome Back'), findsOneWidget);
  });
}
