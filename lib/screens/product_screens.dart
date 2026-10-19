import 'package:flutter/material.dart';

import '../models/product.dart';
import '../services/shop_store.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';

class ProductListingScreen extends StatefulWidget {
  const ProductListingScreen({
    required this.store,
    required this.onOpenProduct,
    this.initialCategory,
    super.key,
  });

  final ShopStore store;
  final ValueChanged<Product> onOpenProduct;
  final String? initialCategory;

  @override
  State<ProductListingScreen> createState() => _ProductListingScreenState();
}

class _ProductListingScreenState extends State<ProductListingScreen> {
  final _search = TextEditingController();
  String category = 'All';
  String _sortBy = 'Featured';

  List<Product> _products = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    category = widget.initialCategory ?? 'All';
    _products = widget.store.products;
    _isLoading = widget.store.isRefreshingProducts && _products.isEmpty;
    widget.store.addListener(_handleStoreChanged);
  }

  void _handleStoreChanged() {
    if (!mounted) return;
    setState(() {
      _products = widget.store.products;
      _isLoading = widget.store.isRefreshingProducts && _products.isEmpty;
    });
  }

  @override
  void didUpdateWidget(covariant ProductListingScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialCategory != widget.initialCategory &&
        widget.initialCategory != null) {
      setState(() => category = widget.initialCategory!);
    }
  }

  @override
  void dispose() {
    widget.store.removeListener(_handleStoreChanged);
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final visible = _products.where((product) {
      final matchesCategory = category == 'All' || product.category == category;
      final matchesSearch = product.name.toLowerCase().contains(
        _search.text.toLowerCase(),
      );
      return matchesCategory && matchesSearch;
    }).toList();
    switch (_sortBy) {
      case 'Price: low to high':
        visible.sort((a, b) => a.currentPrice.compareTo(b.currentPrice));
      case 'Price: high to low':
        visible.sort((a, b) => b.currentPrice.compareTo(a.currentPrice));
    }
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 10),
          child: TextField(
            controller: _search,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'Search beauty essentials',
              prefixIcon: Icon(Icons.search),
              suffixIcon: _search.text.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Clear search',
                      onPressed: () {
                        _search.clear();
                        setState(() {});
                      },
                      icon: const Icon(Icons.close),
                    ),
            ),
          ),
        ),
        SizedBox(
          height: 48,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            scrollDirection: Axis.horizontal,
            children:
                [
                  'All',
                  ...widget.store.products
                      .map((product) => product.category)
                      .where((name) => name != 'Other')
                      .toSet()
                      .toList()
                    ..sort(),
                ].map((name) {
                  final selected = category == name;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(name),
                      selected: selected,
                      onSelected: (_) => setState(() => category = name),
                      selectedColor: AppColors.rose,
                      labelStyle: TextStyle(
                        color: selected ? Colors.white : AppColors.ink,
                        fontWeight: FontWeight.w500,
                      ),
                      side: BorderSide(
                        color: selected ? AppColors.rose : AppColors.line,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      showCheckmark: false,
                    ),
                  );
                }).toList(),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
          child: Row(
            children: [
              Text(
                '${visible.length} products',
                style: const TextStyle(color: AppColors.muted),
              ),
              const Spacer(),
              IconButton(
                tooltip: 'Refresh products',
                onPressed: widget.store.isRefreshingProducts
                    ? null
                    : widget.store.refreshProducts,
                icon: const Icon(Icons.refresh_rounded),
              ),
              PopupMenuButton<String>(
                initialValue: _sortBy,
                onSelected: (value) => setState(() => _sortBy = value),
                itemBuilder: (context) => const [
                  PopupMenuItem(value: 'Featured', child: Text('Featured')),
                  PopupMenuItem(
                    value: 'Price: low to high',
                    child: Text('Price: low to high'),
                  ),
                  PopupMenuItem(
                    value: 'Price: high to low',
                    child: Text('Price: high to low'),
                  ),
                ],
                child: Row(
                  children: [
                    const Icon(Icons.sort, size: 18, color: AppColors.muted),
                    const SizedBox(width: 5),
                    Text(
                      _sortBy,
                      style: const TextStyle(color: AppColors.muted),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : visible.isEmpty
              ? const Center(
                  child: Text('No products found. Try another search.'),
                )
              : GridView.builder(
                  padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 13,
                    crossAxisSpacing: 13,
                    childAspectRatio: .72,
                  ),
                  itemCount: visible.length,
                  itemBuilder: (context, index) => ProductCard(
                    product: visible[index],
                    store: widget.store,
                    onTap: () => widget.onOpenProduct(visible[index]),
                  ),
                ),
        ),
      ],
    );
  }
}

