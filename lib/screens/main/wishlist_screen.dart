import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/product_model.dart';
import '../../admin/product_service.dart';
import '../../services/wishlist_service.dart';
import '../../services/cart_service.dart';
import '../../constants/app_colors.dart';
import 'product_details_screen.dart';

class WishlistScreen extends StatefulWidget {
  const WishlistScreen({super.key});

  @override
  State<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends State<WishlistScreen> {
  final Map<String, ValueNotifier<bool>> _favoriteNotifiers = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {});
      }
    });
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    for (var notifier in _favoriteNotifiers.values) {
      notifier.dispose();
    }
    _favoriteNotifiers.clear();
    super.dispose();
  }

  Future<List<ProductModel>> _loadWishlistProducts() async {
    try {
      final productIds = await WishlistService.getWishlistProductIds();
      if (productIds.isEmpty) return [];

      final allProducts = await ProductService.getProducts();
      final wishlistProducts = allProducts
          .where((product) => product.id != null && productIds.contains(product.id))
          .toList();

      wishlistProducts.sort((a, b) {
        final indexA = productIds.indexOf(a.id!);
        final indexB = productIds.indexOf(b.id!);
        return indexA.compareTo(indexB);
      });

      return wishlistProducts;
    } catch (e) {
      debugPrint('Error loading wishlist products: $e');
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          'My Wishlist',
          style: GoogleFonts.poppins(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                setState(() {});
              },
              child: FutureBuilder<List<ProductModel>>(
                future: _loadWishlistProducts(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          Text(
                            'Error loading wishlist',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  final products = snapshot.data ?? [];

                  if (products.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.favorite_border, size: 80, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          Text(
                            'Your wishlist is empty',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[700],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Tap the heart icon to add products',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: products.length,
                    itemBuilder: (context, index) {
                      final product = products[index];
                      final productId = product.id ?? '';
                      
                      if (!_favoriteNotifiers.containsKey(productId)) {
                        _favoriteNotifiers[productId] = ValueNotifier<bool>(true);
                      }
                      final favoriteNotifier = _favoriteNotifiers[productId]!;

                      return _buildWishlistItem(product, favoriteNotifier);
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWishlistItem(ProductModel product, ValueNotifier<bool> favoriteNotifier) {
    final hasDiscount = product.discount > 0 && product.originalPrice > product.price;
    final isOutOfStock = product.stock == 0;

    return InkWell(
      onTap: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailsScreen(product: product),
          ),
        );
        if (result == true && mounted) {
          setState(() {});
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            
            Stack(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: product.imageUrl != null && product.imageUrl!.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            product.imageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Icon(
                                Icons.image_not_supported_rounded,
                                size: 40,
                                color: Colors.grey[400],
                              );
                            },
                          ),
                        )
                      : Icon(
                          Icons.image_not_supported_rounded,
                          size: 40,
                          color: Colors.grey[400],
                        ),
                ),
                
                if (hasDiscount)
                  Positioned(
                    top: 4,
                    left: 4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.5),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 2,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Text(
                        '${product.discount.toStringAsFixed(0)}% OFF',
                        style: GoogleFonts.poppins(
                          fontSize: 7,
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    product.description,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  
                  Row(
                    children: [
                      if (hasDiscount)
                        Text(
                          product.formattedOriginalPrice,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.grey[400],
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                      if (hasDiscount) const SizedBox(width: 6),
                      Text(
                        product.formattedPrice,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  
                  Row(
                    children: [
                      ...List.generate(5, (index) {
                        return Icon(
                          index < 4 ? Icons.star : Icons.star_border,
                          color: Colors.amber,
                          size: 14,
                        );
                      }),
                      const SizedBox(width: 4),
                      Text(
                        '4.5',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            
            Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                
                ValueListenableBuilder<bool>(
                  valueListenable: favoriteNotifier,
                  builder: (context, isFavorite, child) {
                    return GestureDetector(
                      onTap: () async {
                        final productId = product.id ?? '';
                        if (productId.isNotEmpty) {
                          if (isFavorite) {
                            await WishlistService.removeFromWishlist(productId);
                          } else {
                            await WishlistService.addToWishlist(productId);
                          }
                          favoriteNotifier.value = !isFavorite;
                          if (!isFavorite && mounted) {
                            setState(() {});
                          }
                        }
                      },
                      child: Icon(
                        isFavorite ? Icons.favorite : Icons.favorite_border,
                        color: isFavorite ? Colors.red : Colors.grey[400],
                        size: 24,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20),
                
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isOutOfStock ? Colors.grey[300] : AppColors.amber,
                    shape: BoxShape.circle,
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: isOutOfStock || product.id == null
                          ? null
                          : () async {
                              await CartService.addToCart(product.id!);
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('${product.name} added to cart'),
                                    duration: const Duration(seconds: 1),
                                    backgroundColor: AppColors.success,
                                  ),
                                );
                              }
                            },
                      borderRadius: BorderRadius.circular(20),
                      child: Center(
                        child: Icon(
                          Icons.add,
                          color: isOutOfStock ? Colors.grey[600] : Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
