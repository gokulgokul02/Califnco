class Product {
  final String id;
  final String name;
  final String category;
  final String description;
  final double price;
  final double wholesalePrice;
  final int stock;
  final bool active;
  final String imageUrl;
  final double rating;
  final int reviewsCount;
  final Map<String, String> specifications;

  const Product({
    required this.id,
    required this.name,
    required this.category,
    required this.description,
    required this.price,
    required this.wholesalePrice,
    required this.stock,
    this.active = true,
    required this.imageUrl,
    this.rating = 4.8,
    this.reviewsCount = 42,
    this.specifications = const {},
  });

  factory Product.fromFirestore(String id, Map<String, dynamic> data) {
    return Product(
      id: id,
      name: data['name'] ?? 'Califnco Purifier',
      category: data['category'] ?? 'RO Purifier',
      description: data['description'] ?? '',
      price: (data['price'] as num?)?.toDouble() ?? 0.0,
      wholesalePrice: (data['wholesalePrice'] as num?)?.toDouble() ?? 0.0,
      stock: (data['stock'] as num?)?.toInt() ?? 50,
      active: data['active'] ?? true,
      imageUrl: data['imageUrl'] ?? 'https://images.unsplash.com/photo-1585672840545-be5e76a6d654?auto=format&fit=crop&w=600&q=80',
      rating: (data['rating'] as num?)?.toDouble() ?? 4.7,
      reviewsCount: (((data['reviewsCount'] ??
                  data['reviewCount'] ??
                  data['ratingCount'] ??
                  data['ratingsCount']) as num?)
              ?.toInt() ??
          28),
      specifications: (data['specifications'] as Map<String, dynamic>?)?.map(
            (k, v) => MapEntry(k, v.toString()),
          ) ??
          {},
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'category': category,
      'description': description,
      'price': price,
      'wholesalePrice': wholesalePrice,
      'stock': stock,
      'active': active,
      'imageUrl': imageUrl,
      'rating': rating,
      'reviewsCount': reviewsCount,
      'specifications': specifications,
    };
  }
}
