import 'package:flutter/material.dart';

import '../models/product.dart';
import '../services/shop_store.dart';
import '../theme/app_theme.dart';

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    required this.label,
    required this.onPressed,
    this.icon,
    this.outlined = false,
    this.fullWidth = true,
    this.isLoading = false,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool outlined;
  final bool fullWidth;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final child = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isLoading) ...[
          const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 9),
        ],
        if (icon != null) ...[Icon(icon, size: 19), const SizedBox(width: 9)],
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            softWrap: false,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
    final button = SizedBox(
      height: 50,
      child: outlined
          ? OutlinedButton(
              onPressed: onPressed,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.deepRose,
                side: const BorderSide(color: AppColors.line),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: child,
            )
          : FilledButton(
              onPressed: onPressed,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.rose,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: child,
            ),
    );
    return fullWidth ? SizedBox(width: double.infinity, child: button) : button;
  }
}

class AppTextField extends StatelessWidget {
  const AppTextField({
    required this.label,
    required this.controller,
    this.icon,
    this.obscureText = false,
    this.keyboardType,
    this.validator,
    this.suffix,
    super.key,
  });

  final String label;
  final TextEditingController controller;
  final IconData? icon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final Widget? suffix;

  @override
  Widget build(BuildContext context) => TextFormField(
    controller: controller,
    obscureText: obscureText,
    keyboardType: keyboardType,
    validator: validator,
    decoration: InputDecoration(
      hintText: label,
      prefixIcon: icon == null ? null : Icon(icon, color: AppColors.muted),
      suffixIcon: suffix,
    ),
  );
}

class ProductImage extends StatelessWidget {
  const ProductImage({
    required this.product,
    this.fit = BoxFit.cover,
    super.key,
  });

  final Product product;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final storedUrl = product.imageUrl.trim();
    final fallbackUrl = categoryImageUrl(product.category);
    final imageUrl = storedUrl.isEmpty ? fallbackUrl : storedUrl;

    return Container(
      color: Color(product.tint),
      child: Image.network(
        imageUrl,
        fit: fit,
        errorBuilder: (_, _, _) => storedUrl.isEmpty || storedUrl == fallbackUrl
            ? _productImagePlaceholder()
            : Image.network(
                fallbackUrl,
                fit: fit,
                errorBuilder: (_, _, _) => _productImagePlaceholder(),
              ),
        loadingBuilder: (context, child, progress) => progress == null
            ? child
            : const Center(
                child: SizedBox(
                  height: 22,
                  width: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.rose,
                  ),
                ),
              ),
      ),
    );
  }
}

Widget _productImagePlaceholder() => const Center(
  child: Icon(Icons.spa_outlined, size: 42, color: AppColors.rose),
);

class ProductCard extends StatelessWidget {
  const ProductCard({
    required this.product,
    required this.store,
    required this.onTap,
    super.key,
  });

  final Product product;
  final ShopStore store;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: store,
    builder: (context, _) => Material(
      color: Colors.white,
      clipBehavior: Clip.antiAlias,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.line),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ProductImage(product: product),
                    if (product.salePrice != null)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.rose,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'SALE',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: IconButton(
                        tooltip: store.isFavorite(product)
                            ? 'Remove from favorites'
                            : 'Add to favorites',
                        visualDensity: VisualDensity.compact,
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white.withValues(alpha: .92),
                        ),
                        onPressed: () => store.toggleFavorite(product),
                        icon: Icon(
                          store.isFavorite(product)
                              ? Icons.favorite
                              : Icons.favorite_border,
                          color: AppColors.rose,
                          size: 19,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 9),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.star, size: 13, color: Colors.amber),
                        const SizedBox(width: 3),
                        Text(
                          product.rating.toString(),
                          style: const TextStyle(
                            color: AppColors.muted,
                            fontSize: 11,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          money(product.currentPrice),
                          style: const TextStyle(
                            color: AppColors.deepRose,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 7),
                    SizedBox(
                      height: 30,
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: product.stock <= 0
                            ? null
                            : () => store.addToCart(product),
                        icon: const Icon(Icons.shopping_bag_outlined, size: 14),
                        label: Text(
                          product.stock <= 0 ? 'Sold out' : 'Add to Bag',
                          style: const TextStyle(fontSize: 10),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.deepRose,
                          side: const BorderSide(color: AppColors.line),
                          padding: EdgeInsets.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class CategoryCard extends StatelessWidget {
  const CategoryCard({
    required this.name,
    required this.imageUrl,
    required this.onTap,
    super.key,
  });

  final String name;
  final String imageUrl;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(16),
    child: Column(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: SizedBox(
              width: double.infinity,
              child: Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Container(
                  color: AppColors.blush,
                  child: const Icon(Icons.spa, color: AppColors.rose),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 7),
        Text(
          name,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        ),
      ],
    ),
  );
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.title, {this.action, this.onAction, super.key});

  final String title;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(title, style: Theme.of(context).textTheme.titleLarge),
      if (action != null)
        TextButton(
          onPressed: onAction,
          child: Text(
            action!,
            style: const TextStyle(color: AppColors.rose, fontSize: 12),
          ),
        ),
    ],
  );
}

String money(double amount) => '₱${amount.toStringAsFixed(0)}';
