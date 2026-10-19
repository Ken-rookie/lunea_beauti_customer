import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:lunea_beauti_customer/screens/order_tracking_screen.dart';

import '../services/shop_store.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({
    required this.store,
    required this.onContinueShopping,
    super.key,
  });

  final ShopStore store;
  final VoidCallback onContinueShopping;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: store,
    builder: (context, _) {
      final isEmpty = store.cart.isEmpty;
      return Scaffold(
        body: isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.shopping_bag_outlined,
                        size: 52,
                        color: AppColors.rose,
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'Your bag is waiting',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 7),
                      const Text(
                        'Add something lovely to your beauty routine.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.muted),
                      ),
                      const SizedBox(height: 20),
                      PrimaryButton(
                        label: 'Explore Products',
                        onPressed: onContinueShopping,
                      ),
                    ],
                  ),
                ),
              )
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
                children: [
                  Text(
                    '${store.cartCount} items in your bag',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  for (final line in store.cart) ...[
                    _CartItem(line: line, store: store),
                    const SizedBox(height: 10),
                  ],
                ],
              ),
        bottomNavigationBar: isEmpty
            ? null
            : Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(top: BorderSide(color: AppColors.line)),
                ),
                child: SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _PriceRow(
                          label: 'Subtotal',
                          value: money(store.subtotal),
                        ),
                        const SizedBox(height: 7),
                        _PriceRow(
                          label: 'Shipping',
                          value: store.shipping == 0
                              ? 'FREE'
                              : money(store.shipping),
                        ),
                        const Divider(height: 18),
                        _PriceRow(
                          label: 'Total',
                          value: money(store.total),
                          bold: true,
                        ),
                        const SizedBox(height: 11),
                        PrimaryButton(
                          label: 'Proceed to Checkout',
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => CheckoutScreen(store: store),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
      );
    },
  );
}

class _CartItem extends StatelessWidget {
  const _CartItem({required this.line, required this.store});

