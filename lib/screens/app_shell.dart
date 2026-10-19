import 'dart:async';

import 'package:flutter/material.dart';

import 'addresses_screen.dart';
import '../models/product.dart';
import '../services/shop_store.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import 'order_screens.dart';
import 'product_screens.dart';

class AppShell extends StatefulWidget {
  const AppShell({required this.store, required this.onLogout, super.key});

  final ShopStore store;
  final VoidCallback onLogout;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int selectedTab = 0;
  String selectedCategory = 'All';
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    widget.store.refreshProducts();
    _refreshTimer = Timer.periodic(
      const Duration(minutes: 1),
      (_) => widget.store.refreshProducts(),
    );
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _refreshProducts() async {
    await widget.store.refreshProducts();
    if (!mounted) return;

    final error = widget.store.productsError;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          error == null ? 'Store data refreshed.' : 'Refresh failed: $error',
        ),
      ),
    );
  }

  void _openProduct(Product product) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ProductDetailsScreen(
          product: product,
          store: widget.store,
          onViewCart: () {
            Navigator.of(context).pop();
            setState(() => selectedTab = 2);
          },
          onCheckout: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => CheckoutScreen(store: widget.store),
            ),
          ),
        ),
      ),
    );
  }

  void _selectCategory(String category) {
    setState(() {
      selectedCategory = category;
      selectedTab = 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      AnimatedBuilder(
        animation: widget.store,
        builder: (context, _) => HomeScreen(
          store: widget.store,
          onOpenProduct: _openProduct,
          onShop: () => setState(() {
            selectedCategory = 'All';
            selectedTab = 1;
          }),
          onCategory: _selectCategory,
        ),
      ),

      ProductListingScreen(
        key: ValueKey(selectedCategory),
        store: widget.store,
        initialCategory: selectedCategory,
        onOpenProduct: _openProduct,
      ),
      CartScreen(
        store: widget.store,
        onContinueShopping: () => setState(() => selectedTab = 1),
      ),
      FavoritesScreen(store: widget.store, onOpenProduct: _openProduct),
      ProfileScreen(store: widget.store, onLogout: widget.onLogout),
    ];

    return Scaffold(
      appBar: selectedTab == 0
          ? AppBar(
              title: const Text(
                'Lunéa Beauti',
                style: TextStyle(
                  fontFamily: 'serif',
                  fontWeight: FontWeight.w600,
                  color: AppColors.deepRose,
                ),
              ),
              actions: [
                IconButton(
                  tooltip: 'Refresh store data',
                  onPressed: _refreshProducts,
                  icon: const Icon(Icons.refresh_rounded),
                ),
                IconButton(
                  onPressed: _showNotifications,
                  icon: const Icon(Icons.notifications_none_rounded),
                ),
                IconButton(
                  tooltip: 'My Bag',
                  onPressed: () => setState(() => selectedTab = 2),
                  icon: Badge(
                    isLabelVisible: widget.store.cartCount > 0,
                    label: Text('${widget.store.cartCount}'),
                    child: const Icon(Icons.shopping_bag_outlined),
                  ),
                ),
                const SizedBox(width: 6),
              ],
            )
          : AppBar(
              title: Text(
                [
                  'Home',
                  'Shop',
                  'My Bag',
                  'My Favorites',
                  'My Profile',
                ][selectedTab],
              ),
              actions: [
                IconButton(
                  tooltip: 'Refresh store data',
                  onPressed: _refreshProducts,
                  icon: const Icon(Icons.refresh_rounded),
                ),
                if (selectedTab == 1)
                  IconButton(
                    onPressed: _showNotifications,
                    icon: const Icon(Icons.notifications_none_rounded),
                  ),
                if (selectedTab != 2)
                  IconButton(
                    tooltip: 'My Bag',
                    onPressed: () => setState(() => selectedTab = 2),
                    icon: Badge(
                      isLabelVisible: widget.store.cartCount > 0,
                      label: Text('${widget.store.cartCount}'),
                      child: const Icon(Icons.shopping_bag_outlined),
                    ),
                  ),
              ],
            ),
      body: IndexedStack(index: selectedTab, children: screens),
      bottomNavigationBar: AnimatedBuilder(
        animation: widget.store,
        builder: (context, _) => NavigationBar(
          selectedIndex: selectedTab,
          onDestinationSelected: (index) => setState(() => selectedTab = index),
          height: 68,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: [
            const NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'Home',
            ),
            const NavigationDestination(
              icon: Icon(Icons.grid_view_outlined),
              selectedIcon: Icon(Icons.grid_view_rounded),
              label: 'Shop',
            ),
            NavigationDestination(
              icon: Badge(
                isLabelVisible: widget.store.cartCount > 0,
                label: Text('${widget.store.cartCount}'),
                child: const Icon(Icons.shopping_bag_outlined),
              ),
              selectedIcon: const Icon(Icons.shopping_bag),
              label: 'Cart',
            ),
            const NavigationDestination(
              icon: Icon(Icons.favorite_border),
              selectedIcon: Icon(Icons.favorite),
              label: 'Favorites',
            ),
            const NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }

  void _showNotifications() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => const SizedBox(
        height: 210,
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Notifications',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 19),
              ),
              SizedBox(height: 20),
              Text(
                'You’re all caught up. Check back soon for lovely updates.',
                style: TextStyle(color: AppColors.muted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    required this.store,
    required this.onOpenProduct,
    required this.onShop,
    required this.onCategory,
    super.key,
  });

  final ShopStore store;
  final ValueChanged<Product> onOpenProduct;
  final VoidCallback onShop;
  final ValueChanged<String> onCategory;

  @override
  Widget build(BuildContext context) {
    final newArrivals = store.products.take(4).toList();
    final popular = store.products.skip(2).take(4).toList();
    debugPrint('HOME PRODUCTS: ${store.products.length}');
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 20),
      children: [
        const Row(
          children: [
            Text('Hello, beautiful', style: TextStyle(color: AppColors.muted)),
            SizedBox(width: 4),
            Icon(Icons.waving_hand, size: 16, color: AppColors.muted),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Find your everyday glow',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 15),
        Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: onShop,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.line),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  Icon(Icons.search, color: AppColors.muted, size: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Search beauty essentials',
                      style: TextStyle(color: AppColors.muted, fontSize: 13),
                    ),
                  ),
                  Icon(Icons.tune, color: AppColors.muted, size: 18),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 17),
        _PromoBanner(onShop: onShop),
        const SizedBox(height: 20),
        SectionTitle(
          'Categories',
          action: 'See all',
          onAction: () => onCategory('All'),
        ),
        const SizedBox(height: 9),

        SizedBox(
          height: 122,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              ...store.products
                  .map((product) => product.category)
                  .where((category) => category != 'Other')
                  .toSet()
                  .toList()
                  .map((category) {
                    final imageUrl = categoryImageUrl(category);

                    return SizedBox(
                      width: 82,
                      child: Padding(
                        padding: const EdgeInsets.only(right: 9),
                        child: CategoryCard(
                          name: category,
                          imageUrl: imageUrl,
                          onTap: () => onCategory(category),
                        ),
                      ),
                    );
                  }),
            ],
          ),
        ),

        const SizedBox(height: 17),
        SectionTitle('New Arrivals', action: 'View all', onAction: onShop),
        const SizedBox(height: 9),
        _ProductRow(
          products: newArrivals,
          store: store,
          onOpenProduct: onOpenProduct,
        ),
        const SizedBox(height: 18),
        SectionTitle('Popular Products', action: 'View all', onAction: onShop),
        const SizedBox(height: 9),
        _ProductRow(
          products: popular,
          store: store,
          onOpenProduct: onOpenProduct,
        ),
      ],
    );
  }
}

