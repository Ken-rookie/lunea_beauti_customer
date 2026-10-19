class Product {
  const Product({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    required this.imageUrl,
    required this.tint,
    this.salePrice,
    this.rating = 4.8,
    this.stock = 12,
    this.description =
        'A lovely everyday essential made to bring out your natural glow. '
        'Smooth, comfortable and easy to wear from morning to night.',
  });

  final String id;
  final String name;
  final String category;
  final double price;
  final String imageUrl;
  final int tint;
  final double? salePrice;
  final double rating;
  final int stock;
  final String description;

  double get currentPrice => salePrice ?? price;
}

const sampleProducts = <Product>[
  Product(
    id: 'lipstick',
    name: 'Velvet Lip Cream',
    category: 'Lips',
    price: 499,
    salePrice: 399,
    rating: 4.9,
    imageUrl:
        'https://images.unsplash.com/photo-1586495777744-4413f21062fa?auto=format&fit=crop&w=600&q=85',
    tint: 0xfff3d9d8,
    description:
        'A weightless velvet lip cream with rich, buildable color and a soft matte finish.',
  ),
  Product(
    id: 'glow-blush',
    name: 'Glow Liquid Blush',
    category: 'Cheeks',
    price: 599,
    rating: 4.8,
    imageUrl:
        'https://images.unsplash.com/photo-1599733589046-10c005739ef7?auto=format&fit=crop&w=600&q=85',
    tint: 0xfff6dedd,
    description:
        'A blendable liquid blush that melts into skin for a fresh, dewy flush.',
  ),
  Product(
    id: 'eyeshadow',
    name: 'Rose Edit Palette',
    category: 'Eyes',
    price: 899,
    rating: 4.9,
    imageUrl:
        'https://images.unsplash.com/photo-1512496015851-a90fb38ba796?auto=format&fit=crop&w=600&q=85',
    tint: 0xffeee3df,
    description:
        'A curated edit of soft rose neutrals in silky matte and shimmer finishes.',
  ),
  Product(
    id: 'foundation',
    name: 'Silk Veil Foundation',
    category: 'Face',
    price: 799,
    salePrice: 699,
    rating: 4.7,
    imageUrl:
        'https://images.unsplash.com/photo-1522335789203-aabd1fc54bc9?auto=format&fit=crop&w=600&q=85',
    tint: 0xfff1e2d5,
  ),
  Product(
    id: 'mascara',
    name: 'Lash Muse Mascara',
    category: 'Eyes',
    price: 549,
    rating: 4.8,
    imageUrl:
        'https://images.unsplash.com/photo-1631214540242-6c6b2b6f1f75?auto=format&fit=crop&w=600&q=85',
    tint: 0xffe9dfdc,
  ),
  Product(
    id: 'highlighter',
    name: 'Petal Glow Highlighter',
    category: 'Face',
    price: 649,
    rating: 4.6,
    imageUrl:
        'https://images.unsplash.com/photo-1601049541289-9b1b7bbbfe19?auto=format&fit=crop&w=600&q=85',
    tint: 0xfff5e4dc,
  ),
  Product(
    id: 'brow-pencil',
    name: 'Soft Shape Brow Pencil',
    category: 'Eyes',
    price: 349,
    rating: 4.7,
    imageUrl:
        'https://images.unsplash.com/photo-1596462502278-27bfdc403348?auto=format&fit=crop&w=600&q=85',
    tint: 0xffeee6df,
  ),
  Product(
    id: 'cheek-tint',
    name: 'Petal Cheek Tint',
    category: 'Cheeks',
    price: 459,
    rating: 4.8,
    imageUrl:
        'https://images.unsplash.com/photo-1596704017254-9b121068fb31?auto=format&fit=crop&w=600&q=85',
    tint: 0xfff5dedd,
  ),
];

const productCategories = <String, String>{
  'Lips':
      'https://images.unsplash.com/photo-1586495777744-4413f21062fa?auto=format&fit=crop&w=400&q=80',
  'Face':
      'https://images.unsplash.com/photo-1522335789203-aabd1fc54bc9?auto=format&fit=crop&w=400&q=80',
  'Eyes':
      'https://images.unsplash.com/photo-1512496015851-a90fb38ba796?auto=format&fit=crop&w=400&q=80',
  'Cheeks':
      'https://images.unsplash.com/photo-1599733589046-10c005739ef7?auto=format&fit=crop&w=400&q=80',
};

String categoryImageUrl(String category) {
  final normalized = category.toLowerCase();

  if (normalized.contains('face')) return productCategories['Face']!;
  if (normalized.contains('eye')) return productCategories['Eyes']!;
  if (normalized.contains('lip')) return productCategories['Lips']!;
  if (normalized.contains('cheek')) return productCategories['Cheeks']!;

  return productCategories['Face']!;
}
