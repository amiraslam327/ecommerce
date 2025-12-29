import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';
import '../services/cart_service.dart';

class ProductCard extends StatelessWidget {
  final Map<String, dynamic> product;
  final VoidCallback onFavoriteTap;
  final VoidCallback? onTap;
  final VoidCallback? onAddToCart;

  const ProductCard({
    super.key,
    required this.product,
    required this.onFavoriteTap,
    this.onTap,
    this.onAddToCart,
  });

  @override
  Widget build(BuildContext context) {
    final isFavorite = product['isFavorite'] as bool;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 170,
        margin: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 15,
              offset: const Offset(0, 4),
              spreadRadius: 0,
            ),
          ],
        ),
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          
          Stack(
            children: [
              Container(
                height: 150,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: (product['imageUrl'] != null && 
                        product['imageUrl'] is String && 
                        (product['imageUrl'] as String).isNotEmpty)
                    ? ClipRRect(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(20),
                          topRight: Radius.circular(20),
                        ),
                        child: Image.network(
                          product['imageUrl'] as String,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: 150,
                          errorBuilder: (context, error, stackTrace) {
                            return Center(
                              child: Icon(
                                Icons.sports_esports,
                                size: 60,
                                color: Colors.grey[400],
                              ),
                            );
                          },
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Center(
                              child: CircularProgressIndicator(
                                value: loadingProgress.expectedTotalBytes != null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                        loadingProgress.expectedTotalBytes!
                                    : null,
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
              
              if (product['discount'] != null && 
                  product['discount'] is String && 
                  (product['discount'] as String).isNotEmpty)
                Positioned(
                  top: 10,
                  left: 10,
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
                      product['discount'] as String,
                      style: GoogleFonts.poppins(
                        fontSize: 9,
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              
              Positioned(
                top: 10,
                right: 10,
                child: GestureDetector(
                  onTap: () {
                    onFavoriteTap();
                  },
                  behavior: HitTestBehavior.opaque,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeInOut,
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        isFavorite ? Icons.favorite : Icons.favorite_border,
                        key: ValueKey(isFavorite),
                        color: isFavorite ? Colors.red[600] : Colors.grey[400],
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          
          
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  product['name'] as String,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                    letterSpacing: -0.3,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  product['description'] as String,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: Colors.grey[600],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    
                    if (product['discount'] != null && 
                        product['discount'] is String && 
                        (product['discount'] as String).isNotEmpty)
                      Text(
                        product['originalPrice'] as String,
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          color: Colors.grey[400],
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                    if (product['discount'] != null && 
                        product['discount'] is String && 
                        (product['discount'] as String).isNotEmpty)
                      const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        product['price'] as String,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: Colors.black87,
                          letterSpacing: -0.3,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.star,
                      color: Colors.amber,
                      size: 12,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      '4.5',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: Colors.grey[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 3),
                    Text(
                      '(120)',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
                
                if (onAddToCart != null) ...[
                  const SizedBox(height: 8),
                  Builder(
                    builder: (context) {
                      final stock = product['stock'] as int? ?? 0;
                      final isOutOfStock = stock <= 0;
                      final productId = product['id'] as String?;
                      
                      if (productId == null) {
                        return const SizedBox.shrink();
                      }
                      
                      return StreamBuilder<Map<String, int>>(
                        stream: CartService.getCartStream(),
                        builder: (context, snapshot) {
                          final cartItems = snapshot.data ?? {};
                          final isInCart = cartItems.containsKey(productId);
                          final quantity = cartItems[productId] ?? 0;
                          
                          if (isOutOfStock) {
                            return SizedBox(
                              width: double.infinity,
                              height: 28,
                              child: Material(
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
                              ),
                            );
                          }
                          
                          if (isInCart && quantity > 0) {
                            
                            return SizedBox(
                              width: double.infinity,
                              height: 28,
                              child: Material(
                                color: Colors.amber,
                                borderRadius: BorderRadius.circular(8),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    
                                    IconButton(
                                      onPressed: () async {
                                        if (quantity > 1) {
                                          await CartService.updateQuantity(productId, quantity - 1);
                                        } else {
                                          await CartService.removeFromCart(productId);
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
                                        await CartService.updateQuantity(productId, quantity + 1);
                                      },
                                      icon: const Icon(Icons.add, color: Colors.white, size: 18),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }
                          
                          
                          return SizedBox(
                            width: double.infinity,
                            height: 28,
                            child: Material(
                              color: Colors.amber,
                              borderRadius: BorderRadius.circular(8),
                              child: InkWell(
                                onTap: onAddToCart,
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
                            ),
                          );
                        },
                      );
                    },
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
      ),
    );
  }
}

