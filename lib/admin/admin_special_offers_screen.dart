import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/special_offer_model.dart';
import '../constants/app_colors.dart';
import 'special_offer_service.dart';

class AdminSpecialOffersScreen extends StatefulWidget {
  const AdminSpecialOffersScreen({super.key});

  @override
  State<AdminSpecialOffersScreen> createState() => _AdminSpecialOffersScreenState();
}

class _AdminSpecialOffersScreenState extends State<AdminSpecialOffersScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _subtitleController = TextEditingController();
  final TextEditingController _badgeTextController = TextEditingController();
  final TextEditingController _discountTextController = TextEditingController();
  final TextEditingController _buttonTextController = TextEditingController();
  final TextEditingController _imageUrlController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _imagePicker = ImagePicker();
  
  String? _editingOfferId;
  bool _isLoading = false;
  bool _isActive = true;
  File? _selectedImage;
  String? _imageUrl; 

  @override
  void dispose() {
    _titleController.dispose();
    _subtitleController.dispose();
    _badgeTextController.dispose();
    _discountTextController.dispose();
    _buttonTextController.dispose();
    super.dispose();
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
          .child('special_offers')
          .child('${DateTime.now().millisecondsSinceEpoch}.jpg');

      await storageRef.putFile(_selectedImage!);
      final downloadUrl = await storageRef.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      debugPrint('Error uploading image: $e');
      throw Exception('Failed to upload image: ${e.toString()}');
    }
  }

  Future<void> _showAddEditDialog({SpecialOfferModel? offer}) async {
    _editingOfferId = offer?.id;
    
    if (offer != null) {
      _titleController.text = offer.title;
      _subtitleController.text = offer.subtitle;
      _badgeTextController.text = offer.badgeText;
      _discountTextController.text = offer.discountText;
      _buttonTextController.text = offer.buttonText;
      _imageUrl = offer.imageUrl;
      _imageUrlController.text = offer.imageUrl;
      _isActive = offer.isActive;
      _selectedImage = null;
    } else {
      _titleController.clear();
      _subtitleController.clear();
      _badgeTextController.clear();
      _discountTextController.clear();
      _buttonTextController.clear();
      _imageUrlController.clear();
      _imageUrl = null;
      _isActive = true;
      _selectedImage = null;
    }

    if (!mounted) return;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            width: double.infinity,
            constraints: const BoxConstraints(maxWidth: 500),
            padding: const EdgeInsets.all(20),
            child: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _editingOfferId == null ? 'Add Special Offer' : 'Edit Special Offer',
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    Text(
                      'Banner Image (Optional)',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () => _pickImage(setDialogState),
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
                                      errorBuilder: (context, error, stackTrace) => Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.image_not_supported, color: Colors.grey[400]),
                                          const SizedBox(height: 8),
                                          Text(
                                            'Invalid image URL',
                                            style: GoogleFonts.poppins(
                                              fontSize: 12,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Tap to change',
                                            style: GoogleFonts.poppins(
                                              fontSize: 10,
                                              color: Colors.grey[500],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  )
                                : Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.add_photo_alternate, color: Colors.grey[400], size: 40),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Tap to select image',
                                        style: GoogleFonts.poppins(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    
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
                    const SizedBox(height: 20),
                    
                    TextFormField(
                      controller: _badgeTextController,
                      decoration: InputDecoration(
                        labelText: 'Badge Text',
                        hintText: 'e.g., Boost Season',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      style: GoogleFonts.poppins(),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter badge text';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    TextFormField(
                      controller: _titleController,
                      decoration: InputDecoration(
                        labelText: 'Title',
                        hintText: 'e.g., Get Special Offer',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      style: GoogleFonts.poppins(),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter title';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    TextFormField(
                      controller: _subtitleController,
                      decoration: InputDecoration(
                        labelText: 'Subtitle',
                        hintText: 'e.g., Up to 40%',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      style: GoogleFonts.poppins(),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter subtitle';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    TextFormField(
                      controller: _discountTextController,
                      decoration: InputDecoration(
                        labelText: 'Discount Text',
                        hintText: 'e.g., 40%',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      style: GoogleFonts.poppins(),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter discount text';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    TextFormField(
                      controller: _buttonTextController,
                      decoration: InputDecoration(
                        labelText: 'Button Text',
                        hintText: 'e.g., Shop Now',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      style: GoogleFonts.poppins(),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter button text';
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
                      activeColor: AppColors.primary,
                    ),
                    const SizedBox(height: 20),
                    
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              'Cancel',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : () => _saveOffer(setDialogState),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
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
                                    _editingOfferId == null ? 'Add' : 'Update',
                                    style: GoogleFonts.poppins(
                                      color: Colors.white,
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
    );
  }

  Future<void> _saveOffer(StateSetter setDialogState) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setDialogState(() {
      _isLoading = true;
    });

    try {
      String? uploadedImageUrl = _imageUrl;
      if (_selectedImage != null) {
        uploadedImageUrl = await _uploadImageToFirebase();
      }

      final offer = SpecialOfferModel(
        id: _editingOfferId,
        title: _titleController.text.trim(),
        subtitle: _subtitleController.text.trim(),
        badgeText: _badgeTextController.text.trim(),
        discountText: _discountTextController.text.trim(),
        buttonText: _buttonTextController.text.trim(),
        imageUrl: uploadedImageUrl ?? '',
        isActive: _isActive,
      );

      if (_editingOfferId == null) {
        await SpecialOfferService.addSpecialOffer(offer);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Special offer added successfully',
                style: GoogleFonts.poppins(),
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        await SpecialOfferService.updateSpecialOffer(offer);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Special offer updated successfully',
                style: GoogleFonts.poppins(),
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
      }

      if (mounted) {
        Navigator.pop(context);
        
        _titleController.clear();
        _subtitleController.clear();
        _badgeTextController.clear();
        _discountTextController.clear();
        _buttonTextController.clear();
        _imageUrlController.clear();
        _imageUrl = null;
        _selectedImage = null;
        _editingOfferId = null;
        _isActive = true;
      }
    } catch (e) {
      debugPrint('Error saving special offer: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error saving special offer: ${e.toString()}',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.red,
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

  Future<void> _deleteOffer(SpecialOfferModel offer) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          'Delete Special Offer',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Are you sure you want to delete "${offer.title}"? This action cannot be undone.',
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
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: Text(
              'Delete',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm == true && offer.id != null) {
      try {
        await SpecialOfferService.deleteSpecialOffer(offer.id!);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Special offer deleted successfully',
                style: GoogleFonts.poppins(),
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        debugPrint('Error deleting special offer: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Error deleting special offer: ${e.toString()}',
                style: GoogleFonts.poppins(),
              ),
              backgroundColor: Colors.red,
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
          'Manage Special Offers',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<List<SpecialOfferModel>>(
        stream: SpecialOfferService.getSpecialOffersStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error loading special offers: ${snapshot.error}',
                style: GoogleFonts.poppins(),
              ),
            );
          }

          final offers = snapshot.data ?? [];

          if (offers.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.local_offer,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No special offers yet',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap the + button to add a new offer',
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
            itemCount: offers.length,
            itemBuilder: (context, index) {
              final offer = offers[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(12),
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: offer.imageUrl.isNotEmpty
                        ? Image.network(
                            offer.imageUrl,
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Container(
                              width: 60,
                              height: 60,
                              color: Colors.grey[200],
                              child: Icon(Icons.image_not_supported, color: Colors.grey[400]),
                            ),
                          )
                        : Container(
                            width: 60,
                            height: 60,
                            color: Colors.grey[200],
                            child: Icon(Icons.image, color: Colors.grey[400]),
                          ),
                  ),
                  title: Text(
                    offer.title,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(
                        offer.subtitle,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: offer.isActive
                                  ? Colors.green.withValues(alpha: 0.1)
                                  : Colors.grey.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              offer.isActive ? 'Active' : 'Inactive',
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                color: offer.isActive ? Colors.green : Colors.grey,
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
                        onPressed: () => _showAddEditDialog(offer: offer),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteOffer(offer),
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

