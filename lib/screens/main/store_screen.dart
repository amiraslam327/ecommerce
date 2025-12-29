import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/product_model.dart';
import '../../admin/product_service.dart';
import '../../constants/app_colors.dart';
import '../../services/wishlist_service.dart';
import '../../services/cart_service.dart';
import 'product_details_screen.dart';

class StoreScreen extends StatefulWidget {
  const StoreScreen({super.key});

  @override
  State<StoreScreen> createState() => _StoreScreenState();
}

class _StoreScreenState extends State<StoreScreen> {
  final Map<String, ValueNotifier<bool>> _favoriteNotifiers = {};
  bool _isListView = false; 
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    for (var notifier in _favoriteNotifiers.values) {
      notifier.dispose();
    }
    _favoriteNotifiers.clear();
    super.dispose();
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
          'Store',
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
          
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const SizedBox(width: 16),
                        Icon(Icons.search, color: Colors.grey[400], size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            decoration: InputDecoration(
                              hintText: 'Search',
                              hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                              border: InputBorder.none,
                            ),
                            onChanged: (value) {
                              setState(() {
                                _searchQuery = value.toLowerCase().trim();
                              });
                            },
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.mic, color: Colors.grey[400], size: 20),
                          onPressed: () {},
                        ),
                        const SizedBox(width: 8),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    icon: Icon(
                      _isListView ? Icons.grid_view : Icons.view_list,
                      color: Colors.white,
                      size: 22,
                    ),
                    onPressed: () {
                      setState(() {
                        _isListView = !_isListView;
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
          
          Expanded(
            child: StreamBuilder<List<ProductModel>>(
              stream: ProductService.getProductsStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error loading products',
                      style: GoogleFonts.poppins(
                        color: Colors.grey[600],
                        fontSize: 16,
                      ),
                    ),
                  );
                }

                final products = snapshot.data ?? [];
                
                var activeProducts = products.where((p) => p.isActive).toList();
                
                
                if (_searchQuery.isNotEmpty) {
                  activeProducts = activeProducts.where((p) {
                    return p.name.toLowerCase().contains(_searchQuery);
                  }).toList();
                }

                if (activeProducts.isEmpty) {
                  return Center(
                    child: Text(
                      'No products available',
                      style: GoogleFonts.poppins(
                        color: Colors.grey[600],
                        fontSize: 16,
                      ),
                    ),
                  );
                }

                if (_isListView) {
                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: activeProducts.length,
                    itemBuilder: (context, index) {
                      final product = activeProducts[index];
                      final productId = product.id ?? '';
                      
                      
                      if (!_favoriteNotifiers.containsKey(productId)) {
                        _favoriteNotifiers[productId] = ValueNotifier<bool>(false);
                        
                        WishlistService.isInWishlist(productId).then((isInWishlist) {
                          if (_favoriteNotifiers.containsKey(productId)) {
                            _favoriteNotifiers[productId]!.value = isInWishlist;
                          }
                        });
                      }
                      
                      return GestureDetector(
                        onTap: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ProductDetailsScreen(
                                product: product,
                              ),
                            ),
                          );
                          
                          if (result == true && mounted) {
                            final isInWishlist = await WishlistService.isInWishlist(productId);
                            if (_favoriteNotifiers.containsKey(productId)) {
                              _favoriteNotifiers[productId]!.value = isInWishlist;
                            }
                          }
                        },
                        child: _buildProductListItem(product),
                      );
                    },
                  );
                } else {
                  return GridView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 0.65,
                    ),
                    itemCount: activeProducts.length,
                    itemBuilder: (context, index) {
                      final product = activeProducts[index];
                      final productId = product.id ?? '';
                      
                      
                      if (!_favoriteNotifiers.containsKey(productId)) {
                        _favoriteNotifiers[productId] = ValueNotifier<bool>(false);
                        
                        WishlistService.isInWishlist(productId).then((isInWishlist) {
                          if (_favoriteNotifiers.containsKey(productId)) {
                            _favoriteNotifiers[productId]!.value = isInWishlist;
                          }
                        });
                      }
                      
                      return GestureDetector(
                        onTap: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ProductDetailsScreen(
                                product: product,
                              ),
                            ),
                          );
                          
                          if (result == true && mounted) {
                            final isInWishlist = await WishlistService.isInWishlist(productId);
                            if (_favoriteNotifiers.containsKey(productId)) {
                              _favoriteNotifiers[productId]!.value = isInWishlist;
                            }
                          }
                        },
                        child: _buildProductCard(product),
                      );
                    },
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(ProductModel product) {
    final productId = product.id ?? '';
    final favoriteNotifier = _favoriteNotifiers[productId] ?? ValueNotifier<bool>(false);
    final hasDiscount = product.discount > 0 && product.originalPrice > product.price;

    return ValueListenableBuilder<bool>(
      valueListenable: favoriteNotifier,
      builder: (context, isFavorite, child) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              
              Expanded(
                flex: 3,
                child: Stack(
                  children: [
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(16),
                          topRight: Radius.circular(16),
                        ),
                      ),
                      child: product.imageUrl != null && product.imageUrl!.isNotEmpty
                          ? ClipRRect(
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(16),
                                topRight: Radius.circular(16),
                              ),
                              child: Image.network(
                                product.imageUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Center(
                                    child: Icon(
                                      Icons.sports_esports,
                                      size: 60,
                                      color: Colors.grey[400],
                                    ),
                                  );
                                },
                              ),
                            )
                          : Center(
                              child: Icon(
                                Icons.sports_esports,
                                size: 60,
                                color: Colors.grey[400],
                              ),
                            ),
                    ),
                    
                    if (hasDiscount)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: AppColors.primary.withValues(alpha: 0.5),
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Text(
                            '${product.discount.toStringAsFixed(0)}% OFF',
                            style: GoogleFonts.poppins(
                              fontSize: 9,
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    
                    Positioned(
                      top: 8,
                      right: 8,
                      child: GestureDetector(
                        onTap: () async {
                          final currentValue = favoriteNotifier.value;
                          favoriteNotifier.value = !currentValue;
                          
                          
                          if (!currentValue) {
                            await WishlistService.addToWishlist(productId);
                          } else {
                            await WishlistService.removeFromWishlist(productId);
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Icon(
                            isFavorite ? Icons.favorite : Icons.favorite_border,
                            color: isFavorite ? Colors.red : Colors.grey[400],
                            size: 18,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              Expanded(
                flex: 4,
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product.name,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
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
                              fontSize: 11,
                              color: Colors.grey[600],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              if (product.discount > 0 && product.originalPrice > product.price)
                                Text(
                                  product.formattedOriginalPrice,
                                  style: GoogleFonts.poppins(
                                    fontSize: 10,
                                    color: Colors.grey[400],
                                    decoration: TextDecoration.lineThrough,
                                  ),
                                ),
                              if (product.discount > 0 && product.originalPrice > product.price)
                                const SizedBox(width: 6),
                              Text(
                                product.formattedPrice,
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(Icons.star, color: Colors.amber, size: 14),
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
                      
                      SizedBox(
                        width: double.infinity,
                        height: 32,
                        child: StreamBuilder<Map<String, int>>(
                          stream: CartService.getCartStream(),
                          builder: (context, snapshot) {
                            final cartItems = snapshot.data ?? {};
                            final isInCart = product.id != null && cartItems.containsKey(product.id);
                            final quantity = product.id != null ? (cartItems[product.id] ?? 0) : 0;
                            
                            if (product.stock <= 0) {
                              return Material(
                                color: Colors.grey[300],
                                borderRadius: BorderRadius.circular(8),
                                child: Center(
                                  child: Text(
                                    'Out of Stock',
                                    style: GoogleFonts.poppins(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ),
                              );
                            }
                            
                            if (isInCart && quantity > 0) {
                              
                              return Material(
                                color: Colors.amber,
                                borderRadius: BorderRadius.circular(8),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    
                                    IconButton(
                                      onPressed: () async {
                                        if (quantity > 1) {
                                          await CartService.updateQuantity(product.id!, quantity - 1);
                                        } else {
                                          await CartService.removeFromCart(product.id!);
                                        }
                                      },
                                      icon: const Icon(Icons.remove, color: Colors.white, size: 18),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                    ),
                                    
                                    Text(
                                      quantity.toString(),
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                    
                                    IconButton(
                                      onPressed: () async {
                                        await CartService.updateQuantity(product.id!, quantity + 1);
                                      },
                                      icon: const Icon(Icons.add, color: Colors.white, size: 18),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                    ),
                                  ],
                                ),
                              );
                            }
                            
                            
                            return Material(
                              color: Colors.amber,
                              borderRadius: BorderRadius.circular(8),
                              child: InkWell(
                                onTap: () async {
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
                                borderRadius: BorderRadius.circular(8),
                                child: Center(
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.shopping_bag_outlined,
                                        color: Colors.white,
                                        size: 16,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Add to Cart',
                                        style: GoogleFonts.poppins(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProductListItem(ProductModel product) {
    final productId = product.id ?? '';
    final favoriteNotifier = _favoriteNotifiers[productId] ?? ValueNotifier<bool>(false);
    final hasDiscount = product.discount > 0 && product.originalPrice > product.price;
    final isOutOfStock = product.stock <= 0;

    return ValueListenableBuilder<bool>(
      valueListenable: favoriteNotifier,
      builder: (context, isFavorite, child) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
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
                      color: isOutOfStock ? Colors.grey[300] : Colors.amber,
                      shape: BoxShape.circle,
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: isOutOfStock
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
        );
      },
    );
  }
}

