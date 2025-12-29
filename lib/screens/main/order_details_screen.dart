import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/order_model.dart';
import '../../services/order_service.dart';
import '../../constants/app_colors.dart';
import 'main_navigation_screen.dart';

class OrderDetailsScreen extends StatefulWidget {
  final String orderId;
  final bool showHomeButton; 

  const OrderDetailsScreen({
    super.key,
    required this.orderId,
    this.showHomeButton = false, 
  });

  @override
  State<OrderDetailsScreen> createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends State<OrderDetailsScreen> {
  OrderModel? _order;
  bool _isLoading = true;
  bool _isCancelling = false;

  @override
  void initState() {
    super.initState();
    _loadOrder();
  }

  Future<void> _loadOrder() async {
    try {
      debugPrint('Loading order details for ID: ${widget.orderId}');
      final order = await OrderService.getOrderById(widget.orderId);
      debugPrint('Order loaded: ${order != null ? "Found" : "Not found"}');
      if (mounted) {
        setState(() {
          _order = order;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading order: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
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
        leading: widget.showHomeButton
            ? IconButton(
                icon: const Icon(Icons.home, color: Colors.black),
                onPressed: () {
                  
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(
                      builder: (context) => const MainNavigationScreen(),
                    ),
                    (route) => false,
                  );
                },
              )
            : IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black),
                onPressed: () => Navigator.of(context).pop(),
              ),
        title: Text(
          'Order Details',
          style: GoogleFonts.poppins(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _order == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Order not found',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: _getStatusColor(_order!.status).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _getStatusColor(_order!.status),
                            width: 2,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _getStatusIcon(_order!.status),
                              color: _getStatusColor(_order!.status),
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Order Status',
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _order!.status.toUpperCase(),
                                    style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: _getStatusColor(_order!.status),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      
                      _buildDetailRow('Order ID', '#${_order!.id}'),
                      const SizedBox(height: 16),
                      
                      _buildDetailRow('Customer', _order!.userName),
                      const SizedBox(height: 16),
                      
                      _buildDetailRow('Shipping Address', _order!.shippingAddress, isMultiLine: true),
                      const SizedBox(height: 16),
                      
                      _buildDetailRow('Phone Number', _order!.phoneNumber),
                      const SizedBox(height: 16),
                      
                      _buildDetailRow('Payment Method', _order!.paymentMethod),
                      const SizedBox(height: 20),
                      
                      Text(
                        'Products',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ..._order!.products.map((product) => _buildProductItem(product)),
                      const SizedBox(height: 20),
                      const Divider(),
                      const SizedBox(height: 16),
                      
                      _buildPriceRow('Full Total Price', _order!.totalPrice),
                      if (_order!.productDiscount > 0) ...[
                        const SizedBox(height: 8),
                        _buildPriceRow('Product Discounts', -_order!.productDiscount, isDiscount: true),
                      ],
                      if (_order!.promoCodeDiscount > 0) ...[
                        const SizedBox(height: 8),
                        _buildPriceRow(
                          'Promo Code Discount',
                          -_order!.promoCodeDiscount,
                          isDiscount: true,
                          promoCode: _order!.promoCode,
                        ),
                      ],
                      if (_order!.deliveryFee > 0) ...[
                        const SizedBox(height: 8),
                        _buildPriceRow('Delivery Fee', _order!.deliveryFee),
                      ],
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 16),
                      _buildPriceRow('Final Total', _order!.finalTotal, isTotal: true),
                      const SizedBox(height: 20),
                      
                      _buildDetailRow(
                        'Order Date',
                        '${_order!.createdAt.day}/${_order!.createdAt.month}/${_order!.createdAt.year} ${_order!.createdAt.hour.toString().padLeft(2, '0')}:${_order!.createdAt.minute.toString().padLeft(2, '0')}',
                      ),
                      const SizedBox(height: 20),
                      
                      if (_order!.status.toLowerCase() == 'pending') ...[
                        ElevatedButton(
                          onPressed: _isCancelling ? null : _cancelOrder,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.error,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            minimumSize: const Size(double.infinity, 50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: _isCancelling
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.cancel_outlined, size: 20),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Cancel Order',
                                      style: GoogleFonts.poppins(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ],
                    ],
                  ),
                ),
    );
  }

  Future<void> _cancelOrder() async {
    if (_order == null) return;

    
    if (!mounted) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          'Cancel Order',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          'Are you sure you want to cancel this order? This action cannot be undone.',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'No',
              style: GoogleFonts.poppins(
                color: Colors.grey[600],
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: Text(
              'Yes, Cancel',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    if (!mounted) return;
    setState(() {
      _isCancelling = true;
    });

    try {
      final success = await OrderService.updateOrderStatus(
        _order!.id!,
        _order!.status,
        'cancelled',
      );

      if (!mounted) return;

      if (success) {
        
        await _loadOrder();
        
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Order cancelled successfully',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 2),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to cancel order. Please try again.',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error cancelling order: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error cancelling order: ${e.toString()}',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCancelling = false;
        });
      }
    }
  }

  Widget _buildDetailRow(String label, String value, {bool isMultiLine = false}) {
    return Row(
      crossAxisAlignment: isMultiLine ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.black87,
            ),
            maxLines: isMultiLine ? null : 1,
            overflow: isMultiLine ? null : TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildProductItem(OrderProduct product) {
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
          
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
            ),
            child: product.imageUrl != null && product.imageUrl!.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      product.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => const Icon(
                        Icons.image_not_supported_rounded,
                        color: Colors.grey,
                      ),
                    ),
                  )
                : const Icon(Icons.image_not_supported_rounded, color: Colors.grey),
          ),
          const SizedBox(width: 12),
          
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.productName,
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
                  'Quantity: ${product.quantity}',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (hasDiscount) ...[
                      Text(
                        '\$${(product.originalPrice * product.quantity).toStringAsFixed(2)}',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          decoration: TextDecoration.lineThrough,
                          color: Colors.grey[500],
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      '\$${(product.price * product.quantity).toStringAsFixed(2)}',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                    if (hasDiscount) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '-${product.discount.toStringAsFixed(0)}%',
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            color: AppColors.error,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceRow(String label, double amount, {bool isDiscount = false, bool isTotal = false, String? promoCode}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: isTotal ? 18 : 14,
            fontWeight: isTotal ? FontWeight.w700 : FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        Row(
          children: [
            if (promoCode != null) ...[
              Text(
                '($promoCode) ',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
            Text(
              isDiscount ? '-\$${amount.abs().toStringAsFixed(2)}' : '\$${amount.toStringAsFixed(2)}',
              style: GoogleFonts.poppins(
                fontSize: isTotal ? 18 : 14,
                fontWeight: FontWeight.w700,
                color: isTotal
                    ? AppColors.primary
                    : (isDiscount ? AppColors.success : Colors.black87),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'confirmed':
        return Colors.blue;
      case 'shipped':
        return Colors.purple;
      case 'delivered':
        return AppColors.success;
      case 'cancelled':
        return AppColors.error;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Icons.pending;
      case 'confirmed':
        return Icons.check_circle_outline;
      case 'shipped':
        return Icons.local_shipping;
      case 'delivered':
        return Icons.check_circle;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.info;
    }
  }
}

