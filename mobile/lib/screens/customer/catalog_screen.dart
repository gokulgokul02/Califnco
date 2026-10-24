import 'package:flutter/material.dart';
import '../../widgets/safe_product_image.dart';
import '../../models/product.dart';
import '../../services/cart_service.dart';
import '../../services/firebase_service.dart';
import '../common/image_zoom_dialog.dart';
import 'cart_screen.dart';
import 'product_detail_screen.dart';
import 'profile_screen.dart';

class CatalogScreen extends StatefulWidget {
  final bool isDealerMode;

  const CatalogScreen({super.key, this.isDealerMode = false});

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  String _searchQuery = '';
  String _selectedCategory = 'All';
  String _sortBy = 'Recommended';

  final List<String> _categories = [
    'All',
    'RO Purifier',
    'UV Purifier',
    'UF Purifier',
    'Water Dispenser',
    'Booster Pump',
    'Sediment Filter',
    'Carbon Filter',
    'RO Membrane',
    'Spare Part',
  ];

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xff087f8c);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.isDealerMode ? 'Califnco Wholesale' : 'Califnco',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            Text(
              widget.isDealerMode ? 'Dealer Bulk Tier Pricing' : 'Purifiers, Spares & Accessories',
              style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
            ),
          ],
        ),
        actions: [
          ListenableBuilder(
            listenable: CartService.instance,
            builder: (context, _) {
              final count = CartService.instance.itemCount;
              return Badge(
                isLabelVisible: count > 0,
                label: Text('$count'),
                child: IconButton(
                  icon: const Icon(Icons.shopping_cart_outlined),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const CartScreen()),
                    );
                  },
                ),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Search & Sort Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search purifiers, filters, pumps, spares...',
                      prefixIcon: const Icon(Icons.search, size: 20),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () => setState(() => _searchQuery = ''),
                            )
                          : null,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onChanged: (v) => setState(() => _searchQuery = v),
                  ),
                ),
                const SizedBox(width: 8),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.sort_rounded),
                  tooltip: 'Sort by',
                  initialValue: _sortBy,
                  onSelected: (val) => setState(() => _sortBy = val),
                  itemBuilder: (ctx) => [
                    'Recommended',
                    'Price: Low to High',
                    'Price: High to Low',
                    'Customer Rating',
                  ].map((s) => PopupMenuItem(value: s, child: Text(s))).toList(),
                ),
              ],
            ),
          ),

          // Categories Horizontal Filter (Streamed live from Firestore categories collection)
          SizedBox(
            height: 44,
            child: StreamBuilder<List<String>>(
              stream: FirebaseService.instance.streamCategories(),
              builder: (context, catSnap) {
                final displayCategories = (catSnap.data != null && catSnap.data!.isNotEmpty)
                    ? ['All', ...catSnap.data!]
                    : _categories;

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  scrollDirection: Axis.horizontal,
                  itemCount: displayCategories.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final cat = displayCategories[index];
                    final isSelected = _selectedCategory == cat;
                    return ChoiceChip(
                      label: Text(cat),
                      selected: isSelected,
                      selectedColor: primary.withValues(alpha: 0.18),
                      labelStyle: TextStyle(
                        color: isSelected ? primary : theme.colorScheme.onSurface,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        fontSize: 12,
                      ),
                      onSelected: (_) => setState(() => _selectedCategory = cat),
                    );
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 6),

          // Refer & Earn Banner (Retail Customer)
          if (!widget.isDealerMode)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 2, 16, 6),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ProfileScreen()),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xff087f8c), Color(0xff024950)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xff087f8c).withValues(alpha: 0.25),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.card_giftcard_rounded, color: Colors.white, size: 18),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Refer & Earn ₹150 Credits 🎁',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            Text(
                              'Share your code • Friends get ₹200 OFF',
                              style: TextStyle(color: Colors.white70, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'View Code',
                          style: TextStyle(color: Color(0xff024950), fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Stream / Catalog Grid
          Expanded(
            child: StreamBuilder<List<Product>>(
              stream: FirebaseService.instance.streamProducts(),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting && !snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                var list = snap.data ?? [];

                // Filter by Category
                if (_selectedCategory != 'All') {
                  list = list.where((p) => p.category == _selectedCategory).toList();
                }

                // Filter by Search Query
                if (_searchQuery.trim().isNotEmpty) {
                  final q = _searchQuery.toLowerCase().trim();
                  list = list.where((p) =>
                      p.name.toLowerCase().contains(q) ||
                      p.category.toLowerCase().contains(q) ||
                      p.description.toLowerCase().contains(q)).toList();
                }

                // Sort
                if (_sortBy == 'Price: Low to High') {
                  list.sort((a, b) => a.price.compareTo(b.price));
                } else if (_sortBy == 'Price: High to Low') {
                  list.sort((a, b) => b.price.compareTo(a.price));
                } else if (_sortBy == 'Customer Rating') {
                  list.sort((a, b) => b.rating.compareTo(a.rating));
                }

                if (list.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.search_off_rounded, size: 56, color: Colors.grey),
                          const SizedBox(height: 12),
                          Text('No purifiers found matching "$_searchQuery"',
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: () => setState(() {
                              _searchQuery = '';
                              _selectedCategory = 'All';
                            }),
                            child: const Text('Reset filters'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return LayoutBuilder(
                  builder: (context, constraints) {
                    final crossCount = constraints.maxWidth > 800
                        ? 4
                        : (constraints.maxWidth > 520 ? 3 : 2);

                    return GridView.builder(
                      padding: const EdgeInsets.all(12),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossCount,
                        childAspectRatio: 0.60,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                      ),
                      itemCount: list.length,
                      itemBuilder: (context, index) {
                        final product = list[index];
                        return _buildProductCard(context, product);
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(BuildContext context, Product product) {
    const primary = Color(0xff087f8c);
    final isDealer = widget.isDealerMode || CartService.instance.isDealer;

    return Card(
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ProductDetailScreen(product: product, isDealer: isDealer),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image Stack with Zoom trigger and Category Tag
            Expanded(
              flex: 11,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  SafeProductImage(
                    imageUrl: product.imageUrl,
                    fit: BoxFit.cover,
                  ),
                  // Category Badge
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.65),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        product.category,
                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  // Quick Zoom Button
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Material(
                      color: Colors.black45,
                      shape: const CircleBorder(),
                      child: IconButton(
                        iconSize: 16,
                        padding: const EdgeInsets.all(4),
                        constraints: const BoxConstraints(),
                        tooltip: 'Pinch & Zoom',
                        icon: const Icon(Icons.zoom_in, color: Colors.white),
                        onPressed: () {
                          ImageZoomDialog.show(context, imageUrl: product.imageUrl, title: product.name);
                        },
                      ),
                    ),
                  ),
                  // Wholesale Save % Tag
                  if (isDealer)
                    Positioned(
                      bottom: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade800,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Wholesale ${(100 - (product.wholesalePrice / product.price * 100)).round()}% OFF',
                          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Details Section
            Expanded(
              flex: 9,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 5, 8, 5),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Name + rating
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12, height: 1.2),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            const Icon(Icons.star, size: 12, color: Colors.amber),
                            const SizedBox(width: 2),
                            Text(
                              product.rating.toStringAsFixed(1),
                              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(width: 2),
                            Text(
                              '(${product.reviewsCount > 0 ? product.reviewsCount : 28})',
                              style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ],
                    ),

                    // Price + Cart button
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              isDealer
                                  ? '₹${product.wholesalePrice.toStringAsFixed(0)}'
                                  : '₹${product.price.toStringAsFixed(0)}',
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: primary),
                            ),
                            if (isDealer) ...[
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  '₹${product.price.toStringAsFixed(0)}',
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    decoration: TextDecoration.lineThrough,
                                    decorationColor: Colors.grey,
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 5),
                        ListenableBuilder(
                          listenable: CartService.instance,
                          builder: (context, _) {
                            final inCart = CartService.instance.getQuantity(product.id);
                            if (inCart == 0) {
                              return SizedBox(
                                width: double.infinity,
                                height: 28,
                                child: OutlinedButton(
                                  style: OutlinedButton.styleFrom(
                                    padding: EdgeInsets.zero,
                                    side: const BorderSide(color: primary),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
                                  ),
                                  onPressed: () {
                                    CartService.instance.addToCart(product);
                                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Added "${product.name}" to cart'),
                                        duration: const Duration(seconds: 1),
                                      ),
                                    );
                                  },
                                  child: const Text('Add to Cart', style: TextStyle(fontSize: 11, color: primary)),
                                ),
                              );
                            }

                            return SizedBox(
                              height: 28,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  color: primary.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(7),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    InkWell(
                                      onTap: () => CartService.instance.updateQuantity(product.id, inCart - 1),
                                      child: const SizedBox(
                                        width: 30, height: 28,
                                        child: Icon(Icons.remove, size: 14, color: primary),
                                      ),
                                    ),
                                    Text('$inCart', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                    InkWell(
                                      onTap: () => CartService.instance.updateQuantity(product.id, inCart + 1),
                                      child: const SizedBox(
                                        width: 30, height: 28,
                                        child: Icon(Icons.add, size: 14, color: primary),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

          ],
        ),
      ),
    );
  }
}
