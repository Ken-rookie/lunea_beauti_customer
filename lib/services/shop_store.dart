
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/product.dart';

class CartLine {
  CartLine(this.product, this.quantity);

  final Product product;
  int quantity;

  double get total => product.currentPrice * quantity;
}

class ShopOrder {
  ShopOrder({
    this.id,
    required this.number,
    required this.date,
    required this.status,
    required this.total,
    required this.items,
    this.paymentStatus,
  });

  final String? id;
  final String number;
  final DateTime date;
  final String status;
  final double total;
  final List<CartLine> items;
  final String? paymentStatus;
}

class ShopStore extends ChangeNotifier {
  final Map<String, CartLine> _cart = {};
  final Set<String> _favorites = {};
  final List<ShopOrder> orders = [];

  List<Product> products = [];
  bool isRefreshingProducts = false;
  String? productsError;

  String customerName = 'Jane Dela Cruz';
  String email = 'jane.delacruz@email.com';
  String phone = '';

void loadUserProfile() {
  final user = Supabase.instance.client.auth.currentUser;

  if (user == null) return;

  email = user.email ?? '';

  final metadata = user.userMetadata ?? {};

  customerName =
      metadata['full_name']?.toString() ??
      metadata['name']?.toString() ??
      email;

  phone = metadata['phone']?.toString() ?? '';

  notifyListeners();
}

  void setProducts(List<Product> newProducts) {
    products = newProducts;
    notifyListeners();
  }

  Future<void> refreshProducts() async {
    if (isRefreshingProducts) return;

    isRefreshingProducts = true;
    productsError = null;
    notifyListeners();

    try {
      final supabase = Supabase.instance.client;
      final categoryData = await supabase.from('categories').select('id, name');
      final categoryNames = <String, String>{
        for (final item in categoryData)
          item['id'].toString().trim().toLowerCase(): item['name'].toString(),
      };
      final data = await supabase
          .from('products')
          .select('''
            id,
            name,
            description,
            price,
            sale_price,
            stock,
            image_url,
            is_active,
            category_id
          ''')
          .eq('is_active', true);

      products = data.map<Product>((row) {
        final categoryId = (row['category_id']?.toString() ?? '')
            .trim()
            .toLowerCase();

        return Product(
          id: row['id'].toString(),
          name: row['name'] as String,
          category: categoryNames[categoryId] ?? 'Other',
          price: (row['price'] as num).toDouble(),
          salePrice: row['sale_price'] == null
              ? null
              : (row['sale_price'] as num).toDouble(),
          stock: (row['stock'] as num?)?.toInt() ?? 0,
          imageUrl: row['image_url'] as String? ?? '',
          tint: 0xfff3d9d8,
          description:
              row['description'] as String? ??
              'A lovely beauty essential for your everyday routine.',
        );
      }).toList();
    } catch (error) {
      productsError = error.toString();
    } finally {
      isRefreshingProducts = false;
      notifyListeners();
    }
  }

  List<CartLine> get cart =>
      _cart.values.toList(growable: false);

  Set<String> get favorites => Set.unmodifiable(_favorites);

  int get cartCount =>
      _cart.values.fold(0, (sum, line) => sum + line.quantity);

  double get subtotal =>
      _cart.values.fold(0, (sum, line) => sum + line.total);

  double get shipping => 0;

  double get total => subtotal + shipping;

  bool isFavorite(Product product) =>
      _favorites.contains(product.id);

  void updateProfile({
    String? name,
    String? emailAddress,
    String? phoneNumber,
  }) {
    if (name != null) customerName = name;
    if (emailAddress != null) email = emailAddress;
    if (phoneNumber != null) phone = phoneNumber;
    notifyListeners();
  }

  void toggleFavorite(Product product) {
    if (!_favorites.add(product.id)) {
      _favorites.remove(product.id);
    }
    notifyListeners();
  }

  void addToCart(Product product, {int quantity = 1}) {
    final line = _cart[product.id];

    if (line == null) {
      _cart[product.id] = CartLine(product, quantity);
    } else {
      line.quantity += quantity;
    }

    notifyListeners();
  }

  void setQuantity(Product product, int quantity) {
    if (quantity <= 0) {
      _cart.remove(product.id);
    } else {
      _cart[product.id]?.quantity = quantity;
    }

    notifyListeners();
  }

  void removeFromCart(Product product) {
    _cart.remove(product.id);
    notifyListeners();
  }

  // Local demo order; keep this for now.
  ShopOrder placeOrder() {
    final order = ShopOrder(
      number:
          'LB-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
      date: DateTime.now(),
      status: 'Processing',
      total: total,
      items: cart
          .map((line) => CartLine(line.product, line.quantity))
          .toList(),
    );

    orders.insert(0, order);
    _cart.clear();
    notifyListeners();

    return order;
  }

  // Save an order through Supabase.
  Future<Map<String, dynamic>> placeOrderInSupabase({
    required String customerName,
    required String email,
    required String phone,
    required String deliveryAddress,
    required String paymentMethod,
  }) async {
    final supabase = Supabase.instance.client;

    if (supabase.auth.currentUser == null) {
      throw Exception('Please sign in before placing an order.');
    }

    if (cart.isEmpty) {
      throw Exception('Your cart is empty.');
    }

    final items = cart.map((line) {
      return {
        'product_id': line.product.id,
        'quantity': line.quantity,
      };
    }).toList();

    final result = await supabase.rpc(
      'place_customer_order',
      params: {
        'p_customer_name': customerName,
        'p_email': email,
        'p_phone': phone,
        'p_delivery_address': deliveryAddress,
        'p_payment_method': paymentMethod,
        'p_items': items,
      },
    );

    final orderData = Map<String, dynamic>.from(result as Map);

    // Clear the cart only after Supabase succeeds.
    _cart.clear();
    notifyListeners();

    return orderData;
  }
}