class ProductDetailsScreen extends StatefulWidget {
  const ProductDetailsScreen({
    required this.product,
    required this.store,
    required this.onViewCart,
    required this.onCheckout,
    super.key,
  });

  final Product product;
  final ShopStore store;
  final VoidCallback onViewCart;
  final VoidCallback onCheckout;

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  int quantity = 1;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Product Details'),
      actions: [
        AnimatedBuilder(
          animation: widget.store,
          builder: (context, _) => IconButton(
            onPressed: () => widget.store.toggleFavorite(widget.product),
            icon: Icon(
              widget.store.isFavorite(widget.product)
                  ? Icons.favorite
                  : Icons.favorite_border,
              color: AppColors.rose,
            ),
          ),
        ),
        IconButton(
          onPressed: widget.onViewCart,
          icon: const Icon(Icons.shopping_bag_outlined),
        ),
      ],
    ),
    body: ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        AspectRatio(
          aspectRatio: 1.08,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: ProductImage(product: widget.product),
          ),
        ),
        const SizedBox(height: 18),
        Text(
          widget.product.category.toUpperCase(),
          style: const TextStyle(
            color: AppColors.rose,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          widget.product.name,
          style: Theme.of(
            context,
          ).textTheme.headlineMedium?.copyWith(fontSize: 24),
        ),
        const SizedBox(height: 10),
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 10,
          runSpacing: 8,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.star, color: Colors.amber, size: 17),
                const SizedBox(width: 4),
                Text('${widget.product.rating}  ·  128 reviews'),
              ],
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.product.salePrice != null)
                  Padding(
                    padding: const EdgeInsets.only(right: 7),
                    child: Text(
                      money(widget.product.price),
                      style: const TextStyle(
                        color: AppColors.muted,
                        decoration: TextDecoration.lineThrough,
                        fontSize: 12,
                      ),
                    ),
                  ),
                Text(
                  money(widget.product.currentPrice),
                  style: const TextStyle(
                    color: AppColors.deepRose,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 22),
        const Text(
          'Product details',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
        const SizedBox(height: 7),
        Text(
          widget.product.description,
          style: const TextStyle(color: AppColors.muted, height: 1.5),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Icon(
              widget.product.stock > 0
                  ? Icons.check_circle_outline
                  : Icons.remove_circle_outline,
              size: 17,
              color: widget.product.stock > 0
                  ? AppColors.green
                  : AppColors.rose,
            ),
            const SizedBox(width: 7),
            Flexible(
              child: Text(
                widget.product.stock > 0
                    ? 'In stock · ${widget.product.stock} available'
                    : 'Currently out of stock',
                style: TextStyle(
                  color: widget.product.stock > 0
                      ? AppColors.green
                      : AppColors.rose,
                ),
              ),
            ),
          ],
        ),
      ],
    ),
    bottomNavigationBar: Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.line)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Text(
                    'Quantity',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(width: 10),
                  _QuantityControl(
                    quantity: quantity,
                    onChanged: (value) => setState(() => quantity = value),
                  ),
                  const Spacer(),
                  Text(
                    money(widget.product.currentPrice * quantity),
                    style: const TextStyle(
                      color: AppColors.deepRose,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: PrimaryButton(
                      label: 'Add to Bag',
                      icon: Icons.shopping_bag_outlined,
                      onPressed: widget.product.stock <= 0
                          ? null
                          : () {
                              widget.store.addToCart(
                                widget.product,
                                quantity: quantity,
                              );
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    '${widget.product.name} added to your bag',
                                  ),
                                ),
                              );
                            },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: PrimaryButton(
                      label: 'Buy Now',
                      outlined: true,
                      onPressed: widget.product.stock <= 0
                          ? null
                          : () {
                              widget.store.addToCart(
                                widget.product,
                                quantity: quantity,
                              );
                              widget.onCheckout();
                            },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _QuantityControl extends StatelessWidget {
  const _QuantityControl({required this.quantity, required this.onChanged});

  final int quantity;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: AppColors.palePink,
      borderRadius: BorderRadius.circular(11),
    ),
    child: Row(
      children: [
        IconButton(
          visualDensity: VisualDensity.compact,
          onPressed: quantity > 1 ? () => onChanged(quantity - 1) : null,
          icon: const Icon(Icons.remove, size: 18),
        ),
        Text('$quantity', style: const TextStyle(fontWeight: FontWeight.w600)),
        IconButton(
          visualDensity: VisualDensity.compact,
          onPressed: () => onChanged(quantity + 1),
          icon: const Icon(Icons.add, size: 18),
        ),
      ],
    ),
  );
}
