import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/address_model.dart';
import '../../models/product_model.dart';
import '../../models/promo_code_model.dart';
import '../../services/address_service.dart';
import '../../services/cart_service.dart';
import '../../admin/product_service.dart';
import '../../admin/promo_code_service.dart';
import '../../admin/delivery_price_service.dart';
import '../../constants/app_colors.dart';
import '../../models/payment_method_model.dart';
import '../../models/order_model.dart';
import '../../services/order_service.dart';
import 'address_management_screen.dart';
import '../profile/payment_methods_screen.dart';
import 'order_success_screen.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  AddressModel? _selectedAddress;
  final AddressService _addressService = AddressService();
  Map<String, ProductModel> _cartProducts = {};
  Map<String, int> _cartQuantities = {};
  bool _isLoading = true;
  
  
  final TextEditingController _promoCodeController = TextEditingController();
  PromoCodeModel? _appliedPromoCode;
  bool _isValidatingPromoCode = false;
  String? _promoCodeError;
  
  
  double _deliveryPrice = 0.0;
  
  
  PaymentMethodModel? _selectedPaymentMethod;
  String? _selectedPaymentType; 

  @override
  void initState() {
    super.initState();
    _loadDefaultAddress();
    _loadCartProducts();
    _loadDeliveryPrice();
  }

  Future<void> _loadDeliveryPrice() async {
    try {
      final price = await DeliveryPriceService.getDeliveryPrice();
      if (mounted) {
        setState(() {
          _deliveryPrice = price;
        });
      }
    } catch (e) {
      debugPrint('Error loading delivery price: $e');
    }
  }

  @override
  void dispose() {
    _promoCodeController.dispose();
    super.dispose();
  }

  Future<void> _loadCartProducts() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    try {
      
      final cartItems = await CartService.getCartItems();
      
      if (!mounted) return;
      _cartQuantities = cartItems;

      if (cartItems.isEmpty) {
        if (!mounted) return;
        setState(() {
          _cartProducts = {};
          _isLoading = false;
        });
        return;
      }

      
      final allProducts = await ProductService.getProducts();
      
      if (!mounted) return;
      
      
      final Map<String, ProductModel> cartProducts = {};
      for (var product in allProducts) {
        if (product.id != null && cartItems.containsKey(product.id)) {
          cartProducts[product.id!] = product;
        }
      }

      if (!mounted) return;
      setState(() {
        _cartProducts = cartProducts;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading cart products: $e');
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _updateQuantity(String productId, int newQuantity) async {
    
    if (newQuantity <= 0) {
      
      setState(() {
        _cartQuantities.remove(productId);
        _cartProducts.remove(productId);
      });
    } else {
      
      setState(() {
        _cartQuantities[productId] = newQuantity;
      });
    }
    
    
    try {
      await CartService.updateQuantity(productId, newQuantity);
      
      final cartItems = await CartService.getCartItems();
      if (mounted) {
        setState(() {
          _cartQuantities = cartItems;
          
          _cartProducts.removeWhere((key, value) => !cartItems.containsKey(key));
        });
      }
    } catch (e) {
      
      debugPrint('Error updating quantity: $e');
      if (mounted) {
        _loadCartProducts();
      }
    }
  }

  Future<void> _removeFromCart(String productId) async {
    
    setState(() {
      _cartQuantities.remove(productId);
      _cartProducts.remove(productId);
    });
    
    
    try {
      await CartService.removeFromCart(productId);
      
      _loadCartProducts();
    } catch (e) {
      
      debugPrint('Error removing from cart: $e');
      _loadCartProducts();
    }
  }

  Future<void> _loadDefaultAddress() async {
    final address = await _addressService.getDefaultAddress();
    if (!mounted) return;
    if (address != null) {
      setState(() {
        _selectedAddress = address;
      });
    } else {
      
      final addresses = await _addressService.getAllAddresses();
      if (!mounted) return;
      if (addresses.isNotEmpty) {
        setState(() {
          _selectedAddress = addresses.first;
        });
      }
    }
  }

  Future<void> _selectAddress() async {
    
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddressManagementScreen(
          allowSelection: false,
        ),
      ),
    );
    
    _loadDefaultAddress();
  }

  @override
  Widget build(BuildContext context) {
    
    final canPop = Navigator.canPop(context);
    
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: canPop
            ? IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black),
                onPressed: () => Navigator.of(context).pop(),
              )
            : null,
        title: Text(
          'Checkout',
          style: GoogleFonts.poppins(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  
                  _buildShippingAddressSection(),
                  const SizedBox(height: 8),
                  
                  _buildPaymentMethodSection(),
                  const SizedBox(height: 8),
                  
                  if (_cartProducts.isEmpty)
                    _buildEmptyCart()
                  else
                    _buildCartProductsSection(),
                  const SizedBox(height: 8),
                  const SizedBox(height: 80), 
                ],
              ),
            ),
      bottomNavigationBar: _buildBottomButton(),
    );
  }

  Widget _buildShippingAddressSection() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.only(left: 16,right: 16, bottom: 5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Shipping Address',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit, color: AppColors.warning),
                onPressed: _selectAddress,
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_selectedAddress == null)
            GestureDetector(
              onTap: _selectAddress,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.add_location_alt,
                      color: Colors.grey,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Add Shipping Address',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.location_on,
                  color: AppColors.primary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _selectedAddress!.label,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _selectedAddress!.fullAddress,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _selectedAddress!.phone,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodSection() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Payment Method',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
              TextButton(
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const PaymentMethodsScreen(allowSelection: true),
                    ),
                  );
                  
                  if (result != null && result is PaymentMethodModel) {
                    if (mounted) {
                      setState(() {
                        _selectedPaymentMethod = result;
                        _selectedPaymentType = null;
                      });
                    }
                  } else if (result == 'cod') {
                    
                    if (mounted) {
                      setState(() {
                        _selectedPaymentMethod = null;
                        _selectedPaymentType = 'cod';
                      });
                    }
                  }
                },
                child: Text(
                  _selectedPaymentMethod == null ? 'Select' : 'Change',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_selectedPaymentMethod == null && _selectedPaymentType != 'cod')
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.payment, color: Colors.grey[600], size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'No payment method selected',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                ],
              ),
            )
          else if (_selectedPaymentType == 'cod')
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primary, width: 2),
              ),
              child: Row(
                children: [
                  Icon(Icons.money, color: AppColors.primary, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Cash on Delivery',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Pay when you receive',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )
          else
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primary, width: 2),
              ),
              child: Row(
                children: [
                  Icon(Icons.credit_card, color: AppColors.primary, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _selectedPaymentMethod!.type.toUpperCase(),
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _selectedPaymentMethod!.maskedCardNumber,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyCart() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          Icon(
            Icons.shopping_cart_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Your cart is empty',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add items to your cart to continue',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartProductsSection() {
    return Column(
      children: [
        
        _buildPromoCodeSection(),
        
        Container(
          color: Colors.white,
          padding: const EdgeInsets.only(left: 16,right: 16, bottom: 5),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Cart Items',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
          ..._cartProducts.entries.map((entry) {
                final product = entry.value;
                final quantity = _cartQuantities[product.id] ?? 1;
                return _buildCartItem(product, quantity);
              }),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPromoCodeSection() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Promo Code',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          if (_appliedPromoCode == null)
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _promoCodeController,
                    decoration: InputDecoration(
                      hintText: 'Enter promo code',
                      hintStyle: GoogleFonts.poppins(
                        color: Colors.grey[400],
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: AppColors.primary, width: 2),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: AppColors.error),
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: AppColors.error, width: 2),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                    ),
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                    textCapitalization: TextCapitalization.characters,
                    enabled: !_isValidatingPromoCode,
                  ),
                ),
                const SizedBox(width: 12),
                TextButton(
                  onPressed: _isValidatingPromoCode ? null : _validateAndApplyPromoCode,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
                  child: _isValidatingPromoCode
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                          ),
                        )
                      : Text(
                          'Apply',
                          style: GoogleFonts.poppins(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                ),
              ],
            )
          else
            Row(
              children: [
                Expanded(
                  child: Text(
                    _appliedPromoCode!.code,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  color: Colors.grey[600],
                  onPressed: _removePromoCode,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          
          const SizedBox(height: 4),
          if (_promoCodeError != null)
            Text(
              _promoCodeError!,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: AppColors.error,
              ),
            )
          else if (_appliedPromoCode != null)
            Row(
              children: [
                Text(
                  'You saved: ',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey[700],
                  ),
                ),
                Text(
                  '\$${_calculateDiscount().toStringAsFixed(2)}',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: AppColors.primary,
                      width: 1,
                    ),
                  ),
                  child: Text(
                    '${_appliedPromoCode!.discountValue.toStringAsFixed(_appliedPromoCode!.isPercentage ? 0 : 2)}${_appliedPromoCode!.isPercentage ? '%' : '\$'} OFF',
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            )
          else
            Text(
              'Enter your promo code to get discount',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.grey[500],
              ),
            ),
        ],
      ),
    );
  }


  Widget _buildCartItem(ProductModel product, int quantity) {
    final isOutOfStock = product.stock <= 0;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
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
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: product.imageUrl != null && product.imageUrl!.isNotEmpty
                      ? Image.network(
                          product.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey[200],
                              child: const Icon(
                                Icons.image_not_supported_rounded,
                                color: Colors.grey,
                                size: 40,
                              ),
                            );
                          },
                        )
                      : Container(
                          color: Colors.grey[200],
                          child: const Icon(
                            Icons.image_not_supported_rounded,
                            color: Colors.grey,
                            size: 40,
                          ),
                        ),
                ),
              ),
              
              if (product.discount > 0)
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
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                
                Row(
                  children: [
                    if (product.discount > 0) ...[
                      Text(
                        '\$${product.originalPrice.toStringAsFixed(2)}',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey[600],
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '\$${product.price.toStringAsFixed(2)}',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ] else ...[
                      Text(
                        '\$${product.price.toStringAsFixed(2)}',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline, size: 18),
                          onPressed: quantity > 1
                              ? () => _updateQuantity(product.id!, quantity - 1)
                              : null,
                          color: AppColors.primary,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 32,
                            minHeight: 32,
                          ),
                          iconSize: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '$quantity',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline, size: 18),
                          onPressed: !isOutOfStock && quantity < product.stock
                              ? () => _updateQuantity(product.id!, quantity + 1)
                              : null,
                          color: AppColors.primary,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 32,
                            minHeight: 32,
                          ),
                          iconSize: 18,
                        ),
                      ],
                    ),
                    
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 20),
                      onPressed: () => _removeFromCart(product.id!),
                      color: AppColors.error,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                if (isOutOfStock)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      'Out of Stock',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: AppColors.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  double _calculateSubtotal() {
    double subtotal = 0.0;
    for (var entry in _cartProducts.entries) {
      final product = entry.value;
      final quantity = _cartQuantities[product.id] ?? 1;
      subtotal += product.price * quantity;
    }
    return subtotal;
  }

  
  double _calculateFullTotal() {
    double fullTotal = 0.0;
    for (var entry in _cartProducts.entries) {
      final product = entry.value;
      final quantity = _cartQuantities[product.id] ?? 1;
      fullTotal += product.originalPrice * quantity;
    }
    return fullTotal;
  }

  
  double _calculateProductDiscounts() {
    double productDiscounts = 0.0;
    for (var entry in _cartProducts.entries) {
      final product = entry.value;
      final quantity = _cartQuantities[product.id] ?? 1;
      if (product.discount > 0) {
        final originalPrice = product.originalPrice * quantity;
        final discountedPrice = product.price * quantity;
        productDiscounts += (originalPrice - discountedPrice);
      }
    }
    return productDiscounts;
  }

  
  double _calculatePromoDiscount() {
    if (_appliedPromoCode == null) return 0.0;
    
    final subtotal = _calculateSubtotal();
    if (_appliedPromoCode!.isPercentage) {
      return subtotal * (_appliedPromoCode!.discountValue / 100);
    } else {
      return _appliedPromoCode!.discountValue;
    }
  }


  double _calculateDiscount() {
    return _calculatePromoDiscount();
  }

  double _calculateTotal() {
    final subtotal = _calculateSubtotal();
    final discount = _calculateDiscount();
    
    final totalAfterDiscounts = (subtotal - discount).clamp(0.0, double.infinity);
    
    return totalAfterDiscounts + _deliveryPrice;
  }

  
  double _calculateTotalWithoutDelivery() {
    final subtotal = _calculateSubtotal();
    final discount = _calculateDiscount();
    
    return (subtotal - discount).clamp(0.0, double.infinity);
  }

  Future<void> _validateAndApplyPromoCode() async {
    final code = _promoCodeController.text.trim().toUpperCase();
    
    if (code.isEmpty) {
      setState(() {
        _promoCodeError = 'Please enter a promo code';
        _appliedPromoCode = null;
      });
      return;
    }

    setState(() {
      _isValidatingPromoCode = true;
      _promoCodeError = null;
    });

    try {
      final promoCode = await PromoCodeService.getPromoCodeByCode(code);
      
      if (!mounted) return;
      
      if (promoCode == null) {
        setState(() {
          _promoCodeError = 'Invalid promo code';
          _appliedPromoCode = null;
          _isValidatingPromoCode = false;
        });
        return;
      }

      
      if (!promoCode.isActive) {
        setState(() {
          _promoCodeError = 'This promo code is not active';
          _appliedPromoCode = null;
          _isValidatingPromoCode = false;
        });
        return;
      }

      
      final now = DateTime.now();
      if (promoCode.validFrom != null && now.isBefore(promoCode.validFrom!)) {
        setState(() {
          _promoCodeError = 'This promo code is not yet valid';
          _appliedPromoCode = null;
          _isValidatingPromoCode = false;
        });
        return;
      }

      if (promoCode.validUntil != null && now.isAfter(promoCode.validUntil!)) {
        setState(() {
          _promoCodeError = 'This promo code has expired';
          _appliedPromoCode = null;
          _isValidatingPromoCode = false;
        });
        return;
      }

      
      setState(() {
        _appliedPromoCode = promoCode;
        _promoCodeError = null;
        _isValidatingPromoCode = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Promo code applied successfully!',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: AppColors.primary,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error validating promo code: $e');
      if (!mounted) return;
      setState(() {
        _promoCodeError = 'Error validating promo code';
        _appliedPromoCode = null;
        _isValidatingPromoCode = false;
      });
    }
  }

  void _removePromoCode() {
    setState(() {
      _appliedPromoCode = null;
      _promoCodeController.clear();
      _promoCodeError = null;
    });
  }

  String _getUserName() {
    final user = FirebaseAuth.instance.currentUser;
    return user?.displayName ?? user?.email?.split('@')[0] ?? 'Guest';
  }

  String _getUserId() {
    final user = FirebaseAuth.instance.currentUser;
    return user?.uid ?? 'guest';
  }

  Future<void> _saveOrderAndConfirm() async {
    try {
      
      final outOfStockItems = <String>[];
      for (var entry in _cartProducts.entries) {
        final product = entry.value;
        final quantity = _cartQuantities[product.id] ?? 1;
        
        if (product.stock <= 0) {
          outOfStockItems.add(product.name);
        } else if (quantity > product.stock) {
          outOfStockItems.add('${product.name} (Requested: $quantity, Available: ${product.stock})');
        }
      }
      
      if (outOfStockItems.isNotEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Some items are out of stock:',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  ...outOfStockItems.map((item) => Text(
                    '• $item',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.white,
                    ),
                  )),
                ],
              ),
              duration: const Duration(seconds: 4),
              backgroundColor: AppColors.error,
            ),
          );
        }
        return;
      }
      
      
      final orderProducts = _cartProducts.entries.map((entry) {
        final product = entry.value;
        final quantity = _cartQuantities[product.id] ?? 1;
        return OrderProduct(
          productId: product.id!,
          productName: product.name,
          quantity: quantity,
          originalPrice: product.originalPrice,
          price: product.price,
          discount: product.discount,
          imageUrl: product.imageUrl,
        );
      }).toList();

      
      String paymentMethod = 'Not selected';
      String? paymentMethodType;
      String? paymentCardNumber;
      
      if (_selectedPaymentType == 'cod') {
        paymentMethod = 'Cash on Delivery';
        paymentMethodType = 'cod';
      } else if (_selectedPaymentMethod != null) {
        paymentMethod = '${_selectedPaymentMethod!.type.toUpperCase()} ${_selectedPaymentMethod!.maskedCardNumber}';
        paymentMethodType = _selectedPaymentMethod!.type;
        paymentCardNumber = _selectedPaymentMethod!.maskedCardNumber;
      }

      
      final order = OrderModel(
        userId: _getUserId(),
        userName: _getUserName(),
        shippingAddress: '${_selectedAddress!.label}\n${_selectedAddress!.fullAddress}\n${_selectedAddress!.phone}',
        phoneNumber: _selectedAddress!.phone,
        paymentMethod: paymentMethod,
        paymentMethodType: paymentMethodType,
        paymentCardNumber: paymentCardNumber,
        products: orderProducts,
        totalPrice: _calculateFullTotal(),
        productDiscount: _calculateProductDiscounts(),
        promoCodeDiscount: _calculatePromoDiscount(),
        deliveryFee: _deliveryPrice,
        finalTotal: _calculateTotal(),
        promoCode: _appliedPromoCode?.code,
        status: 'pending',
        createdAt: DateTime.now(),
      );

      
      final orderId = await OrderService.saveOrder(order);

      if (orderId != null && mounted) {
        
        final navigatorContext = Navigator.of(context);
        
        
        await CartService.clearCart();
        
        
        _loadCartProducts();

        if (!mounted) return;
        
        
        if (navigatorContext.canPop()) {
          navigatorContext.pop();
        }
        
        if (!mounted) return;
        
        
        navigatorContext.pushReplacement(
          MaterialPageRoute(
            builder: (context) => OrderSuccessScreen(orderId: orderId),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error saving order: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error placing order. Please try again.',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }


  void _showOrderSummary() {
    if (_cartProducts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Your cart is empty',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    
    final outOfStockItems = <String>[];
    for (var entry in _cartProducts.entries) {
      final product = entry.value;
      final quantity = _cartQuantities[product.id] ?? 1;
      
      if (product.stock <= 0) {
        outOfStockItems.add(product.name);
      } else if (quantity > product.stock) {
        outOfStockItems.add('${product.name} (Requested: $quantity, Available: ${product.stock})');
      }
    }
    
    if (outOfStockItems.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Some items are out of stock:',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              ...outOfStockItems.map((item) => Text(
                '• $item',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.white,
                ),
              )),
            ],
          ),
          duration: const Duration(seconds: 4),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (_selectedAddress == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please select a shipping address',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    if (_selectedPaymentMethod == null && _selectedPaymentType != 'cod') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please select a payment method first',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildOrderSummarySheet(),
    );
  }

  Widget _buildOrderSummarySheet() {
    final total = _calculateTotal();

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return Column(
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
                padding: const EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Order Summary',
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      
                      _buildSummaryRow(
                        icon: Icons.person,
                        label: 'Customer',
                        value: _getUserName(),
                      ),
                      const SizedBox(height: 16),
                      
                      _buildSummaryRow(
                        icon: Icons.location_on,
                        label: 'Shipping Address',
                        value: '${_selectedAddress!.label}\n${_selectedAddress!.fullAddress}\n${_selectedAddress!.phone}',
                        isMultiLine: true,
                      ),
                      const SizedBox(height: 16),
                      
                      _buildSummaryRow(
                        icon: _selectedPaymentType == 'cod' 
                            ? Icons.money 
                            : Icons.credit_card,
                        label: 'Payment Method',
                        value: _selectedPaymentType == 'cod'
                            ? 'Cash on Delivery'
                            : _selectedPaymentMethod != null
                                ? '${_selectedPaymentMethod!.type.toUpperCase()}\n${_selectedPaymentMethod!.maskedCardNumber}'
                                : 'Not selected',
                        isMultiLine: _selectedPaymentMethod != null,
                      ),
                      const SizedBox(height: 16),
                      const SizedBox(height: 24),
                      
                      Text(
                        'Products',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ..._cartProducts.entries.map((entry) {
                        final product = entry.value;
                        final quantity = _cartQuantities[product.id] ?? 1;
                        return _buildProductSummaryItem(product, quantity);
                      }),
                      const SizedBox(height: 24),
                      const Divider(),
                      const SizedBox(height: 16),
                      
                      _buildPriceRow('Full Total Price', _calculateFullTotal()),
                      if (_calculateProductDiscounts() > 0) ...[
                        const SizedBox(height: 8),
                        _buildPriceRow(
                          'Product Discounts',
                          -_calculateProductDiscounts(),
                          isDiscount: true,
                        ),
                      ],
                      if (_calculatePromoDiscount() > 0) ...[
                        const SizedBox(height: 8),
                        _buildPriceRow(
                          'Promo Code Discount',
                          -_calculatePromoDiscount(),
                          isDiscount: true,
                          promoCode: _appliedPromoCode?.code,
                        ),
                      ],
                      if (_deliveryPrice > 0) ...[
                        const SizedBox(height: 8),
                        _buildPriceRow(
                          'Delivery Price',
                          _deliveryPrice,
                        ),
                      ],
                      const SizedBox(height: 12),
                      const Divider(),
                      const SizedBox(height: 12),
                      _buildPriceRow('Final Total', total, isTotal: true),
                      const SizedBox(height: 20),
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
                child: SafeArea(
                  child: SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () async {
                        Navigator.pop(context); 
                        await _saveOrderAndConfirm();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.amber,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Confirm Payment',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSummaryRow({
    required IconData icon,
    required String label,
    required String value,
    bool isMultiLine = false,
  }) {
    return Row(
      crossAxisAlignment: isMultiLine ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      children: [
        Icon(icon, color: AppColors.primary, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 4),
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
        ),
      ],
    );
  }

  Widget _buildProductSummaryItem(ProductModel product, int quantity) {
    final itemSubtotal = product.price * quantity;
    final itemOriginalPrice = product.originalPrice * quantity;
    final hasDiscount = product.discount > 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          
          Stack(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: product.imageUrl != null && product.imageUrl!.isNotEmpty
                      ? Image.network(
                          product.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(Icons.image_not_supported, color: Colors.grey[400]);
                          },
                        )
                      : Icon(Icons.image_not_supported, color: Colors.grey[400]),
                ),
              ),
              
              if (hasDiscount)
                Positioned(
                  top: 3,
                  left: 3,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(3),
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
                      '${product.discount.toStringAsFixed(0)}%',
                      style: GoogleFonts.poppins(
                        fontSize: 6,
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
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  'Qty: $quantity',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                
                if (hasDiscount) ...[
                  Row(
                    children: [
                      Text(
                        '\$${itemOriginalPrice.toStringAsFixed(2)}',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey[500],
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '\$${itemSubtotal.toStringAsFixed(2)}',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ] else
                  Text(
                    '\$${itemSubtotal.toStringAsFixed(2)}',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceRow(String label, double amount, {bool isDiscount = false, String? promoCode, bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            if (isDiscount && promoCode != null) ...[
              Text(
                '$label (${promoCode.toUpperCase()})',
                style: GoogleFonts.poppins(
                  fontSize: isTotal ? 16 : 14,
                  fontWeight: isTotal ? FontWeight.w700 : FontWeight.w500,
                  color: isDiscount ? AppColors.primary : Colors.black87,
                ),
              ),
            ] else
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: isTotal ? 16 : 14,
                  fontWeight: isTotal ? FontWeight.w700 : FontWeight.w500,
                  color: isDiscount ? AppColors.primary : Colors.black87,
                ),
              ),
          ],
        ),
        Text(
          '${isDiscount ? '-' : ''}\$${amount.abs().toStringAsFixed(2)}',
          style: GoogleFonts.poppins(
            fontSize: isTotal ? 18 : 14,
            fontWeight: isTotal ? FontWeight.w700 : FontWeight.w600,
            color: isTotal
                ? Colors.black87
                : (isDiscount ? AppColors.primary : Colors.black87),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomButton() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(20),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: _showOrderSummary,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.amber,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Confirm to Payment',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                if (_cartProducts.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '\$${_calculateTotalWithoutDelivery().toStringAsFixed(2)}',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

