import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/promo_code_model.dart';
import '../constants/app_colors.dart';
import 'promo_code_service.dart';

class AdminPromoCodesScreen extends StatefulWidget {
  const AdminPromoCodesScreen({super.key});

  @override
  State<AdminPromoCodesScreen> createState() => _AdminPromoCodesScreenState();
}

class _AdminPromoCodesScreenState extends State<AdminPromoCodesScreen> {
  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _discountController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  
  String? _editingPromoCodeId;
  bool _isLoading = false;
  bool _isPercentage = true;
  bool _isActive = true;
  DateTime? _validFrom;
  DateTime? _validUntil;

  @override
  void dispose() {
    _codeController.dispose();
    _discountController.dispose();
    super.dispose();
  }

  Future<void> _showAddEditDialog({PromoCodeModel? promoCode}) async {
    _editingPromoCodeId = promoCode?.id;
    _codeController.text = promoCode?.code ?? '';
    _discountController.text = promoCode?.discountValue.toString() ?? '';
    _isPercentage = promoCode?.isPercentage ?? true;
    _isActive = promoCode?.isActive ?? true;
    _validFrom = promoCode?.validFrom;
    _validUntil = promoCode?.validUntil;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400, maxHeight: 700),
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  promoCode == null ? 'Add Promo Code' : 'Edit Promo Code',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 20),
                Flexible(
                  child: SingleChildScrollView(
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextFormField(
                            controller: _codeController,
                            decoration: InputDecoration(
                              labelText: 'Promo Code',
                              hintText: 'e.g., SAVE20',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              prefixIcon: const Icon(Icons.local_offer),
                            ),
                            style: GoogleFonts.poppins(),
                            textCapitalization: TextCapitalization.characters,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter promo code';
                              }
                              if (value.trim().length < 3) {
                                return 'Promo code must be at least 3 characters';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _discountController,
                                  decoration: InputDecoration(
                                    labelText: 'Discount Value',
                                    hintText: _isPercentage ? 'e.g., 20' : 'e.g., 50',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    prefixIcon: const Icon(Icons.percent),
                                    suffixText: _isPercentage ? '%' : '\$',
                                  ),
                                  keyboardType: TextInputType.number,
                                  style: GoogleFonts.poppins(),
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Please enter discount value';
                                    }
                                    final discount = double.tryParse(value);
                                    if (discount == null) {
                                      return 'Please enter a valid number';
                                    }
                                    if (discount <= 0) {
                                      return 'Discount must be greater than 0';
                                    }
                                    if (_isPercentage && discount > 100) {
                                      return 'Percentage cannot exceed 100';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              Expanded(
                                child: CheckboxListTile(
                                  title: Text(
                                    'Percentage Discount',
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                    ),
                                  ),
                                  value: _isPercentage,
                                  onChanged: (value) {
                                    setDialogState(() {
                                      _isPercentage = value ?? true;
                                    });
                                  },
                                  contentPadding: EdgeInsets.zero,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: CheckboxListTile(
                                  title: Text(
                                    'Active',
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                    ),
                                  ),
                                  value: _isActive,
                                  onChanged: (value) {
                                    setDialogState(() {
                                      _isActive = value ?? true;
                                    });
                                  },
                                  contentPadding: EdgeInsets.zero,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'Valid From (Optional)',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          InkWell(
                            onTap: () async {
                              final navigatorContext = context;
                              final date = await showDatePicker(
                                context: navigatorContext,
                                initialDate: _validFrom ?? DateTime.now(),
                                firstDate: DateTime.now().subtract(const Duration(days: 365)),
                                lastDate: DateTime.now().add(const Duration(days: 365)),
                              );
                              if (date != null && navigatorContext.mounted) {
                                final time = await showTimePicker(
                                  context: navigatorContext,
                                  initialTime: TimeOfDay.fromDateTime(_validFrom ?? DateTime.now()),
                                );
                                if (time != null) {
                                  setDialogState(() {
                                    _validFrom = DateTime(
                                      date.year,
                                      date.month,
                                      date.day,
                                      time.hour,
                                      time.minute,
                                    );
                                  });
                                }
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey[300]!),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.calendar_today, color: Colors.grey[600]),
                                  const SizedBox(width: 12),
                                  Text(
                                    _validFrom != null
                                        ? '${_validFrom!.day}/${_validFrom!.month}/${_validFrom!.year} ${_validFrom!.hour}:${_validFrom!.minute.toString().padLeft(2, '0')}'
                                        : 'Select date and time',
                                    style: GoogleFonts.poppins(
                                      color: _validFrom != null ? Colors.black87 : Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          if (_validFrom != null) ...[
                            const SizedBox(height: 8),
                            TextButton(
                              onPressed: () {
                                setDialogState(() {
                                  _validFrom = null;
                                });
                              },
                              child: Text(
                                'Clear',
                                style: GoogleFonts.poppins(
                                  color: AppColors.error,
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 20),
                          Text(
                            'Valid Until (Optional)',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          InkWell(
                            onTap: () async {
                              final navigatorContext = context;
                              final date = await showDatePicker(
                                context: navigatorContext,
                                initialDate: _validUntil ?? DateTime.now().add(const Duration(days: 30)),
                                firstDate: DateTime.now(),
                                lastDate: DateTime.now().add(const Duration(days: 365)),
                              );
                              if (date != null && navigatorContext.mounted) {
                                final time = await showTimePicker(
                                  context: navigatorContext,
                                  initialTime: TimeOfDay.fromDateTime(_validUntil ?? DateTime.now()),
                                );
                                if (time != null) {
                                  setDialogState(() {
                                    _validUntil = DateTime(
                                      date.year,
                                      date.month,
                                      date.day,
                                      time.hour,
                                      time.minute,
                                    );
                                  });
                                }
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey[300]!),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.calendar_today, color: Colors.grey[600]),
                                  const SizedBox(width: 12),
                                  Text(
                                    _validUntil != null
                                        ? '${_validUntil!.day}/${_validUntil!.month}/${_validUntil!.year} ${_validUntil!.hour}:${_validUntil!.minute.toString().padLeft(2, '0')}'
                                        : 'Select date and time',
                                    style: GoogleFonts.poppins(
                                      color: _validUntil != null ? Colors.black87 : Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          if (_validUntil != null) ...[
                            const SizedBox(height: 8),
                            TextButton(
                              onPressed: () {
                                setDialogState(() {
                                  _validUntil = null;
                                });
                              },
                              child: Text(
                                'Clear',
                                style: GoogleFonts.poppins(
                                  color: AppColors.error,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        _codeController.clear();
                        _discountController.clear();
                        _editingPromoCodeId = null;
                        _validFrom = null;
                        _validUntil = null;
                      },
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.poppins(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () async {
                        if (_formKey.currentState!.validate()) {
                          Navigator.of(context).pop();
                          await _savePromoCode();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        promoCode == null ? 'Add' : 'Update',
                        style: GoogleFonts.poppins(
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
      ),
    );
  }

  Future<void> _savePromoCode() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final code = _codeController.text.trim().toUpperCase();
      final discountValue = double.parse(_discountController.text.trim());

      
      if (_editingPromoCodeId == null) {
        final exists = await PromoCodeService.promoCodeExists(code);
        if (exists) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Promo code "$code" already exists',
                  style: GoogleFonts.poppins(),
                ),
                backgroundColor: AppColors.error,
              ),
            );
          }
          setState(() {
            _isLoading = false;
          });
          return;
        }
      }

      if (_editingPromoCodeId == null) {
        
        await PromoCodeService.addPromoCode(
          code: code,
          discountValue: discountValue,
          isPercentage: _isPercentage,
          isActive: _isActive,
          validFrom: _validFrom,
          validUntil: _validUntil,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Promo code added successfully',
                style: GoogleFonts.poppins(),
              ),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } else {
        
        await PromoCodeService.updatePromoCode(
          id: _editingPromoCodeId!,
          code: code,
          discountValue: discountValue,
          isPercentage: _isPercentage,
          isActive: _isActive,
          validFrom: _validFrom,
          validUntil: _validUntil,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Promo code updated successfully',
                style: GoogleFonts.poppins(),
              ),
              backgroundColor: AppColors.success,
            ),
          );
        }
      }

      
      _codeController.clear();
      _discountController.clear();
      _editingPromoCodeId = null;
      _validFrom = null;
      _validUntil = null;
    } catch (e) {
      debugPrint('Error saving promo code: $e');
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
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _deletePromoCode(String id, String code) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          'Delete Promo Code',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          'Are you sure you want to delete "$code"? This action cannot be undone.',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Delete',
              style: GoogleFonts.poppins(
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await PromoCodeService.deletePromoCode(id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Promo code deleted successfully',
                style: GoogleFonts.poppins(),
              ),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } catch (e) {
        debugPrint('Error deleting promo code: $e');
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        title: Text(
          'Promo Codes',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : StreamBuilder<List<PromoCodeModel>>(
              stream: PromoCodeService.getPromoCodesStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
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
                          'Error loading promo codes',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final promoCodes = snapshot.data ?? [];

                if (promoCodes.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.local_offer_outlined,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No promo codes yet',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            color: Colors.grey[700],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tap the + button to add one',
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
                  padding: const EdgeInsets.all(16),
                  itemCount: promoCodes.length,
                  itemBuilder: (context, index) {
                    final promoCode = promoCodes[index];
                    final isExpired = promoCode.validUntil != null &&
                        promoCode.validUntil!.isBefore(DateTime.now());
                    final isNotStarted = promoCode.validFrom != null &&
                        promoCode.validFrom!.isAfter(DateTime.now());

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        leading: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: promoCode.isActive && !isExpired && !isNotStarted
                                ? AppColors.primary.withValues(alpha: 0.1)
                                : Colors.grey[200],
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.local_offer,
                            color: promoCode.isActive && !isExpired && !isNotStarted
                                ? AppColors.primary
                                : Colors.grey[600],
                            size: 24,
                          ),
                        ),
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(
                                promoCode.code,
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                            if (!promoCode.isActive || isExpired || isNotStarted)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.grey[300],
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  !promoCode.isActive
                                      ? 'Inactive'
                                      : isExpired
                                          ? 'Expired'
                                          : 'Not Started',
                                  style: GoogleFonts.poppins(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey[700],
                                  ),
                                ),
                              ),
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 8),
                            Text(
                              'Discount: ${promoCode.discountValue.toStringAsFixed(promoCode.isPercentage ? 0 : 2)}${promoCode.isPercentage ? '%' : '\$'}',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: Colors.grey[700],
                              ),
                            ),
                            if (promoCode.validFrom != null || promoCode.validUntil != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                promoCode.validFrom != null && promoCode.validUntil != null
                                    ? 'Valid: ${_formatDate(promoCode.validFrom!)} - ${_formatDate(promoCode.validUntil!)}'
                                    : promoCode.validFrom != null
                                        ? 'Starts: ${_formatDate(promoCode.validFrom!)}'
                                        : 'Expires: ${_formatDate(promoCode.validUntil!)}',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: AppColors.primary),
                              onPressed: () => _showAddEditDialog(promoCode: promoCode),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: AppColors.error),
                              onPressed: () => _deletePromoCode(promoCode.id!, promoCode.code),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditDialog(),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

