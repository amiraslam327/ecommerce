import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../widgets/category_item.dart';
import '../../widgets/product_card.dart';
import '../../constants/app_colors.dart';
import '../../models/category_model.dart';
import '../../models/product_model.dart';
import '../../admin/admin_service.dart';
import '../../admin/admin_login_screen.dart';
import '../../admin/admin_dashboard_screen.dart';
import '../../admin/category_service.dart';
import '../../admin/product_service.dart';
import '../../admin/special_offer_service.dart';
import '../../models/special_offer_model.dart';
import '../../services/wishlist_service.dart';
import '../../services/cart_service.dart';
import '../../services/address_service.dart';
import '../../models/address_model.dart';
import 'categories_screen.dart';
import 'category_products_screen.dart';
import 'all_products_screen.dart';
import 'product_details_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ValueNotifier<int> _currentBannerIndexNotifier = ValueNotifier<int>(0);
  final Map<String, ValueNotifier<bool>> _favoriteNotifiers = {}; 
  final AddressService _addressService = AddressService();
  AddressModel? _currentAddress;
  final TextEditingController _searchController = TextEditingController();
  final ValueNotifier<bool> _hasSearchTextNotifier = ValueNotifier<bool>(false);
  DateTime? _lastRefreshTime;
  static const _refreshCooldown = Duration(seconds: 2); 

  @override
  void initState() {
    super.initState();
    _initializeWishlistStatus();
    _loadCurrentAddress();
    
    _searchController.addListener(() {
      _hasSearchTextNotifier.value = _searchController.text.isNotEmpty;
    });
  }


  Future<void> _loadCurrentAddress() async {
    try {
      
      AddressModel? address = await _addressService.getDefaultAddress();
      
      
      if (address == null) {
        final addresses = await _addressService.getAllAddresses();
        if (addresses.isNotEmpty) {
          address = addresses.first;
        }
      }
      
      if (mounted) {
        setState(() {
          _currentAddress = address;
        });
      }
    } catch (e) {
      debugPrint('Error loading current address: $e');
    }
  }

  Future<void> _initializeWishlistStatus() async {
    final wishlistIds = await WishlistService.getWishlistProductIds();
    
    for (var notifier in _favoriteNotifiers.values) {
      notifier.dispose();
    }
    _favoriteNotifiers.clear();
    
    
    for (var productId in wishlistIds) {
      if (productId.isNotEmpty && !_favoriteNotifiers.containsKey(productId)) {
        _favoriteNotifiers[productId] = ValueNotifier<bool>(true);
      }
    }
    
  }

  @override
  void dispose() {
    _searchController.dispose();
    _hasSearchTextNotifier.dispose();
    
    _currentBannerIndexNotifier.dispose();
    for (var notifier in _favoriteNotifiers.values) {
      notifier.dispose();
    }
    _favoriteNotifiers.clear();
    super.dispose();
  }

  Future<void> _refreshFavoriteStatus() async {
    if (!mounted) return;
    
    
    final now = DateTime.now();
    if (_lastRefreshTime != null && 
        now.difference(_lastRefreshTime!) < _refreshCooldown) {
      return;
    }
    _lastRefreshTime = now;
    
    
    final wishlistIds = await WishlistService.getWishlistProductIds();
    final wishlistSet = wishlistIds.toSet();
    
    
    if (!mounted) return;
    
    
    final productIds = List<String>.from(_favoriteNotifiers.keys);
    
    for (var productId in productIds) {
      if (productId.isNotEmpty && mounted) {
        final isInWishlist = wishlistSet.contains(productId);
        final notifier = _favoriteNotifiers[productId];
        
        if (notifier != null) {
          try {
            notifier.value = isInWishlist;
          } catch (e) {
            
            _favoriteNotifiers.remove(productId);
          }
        }
      }
    }
  }

  String _getUserName() {
    final user = FirebaseAuth.instance.currentUser;
    return user?.displayName ?? user?.email?.split('@')[0] ?? 'Lily';
  }

  String _getShortAddress(String address) {
    if (address == 'No address set') return address;
    
    if (address.length > 30) {
      return '${address.substring(0, 30)}...';
    }
    return address;
  }

  double? _extractDiscountPercentage(String discountText) {
    if (discountText.isEmpty) return null;
    
    final regex = RegExp(r'(\d+(?:\.\d+)?)');
    final match = regex.firstMatch(discountText);
    if (match != null) {
      return double.tryParse(match.group(1) ?? '');
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          
          _buildHeader(),
          
          
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  
                  _buildSpecialForYouSection(),
                  const SizedBox(height: 5),
                  
                  _buildCategoriesSection(),
                  const SizedBox(height: 5),
                  
                  _buildRecommendedSection(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  
  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        bottom: 20,
      ),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hello, ${_getUserName()}!',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.5,
                      ),
                      overflow: TextOverflow.visible,
                      softWrap: true,
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          color: Colors.white.withValues(alpha: 0.85),
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            _getShortAddress(_currentAddress?.fullAddress ?? 'No address set'),
                            style: GoogleFonts.poppins(
                              color: Colors.white.withValues(alpha: 0.85),
                              fontSize: 13,
                              fontWeight: FontWeight.w400,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              
              _buildHeaderIcon(Icons.admin_panel_settings, isNotification: true),
            ],
          ),
          const SizedBox(height: 10),
          
          _buildSearchBar(),
        ],
      ),
    );
  }


  Widget _buildHeaderIcon(IconData icon, {bool isNotification = false}) {
    
    final displayIcon = isNotification ? Icons.admin_panel_settings : icon;
    return InkWell(
      onTap: () async {
        if (isNotification) {
          final user = FirebaseAuth.instance.currentUser;
          if (user != null && user.email != null) {
            
            final isAdminUser = await AdminService.isAdmin(user.email!, isEmail: true);
            if (isAdminUser && mounted) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AdminDashboardScreen(),
                ),
              );
            } else if (mounted) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AdminLoginScreen(),
                ),
              );
            }
          } else if (mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const AdminLoginScreen(),
              ),
            );
          }
        }
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(4.0),
        child: Icon(
          displayIcon,
          color: Colors.white,
          size: 24,
        ),
      ),
    );
  }

  
  void _performSearch() {
    final query = _searchController.text.trim();
    if (query.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AllProductsScreen(
            initialSearchQuery: query,
          ),
        ),
      );
    }
  }

  
  void _showFilterDialog() async {
    if (!mounted) return;
    
    String? selectedSortBy;
    String? selectedCategory = 'All Categories';
    final minPriceController = TextEditingController();
    final maxPriceController = TextEditingController();
    final minDiscountController = TextEditingController();
    double? minPrice;
    double? maxPrice;
    double? minDiscount;

    final sortOptions = [
      'Price: Low to High',
      'Price: High to Low',
      'Name: A-Z',
      'Name: Z-A',
      'Newest First',
      'Oldest First',
    ];

    
    final categories = await CategoryService.getCategories();
    final categoryNames = ['All Categories', ...categories.map((c) => c.name)];

    if (!mounted) return;
    
    final result = await showModalBottomSheet<Map<String, dynamic>?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext bottomSheetContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.75,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Column(
                children: [
                  
                  Container(
                    margin: const EdgeInsets.only(top: 12),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Filter & Sort',
                          style: GoogleFonts.poppins(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.black54),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          
                          Row(
                            children: [
                              Icon(Icons.sort, color: AppColors.primary, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'Sort By',
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: sortOptions.map((option) {
                              final isSelected = selectedSortBy == option;
                              return FilterChip(
                                label: Text(
                                  option,
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                  ),
                                ),
                                selected: isSelected,
                                onSelected: (selected) {
                                  setDialogState(() {
                                    selectedSortBy = selected ? option : null;
                                  });
                                },
                                selectedColor: AppColors.primary.withValues(alpha: 0.2),
                                checkmarkColor: AppColors.primary,
                                labelStyle: TextStyle(
                                  color: isSelected ? AppColors.primary : Colors.black87,
                                ),
                                side: BorderSide(
                                  color: isSelected ? AppColors.primary : Colors.grey[300]!,
                                  width: isSelected ? 1.5 : 1,
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 16),
                          const Divider(),
                          const SizedBox(height: 16),
                          
                          Row(
                            children: [
                              Icon(Icons.attach_money, color: AppColors.primary, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'Price Range',
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey[300]!),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: TextField(
                                    controller: minPriceController,
                                    decoration: InputDecoration(
                                      labelText: 'Min Price',
                                      labelStyle: GoogleFonts.poppins(color: Colors.grey[600]),
                                      border: InputBorder.none,
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                      prefixIcon: Icon(Icons.trending_down, color: Colors.grey[400], size: 20),
                                    ),
                                    style: GoogleFonts.poppins(fontSize: 14),
                                    keyboardType: TextInputType.number,
                                    onChanged: (value) {
                                      minPrice = value.isEmpty ? null : double.tryParse(value);
                                    },
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Container(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  'to',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Container(
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey[300]!),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: TextField(
                                    controller: maxPriceController,
                                    decoration: InputDecoration(
                                      labelText: 'Max Price',
                                      labelStyle: GoogleFonts.poppins(color: Colors.grey[600]),
                                      border: InputBorder.none,
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                      prefixIcon: Icon(Icons.trending_up, color: Colors.grey[400], size: 20),
                                    ),
                                    style: GoogleFonts.poppins(fontSize: 14),
                                    keyboardType: TextInputType.number,
                                    onChanged: (value) {
                                      maxPrice = value.isEmpty ? null : double.tryParse(value);
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          const Divider(),
                          const SizedBox(height: 16),
                          
                          Row(
                            children: [
                              Icon(Icons.category, color: AppColors.primary, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'Category & Discount',
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey[300]!),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: DropdownButtonFormField<String>(
                                    value: selectedCategory ?? 'All Categories',
                                    isExpanded: true,
                                    decoration: InputDecoration(
                                      border: InputBorder.none,
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                      prefixIcon: Icon(Icons.filter_list, color: AppColors.primary, size: 18),
                                    ),
                                    items: categoryNames.map((name) {
                                      return DropdownMenuItem(
                                        value: name,
                                        child: Text(
                                          name,
                                          style: GoogleFonts.poppins(fontSize: 13),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      );
                                    }).toList(),
                                    onChanged: (value) {
                                      setDialogState(() {
                                        selectedCategory = value;
                                      });
                                    },
                                    style: GoogleFonts.poppins(fontSize: 13, color: Colors.black87),
                                    dropdownColor: Colors.white,
                                    icon: Icon(Icons.arrow_drop_down, color: AppColors.primary, size: 20),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Container(
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey[300]!),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: TextField(
                                    controller: minDiscountController,
                                    textAlign: TextAlign.center,
                                    decoration: InputDecoration(
                                      labelText: 'Discount (%)',
                                      labelStyle: GoogleFonts.poppins(color: Colors.grey[600], fontSize: 13),
                                      border: InputBorder.none,
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                      prefixIcon: Icon(Icons.percent, color: Colors.grey[400], size: 18),
                                    ),
                                    style: GoogleFonts.poppins(fontSize: 13),
                                    keyboardType: TextInputType.number,
                                    onChanged: (value) {
                                      minDiscount = value.isEmpty ? null : double.tryParse(value);
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, -2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              setDialogState(() {
                                selectedSortBy = null;
                                selectedCategory = 'All Categories';
                                minPriceController.clear();
                                maxPriceController.clear();
                                minDiscountController.clear();
                                minPrice = null;
                                maxPrice = null;
                                minDiscount = null;
                              });
                            },
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              side: BorderSide(color: Colors.grey[300]!),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              'Reset',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            onPressed: () {
                              
                              Navigator.of(bottomSheetContext).pop({
                                'sortBy': selectedSortBy,
                                'category': selectedCategory == 'All Categories' ? null : selectedCategory,
                                'minPrice': minPrice,
                                'maxPrice': maxPrice,
                                'minDiscount': minDiscount,
                              });
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            child: Text(
                              'Apply Filters',
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
                ],
              ),
            );
          },
        );
      },
    );
    
    
    await Future.delayed(const Duration(milliseconds: 400));
    
    
    if (mounted) {
      minPriceController.dispose();
      maxPriceController.dispose();
      minDiscountController.dispose();
    }
    
    
    if (result != null && mounted) {
      
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AllProductsScreen(
                initialSearchQuery: _searchController.text.trim().isNotEmpty
                    ? _searchController.text.trim()
                    : null,
                sortBy: result['sortBy'],
                categoryFilter: result['category'],
                minPrice: result['minPrice'],
                maxPrice: result['maxPrice'],
                minDiscount: result['minDiscount'],
              ),
            ),
          );
        }
      });
    }
  }

  
  Widget _buildSearchBar() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              children: [
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search products',
                      hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                      border: InputBorder.none,
                    ),
                    onSubmitted: (value) {
                      _performSearch();
                    },
                  ),
                ),
                ValueListenableBuilder<bool>(
                  valueListenable: _hasSearchTextNotifier,
                  builder: (context, hasSearchText, child) {
                    if (hasSearchText) {
                      return IconButton(
                        icon: Icon(Icons.clear, color: Colors.grey[400], size: 20),
                        onPressed: () {
                          _searchController.clear();
                        },
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
                IconButton(
                  icon: Icon(Icons.search, color: AppColors.primary, size: 20),
                  onPressed: _performSearch,
                ),
                const SizedBox(width: 8),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Container(
          width: 45,
          height: 50,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 12,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: IconButton(
            icon: Icon(Icons.tune, color: AppColors.primary, size: 22),
            onPressed: () {
              _showFilterDialog();
            },
          ),
        ),
      ],
    );
  }

  
  Widget _buildSpecialForYouSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Text(
            'Special For You',
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Colors.black54,
              letterSpacing: -0.3,
            ),
          ),
        ),
        const SizedBox(height: 8),
        
        StreamBuilder<List<SpecialOfferModel>>(
          stream: SpecialOfferService.getActiveSpecialOffersStream(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox(
                height: 170,
                child: Center(child: CircularProgressIndicator()),
              );
            }

            if (snapshot.hasError) {
              return SizedBox(
                height: 170,
                child: Center(
                  child: Text(
                    'Error loading offers',
                    style: GoogleFonts.poppins(),
                  ),
                ),
              );
            }

            final offers = snapshot.data ?? [];
            
            if (offers.isEmpty) {
              
              return Column(
                children: [
                  SizedBox(
                    height: 170,
                    child: PageView.builder(
                      itemCount: 3,
                      onPageChanged: (index) {
                        _currentBannerIndexNotifier.value = index;
                      },
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: _buildBannerCard(index),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  ValueListenableBuilder<int>(
                    valueListenable: _currentBannerIndexNotifier,
                    builder: (context, currentIndex, child) {
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(3, (index) {
                          final isActive = currentIndex == index;
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                            width: isActive ? 30 : 8,
                            height: 8,
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(4),
                              color: isActive ? AppColors.primary : Colors.grey[300],
                            ),
                          );
                        }),
                      );
                    },
                  ),
                ],
              );
            }

            return Column(
              children: [
                SizedBox(
                  height: 170,
                  child: PageView.builder(
                    itemCount: offers.length,
                    onPageChanged: (index) {
                      _currentBannerIndexNotifier.value = index;
                    },
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: _buildSpecialOfferCard(offers[index]),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
                
                ValueListenableBuilder<int>(
                  valueListenable: _currentBannerIndexNotifier,
                  builder: (context, currentIndex, child) {
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(offers.length, (index) {
                        final isActive = currentIndex == index;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                          width: isActive ? 30 : 8,
                          height: 8,
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4),
                            color: isActive ? AppColors.primary : Colors.grey[300],
                          ),
                        );
                      }),
                    );
                  },
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildBannerCard(int index) {
    
    final imagePath = index % 2 == 0 
        ? 'assets/images/img.png' 
        : 'assets/images/img1.png';
    
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withValues(alpha: 0.1),
            Colors.white,
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 6),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Boost Season',
                      style: GoogleFonts.poppins(
                        color: AppColors.primary,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Get Special Offer',
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Up to ',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.black,
                          letterSpacing: -0.3,
                        ),
                      ),
                      Text(
                        '40%',
                        style: GoogleFonts.poppins(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: AppColors.black,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.amber,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'Shop Now',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(
            width: 140,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
            ),
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
              child: Image.asset(
                imagePath,
                fit: BoxFit.cover,
                width: 140,
                height: double.infinity,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpecialOfferCard(SpecialOfferModel offer) {
    return Container(
      height: 170,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withValues(alpha: 0.08),
            Colors.white,
            AppColors.primary.withValues(alpha: 0.03),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.15),
            blurRadius: 15,
            offset: const Offset(0, 4),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Stack(
        children: [
          
          if (offer.imageUrl.isNotEmpty)
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.network(
                  offer.imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppColors.primary.withValues(alpha: 0.15),
                            AppColors.primary.withValues(alpha: 0.05),
                          ],
                        ),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.local_offer_rounded,
                          color: AppColors.primary.withValues(alpha: 0.3),
                          size: 50,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: Colors.black.withValues(alpha: 0.5),
              ),
            ),
          ),
          
          Positioned(
            left: 16,
            top: 16,
            right: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.5),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    offer.badgeText,
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                
                Text(
                  offer.title,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.4,
                    height: 1.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      offer.subtitle,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withValues(alpha: 0.9),
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      offer.discountText,
                      style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: AppColors.amber,
                        letterSpacing: -0.8,
                        height: 1,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          Positioned(
            right: 16,
            bottom: 16,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.amber.withValues(alpha: 0.5),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: () {
                  final discountValue = _extractDiscountPercentage(offer.discountText);
                  if (discountValue != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AllProductsScreen(
                          maxDiscount: discountValue,
                        ),
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.amber,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      offer.buttonText,
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.arrow_forward_rounded,
                      color: Colors.white,
                      size: 14,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  
  Widget _buildCategoriesSection() {
    return GestureDetector(
      onTap: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const CategoriesScreen(),
          ),
        );
        
        if (result == true && mounted) {
          _initializeWishlistStatus();
        }
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'Categories',
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Colors.black54,
                letterSpacing: -0.3,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.grey[300]!,
                width: 1,
              ),
            ),
            child: StreamBuilder<List<CategoryModel>>(
              stream: CategoryService.getCategoriesStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20.0),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }
                
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Text(
                        'Error loading categories',
                        style: GoogleFonts.poppins(),
                      ),
                    ),
                  );
                }
                
                final categories = snapshot.data ?? [];
                final displayedCategories = categories.take(7).toList();
                
                
                displayedCategories.add(
                  CategoryModel(
                    name: 'More',
                    iconName: 'more_horiz',
                  ),
                );
                
                return GridView.builder(
                  shrinkWrap: true,
                  padding: EdgeInsets.zero,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    crossAxisSpacing: 30,
                    mainAxisSpacing: 10,
                    childAspectRatio: 0.75,
                  ),
                  itemCount: displayedCategories.length,
                  itemBuilder: (context, index) {
                    final category = displayedCategories[index];
                    return GestureDetector(
                      onTap: () async {
                        if (category.name == 'More') {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const CategoriesScreen(),
                            ),
                          );
                          
                          if (result == true && mounted) {
                            _initializeWishlistStatus();
                          }
                        } else {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => CategoryProductsScreen(
                                categoryName: category.name,
                              ),
                            ),
                          );
                          
                          if (mounted) {
                            _refreshFavoriteStatus();
                          }
                        }
                      },
                      child: CategoryItem(
                        name: category.name,
                        icon: category.getIcon(),
                      ),
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

  
  Widget _buildRecommendedSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recommended For You',
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Colors.black54,
                  letterSpacing: -0.3,
                ),
              ),
              TextButton(
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AllProductsScreen(showRecommendedOnly: true),
                    ),
                  );
                  
                  if (mounted) {
                    _refreshFavoriteStatus();
                  }
                },
                child: Text(
                  'See All',
                  style: GoogleFonts.poppins(
                    color: AppColors.primaryLight,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        SizedBox(
          height: 300,
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
                    style: GoogleFonts.poppins(),
                  ),
                );
              }

              final products = snapshot.data ?? [];
              
              final featuredProducts = products
                  .where((p) => p.isActive && p.isRecommended)
                  .take(6)
                  .toList();

              if (featuredProducts.isEmpty) {
                return Center(
                  child: Text(
                    'No featured products available',
                    style: GoogleFonts.poppins(),
                  ),
                );
              }

              return ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.only(left: 20, right: 10),
                itemCount: featuredProducts.length,
                itemBuilder: (context, index) {
                  final product = featuredProducts[index];
                  final productId = product.id ?? '';
                  
                  
                  if (!_favoriteNotifiers.containsKey(productId)) {
                    _favoriteNotifiers[productId] = ValueNotifier<bool>(false);
                    
                    WishlistService.isInWishlist(productId).then((isInWishlist) {
                      if (!mounted) return;
                      final notifier = _favoriteNotifiers[productId];
                      if (notifier != null) {
                        try {
                          notifier.value = isInWishlist;
                        } catch (e) {
                          
                          _favoriteNotifiers.remove(productId);
                        }
                      }
                    });
                  }
                  
                  final favoriteNotifier = _favoriteNotifiers[productId];
                  if (favoriteNotifier == null) {
                    
                    return const SizedBox.shrink();
                  }
                  
                  return Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: ValueListenableBuilder<bool>(
                      valueListenable: favoriteNotifier,
                      builder: (context, isFavorite, child) {
                        return ProductCard(
                          product: {
                            'id': productId,
                            'name': product.name,
                            'description': product.description,
                            'originalPrice': product.formattedOriginalPrice,
                            'price': product.formattedPrice,
                            'discount': product.discount > 0 ? '${product.discount.toStringAsFixed(0)}% OFF' : '',
                            'imageUrl': product.imageUrl,
                            'isFavorite': isFavorite,
                            'stock': product.stock,
                          },
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ProductDetailsScreen(
                                  product: product,
                                ),
                              ),
                            );
                            
                            
                            if (mounted) {
                              _refreshFavoriteStatus();
                            }
                          },
                          onFavoriteTap: () async {
                            if (!mounted || !_favoriteNotifiers.containsKey(productId)) return;
                            
                            final notifier = _favoriteNotifiers[productId];
                            if (notifier == null) return;
                            
                            try {
                              final currentValue = notifier.value;
                              notifier.value = !currentValue;
                              
                              
                              if (!currentValue) {
                                await WishlistService.addToWishlist(productId);
                              } else {
                                await WishlistService.removeFromWishlist(productId);
                              }
                            } catch (e) {
                              
                              debugPrint('Error updating favorite: $e');
                            }
                          },
                          onAddToCart: product.stock > 0 ? () async {
                            await CartService.addToCart(product.id!);
                            if (!mounted) return;
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('${product.name} added to cart'),
                                  duration: const Duration(seconds: 1),
                                  backgroundColor: AppColors.success,
                                ),
                              );
                            }
                          } : null,
                        );
                      },
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

}