  final CartLine line;
  final ShopStore store;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppColors.line),
    ),
    child: Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            width: 76,
            height: 82,
            child: ProductImage(product: line.product),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                line.product.name,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 5),
              Text(
                money(line.product.currentPrice),
                style: const TextStyle(
                  color: AppColors.deepRose,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 7),
              Row(
                children: [
                  _SmallIconButton(
                    icon: Icons.remove,
                    onPressed: () =>
                        store.setQuantity(line.product, line.quantity - 1),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 11),
                    child: Text('${line.quantity}'),
                  ),
                  _SmallIconButton(
                    icon: Icons.add,
                    onPressed: () =>
                        store.setQuantity(line.product, line.quantity + 1),
                  ),
                  const Spacer(),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    onPressed: () => store.removeFromCart(line.product),
                    icon: const Icon(
                      Icons.delete_outline,
                      color: AppColors.muted,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({required this.store, super.key});

  final ShopStore store;

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _address = TextEditingController();
  String paymentMethod = 'PayMongo';

  List<Map<String, dynamic>> _savedAddresses = [];
  String? _selectedAddressId;
  bool _loadingAddresses = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _loadSavedAddresses();
    });
  }

  @override
  void dispose() {
    _address.dispose();
    super.dispose();
  }

  Future<void> _loadSavedAddresses() async {
    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;

      if (user == null) {
        throw Exception('Please sign in again.');
      }

      final result = await supabase
          .from('customer_addresses')
          .select()
          .eq('user_id', user.id)
          .order('is_default', ascending: false)
          .order('created_at', ascending: false);

      if (!mounted) return;

      final addresses = List<Map<String, dynamic>>.from(result);

      setState(() {
        _savedAddresses = addresses;
        _loadingAddresses = false;

        if (addresses.isNotEmpty) {
          final selected = addresses.first;
          _selectedAddressId = selected['id'].toString();
          _address.text = _formatAddress(selected);
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingAddresses = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Could not load saved addresses. You can enter one manually.',
          ),
        ),
      );
    }
  }

  String _formatAddress(Map<String, dynamic> address) {
    return [
          address['address_line'],
          'Barangay ${address['barangay']}',
          address['city'],
          address['province'],
          address['postal_code'],
        ]
        .where((part) => part != null && part.toString().trim().isNotEmpty)
        .join(', ');
  }

  void _continueToPayment() {
    if (_address.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a delivery address.')),
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PaymentScreen(
          store: widget.store,
          method: paymentMethod,
          address: _address.text.trim(),
          subtotal: widget.store.subtotal,
          shipping: widget.store.shipping,
          total: widget.store.total,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Checkout')),
    body: AnimatedBuilder(
      animation: widget.store,
      builder: (context, _) => ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          const _SectionHeading(
            icon: Icons.location_on_outlined,
            title: 'Delivery Address',
          ),
          const SizedBox(height: 10),

          if (_loadingAddresses) const LinearProgressIndicator(),

          if (_savedAddresses.isNotEmpty) ...[
            DropdownButtonFormField<String>(
              initialValue: _selectedAddressId,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Choose a saved address',
                prefixIcon: Icon(Icons.home_outlined),
              ),
              items: _savedAddresses.map((address) {
                return DropdownMenuItem<String>(
                  value: address['id'].toString(),
                  child: Text(
                    '${address['full_name']} — ${address['city']}',
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
              onChanged: (id) {
                if (id == null) return;

                final selected = _savedAddresses.firstWhere(
                  (item) => item['id'].toString() == id,
                );

                setState(() {
                  _selectedAddressId = id;
                  _address.text = _formatAddress(selected);
                });
              },
            ),
            const SizedBox(height: 12),
          ],

          TextField(
            controller: _address,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Delivery address',
              hintText: 'Enter your complete delivery address',
              prefixIcon: Icon(Icons.location_on_outlined),
            ),
          ),

          const SizedBox(height: 22),
          const _SectionHeading(
            icon: Icons.receipt_long_outlined,
            title: 'Order Summary',
          ),
          const SizedBox(height: 10),

          for (final line in widget.store.cart)
            Padding(
              padding: const EdgeInsets.only(bottom: 9),
              child: Row(
                children: [
                  Expanded(
                    child: Text('${line.product.name} × ${line.quantity}'),
                  ),
                  Text(
                    money(line.total),
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),

          const Divider(color: AppColors.line, height: 22),
          _PriceRow(label: 'Subtotal', value: money(widget.store.subtotal)),
          const SizedBox(height: 9),
          _PriceRow(
            label: 'Shipping',
            value: widget.store.shipping == 0
                ? 'FREE'
                : money(widget.store.shipping),
          ),
          const SizedBox(height: 8),
          _PriceRow(
            label: 'Total',
            value: money(widget.store.total),
            bold: true,
          ),

          const SizedBox(height: 23),
          const _SectionHeading(
            icon: Icons.payments_outlined,
            title: 'Payment Method',
          ),
          const SizedBox(height: 10),

          RadioGroup<String>(
            groupValue: paymentMethod,
            onChanged: (value) {
              if (value != null) {
                setState(() => paymentMethod = value);
              }
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _PaymentMethodTile(
                  value: 'PayMongo',
                  selected: paymentMethod == 'PayMongo',
                  icon: Icons.account_balance_wallet_outlined,
                  title: 'PayMongo',
                  subtitle: 'QRPH, GCash, Maya, debit or credit card',
                ),
                const SizedBox(height: 10),
                _PaymentMethodTile(
                  value: 'Cash on Delivery',
                  selected: paymentMethod == 'Cash on Delivery',
                  icon: Icons.local_shipping_outlined,
                  title: 'Cash on Delivery',
                  subtitle: 'Pay in cash when your order arrives',
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.palePink,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.lock_outline,
                  size: 18,
                  color: AppColors.deepRose,
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    paymentMethod == 'PayMongo'
                        ? 'You will continue to PayMongo to complete your payment.'
                        : 'Your payment is collected when your order is delivered.',
                    style: const TextStyle(
                      color: AppColors.deepRose,
                      fontSize: 12,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
    bottomNavigationBar: AnimatedBuilder(
      animation: widget.store,
      builder: (context, _) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: AppColors.line)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _PriceRow(
                  label: 'Order total',
                  value: money(widget.store.total),
                  bold: true,
                ),
                const SizedBox(height: 10),
                PrimaryButton(
                  label: 'Continue to payment',
                  onPressed: widget.store.cart.isEmpty
                      ? null
                      : _continueToPayment,
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class _PaymentMethodTile extends StatelessWidget {
  const _PaymentMethodTile({
    required this.value,
    required this.selected,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final String value;
  final bool selected;
  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) => Material(
    color: selected ? AppColors.palePink : Colors.white,
    shape: RoundedRectangleBorder(
      side: BorderSide(
        color: selected ? AppColors.rose : AppColors.line,
        width: selected ? 1.5 : 1,
      ),
      borderRadius: BorderRadius.circular(12),
    ),
    clipBehavior: Clip.antiAlias,
    child: RadioListTile<String>(
      value: value,
      activeColor: AppColors.rose,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      title: Row(
        children: [
          Icon(icon, size: 19, color: AppColors.deepRose),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 3),
        child: Text(subtitle),
      ),
    ),
  );
}

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({
    required this.store,
    required this.method,
    required this.address,
    required this.subtotal,
    required this.shipping,
    required this.total,
    super.key,
  });

  final ShopStore store;
  final String method;
  final String address;
  final double subtotal;
  final double shipping;
  final double total;

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  bool _isSubmitting = false;

  Future<void> _placeOrder() async {
    if (_isSubmitting) return;

    if (widget.store.cart.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Your cart is empty.')));
      return;
    }

    setState(() => _isSubmitting = true);
    final paymentMethod = widget.method == 'Cash on Delivery'
        ? 'COD'
        : 'PayMongo';

    try {
      final orderData = await widget.store.placeOrderInSupabase(
        customerName: widget.store.customerName,
        email: widget.store.email,
        phone: widget.store.phone,
        deliveryAddress: widget.address,
        paymentMethod: paymentMethod,
      );

      if (!context.mounted) return;

      final order = ShopOrder(
        id: orderData['order_id'].toString(),
        number: orderData['order_number'].toString(),
        date: DateTime.now(),
        status: widget.method == 'Cash on Delivery'
            ? 'Processing'
            : 'Awaiting payment',
        total: (orderData['total'] as num).toDouble(),
        items: const [],
      );

      widget.store.orders.insert(0, order);

      // Cash on Delivery does not use PayMongo.
      if (widget.method == 'Cash on Delivery') {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute<void>(
            builder: (_) =>
                OrderSuccessScreen(store: widget.store, order: order),
          ),
          (route) => route.isFirst,
        );
        return;
      }

      // Create a PayMongo checkout session for online payments.
      final response = await Supabase.instance.client.functions.invoke(
        'bright-endpoint',
        body: {'order_id': order.id},
      );

      if (response.status < 200 || response.status >= 300) {
        throw Exception('Could not create PayMongo checkout.');
      }

      final result = Map<String, dynamic>.from(response.data as Map);
      final checkoutUrl = result['checkout_url']?.toString();

      if (checkoutUrl == null) {
        throw Exception('PayMongo did not return a checkout URL.');
      }

      final uri = Uri.tryParse(checkoutUrl);

      if (uri == null ||
          uri.scheme != 'https' ||
          uri.host != 'checkout.paymongo.com') {
        throw Exception('The PayMongo checkout URL is invalid.');
      }

      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);

      if (!opened) {
        throw Exception('Could not open the PayMongo checkout page.');
      }
    } catch (error) {
      if (!context.mounted) return;

      final errorMessage = error.toString();
      final customerMessage = errorMessage.contains('PAYMONGO_RETURN_URL')
          ? 'PayMongo is not configured yet. Choose Cash on Delivery or try again later.'
          : errorMessage;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Checkout could not continue: $customerMessage')),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Review your order')),
    body: Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.palePink,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Icon(
                      widget.method == 'Cash on Delivery'
                          ? Icons.local_shipping_outlined
                          : Icons.lock_outline,
                      size: 28,
                      color: AppColors.deepRose,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      widget.method == 'Cash on Delivery'
                          ? 'Cash on Delivery'
                          : 'Pay securely with PayMongo',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 17,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      widget.method == 'Cash on Delivery'
                          ? 'Pay in cash when your order arrives.'
                          : 'Continue to PayMongo for QRPH, GCash, Maya or card payment.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.muted),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      money(widget.total),
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppColors.deepRose,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              const _SectionHeading(
                icon: Icons.location_on_outlined,
                title: 'Delivery address',
              ),
              const SizedBox(height: 8),
              Text(
                widget.address,
                style: const TextStyle(color: AppColors.muted, height: 1.4),
              ),
              const SizedBox(height: 22),
              const _SectionHeading(
                icon: Icons.receipt_long_outlined,
                title: 'Order total',
              ),
              const SizedBox(height: 10),
              _PriceRow(label: 'Subtotal', value: money(widget.subtotal)),
              const SizedBox(height: 8),
              _PriceRow(
                label: 'Shipping',
                value: widget.shipping == 0 ? 'FREE' : money(widget.shipping),
              ),
              const Divider(color: AppColors.line, height: 20),
              _PriceRow(label: 'Total', value: money(widget.total), bold: true),
            ],
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
            child: PrimaryButton(
              label: _isSubmitting
                  ? 'Preparing checkout...'
                  : widget.method == 'Cash on Delivery'
                  ? 'Place COD order'
                  : 'Continue to PayMongo',
              isLoading: _isSubmitting,
              onPressed: _isSubmitting || widget.store.cart.isEmpty
                  ? null
                  : _placeOrder,
            ),
          ),
        ),
      ],
    ),
  );
}

class OrderSuccessScreen extends StatelessWidget {
  const OrderSuccessScreen({
    required this.store,
    required this.order,
    super.key,
  });

  final ShopStore store;
  final ShopOrder order;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(22, 36, 22, 20),
              children: [
                Center(
                  child: Container(
                    height: 76,
                    width: 76,
                    decoration: const BoxDecoration(
                      color: AppColors.blush,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_circle,
                      size: 48,
                      color: AppColors.rose,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'Order placed',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Thank you for shopping with Lunéa Beauti.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.muted),
                ),
                const SizedBox(height: 22),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: AppColors.line),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Order #${order.number}',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Total  ${money(order.total)}',
                        style: const TextStyle(
                          color: AppColors.deepRose,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                PrimaryButton(
                  label: 'View Order',
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => OrderDetailsScreen(order: order),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                PrimaryButton(
                  label: 'Continue Shopping',
                  outlined: true,
                  onPressed: () =>
                      Navigator.of(context).popUntil((route) => route.isFirst),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class MyOrdersScreen extends StatefulWidget {
  const MyOrdersScreen({required this.store, super.key});

  final ShopStore store;

  @override
  State<MyOrdersScreen> createState() => _MyOrdersScreenState();
}

class _MyOrdersScreenState extends State<MyOrdersScreen> {
  String filter = 'All';
  Timer? _refreshTimer;

  List<ShopOrder> _orders = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadOrders();
    _refreshTimer = Timer.periodic(
      const Duration(minutes: 1),
      (_) => _loadOrders(),
    );
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadOrders() async {
    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;

      if (user == null) {
        throw Exception('Please sign in to view your orders.');
      }

      final result = await supabase
          .from('orders')
          .select(
            'id, order_number, total, order_status, payment_status, created_at',
          )
          .eq('user_id', user.id)
          .order('created_at', ascending: false);

      final loadedOrders = (result as List).map((row) {
        final data = Map<String, dynamic>.from(row);

        return ShopOrder(
          id: data['id'].toString(),
          number: data['order_number'].toString(),
          date: DateTime.parse(data['created_at'].toString()),
          status: data['order_status'].toString(),
          paymentStatus: data['payment_status']?.toString(),
          total: (data['total'] as num).toDouble(),
          items: <CartLine>[],
        );
      }).toList();

      if (!mounted) return;

      setState(() {
        _orders = loadedOrders;
        _isLoading = false;
        _error = null;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _error = error.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final orders = _orders
        .where((order) => filter == 'All' || order.status == filter)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Orders'),
        actions: [
          IconButton(
            onPressed: _loadOrders,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh orders',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Could not load your orders.'),
                    const SizedBox(height: 8),
                    Text(_error!, textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _loadOrders,
                      child: const Text('Try Again'),
                    ),
                  ],
                ),
              ),
            )
          : Column(
              children: [
                SizedBox(
                  height: 56,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    children:
                        [
                          'All',
                          'Awaiting payment',
                          'Processing',
                          'Shipped',
                          'Delivered',
                        ].map((status) {
                          final selected = filter == status;

                          return Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 7,
                            ),
                            child: ChoiceChip(
                              label: Text(status),
                              selected: selected,
                              showCheckmark: false,
                              selectedColor: AppColors.rose,
                              labelStyle: TextStyle(
                                color: selected ? Colors.white : AppColors.ink,
                              ),
                              onSelected: (_) {
                                setState(() => filter = status);
                              },
                            ),
                          );
                        }).toList(),
                  ),
                ),
                Expanded(
                  child: orders.isEmpty
                      ? const Center(
                          child: Text('Your orders will appear here.'),
                        )
                      : ListView(
                          padding: const EdgeInsets.all(16),
                          children: orders
                              .map((order) => _OrderTile(order: order))
                              .toList(),
                        ),
                ),
              ],
            ),
    );
  }
}

class _OrderTile extends StatelessWidget {
  const _OrderTile({required this.order});

  final ShopOrder order;

  @override
  Widget build(BuildContext context) => Card(
    elevation: 0,
    color: Colors.white,
    margin: const EdgeInsets.only(bottom: 11),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
      side: const BorderSide(color: AppColors.line),
    ),
    child: ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.blush,
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(
          Icons.shopping_bag_outlined,
          size: 19,
          color: AppColors.deepRose,
        ),
      ),
      title: Text(
        '#${order.number}',
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Text(
          '${order.date.day}/${order.date.month}/${order.date.year}  ·  ${money(order.total)}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      trailing: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _StatusPill(
            order.paymentStatus?.toLowerCase() == 'paid' ? 'Paid' : 'Pending',
          ),
          const SizedBox(height: 4),
          Text(
            order.status,
            style: const TextStyle(color: AppColors.muted, fontSize: 10),
          ),
        ],
      ),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => OrderDetailsScreen(order: order),
        ),
      ),
    ),
  );
}

class OrderDetailsScreen extends StatefulWidget {
  const OrderDetailsScreen({required this.order, super.key});

  final ShopOrder order;

  @override
  State<OrderDetailsScreen> createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends State<OrderDetailsScreen> {
  bool _isLoading = true;
  String? _errorMessage;

  Map<String, dynamic>? _orderData;
  List<Map<String, dynamic>> _orderItems = [];

  @override
  void initState() {
    super.initState();
    _loadOrderDetails();
  }

  Future<void> _loadOrderDetails() async {
    final orderId = widget.order.id;

    if (orderId == null || orderId.isEmpty) {
      setState(() {
        _errorMessage = 'Order ID is missing.';
        _isLoading = false;
      });
      return;
    }

    try {
      final supabase = Supabase.instance.client;

      final orderResult = await supabase
          .from('orders')
          .select(
            'order_number, subtotal, shipping_fee, total, '
            'payment_method, payment_status, order_status, '
            'delivery_address, created_at',
          )
          .eq('id', orderId)
          .single();

      final itemsResult = await supabase
          .from('order_items')
          .select('product_name, unit_price, quantity, line_total')
          .eq('order_id', orderId);

      if (!mounted) return;

      setState(() {
        _orderData = Map<String, dynamic>.from(orderResult);
        _orderItems = (itemsResult as List)
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = 'Could not load order details: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Order Details')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Order Details')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Text(_errorMessage!),
          ),
        ),
      );
    }

    final data = _orderData!;

    final subtotal = (data['subtotal'] as num).toDouble();
    final shippingFee = (data['shipping_fee'] as num).toDouble();
    final total = (data['total'] as num).toDouble();

    return Scaffold(
      appBar: AppBar(title: const Text('Order Details')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        children: [
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: AppColors.line),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Order #${data['order_number']}',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${widget.order.date.day}/${widget.order.date.month}/${widget.order.date.year}',
                            style: const TextStyle(
                              color: AppColors.muted,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _StatusPill(data['order_status'].toString()),
                  ],
                ),
                const Divider(height: 22),
                Row(
                  children: [
                    const Text('Payment'),
                    const Spacer(),
                    _StatusPill(
                      data['payment_status'].toString().toLowerCase() == 'paid'
                          ? 'Paid'
                          : 'Pending',
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Method: ${data['payment_method']}',
                  style: const TextStyle(fontSize: 12),
                ),
                const SizedBox(height: 9),
                Text(
                  'Delivering to ${data['delivery_address']}',
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const _SectionHeading(
            icon: Icons.shopping_bag_outlined,
            title: 'Items',
          ),
          const SizedBox(height: 12),

          if (_orderItems.isEmpty)
            const Text('No items found for this order.')
          else
            for (final item in _orderItems)
              Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Row(
                  children: [
                    const Icon(
                      Icons.shopping_bag_outlined,
                      size: 42,
                      color: AppColors.muted,
                    ),
                    const SizedBox(width: 11),
                    Expanded(
                      child: Text(
                        '${item['product_name']}\n'
                        'Quantity: ${item['quantity']}',
                        style: const TextStyle(height: 1.5),
                      ),
                    ),
                    Text(
                      money((item['line_total'] as num).toDouble()),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),

          const Divider(height: 18, color: AppColors.line),

          _PriceRow(label: 'Subtotal', value: money(subtotal)),
          const SizedBox(height: 9),
          _PriceRow(label: 'Shipping', value: money(shippingFee)),
          const Divider(height: 25, color: AppColors.line),
          _PriceRow(label: 'Total', value: money(total), bold: true),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
          child: PrimaryButton(
            label: 'Track Order',
            icon: Icons.local_shipping_outlined,
            onPressed: () {
              if (widget.order.id == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Order ID is missing. Please refresh your order.',
                    ),
                  ),
                );
                return;
              }

              Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (context) => OrderTrackingScreen(
                    orderId: widget.order.id!,
                    orderNumber: widget.order.number,
                    orderStatus:
                        _orderData?['order_status']?.toString() ??
                        widget.order.status,
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, size: 20, color: AppColors.rose),
      const SizedBox(width: 8),
      Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
      ),
    ],
  );
}

class _PriceRow extends StatelessWidget {
  const _PriceRow({
    required this.label,
    required this.value,
    this.bold = false,
  });

  final String label;
  final String value;
  final bool bold;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Text(
        label,
        style: TextStyle(
          fontWeight: bold ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      const Spacer(),
      Text(
        value,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: bold ? AppColors.deepRose : AppColors.ink,
        ),
      ),
    ],
  );
}

class _SmallIconButton extends StatelessWidget {
  const _SmallIconButton({required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => InkWell(
    borderRadius: BorderRadius.circular(7),
    onTap: onPressed,
    child: Container(
      height: 25,
      width: 25,
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Icon(icon, size: 15, color: AppColors.deepRose),
    ),
  );
}

class _StatusPill extends StatelessWidget {
  const _StatusPill(this.status);

  final String status;

  @override
  Widget build(BuildContext context) {
    final normalizedStatus = status.toLowerCase();
    final color = normalizedStatus == 'delivered' || normalizedStatus == 'paid'
        ? AppColors.green
        : normalizedStatus == 'shipped'
        ? const Color(0xff5687a4)
        : normalizedStatus == 'pending'
        ? const Color(0xffa46c16)
        : AppColors.rose;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class PaymentReturnScreen extends StatefulWidget {
  const PaymentReturnScreen({
    required this.store,
    required this.paymentResult,
    required this.orderId,
    required this.onContinueShopping,
    super.key,
  });

  final ShopStore store;
  final String paymentResult;
  final String? orderId;
  final VoidCallback onContinueShopping;

  @override
  State<PaymentReturnScreen> createState() => _PaymentReturnScreenState();
}

class _PaymentReturnScreenState extends State<PaymentReturnScreen> {
  Map<String, dynamic>? _order;
  String? _error;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    unawaited(_pollPaymentStatus());
  }

  Future<void> _pollPaymentStatus() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (widget.orderId == null || widget.orderId!.isEmpty || user == null) {
      await _loadPaymentStatus();
      return;
    }

    for (var attempt = 0; attempt < 15 && mounted; attempt++) {
      await _loadPaymentStatus(showLoading: attempt == 0);
      if (!mounted || _isPaid) return;
      if (attempt < 14) {
        await Future<void>.delayed(const Duration(seconds: 2));
      }
    }
  }

  bool get _isPaid =>
      _order?['payment_status']?.toString().toLowerCase() == 'paid';

  Future<void> _loadPaymentStatus({bool showLoading = true}) async {
    final orderId = widget.orderId;
    final user = Supabase.instance.client.auth.currentUser;

    if (orderId == null || orderId.isEmpty || user == null) {
      setState(() {
        _error =
            'We could not verify this payment. Sign in and check My Orders.';
        _isLoading = false;
      });
      return;
    }

    setState(() {
      if (showLoading) _isLoading = true;
      _error = null;
    });

    try {
      final result = await Supabase.instance.client
          .from('orders')
          .select('order_number, total, payment_status')
          .eq('id', orderId)
          .eq('user_id', user.id)
          .maybeSingle();

      if (!mounted) return;

      if (result == null) {
        setState(() {
          _error = 'We could not find this order in your account.';
          _isLoading = false;
        });
        return;
      }

      setState(() {
        _order = Map<String, dynamic>.from(result);
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Payment status could not be loaded. Please try again.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final paid = _isPaid;
    final cancelled = widget.paymentResult == 'cancelled';
    final title = paid
        ? 'Payment confirmed'
        : cancelled
        ? 'Payment not completed'
        : 'Payment processing';
    final description = paid
        ? 'Your QRPH payment has been confirmed. Thank you for your order.'
        : cancelled
        ? 'No payment was confirmed. You can review the order in My Orders.'
        : 'We are waiting for PayMongo to confirm your payment.';

    return Scaffold(
      appBar: AppBar(title: const Text('Payment status')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(22, 28, 22, 24),
          children: [
            Center(
              child: Container(
                width: 72,
                height: 72,
                decoration: const BoxDecoration(
                  color: AppColors.blush,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  paid ? Icons.check_circle : Icons.qr_code_2,
                  color: AppColors.rose,
                  size: 42,
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              _isLoading ? 'Checking payment' : title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              _isLoading
                  ? 'Please wait while we confirm your order.'
                  : _error ?? description,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.muted, height: 1.45),
            ),
            if (_isLoading) ...[
              const SizedBox(height: 20),
              const Center(
                child: CircularProgressIndicator(color: AppColors.rose),
              ),
            ],
            if (!_isLoading && _order != null) ...[
              const SizedBox(height: 22),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: AppColors.line),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Text('Order #${_order!['order_number']}'),
                    const SizedBox(height: 6),
                    Text(
                      'Payment: ${_order!['payment_status']}',
                      style: const TextStyle(color: AppColors.muted),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      money((_order!['total'] as num).toDouble()),
                      style: const TextStyle(
                        color: AppColors.deepRose,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (!_isLoading && (!paid || _error != null)) ...[
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () => _loadPaymentStatus(),
                icon: const Icon(Icons.refresh),
                label: const Text('Refresh payment status'),
              ),
            ],
            const SizedBox(height: 12),
            PrimaryButton(
              label: 'View My Orders',
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => MyOrdersScreen(store: widget.store),
                ),
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: widget.onContinueShopping,
              child: const Text('Continue Shopping'),
            ),
          ],
        ),
      ),
    );
  }
}
