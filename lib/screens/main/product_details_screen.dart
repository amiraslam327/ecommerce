import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/product_model.dart';
import '../../constants/app_colors.dart';
import '../../services/wishlist_service.dart';
import '../../services/cart_service.dart';
import 'cart_screen.dart';

class ProductDetailsScreen extends StatefulWidget {
  final ProductModel product;

  const ProductDetailsScreen({
    super.key,
    required this.product,
  });

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen>
    with SingleTickerProviderStateMixin {
  int _currentImageIndex = 0;
  final ValueNotifier<bool> _isFavoriteNotifier = ValueNotifier<bool>(false);
  late TabController _tabController;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _pageController = PageController(initialPage: 0);
    _initializeWishlistStatus();
  }

  Future<void> _initializeWishlistStatus() async {
    final productId = widget.product.id ?? '';
    if (productId.isNotEmpty) {
      final isInWishlist = await WishlistService.isInWishlist(productId);
      _isFavoriteNotifier.value = isInWishlist;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _pageController.dispose();
    _isFavoriteNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasDiscount = widget.product.discount > 0 &&
        widget.product.originalPrice > widget.product.price;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          Navigator.of(context).pop(true); 
        }
      },
      child: Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(true), 
        ),
        title: Text(
          'Product Details',
          style: GoogleFonts.poppins(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          ValueListenableBuilder<bool>(
            valueListenable: _isFavoriteNotifier,
            builder: (context, isFavorite, child) {
              return IconButton(
                icon: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  transitionBuilder: (Widget child, Animation<double> animation) {
                    return ScaleTransition(scale: animation, child: child);
                  },
                  child: Icon(
                    isFavorite ? Icons.favorite : Icons.favorite_border,
                    key: ValueKey(isFavorite),
                    color: isFavorite ? Colors.red : Colors.black,
                  ),
                ),
                onPressed: () async {
                  final productId = widget.product.id ?? '';
                  if (productId.isNotEmpty) {
                    final currentValue = _isFavoriteNotifier.value;
                    _isFavoriteNotifier.value = !currentValue;
                    
                    
                    if (!currentValue) {
                      await WishlistService.addToWishlist(productId);
                    } else {
                      await WishlistService.removeFromWishlist(productId);
                    }
                  }
                },
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            
            Container(
              height: 300,
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Colors.white,
              ),
              child: Stack(
                children: [
                  
                  PageView.builder(
                    controller: _pageController,
                    onPageChanged: (index) {
                      setState(() {
                        _currentImageIndex = index;
                      });
                    },
                    itemCount: _getImageCount(),
                    itemBuilder: (context, index) {
                      final imageUrl = _getImageUrl(index);
                      return Center(
                        child: imageUrl != null && imageUrl.isNotEmpty
                            ? Container(
                                color: Colors.white,
                                child: Image.network(
                                  imageUrl,
                                  fit: BoxFit.contain,
                                  height: 250,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      color: Colors.white,
                                      child: Icon(
                                        Icons.image_not_supported_rounded,
                                        size: 120,
                                        color: Colors.grey[400],
                                      ),
                                    );
                                  },
                                ),
                              )
                            : Container(
                                color: Colors.white,
                                child: Icon(
                                  Icons.image_not_supported_rounded,
                                  size: 120,
                                  color: Colors.grey[400],
                                ),
                              ),
                      );
                    },
                  ),
                  
                  if (hasDiscount)
                    Positioned(
                      top: 16,
                      left: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(8),
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
                          '${widget.product.discount.toStringAsFixed(0)}% OFF',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  
                  Positioned(
                    bottom: 20,
                    left: 0,
                    right: 0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(_getImageCount(), (index) {
                        return GestureDetector(
                          onTap: () {
                            _pageController.animateToPage(
                              index,
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          },
                          child: Container(
                            width: _currentImageIndex == index ? 24 : 8,
                            height: 8,
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            decoration: BoxDecoration(
                              color: _currentImageIndex == index
                                  ? AppColors.primary
                                  : Colors.grey[300],
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                ],
              ),
            ),

            
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          widget.product.name,
                          style: GoogleFonts.poppins(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: Colors.black87,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  
                  Row(
                    children: [
                      Icon(Icons.star, color: Colors.amber, size: 18),
                      const SizedBox(width: 4),
                      Text(
                        '4.0',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '(Sold 597)',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        widget.product.formattedPrice,
                        style: GoogleFonts.poppins(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: Colors.black87,
                        ),
                      ),
                      if (hasDiscount) ...[
                        const SizedBox(width: 12),
                        Text(
                          widget.product.formattedOriginalPrice,
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            color: Colors.grey[500],
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 16),

                  
                  Row(
                    children: [
                      Icon(
                        Icons.local_shipping,
                        color: AppColors.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Express 3 Day Delivery',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  
                  TabBar(
                    controller: _tabController,
                    labelColor: AppColors.primary,
                    unselectedLabelColor: Colors.grey[600],
                    indicatorColor: AppColors.primary,
                    tabs: [
                      Tab(
                        child: Text(
                          'Description',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      Tab(
                        child: Text(
                          'Specification',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      Tab(
                        child: Text(
                          'Review',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  
                  SizedBox(
                    height: 300,
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        
                        _buildDescriptionTab(),
                        
                        _buildSpecificationTab(),
                        
                        _buildReviewTab(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            children: [
              
              Expanded(
                child: OutlinedButton(
                  onPressed: widget.product.stock > 0 && widget.product.id != null
                      ? () async {
                          await CartService.addToCart(widget.product.id!);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('${widget.product.name} added to cart'),
                                duration: const Duration(seconds: 1),
                                backgroundColor: AppColors.success,
                              ),
                            );
                          }
                        }
                      : null,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: BorderSide(
                      color: widget.product.stock > 0 ? AppColors.amber : Colors.grey,
                      width: 2,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.shopping_bag_outlined,
                        color: widget.product.stock > 0 ? AppColors.amber : Colors.grey,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        widget.product.stock > 0 ? 'Add to Cart' : 'Out of Stock',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: widget.product.stock > 0 ? AppColors.amber : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              
              Expanded(
                child: ElevatedButton(
                  onPressed: widget.product.stock > 0 && widget.product.id != null
                      ? () async {
                          
                          await CartService.addToCart(widget.product.id!);
                          if (mounted) {
                            
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const CartScreen(),
                              ),
                            );
                          }
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    widget.product.stock > 0 ? 'Buy Now' : 'Out of Stock',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }

  Widget _buildDescriptionTab() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Smooth Rides. Stylish Design. Built to Last.',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            widget.product.description,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey[700],
              height: 1.6,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 24),
          
          GridView.count(
            crossAxisCount: 5,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.8,
            children: [
              _buildSpecCard(Icons.straighten, '32', 'Size'),
              _buildSpecCard(Icons.forest, 'Maple', 'Material'),
              _buildSpecCard(Icons.settings, 'PU 78A', 'Wheels'),
              _buildSpecCard(Icons.person, 'Beginner', 'For'),
              _buildSpecCard(Icons.fitness_center, '100kg', 'Load'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSpecCard(IconData icon, String value, String label) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: AppColors.primary, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 10,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpecificationTab() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSpecRow('Category', widget.product.categoryName),
          _buildSpecRow('Stock', '${widget.product.stock} available'),
          _buildSpecRow('Original Price', widget.product.formattedOriginalPrice),
          _buildSpecRow('Current Price', widget.product.formattedPrice),
          if (widget.product.discount > 0)
            _buildSpecRow('Discount', '${widget.product.discount.toStringAsFixed(0)}%'),
          _buildSpecRow('Status', widget.product.isActive ? 'Active' : 'Inactive'),
        ],
      ),
    );
  }

  Widget _buildSpecRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.reviews_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No reviews yet',
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Be the first to review this product',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  
  int _getImageCount() {
    return 3;
  }

  
  String? _getImageUrl(int index) {
    
    if (widget.product.imageUrls.isNotEmpty) {
      if (index < widget.product.imageUrls.length) {
        return widget.product.imageUrls[index];
      }
      
      return widget.product.imageUrls.last;
    }
    
    
    if (widget.product.imageUrl != null && widget.product.imageUrl!.isNotEmpty) {
      return widget.product.imageUrl;
    }
    
    
    return null;
  }
}

