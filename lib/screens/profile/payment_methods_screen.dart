import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/payment_method_model.dart';
import '../../services/payment_method_service.dart';
import '../../constants/app_colors.dart';

class PaymentMethodsScreen extends StatefulWidget {
  final bool allowSelection;
  
  const PaymentMethodsScreen({super.key, this.allowSelection = false});

  @override
  State<PaymentMethodsScreen> createState() => _PaymentMethodsScreenState();
}

class _PaymentMethodsScreenState extends State<PaymentMethodsScreen> {
  final PaymentMethodService _paymentMethodService = PaymentMethodService();
  List<PaymentMethodModel> _paymentMethods = [];
  bool _isLoading = true;
  String? _selectedPaymentMethod; 

  @override
  void initState() {
    super.initState();
    _loadPaymentMethods();
  }

  Future<void> _loadPaymentMethods() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final methods = await _paymentMethodService.getAllPaymentMethods();
      if (mounted) {
        setState(() {
          _paymentMethods = methods;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading payment methods: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _showAddEditDialog({PaymentMethodModel? paymentMethod}) async {
    final formKey = GlobalKey<FormState>();
    final cardNumberController = TextEditingController(
      text: paymentMethod?.cardNumber ?? '',
    );
    final cardHolderController = TextEditingController(
      text: paymentMethod?.cardHolderName ?? '',
    );
    final cvvController = TextEditingController(
      text: paymentMethod?.cvv ?? '',
    );
    String selectedType = paymentMethod?.type ?? 'visa';
    bool isDefault = paymentMethod?.isDefault ?? false;
    DateTime? selectedExpiryDate;
    
    
    if (paymentMethod?.expiryDate != null) {
      try {
        final parts = paymentMethod!.expiryDate.split('/');
        if (parts.length == 2) {
          final month = int.parse(parts[0]);
          final year = int.parse('20${parts[1]}');
          selectedExpiryDate = DateTime(year, month);
        }
      } catch (e) {
        debugPrint('Error parsing expiry date: $e');
      }
    }

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          backgroundColor: Colors.transparent,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400, maxHeight: 700),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            paymentMethod == null ? 'Add Payment Method' : 'Edit Payment Method',
                            style: GoogleFonts.poppins(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: Colors.black87,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.pop(context),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                    
                    Text(
                      'Card Type',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: selectedType,
                      decoration: InputDecoration(
                        hintText: 'Select card type',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppColors.primary, width: 2),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                      dropdownColor: Colors.white,
                      items: ['visa', 'mastercard']
                          .map((type) => DropdownMenuItem(
                                value: type,
                                child: Text(
                                  type.toUpperCase(),
                                  style: GoogleFonts.poppins(
                                    color: Colors.black87,
                                  ),
                                ),
                              ))
                          .toList(),
                      onChanged: (value) {
                        setDialogState(() {
                          selectedType = value!;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    Text(
                      'Card Number',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: cardNumberController,
                      decoration: InputDecoration(
                        hintText: '1234 5678 9012 3456',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppColors.primary, width: 2),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        filled: true,
                        fillColor: Colors.white,
                        prefixIcon: const Icon(Icons.credit_card, color: AppColors.primary),
                      ),
                      style: GoogleFonts.poppins(fontSize: 14),
                      keyboardType: TextInputType.number,
                      maxLength: 19,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter card number';
                        }
                        final cleaned = value.replaceAll(' ', '');
                        if (cleaned.length < 13 || cleaned.length > 19) {
                          return 'Invalid card number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    Text(
                      'Card Holder Name',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: cardHolderController,
                      decoration: InputDecoration(
                        hintText: 'John Doe',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppColors.primary, width: 2),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        filled: true,
                        fillColor: Colors.white,
                        prefixIcon: const Icon(Icons.person, color: AppColors.primary),
                      ),
                      style: GoogleFonts.poppins(fontSize: 14),
                      textCapitalization: TextCapitalization.words,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter card holder name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Expiry Date',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 8),
                              InkWell(
                                onTap: () async {
                                  final navigatorContext = context;
                                  final now = DateTime.now();
                                  final firstDate = DateTime(now.year, now.month);
                                  final lastDate = DateTime(now.year + 20, 12);
                                  
                                  final picked = await showDatePicker(
                                    context: navigatorContext,
                                    initialDate: selectedExpiryDate ?? firstDate,
                                    firstDate: firstDate,
                                    lastDate: lastDate,
                                    initialDatePickerMode: DatePickerMode.year,
                                    helpText: 'Select expiry date',
                                    builder: (context, child) {
                                      return Theme(
                                        data: Theme.of(context).copyWith(
                                          colorScheme: ColorScheme.light(
                                            primary: AppColors.primary,
                                            onPrimary: Colors.white,
                                            surface: Colors.white,
                                            onSurface: Colors.black87,
                                          ),
                                        ),
                                        child: child!,
                                      );
                                    },
                                  );
                                  
                                  if (picked != null && navigatorContext.mounted) {
                                    setDialogState(() {
                                      selectedExpiryDate = picked;
                                    });
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey[300]!),
                                    borderRadius: BorderRadius.circular(12),
                                    color: Colors.white,
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.calendar_today, color: AppColors.primary, size: 20),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          selectedExpiryDate != null
                                              ? '${selectedExpiryDate!.month.toString().padLeft(2, '0')}/${selectedExpiryDate!.year.toString().substring(2)}'
                                              : 'MM/YY',
                                          style: GoogleFonts.poppins(
                                            fontSize: 14,
                                            color: selectedExpiryDate != null
                                                ? Colors.black87
                                                : Colors.grey[400],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'CVV',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: cvvController,
                                decoration: InputDecoration(
                                  hintText: '123',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: Colors.grey[300]!),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: Colors.grey[300]!),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: AppColors.primary, width: 2),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                  filled: true,
                                  fillColor: Colors.white,
                                  prefixIcon: const Icon(Icons.lock, color: AppColors.primary),
                                ),
                                style: GoogleFonts.poppins(fontSize: 14),
                                keyboardType: TextInputType.number,
                                maxLength: 4,
                                obscureText: true,
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Required';
                                  }
                                  if (value.length < 3) {
                                    return 'Invalid CVV';
                                  }
                                  return null;
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: StatefulBuilder(
                        builder: (context, setCheckboxState) => CheckboxListTile(
                          title: Text(
                            'Set as default payment method',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          value: isDefault,
                          onChanged: (value) {
                            setCheckboxState(() {
                              isDefault = value ?? false;
                            });
                            setDialogState(() {
                              isDefault = value ?? false;
                            });
                          },
                          contentPadding: EdgeInsets.zero,
                          activeColor: AppColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              side: BorderSide(color: Colors.grey[300]!),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              'Cancel',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[700],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            onPressed: () async {
                              if (formKey.currentState!.validate()) {
                                if (selectedExpiryDate == null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Please select expiry date',
                                        style: GoogleFonts.poppins(),
                                      ),
                                      backgroundColor: AppColors.error,
                                    ),
                                  );
                                  return;
                                }
                                
                                final expiryDateStr = '${selectedExpiryDate!.month.toString().padLeft(2, '0')}/${selectedExpiryDate!.year.toString().substring(2)}';
                                
                                Navigator.pop(context);
                                await _savePaymentMethod(
                                  paymentMethod: paymentMethod,
                                  type: selectedType,
                                  cardNumber: cardNumberController.text.replaceAll(' ', ''),
                                  cardHolderName: cardHolderController.text.trim(),
                                  expiryDate: expiryDateStr,
                                  cvv: cvvController.text.trim(),
                                  isDefault: isDefault,
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              paymentMethod == null ? 'Add Payment' : 'Update Payment',
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ),
    );
  }

  Future<void> _savePaymentMethod({
    PaymentMethodModel? paymentMethod,
    required String type,
    required String cardNumber,
    required String cardHolderName,
    required String expiryDate,
    required String cvv,
    required bool isDefault,
  }) async {
    try {
      if (paymentMethod == null) {
        
        await _paymentMethodService.addPaymentMethod(
          PaymentMethodModel(
            type: type,
            cardNumber: cardNumber,
            cardHolderName: cardHolderName,
            expiryDate: expiryDate,
            cvv: cvv,
            isDefault: isDefault,
          ),
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Payment method added successfully',
                style: GoogleFonts.poppins(),
              ),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } else {
        
        await _paymentMethodService.updatePaymentMethod(
          paymentMethod.copyWith(
            type: type,
            cardNumber: cardNumber,
            cardHolderName: cardHolderName,
            expiryDate: expiryDate,
            cvv: cvv,
            isDefault: isDefault,
          ),
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Payment method updated successfully',
                style: GoogleFonts.poppins(),
              ),
              backgroundColor: AppColors.success,
            ),
          );
        }
      }
      _loadPaymentMethods();
    } catch (e) {
      debugPrint('Error saving payment method: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error: ${e.toString()}',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _deletePaymentMethod(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          'Delete Payment Method',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Are you sure you want to delete this payment method?',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: GoogleFonts.poppins()),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: Text(
              'Delete',
              style: GoogleFonts.poppins(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _paymentMethodService.deletePaymentMethod(id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Payment method deleted successfully',
                style: GoogleFonts.poppins(),
              ),
              backgroundColor: AppColors.success,
            ),
          );
        }
        _loadPaymentMethods();
      } catch (e) {
        debugPrint('Error deleting payment method: $e');
      }
    }
  }

  Widget _getPaymentMethodIcon(String type) {
    switch (type.toLowerCase()) {
      case 'visa':
        return Image.asset(
          'assets/images/visa.png',
          width: 40,
          height: 24,
          errorBuilder: (context, error, stackTrace) => const Icon(Icons.credit_card, size: 24),
        );
      case 'mastercard':
        return Image.asset(
          'assets/images/mastercard.png',
          width: 40,
          height: 24,
          errorBuilder: (context, error, stackTrace) => const Icon(Icons.credit_card, size: 24),
        );
      default:
        return const Icon(Icons.credit_card, size: 24);
    }
  }

  Widget _buildCardDesign({
    required PaymentMethodModel method,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    
    String backgroundImage;
    if (method.type.toLowerCase() == 'visa') {
      backgroundImage = 'assets/images/visa.png';
    } else if (method.type.toLowerCase() == 'mastercard') {
      backgroundImage = 'assets/images/masterCard.png';
    } else {
      
      backgroundImage = 'assets/images/visa.png';
    }

    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        height: 200,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              
              Positioned.fill(
                child: Image.asset(
                  backgroundImage,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    
                    return Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: isSelected
                              ? [AppColors.primary, AppColors.primaryDark]
                              : [Colors.grey[800]!, Colors.grey[900]!],
                        ),
                      ),
                    );
                  },
                ),
              ),
              
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: isSelected ? 0.1 : 0.3),
                  ),
                ),
              ),
              
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.credit_card,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                    Row(
                  children: [
                    GestureDetector(
                      onTap: () => _deletePaymentMethod(method.id!),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.delete_outline,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    widget.allowSelection ? Radio<String>(
                      value: '${method.id}',
                      groupValue: _selectedPaymentMethod,
                      onChanged: (value) {
                        setState(() {
                          _selectedPaymentMethod = value;
                        });
                      },
                      activeColor: Colors.white,
                      fillColor: WidgetStateProperty.all(Colors.white),
                    ): Container(),
                  ],
                ),
              ],
            ),
            const Spacer(),
            Text(
              method.maskedCardNumber,
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.white,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'CARDHOLDER',
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        color: Colors.white.withValues(alpha: 0.7),
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      method.cardHolderName.toUpperCase(),
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'EXPIRES',
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        color: Colors.white.withValues(alpha: 0.7),
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      method.expiryDate,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ],
            ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAddCardItem() {
    return InkWell(
      onTap: () {
        _showAddEditDialog();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            bottom: BorderSide(color: Colors.grey[200]!),
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.credit_card, size: 24, color: Colors.black87),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                'Credit or Debit card',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
            ),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.add,
                color: Colors.white,
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethodItem({
    required String id,
    required String title,
    required String? subtitle,
    required IconData icon,
    required bool isSelected,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            bottom: BorderSide(color: Colors.grey[200]!),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 24, color: Colors.black87),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            widget.allowSelection ? Radio<String>(
              value: id,
              groupValue: _selectedPaymentMethod,
              onChanged: (value) {
                setState(() {
                  _selectedPaymentMethod = value;
                });
              },
              activeColor: Colors.black,
            ): Container(),
          ],
        ),
      ),
    );
  }

  Widget _buildCardForm() {
    final formKey = GlobalKey<FormState>();
    final cardNumberController = TextEditingController();
    final expiryController = TextEditingController();
    final cvvController = TextEditingController();
    final cardHolderController = TextEditingController();
    bool saveCard = false;

    return StatefulBuilder(
      builder: (context, setFormState) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
      child: Form(
        key: formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Card number',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: cardNumberController,
              decoration: InputDecoration(
                hintText: '1234 5678 9012 3456',
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
                  borderSide: BorderSide(color: Colors.black, width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                suffixIcon: const Icon(Icons.credit_card, size: 20),
              ),
              keyboardType: TextInputType.number,
              maxLength: 19,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter card number';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'MM/YY',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: expiryController,
                        decoration: InputDecoration(
                          hintText: '12/26',
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
                            borderSide: BorderSide(color: Colors.black, width: 2),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        maxLength: 5,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Required';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'CVC/CVV',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(Icons.info_outline, size: 16, color: Colors.grey[600]),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: cvvController,
                        decoration: InputDecoration(
                          hintText: '123',
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
                            borderSide: BorderSide(color: Colors.black, width: 2),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        keyboardType: TextInputType.number,
                        maxLength: 4,
                        obscureText: true,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Required';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Cardholder name',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: cardHolderController,
              decoration: InputDecoration(
                hintText: 'John Smith',
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
                  borderSide: BorderSide(color: Colors.black, width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              textCapitalization: TextCapitalization.words,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter cardholder name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            StatefulBuilder(
              builder: (context, setCheckboxState) => CheckboxListTile(
                title: Text(
                  'Save card for future payment',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                ),
                value: saveCard,
                onChanged: (value) {
                  setCheckboxState(() {
                    saveCard = value ?? false;
                  });
                  setFormState(() {
                    saveCard = value ?? false;
                  });
                },
                contentPadding: EdgeInsets.zero,
                activeColor: Colors.black,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () {
                    setState(() {
                      _selectedPaymentMethod = null;
                    });
                  },
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () {
                    if (formKey.currentState!.validate()) {
                      
                      if (saveCard) {
                        _saveCardFromForm(
                          cardNumber: cardNumberController.text.replaceAll(' ', ''),
                          expiryDate: expiryController.text.trim(),
                          cvv: cvvController.text.trim(),
                          cardHolderName: cardHolderController.text.trim(),
                        );
                      }
                      setState(() {
                        
                      });
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'Save',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
    );
  }

  Future<void> _saveCardFromForm({
    required String cardNumber,
    required String expiryDate,
    required String cvv,
    required String cardHolderName,
  }) async {
    try {
      
      String cardType = 'visa'; 
      if (cardNumber.isNotEmpty) {
        final firstDigit = cardNumber[0];
        if (firstDigit == '4') {
          cardType = 'visa';
        } else if (firstDigit == '5') {
          cardType = 'mastercard';
        }
        
      }

      await _paymentMethodService.addPaymentMethod(
        PaymentMethodModel(
          type: cardType,
          cardNumber: cardNumber,
          cardHolderName: cardHolderName,
          expiryDate: expiryDate,
          cvv: cvv,
          isDefault: false,
        ),
      );
      _loadPaymentMethods();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Card saved successfully',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error saving card: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.account_balance_wallet, size: 20, color: AppColors.primary),
            ),
            const SizedBox(width: 12),
            Text(
              'Payment list',
              style: GoogleFonts.poppins(
                color: Colors.black,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
                              child: Text(
                                'Payment methods',
                                style: GoogleFonts.poppins(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                            
                            _buildAddCardItem(),
                            
                            _buildPaymentMethodItem(
                              id: 'cod',
                              title: 'Cash on Delivery',
                              subtitle: 'Pay when you receive',
                              icon: Icons.money,
                              isSelected: _selectedPaymentMethod == 'cod',
                              onTap: () {
                                setState(() {
                                  _selectedPaymentMethod = 'cod';
                                });
                              },
                            ),
                            
                            ..._paymentMethods.map((method) {
                              return _buildCardDesign(
                                method: method,
                                isSelected: _selectedPaymentMethod == '${method.id}',
                                onTap: () {
                                  setState(() {
                                    _selectedPaymentMethod = '${method.id}';
                                  });
                                },
                              );
                            }),
                            if (_paymentMethods.isEmpty)
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: Center(
                                  child: Column(
                                    children: [
                                      Icon(
                                        Icons.credit_card_off,
                                        size: 64,
                                        color: Colors.grey[400],
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        'No saved cards',
                                        style: GoogleFonts.poppins(
                                          fontSize: 16,
                                          color: Colors.grey[700],
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Add cards from Bank & Card Info',
                                        style: GoogleFonts.poppins(
                                          fontSize: 12,
                                          color: Colors.grey[500],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
      bottomNavigationBar: widget.allowSelection && _selectedPaymentMethod != null
          ? Container(
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
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {
                      if (_selectedPaymentMethod != null) {
                        if (_selectedPaymentMethod == 'cod') {
                          Navigator.pop(context, 'cod');
                        } else {
                          
                          final selectedMethod = _paymentMethods.firstWhere(
                            (method) => '${method.id}' == _selectedPaymentMethod,
                          );
                          Navigator.pop(context, selectedMethod);
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.amber,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'Select Payment Method',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            )
          : null,
    );
  }
}

