import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../services/cart_service.dart';

class CustomBottomNavigationBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const CustomBottomNavigationBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 70,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  
                  _buildNavItem(
                    icon: Icons.home_outlined,
                    filledIcon: Icons.home,
                    label: 'Home',
                    index: 0,
                  ),
                  
                  _buildNavItem(
                    icon: Icons.favorite_border,
                    filledIcon: Icons.favorite,
                    label: 'Wishlist',
                    index: 1,
                  ),
                  
                  const SizedBox(width: 56),
                  
                  _buildCartNavItem(),
                  
                  _buildNavItem(
                    icon: Icons.person_outline,
                    filledIcon: Icons.person,
                    label: 'Profile',
                    index: 4,
                  ),
                ],
              ),
            ),
            
            Positioned(
              left: MediaQuery.of(context).size.width / 2 - 28,
              top: -28,
              child: _buildCenterButton(),
            ),
          ],
        ),
      ),
    );
  }

  
  Widget _buildNavItem({
    required IconData icon,
    required IconData filledIcon,
    required String label,
    required int index,
  }) {
    final isSelected = currentIndex == index;

    return Expanded(
      child: InkWell(
        onTap: () => onTap(index),
        borderRadius: BorderRadius.circular(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                isSelected ? filledIcon : icon,
                key: ValueKey(isSelected),
                color: isSelected ? AppColors.primary : Colors.grey[400],
                size: 24,
              ),
            ),
            const SizedBox(height: 2),
            Flexible(
              child: Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: isSelected ? AppColors.primary : Colors.grey[600],
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  
  Widget _buildCartNavItem() {
    final isSelected = currentIndex == 3;

    return Expanded(
      child: InkWell(
        onTap: () => onTap(3),
        borderRadius: BorderRadius.circular(12),
        child: StreamBuilder<Map<String, int>>(
          stream: CartService.getCartStream(),
          builder: (context, snapshot) {
            int cartItemCount = 0;
            if (snapshot.hasData) {
              
              cartItemCount = snapshot.data!.length;
            }

            return Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        isSelected ? Icons.shopping_cart : Icons.shopping_cart_outlined,
                        key: ValueKey(isSelected),
                        color: isSelected ? AppColors.primary : Colors.grey[400],
                        size: 24,
                      ),
                    ),
                    if (cartItemCount > 0)
                      Positioned(
                        right: -6,
                        top: -6,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 1.5),
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
                          child: Center(
                            child: Text(
                              cartItemCount > 99 ? '99+' : cartItemCount.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 2),
                Flexible(
                  child: Text(
                    'Cart',
                    style: TextStyle(
                      fontSize: 10,
                      color: isSelected ? AppColors.primary : Colors.grey[600],
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  
  Widget _buildCenterButton() {
    final isSelected = currentIndex == 2;

    return GestureDetector(
      onTap: () => onTap(2),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: AppColors.primary,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(
          Icons.storefront,
          color: Colors.white,
          size: 28,
        ),
      ),
    );
  }
}
