import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/product_model.dart';
import '../models/category_model.dart';
import '../constants/app_colors.dart';
import 'product_service.dart';
import 'category_service.dart';

class AdminProductsScreen extends StatefulWidget {
  const AdminProductsScreen({super.key});

  @override
  State<AdminProductsScreen> createState() => _AdminProductsScreenState();
}

class _AdminProductsScreenState extends State<AdminProductsScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _originalPriceController = TextEditingController();
  final TextEditingController _discountController = TextEditingController();
  final TextEditingController _stockController = TextEditingController();
  final TextEditingController _imageUrlController = TextEditingController();
  final TextEditingController _imageUrl1Controller = TextEditingController();
  final TextEditingController _imageUrl2Controller = TextEditingController();
  final TextEditingController _imageUrl3Controller = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _imagePicker = ImagePicker();
  
  String? _editingProductId;
  String? _oldCategoryName; 
  bool _isLoading = false;
  String? _selectedCategoryId;
  String? _selectedCategoryName;
  bool _isActive = true;
  bool _isRecommended = false; 
  List<CategoryModel> _categories = [];
  File? _selectedImage;
  String? _imageUrl; 

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final categories = await CategoryService.getCategories();
      if (mounted) {
        setState(() {
          _categories = categories;
        });
      }
    } catch (e) {
      debugPrint('Error loading categories: $e');
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _originalPriceController.dispose();
    _discountController.dispose();
    _stockController.dispose();
    _imageUrlController.dispose();
    _imageUrl1Controller.dispose();
    _imageUrl2Controller.dispose();
    _imageUrl3Controller.dispose();
    super.dispose();
  }

  
  void _calculateAndUpdatePrice(StateSetter setDialogState) {
    setDialogState(() {
      
    });
  }

  Future<void> _pickImage(StateSetter? setDialogState) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      
      if (image != null) {
        if (setDialogState != null) {
          setDialogState(() {
            _selectedImage = File(image.path);
            _imageUrl = null; 
            _imageUrlController.clear(); 
          });
        } else {
          setState(() {
            _selectedImage = File(image.path);
            _imageUrl = null; 
            _imageUrlController.clear(); 
          });
        }
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
      if (mounted) {
        String errorMessage = 'Failed to pick image';
        
        
        final errorString = e.toString().toLowerCase();
        if (errorString.contains('permission') || errorString.contains('denied')) {
          errorMessage = 'Permission denied. Please grant photo library access in app settings.';
        } else if (errorString.contains('channel') || errorString.contains('connection')) {
          errorMessage = 'Image picker error. Please restart the app and try again.';
        } else {
          errorMessage = 'Error picking image: ${e.toString()}';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              errorMessage,
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  Future<String?> _uploadImageToFirebase() async {
    if (_selectedImage == null) {
      return _imageUrl; 
    }

    try {
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('products')
          .child('${DateTime.now().millisecondsSinceEpoch}.jpg');

      await storageRef.putFile(_selectedImage!);
      final downloadUrl = await storageRef.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      debugPrint('Error uploading image: $e');
      throw Exception('Failed to upload image: ${e.toString()}');
    }
  }

  Future<void> _showAddEditDialog({ProductModel? product}) async {
    
    await _loadCategories();
    
    if (!mounted) return;
    
    _editingProductId = product?.id;
    _oldCategoryName = product?.categoryName; 
    _nameController.text = product?.name ?? '';
    _descriptionController.text = product?.description ?? '';
    _originalPriceController.text = product?.originalPrice.toStringAsFixed(2) ?? '';
    _discountController.text = product?.discount.toStringAsFixed(0) ?? '';
    _stockController.text = product?.stock.toString() ?? '1';
    
    if (product?.categoryName != null) {
      final matchingCategory = _categories.firstWhere(
        (c) => c.name == product!.categoryName,
        orElse: () => _categories.isNotEmpty ? _categories.first : CategoryModel(name: '', iconName: ''),
      );
      _selectedCategoryId = matchingCategory.id;
      _selectedCategoryName = product?.categoryName;
    } else {
      _selectedCategoryId = null;
      _selectedCategoryName = null;
    }
    _isActive = product?.isActive ?? true;
    _isRecommended = product != null ? (product.isRecommended) : false;
    
    if (product == null) {
      _imageUrl = null;
      _imageUrlController.clear();
      _imageUrl1Controller.clear();
      _imageUrl2Controller.clear();
      _imageUrl3Controller.clear();
      _selectedImage = null;
    } else {
      _imageUrl = product.imageUrl;
      _imageUrlController.text = product.imageUrl ?? '';
      
      if (product.imageUrls.isNotEmpty) {
        _imageUrl1Controller.text = product.imageUrls.isNotEmpty ? product.imageUrls[0] : '';
        _imageUrl2Controller.text = product.imageUrls.length > 1 ? product.imageUrls[1] : '';
        _imageUrl3Controller.text = product.imageUrls.length > 2 ? product.imageUrls[2] : '';
      } else if (product.imageUrl != null && product.imageUrl!.isNotEmpty) {
        
        _imageUrl1Controller.text = product.imageUrl!;
      }
      _selectedImage = null; 
    }

    
    final categories = List<CategoryModel>.from(_categories);

    if (!mounted) return;
    
    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 500, maxHeight: 700),
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      product == null ? 'Add Product' : 'Edit Product',
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
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
                            controller: _nameController,
                            decoration: InputDecoration(
                              labelText: 'Product Name',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              prefixIcon: const Icon(Icons.shopping_bag),
                            ),
                            style: GoogleFonts.poppins(),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter product name';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          
                          DropdownButtonFormField<String>(
                            value: _selectedCategoryId,
                            decoration: InputDecoration(
                              labelText: 'Category',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              prefixIcon: _selectedCategoryId != null &&
                                      categories.any((c) => c.id == _selectedCategoryId)
                                  ? Icon(
                                      categories
                                          .firstWhere((c) => c.id == _selectedCategoryId)
                                          .getIcon(),
                                      color: AppColors.primary,
                                    )
                                  : const Icon(Icons.category),
                            ),
                            dropdownColor: Colors.white,
                            style: GoogleFonts.poppins(
                              color: Colors.black87,
                              fontSize: 16,
                            ),
                            items: categories.isEmpty
                                ? [
                                    DropdownMenuItem(
                                      value: null,
                                      child: Text(
                                        'No categories available',
                                        style: GoogleFonts.poppins(
                                          color: Colors.grey[400],
                                        ),
                                      ),
                                    ),
                                  ]
                                : categories.map((category) {
                                    return DropdownMenuItem(
                                      value: category.id,
                                      child: Row(
                                        children: [
                                          Icon(
                                            category.getIcon(),
                                            color: AppColors.primary,
                                            size: 20,
                                          ),
                                          const SizedBox(width: 12),
                                          Text(
                                            category.name,
                                            style: GoogleFonts.poppins(
                                              color: Colors.black87,
                                              fontSize: 16,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                            onChanged: categories.isEmpty
                                ? null
                                : (value) {
                                    setDialogState(() {
                                      _selectedCategoryId = value;
                                      _selectedCategoryName = categories
                                          .firstWhere((c) => c.id == value)
                                          .name;
                                    });
                                  },
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please select a category';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          
                          TextFormField(
                            controller: _descriptionController,
                            decoration: InputDecoration(
                              labelText: 'Description',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              prefixIcon: const Icon(Icons.description),
                            ),
                            style: GoogleFonts.poppins(),
                            maxLines: 3,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter description';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          
                          TextFormField(
                            controller: _originalPriceController,
                            decoration: InputDecoration(
                              labelText: 'Original Price (\$)',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              prefixIcon: const Icon(Icons.attach_money),
                            ),
                            style: GoogleFonts.poppins(),
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter original price';
                              }
                              final price = double.tryParse(value);
                              if (price == null || price <= 0) {
                                return 'Please enter a valid price';
                              }
                              return null;
                            },
                            onChanged: (value) {
                              
                              _calculateAndUpdatePrice(setDialogState);
                            },
                          ),
                          const SizedBox(height: 16),
                          
                          TextFormField(
                            controller: _discountController,
                            decoration: InputDecoration(
                              labelText: 'Discount (%)',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              prefixIcon: const Icon(Icons.percent),
                            ),
                            style: GoogleFonts.poppins(),
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter discount';
                              }
                              final discount = double.tryParse(value);
                              if (discount == null || discount < 0 || discount > 100) {
                                return 'Please enter a valid discount (0-100)';
                              }
                              return null;
                            },
                            onChanged: (value) {
                              
                              _calculateAndUpdatePrice(setDialogState);
                            },
                          ),
                          const SizedBox(height: 16),
                          
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.grey[300]!,
                                width: 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.price_check, color: AppColors.primary),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Current Price (After Discount)',
                                        style: GoogleFonts.poppins(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Builder(
                                        builder: (context) {
                                          final originalPriceText = _originalPriceController.text.trim();
                                          final discountText = _discountController.text.trim();
                                          
                                          if (originalPriceText.isNotEmpty && discountText.isNotEmpty) {
                                            final originalPrice = double.tryParse(originalPriceText);
                                            final discount = double.tryParse(discountText);
                                            
                                            if (originalPrice != null && discount != null && originalPrice > 0 && discount >= 0 && discount <= 100) {
                                              final calculatedPrice = originalPrice - (originalPrice * discount / 100);
                                              return Text(
                                                '\$${calculatedPrice.toStringAsFixed(2)}',
                                                style: GoogleFonts.poppins(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.w700,
                                                  color: AppColors.primary,
                                                ),
                                              );
                                            }
                                          }
                                          return Text(
                                            'Enter original price and discount',
                                            style: GoogleFonts.poppins(
                                              fontSize: 14,
                                              color: Colors.grey[400],
                                            ),
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          Text(
                            'Product Image (Optional)',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 8),
                          GestureDetector(
                            onTap: () async {
                              await _pickImage(setDialogState);
                            },
                            child: Container(
                              height: 150,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.grey[300]!,
                                  width: 1,
                                ),
                              ),
                              child: _selectedImage != null
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.file(
                                        _selectedImage!,
                                        fit: BoxFit.cover,
                                      ),
                                    )
                                  : (_imageUrl != null && _imageUrl!.isNotEmpty) || (_imageUrlController.text.trim().isNotEmpty)
                                      ? ClipRRect(
                                          borderRadius: BorderRadius.circular(12),
                                          child: Image.network(
                                            _imageUrl ?? _imageUrlController.text.trim(),
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error, stackTrace) {
                                              return Column(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  Icon(
                                                    Icons.image_not_supported,
                                                    size: 48,
                                                    color: Colors.grey[400],
                                                  ),
                                                  const SizedBox(height: 8),
                                                  Text(
                                                    'Invalid image URL',
                                                    style: GoogleFonts.poppins(
                                                      color: Colors.grey[600],
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    'Tap to change',
                                                    style: GoogleFonts.poppins(
                                                      color: Colors.grey[500],
                                                      fontSize: 10,
                                                    ),
                                                  ),
                                                ],
                                              );
                                            },
                                          ),
                                        )
                                      : Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.add_photo_alternate,
                                              size: 48,
                                              color: Colors.grey[400],
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              'Tap to select image (Optional)',
                                              style: GoogleFonts.poppins(
                                                color: Colors.grey[600],
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          TextFormField(
                            controller: _imageUrlController,
                            decoration: InputDecoration(
                              labelText: 'Image URL (Optional)',
                              hintText: 'Enter image URL or upload from gallery above',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              filled: true,
                              fillColor: Colors.white,
                              prefixIcon: const Icon(Icons.link),
                            ),
                            style: GoogleFonts.poppins(),
                            onChanged: (value) {
                              setDialogState(() {
                                if (value.trim().isNotEmpty) {
                                  _imageUrl = value.trim();
                                  _selectedImage = null; 
                                } else {
                                  _imageUrl = null;
                                }
                              });
                            },
                          ),
                          const SizedBox(height: 16),
                          
                          TextFormField(
                            controller: _imageUrl1Controller,
                            decoration: InputDecoration(
                              labelText: 'Image URL 1 (Optional)',
                              hintText: 'Enter first image URL',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              filled: true,
                              fillColor: Colors.white,
                              prefixIcon: const Icon(Icons.link),
                            ),
                            style: GoogleFonts.poppins(),
                          ),
                          const SizedBox(height: 16),
                          
                          TextFormField(
                            controller: _imageUrl2Controller,
                            decoration: InputDecoration(
                              labelText: 'Image URL 2 (Optional)',
                              hintText: 'Enter second image URL',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              filled: true,
                              fillColor: Colors.white,
                              prefixIcon: const Icon(Icons.link),
                            ),
                            style: GoogleFonts.poppins(),
                          ),
                          const SizedBox(height: 16),
                          
                          TextFormField(
                            controller: _imageUrl3Controller,
                            decoration: InputDecoration(
                              labelText: 'Image URL 3 (Optional)',
                              hintText: 'Enter third image URL',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              filled: true,
                              fillColor: Colors.white,
                              prefixIcon: const Icon(Icons.link),
                            ),
                            style: GoogleFonts.poppins(),
                          ),
                          const SizedBox(height: 16),
                          
                          TextFormField(
                            controller: _stockController,
                            decoration: InputDecoration(
                              labelText: 'Stock Quantity',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              prefixIcon: const Icon(Icons.inventory),
                            ),
                            style: GoogleFonts.poppins(),
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter stock quantity';
                              }
                              final stock = int.tryParse(value);
                              if (stock == null || stock < 1) {
                                return 'Please enter a valid stock quantity (minimum 1)';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          
                          CheckboxListTile(
                            title: Text(
                              'Active',
                              style: GoogleFonts.poppins(),
                            ),
                            value: _isActive,
                            onChanged: (value) {
                              setDialogState(() {
                                _isActive = value ?? true;
                              });
                            },
                            controlAffinity: ListTileControlAffinity.leading,
                          ),
                          const SizedBox(height: 8),
                          
                          CheckboxListTile(
                            title: Text(
                              'Recommended Product',
                              style: GoogleFonts.poppins(),
                            ),
                            subtitle: Text(
                              'Mark as recommended product',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                            value: _isRecommended,
                            onChanged: (value) {
                              setDialogState(() {
                                _isRecommended = value ?? false;
                              });
                            },
                            controlAffinity: ListTileControlAffinity.leading,
                          ),
                          const SizedBox(height: 20),
                          
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: Text(
                                  'Cancel',
                                  style: GoogleFonts.poppins(),
                                ),
                              ),
                              const SizedBox(width: 12),
                              ElevatedButton(
                                onPressed: _isLoading
                                    ? null
                                    : () => _saveProduct(setDialogState),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 12,
                                  ),
                                ),
                                child: _isLoading
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                        ),
                                      )
                                    : Text(
                                        product == null ? 'Add' : 'Update',
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
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _saveProduct(StateSetter setDialogState) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedCategoryId == null || _selectedCategoryName == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please select a category',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setDialogState(() {
      _isLoading = true;
    });

    try {
      final originalPrice = double.parse(_originalPriceController.text);
      final discount = double.parse(_discountController.text);
      
      
      
      final price = originalPrice * (1 - discount / 100);
      
      final calculatedPrice = price.clamp(0.0, originalPrice);
      final stock = int.parse(_stockController.text);
      
      
      String? uploadedImageUrl;
      if (_selectedImage != null) {
        
        uploadedImageUrl = await _uploadImageToFirebase();
      } else if (_imageUrlController.text.trim().isNotEmpty) {
        
        uploadedImageUrl = _imageUrlController.text.trim();
      } else {
        
        uploadedImageUrl = _imageUrl;
      }

      
      List<String> imageUrls = [];
      
      
      if (uploadedImageUrl != null && uploadedImageUrl.isNotEmpty) {
        
        imageUrls.add(uploadedImageUrl);
      } else if (_imageUrl1Controller.text.trim().isNotEmpty) {
        
        imageUrls.add(_imageUrl1Controller.text.trim());
      }
      
      
      if (_imageUrl2Controller.text.trim().isNotEmpty) {
        imageUrls.add(_imageUrl2Controller.text.trim());
      }
      
      
      if (_imageUrl3Controller.text.trim().isNotEmpty) {
        imageUrls.add(_imageUrl3Controller.text.trim());
      }
      
      
      if (imageUrls.isNotEmpty && imageUrls.length < 3) {
        final lastImage = imageUrls.last;
        while (imageUrls.length < 3) {
          imageUrls.add(lastImage);
        }
      }
      
      
      if (imageUrls.length > 3) {
        imageUrls = imageUrls.take(3).toList();
      }

      if (_editingProductId == null) {
        
        await ProductService.addProduct(
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim(),
          originalPrice: originalPrice,
          price: calculatedPrice, 
          discount: discount,
          categoryName: _selectedCategoryName!,
          imageUrl: uploadedImageUrl,
          imageUrls: imageUrls.isNotEmpty ? imageUrls : null, 
          stock: stock,
          isActive: _isActive,
          isRecommended: _isRecommended,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Product added successfully',
                style: GoogleFonts.poppins(),
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        
        await ProductService.updateProduct(
          id: _editingProductId!,
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim(),
          originalPrice: originalPrice,
          price: calculatedPrice, 
          discount: discount,
          categoryName: _selectedCategoryName!,
          oldCategoryName: _oldCategoryName ?? _selectedCategoryName!,
          imageUrl: uploadedImageUrl,
          imageUrls: imageUrls.isNotEmpty ? imageUrls : null,
          stock: stock,
          isActive: _isActive,
          isRecommended: _isRecommended,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Product updated successfully',
                style: GoogleFonts.poppins(),
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
      }

      if (mounted) {
        
        Navigator.pop(context);
        
        
        _nameController.clear();
        _descriptionController.clear();
        _originalPriceController.clear();
        _discountController.clear();
        _stockController.clear();
        _imageUrlController.clear();
        _imageUrl1Controller.clear();
        _imageUrl2Controller.clear();
        _imageUrl3Controller.clear();
        _selectedImage = null;
        _imageUrl = null;
        _selectedCategoryId = null;
        _selectedCategoryName = null;
        _editingProductId = null;
        _oldCategoryName = null;
        _isActive = true;
        _isRecommended = false;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.toString().replaceFirst('Exception: ', ''),
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setDialogState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _deleteProduct(ProductModel product) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Delete Product',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Are you sure you want to delete "${product.name}"? This action cannot be undone.',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: Text(
              'Delete',
              style: GoogleFonts.poppins(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await ProductService.deleteProduct(product.id!, product.categoryName);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Product deleted successfully',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.toString().replaceFirst('Exception: ', ''),
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
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
          'Manage Products',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<List<ProductModel>>(
        stream: ProductService.getProductsStream(),
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
                    'Error loading products',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    snapshot.error.toString(),
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          final products = snapshot.data ?? [];

          if (products.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.shopping_bag_outlined,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No products yet',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap the + button to add your first product',
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
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: CircleAvatar(
                    backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                    child: Icon(
                      Icons.shopping_bag,
                      color: AppColors.primary,
                    ),
                  ),
                  title: Text(
                    product.name,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(
                        product.categoryName,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: AppColors.primary,
                        ),
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
                      const SizedBox(height: 4),
                      
                      Row(
                        children: [
                          if (product.discount > 0 && product.originalPrice > product.price) ...[
                            
                            Text(
                              product.formattedOriginalPrice,
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: Colors.grey[500],
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                            const SizedBox(width: 8),
                            
                            Text(
                              product.formattedPrice,
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(width: 8),
                            
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.red.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '${product.discount.toStringAsFixed(0)}% Off',
                                style: GoogleFonts.poppins(
                                  fontSize: 10,
                                  color: Colors.red,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ] else ...[
                            
                            Text(
                              product.formattedPrice,
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.inventory,
                            size: 14,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Stock: ${product.stock}',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: product.isActive
                                  ? Colors.green.withValues(alpha: 0.1)
                                  : Colors.red.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              product.isActive ? 'Active' : 'Inactive',
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                color: product.isActive ? Colors.green : Colors.red,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: AppColors.primary),
                        onPressed: () => _showAddEditDialog(product: product),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteProduct(product),
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
}

