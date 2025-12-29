import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/app_colors.dart';
import 'admin_categories_screen.dart';
import 'admin_products_screen.dart';
import 'admin_promo_codes_screen.dart';
import 'admin_delivery_price_screen.dart';
import 'admin_special_offers_screen.dart';
import 'admin_orders_screen.dart';
import 'category_service.dart';
import 'product_service.dart';
import '../../services/order_service.dart';

class AdminHomeScreen extends StatefulWidget {
  final Map<String, dynamic>? adminData;

  const AdminHomeScreen({
    super.key,
    required this.adminData,
  });

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  int _categoryCount = 0;
  int _productCount = 0;
  int _totalOrders = 0;
  int _pendingOrders = 0;
  bool _isLoadingStats = true;

  @override
  void initState() {
    super.initState();
    _loadStatistics();
  }

  Future<void> _loadStatistics() async {
    setState(() {
      _isLoadingStats = true;
    });

    try {
      final results = await Future.wait([
        CategoryService.getCategoryCount(),
        ProductService.getProductCount(),
        OrderService.getOrderCounts(),
      ]);

      if (mounted) {
        setState(() {
          _categoryCount = results[0] as int;
          _productCount = results[1] as int;
          final orderCounts = results[2] as Map<String, int>;
          _totalOrders = orderCounts['total'] ?? 0;
          _pendingOrders = orderCounts['pending'] ?? 0;
          _isLoadingStats = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading statistics: $e');
      if (mounted) {
        setState(() {
          _isLoadingStats = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome, ${widget.adminData?['name'] ?? 'Admin'}!',
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.adminData?['email'] ?? '',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          
          Text(
            'Statistics',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          if (_isLoadingStats)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20.0),
                child: CircularProgressIndicator(),
              ),
            )
          else
            Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        icon: Icons.category,
                        label: 'Categories',
                        value: _categoryCount.toString(),
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        icon: Icons.shopping_bag,
                        label: 'Products',
                        value: _productCount.toString(),
                        color: Colors.orange,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        icon: Icons.shopping_cart,
                        label: 'Total Orders',
                        value: _totalOrders.toString(),
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        icon: Icons.pending,
                        label: 'Pending Orders',
                        value: _pendingOrders.toString(),
                        color: Colors.orange,
                      ),
                    ),
                  ],
                ),
              ],
          ),
          const SizedBox(height: 24),
          
          Text(
            'Quick Actions',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          _buildActionCard(
            icon: Icons.category,
            title: 'Manage Categories',
            subtitle: 'Add, edit, or delete categories',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AdminCategoriesScreen(),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          _buildActionCard(
            icon: Icons.shopping_bag,
            title: 'Manage Products',
            subtitle: 'Add, edit, or delete products',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AdminProductsScreen(),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          _buildActionCard(
            icon: Icons.local_offer,
            title: 'Manage Promo Codes',
            subtitle: 'Add, edit, or delete promo codes',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AdminPromoCodesScreen(),
            ),
              );
            },
          ),
          const SizedBox(height: 12),
          _buildActionCard(
            icon: Icons.local_shipping,
            title: 'Delivery Price',
            subtitle: 'Set delivery price for orders',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AdminDeliveryPriceScreen(),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          _buildActionCard(
            icon: Icons.local_offer,
            title: 'Special Offers',
            subtitle: 'Manage home page banner offers',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AdminSpecialOffersScreen(),
                ),
              );
            },
              ),
          const SizedBox(height: 12),
          _buildActionCard(
            icon: Icons.shopping_cart,
            title: 'Manage Orders',
            subtitle: 'View, accept, cancel, or complete orders',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AdminOrdersScreen(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: AppColors.primary,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Colors.grey[400],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: color,
            size: 28,
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}