class _ProductRow extends StatelessWidget {
  const _ProductRow({
    required this.products,
    required this.store,
    required this.onOpenProduct,
  });

  final List<Product> products;
  final ShopStore store;
  final ValueChanged<Product> onOpenProduct;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 224,
    child: ListView.separated(
      scrollDirection: Axis.horizontal,
      itemCount: products.length,
      separatorBuilder: (_, _) => const SizedBox(width: 11),
      itemBuilder: (context, index) => SizedBox(
        width: 150,
        child: ProductCard(
          product: products[index],
          store: store,
          onTap: () => onOpenProduct(products[index]),
        ),
      ),
    ),
  );
}

class _PromoBanner extends StatelessWidget {
  const _PromoBanner({required this.onShop});

  final VoidCallback onShop;

  @override
  Widget build(BuildContext context) => Container(
    height: 144,
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(
      color: AppColors.blush,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Stack(
      fit: StackFit.expand,
      children: [
        Image.network(
          'https://images.unsplash.com/photo-1611930022073-b7a4ba5fcccd?auto=format&fit=crop&w=1000&q=85',
          fit: BoxFit.cover,
          alignment: Alignment.centerRight,
          errorBuilder: (_, _, _) => const ColoredBox(color: AppColors.blush),
        ),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xfff8e8e3), Color(0xd9f8e8e3), Color(0x00f8e8e3)],
              stops: [0, .58, 1],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(17, 17, 8, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'SOFT LOOKS,\nBOLD CONFIDENCE',
                style: TextStyle(
                  fontSize: 17,
                  height: 1.25,
                  color: AppColors.deepRose,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 5),
              const Text(
                'Up to 25% off selected beauty',
                style: TextStyle(fontSize: 11, color: AppColors.ink),
              ),
              const Spacer(),
              SizedBox(
                height: 32,
                child: FilledButton(
                  onPressed: onShop,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.rose,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                  ),
                  child: const Text('Shop Now', style: TextStyle(fontSize: 11)),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({
    required this.store,
    required this.onOpenProduct,
    super.key,
  });

  final ShopStore store;
  final ValueChanged<Product> onOpenProduct;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: store,
    builder: (context, _) {
      final products = store.products
          .where((product) => store.isFavorite(product))
          .toList();
      if (products.isEmpty) {
        return const Center(
          child: Padding(
            padding: EdgeInsets.all(30),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.favorite_border, size: 52, color: AppColors.rose),
                SizedBox(height: 12),
                Text(
                  'Your favorites live here',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 17),
                ),
                SizedBox(height: 6),
                Text(
                  'Tap the heart on any product to save it.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.muted),
                ),
              ],
            ),
          ),
        );
      }
      return GridView.builder(
        padding: const EdgeInsets.all(18),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 13,
          crossAxisSpacing: 13,
          childAspectRatio: .72,
        ),
        itemCount: products.length,
        itemBuilder: (context, index) => ProductCard(
          product: products[index],
          store: store,
          onTap: () => onOpenProduct(products[index]),
        ),
      );
    },
  );
}

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({required this.store, required this.onLogout, super.key});

  final ShopStore store;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
    children: [
      Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.palePink,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const CircleAvatar(
              radius: 31,
              backgroundColor: AppColors.blush,
              child: Icon(Icons.person, color: AppColors.rose, size: 32),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    store.customerName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    store.email,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 21),
      _ProfileAction(
        icon: Icons.receipt_long_outlined,
        label: 'My Orders',
        onTap: () => _open(context, MyOrdersScreen(store: store)),
      ),

      _ProfileAction(
        icon: Icons.location_on_outlined,
        label: 'Addresses',
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const AddressesScreen()),
          );
        },
      ),

      _ProfileAction(
        icon: Icons.favorite_border,
        label: 'Favorites',
        onTap: () => ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Select Favorites from the bottom navigation.'),
          ),
        ),
      ),
      _ProfileAction(
        icon: Icons.credit_card_outlined,
        label: 'Payment Methods',
        onTap: () => _showPaymentMethods(context),
      ),
      _ProfileAction(
        icon: Icons.settings_outlined,
        label: 'Settings',
        onTap: () => _showInfo(context, 'Settings'),
      ),
      _ProfileAction(
        icon: Icons.help_outline,
        label: 'Help & Support',
        onTap: () => _showInfo(context, 'Help & Support'),
      ),
      const Divider(height: 22, color: AppColors.line),
      _ProfileAction(
        icon: Icons.logout,
        label: 'Log Out',
        destructive: true,
        onTap: onLogout,
      ),
    ],
  );

  void _open(BuildContext context, Widget screen) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => screen));
  }

  void _showInfo(BuildContext context, String title) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: const Text(
          'This section will be available in a future update.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showPaymentMethods(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Payment methods',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 6),
              const Text(
                'Choose a payment method during checkout.',
                style: TextStyle(color: AppColors.muted),
              ),
              const SizedBox(height: 16),
              const ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  Icons.account_balance_wallet_outlined,
                  color: AppColors.deepRose,
                ),
                title: Text('PayMongo'),
                subtitle: Text('QRPH, GCash, Maya, debit or credit card'),
              ),
              const ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  Icons.local_shipping_outlined,
                  color: AppColors.deepRose,
                ),
                title: Text('Cash on Delivery (COD)'),
                subtitle: Text('Pay in cash when your order arrives'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileAction extends StatelessWidget {
  const _ProfileAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.destructive = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
    minLeadingWidth: 40,
    leading: Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: destructive ? AppColors.blush : AppColors.palePink,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(
        icon,
        size: 19,
        color: destructive ? AppColors.rose : AppColors.deepRose,
      ),
    ),
    title: Text(
      label,
      style: TextStyle(
        color: destructive ? AppColors.rose : AppColors.ink,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
    ),
    trailing: destructive
        ? null
        : const Icon(Icons.chevron_right, color: AppColors.muted, size: 20),
    onTap: onTap,
  );
}
