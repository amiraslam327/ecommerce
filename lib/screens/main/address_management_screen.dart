import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import '../../models/address_model.dart';
import '../../services/address_service.dart';
import '../../constants/app_colors.dart';

class AddressManagementScreen extends StatefulWidget {
  final bool allowSelection;
  final int? selectedAddressId;

  const AddressManagementScreen({
    super.key,
    this.allowSelection = false,
    this.selectedAddressId,
  });

  @override
  State<AddressManagementScreen> createState() => _AddressManagementScreenState();
}

class _AddressManagementScreenState extends State<AddressManagementScreen> {
  final AddressService _addressService = AddressService();
  List<AddressModel> _addresses = [];
  final _formKey = GlobalKey<FormState>();
  final _labelController = TextEditingController();
  final _addressController = TextEditingController();
  String _phoneNumber = '';
  String _countryCode = '+966';
  bool _isDefault = false;
  bool _isEditing = false;
  int? _editingId;
  bool _isLoadingLocation = false;

  @override
  void initState() {
    super.initState();
    _loadAddresses();
  }

  @override
  void dispose() {
    _labelController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _loadAddresses() async {
    final addresses = await _addressService.getAllAddresses();
    setState(() {
      _addresses = addresses;
    });
    
    
    if (widget.allowSelection && addresses.isNotEmpty && mounted) {
      
      final defaultAddress = addresses.firstWhere(
        (addr) => addr.isDefault,
        orElse: () => addresses.first,
      );
      
      
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.pop(context, defaultAddress);
        }
      });
    }
  }

  void _showAddAddressDialog() {
    _labelController.clear();
    _addressController.clear();
    _phoneNumber = '';
    _countryCode = '+966';
    _isDefault = false;
    _isEditing = false;
    _editingId = null;

    showDialog(
      context: context,
      builder: (context) => _buildAddressDialog(),
    );
  }

  void _showEditAddressDialog(AddressModel address) {
    _labelController.text = address.label;
    _addressController.text = address.fullAddress;
    
    if (address.phone.startsWith('+966')) {
      _countryCode = '+966';
      _phoneNumber = address.phone.substring(4);
    } else {
      _countryCode = '+966';
      _phoneNumber = address.phone.replaceAll(RegExp(r'[^\d]'), '');
    }
    _isDefault = address.isDefault;
    _isEditing = true;
    _editingId = address.id;

    showDialog(
      context: context,
      builder: (context) => _buildAddressDialog(),
    );
  }

  Future<void> _getCurrentLocation() async {
    if (!mounted) return;
    
    setState(() {
      _isLoadingLocation = true;
    });

    try {
      
      try {
        await Geolocator.isLocationServiceEnabled();
      } catch (e) {
        if (mounted) {
          setState(() {
            _isLoadingLocation = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Location services are not available. Please restart the app after a full rebuild.',
                style: GoogleFonts.poppins(),
              ),
              backgroundColor: AppColors.error,
              duration: const Duration(seconds: 4),
            ),
          );
        }
        return;
      }
      
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          setState(() {
            _isLoadingLocation = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Location services are disabled. Please enable location services in your device settings.',
                style: GoogleFonts.poppins(),
              ),
              backgroundColor: AppColors.error,
              duration: const Duration(seconds: 3),
            ),
          );
        }
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            setState(() {
              _isLoadingLocation = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Location permission is required to get your current address.',
                  style: GoogleFonts.poppins(),
                ),
                backgroundColor: AppColors.error,
                duration: const Duration(seconds: 3),
              ),
            );
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          setState(() {
            _isLoadingLocation = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Location permission is permanently denied. Please enable it in app settings.',
                style: GoogleFonts.poppins(),
              ),
              backgroundColor: AppColors.error,
              duration: const Duration(seconds: 4),
              action: SnackBarAction(
                label: 'Open Settings',
                textColor: Colors.white,
                onPressed: () {
                  Geolocator.openLocationSettings();
                },
              ),
            ),
          );
        }
        return;
      }

      
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw TimeoutException('Location request timed out. Please try again.');
        },
      );

      
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException('Address lookup timed out. Please try again.');
        },
      );

      if (placemarks.isEmpty) {
        if (mounted) {
          setState(() {
            _isLoadingLocation = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Could not find address for this location. Please enter address manually.',
                style: GoogleFonts.poppins(),
              ),
              backgroundColor: AppColors.warning,
              duration: const Duration(seconds: 3),
            ),
          );
        }
        return;
      }

      Placemark place = placemarks[0];
      String address = '';
      
      if (place.street != null && place.street!.isNotEmpty) {
        address += place.street!;
      }
      if (place.subLocality != null && place.subLocality!.isNotEmpty) {
        if (address.isNotEmpty) address += ', ';
        address += place.subLocality!;
      }
      if (place.locality != null && place.locality!.isNotEmpty) {
        if (address.isNotEmpty) address += ', ';
        address += place.locality!;
      }
      if (place.administrativeArea != null && place.administrativeArea!.isNotEmpty) {
        if (address.isNotEmpty) address += ', ';
        address += place.administrativeArea!;
      }
      if (place.postalCode != null && place.postalCode!.isNotEmpty) {
        if (address.isNotEmpty) address += ', ';
        address += place.postalCode!;
      }
      if (place.country != null && place.country!.isNotEmpty) {
        if (address.isNotEmpty) address += ', ';
        address += place.country!;
      }

      if (address.isEmpty) {
        if (mounted) {
          setState(() {
            _isLoadingLocation = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Address information is incomplete. Please enter address manually.',
                style: GoogleFonts.poppins(),
              ),
              backgroundColor: AppColors.warning,
              duration: const Duration(seconds: 3),
            ),
          );
        }
        return;
      }

      if (mounted) {
        setState(() {
          _addressController.text = address;
          _isLoadingLocation = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Address retrieved successfully!',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } on TimeoutException catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingLocation = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.message ?? 'Request timed out. Please try again.',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingLocation = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error getting location: ${e.toString()}',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Widget _buildAddressDialog() {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _isEditing ? 'Edit Address' : 'Add Address',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.grey),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      
                      Text(
                        'Label',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _labelController,
                        decoration: InputDecoration(
                          hintText: 'e.g., Home, Office',
                          hintStyle: GoogleFonts.poppins(
                            color: Colors.grey[400],
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
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
                            borderSide: const BorderSide(color: AppColors.amber, width: 2),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                        ),
                        style: GoogleFonts.poppins(),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a label';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Address',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: _addressController,
                                  decoration: InputDecoration(
                                    hintText: 'Enter full address',
                                    hintStyle: GoogleFonts.poppins(
                                      color: Colors.grey[400],
                                    ),
                                    filled: true,
                                    fillColor: Colors.grey[50],
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
                                      borderSide: const BorderSide(color: AppColors.amber, width: 2),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 16,
                                    ),
                                  ),
                                  maxLines: 3,
                                  style: GoogleFonts.poppins(),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter an address';
                                    }
                                    return null;
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            margin: const EdgeInsets.only(top: 32),
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: AppColors.amber,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: IconButton(
                              icon: _isLoadingLocation
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    )
                                  : const Icon(Icons.my_location, color: Colors.white),
                              onPressed: _isLoadingLocation ? null : _getCurrentLocation,
                              tooltip: 'Get current location',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      
                      Text(
                        'Phone Number',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      IntlPhoneField(
                        initialCountryCode: 'SA',
                        initialValue: _isEditing ? _phoneNumber : null,
                        decoration: InputDecoration(
                          hintText: 'Enter phone number',
                          hintStyle: GoogleFonts.poppins(
                            color: Colors.grey[400],
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
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
                            borderSide: const BorderSide(color: AppColors.amber, width: 2),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                        ),
                        style: GoogleFonts.poppins(),
                        onChanged: (phone) {
                          _countryCode = phone.countryCode;
                          _phoneNumber = phone.number;
                        },
                        validator: (phone) {
                          if (phone == null || phone.number.isEmpty) {
                            return 'Please enter a phone number';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      
                      StatefulBuilder(
                        builder: (context, setDialogState) {
                          return Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey[200]!),
                            ),
                            child: Row(
                              children: [
                                Checkbox(
                                  value: _isDefault,
                                  activeColor: AppColors.amber,
                                  onChanged: (value) {
                                    setDialogState(() {
                                      _isDefault = value ?? false;
                                    });
                                    setState(() {
                                      _isDefault = value ?? false;
                                    });
                                  },
                                ),
                                Expanded(
                                  child: Text(
                                    'Set as default address',
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
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
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: BorderSide(color: Colors.grey[300]!),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Cancel',
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
                      onPressed: _saveAddress,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.amber,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        _isEditing ? 'Update Address' : 'Add Address',
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
      ),
    );
  }

  Future<void> _saveAddress() async {
    if (_formKey.currentState!.validate()) {
      try {
        
        String formattedPhone = _phoneNumber.startsWith('+')
            ? _phoneNumber
            : '$_countryCode$_phoneNumber';

        final address = AddressModel(
          id: _editingId,
          label: _labelController.text.trim(),
          fullAddress: _addressController.text.trim(),
          phone: formattedPhone,
          isDefault: _isDefault,
        );

        if (_isEditing) {
          await _addressService.updateAddress(address);
          if (mounted) {
            Navigator.pop(context);
            _loadAddresses();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Address updated successfully',
                  style: GoogleFonts.poppins(),
                ),
                backgroundColor: AppColors.success,
                duration: const Duration(seconds: 2),
              ),
            );
          }
        } else {
          await _addressService.addAddress(address);
          if (mounted) {
            Navigator.pop(context);
            _loadAddresses();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Address added successfully',
                  style: GoogleFonts.poppins(),
                ),
                backgroundColor: AppColors.success,
                duration: const Duration(seconds: 2),
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Error saving address: ${e.toString()}',
                style: GoogleFonts.poppins(),
              ),
              backgroundColor: AppColors.error,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    }
  }

  Future<void> _deleteAddress(int id) async {
    if (!mounted) return;
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.delete_outline,
                  color: Colors.red,
                  size: 32,
                ),
              ),
              const SizedBox(height: 20),
              
              Text(
                'Delete Address',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              
              Text(
                'Are you sure you want to delete this address? This action cannot be undone.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 24),
              
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context, false),
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
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.error,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Delete',
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
            ],
          ),
        ),
      ),
    );

    if (confirmed == true && mounted) {
      try {
        final result = await _addressService.deleteAddress(id);
        if (mounted) {
          if (result > 0) {
            _loadAddresses();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Address deleted successfully',
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
                  'Address not found or already deleted',
                  style: GoogleFonts.poppins(),
                ),
                backgroundColor: AppColors.warning,
                duration: const Duration(seconds: 2),
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Error deleting address: ${e.toString()}',
                style: GoogleFonts.poppins(),
              ),
              backgroundColor: AppColors.error,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    }
  }

  Future<void> _setDefaultAddress(int id) async {
    await _addressService.setDefaultAddress(id);
    _loadAddresses();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context, true),
        ),
        title: Text(
          'Addresses',
          style: GoogleFonts.poppins(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
      ),
      body: _addresses.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.location_off,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No addresses yet',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Add your first address',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _addresses.length,
              itemBuilder: (context, index) {
                final address = _addresses[index];
                return InkWell(
                  onTap: () {
                    _showEditAddressDialog(address);
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: address.isDefault ? AppColors.primary : Colors.grey[300]!,
                        width: address.isDefault ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.location_on,
                                    color: AppColors.primary,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      address.label,
                                      style: GoogleFonts.poppins(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ),
                                  if (address.isDefault) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        'Default',
                                        style: GoogleFonts.poppins(
                                          fontSize: 10,
                                          color: AppColors.primary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12), 
                                  ],
                                ],
                              ),
                            ),
                            
                            GestureDetector(
                              onTap: address.id != null
                                  ? () => _deleteAddress(address.id!)
                                  : null,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.red[100],
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.red[300]!, width: 1),
                                ),
                                child: IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red, size: 22),
                                  onPressed: null, 
                                  tooltip: 'Delete address',
                                  padding: const EdgeInsets.all(10),
                                  constraints: const BoxConstraints(
                                    minWidth: 40,
                                    minHeight: 40,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              address.fullAddress,
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              address.phone,
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                        if (!address.isDefault) ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              InkWell(
                                onTap: () => _setDefaultAddress(address.id!),
                                borderRadius: BorderRadius.circular(4),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  child: Text(
                            'Set as Default',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: AppColors.amber,
                              fontWeight: FontWeight.w600,
                            ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddAddressDialog,
        backgroundColor: AppColors.amber,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

