import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../../constants/app_colors.dart';
import 'payment_methods_screen.dart';
import 'orders_screen.dart';
import 'personal_info_screen.dart';
import 'help_support_screen.dart';
import 'refer_earn_screen.dart';
import 'security_settings_screen.dart';
import 'notifications_screen.dart';
import '../main/address_management_screen.dart';
import '../auth/login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  File? _profilePhoto;

  @override
  void initState() {
    super.initState();
    _loadProfilePhoto();
  }

  Future<void> _loadProfilePhoto() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final directory = await getApplicationDocumentsDirectory();
      final photoPath = path.join(directory.path, 'profile_photo_${user.uid}.jpg');
      final photoFile = File(photoPath);

      if (photoFile.existsSync()) {
        setState(() {
          _profilePhoto = photoFile;
        });
      }
    } catch (e) {
      debugPrint('Error loading profile photo: $e');
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    _loadProfilePhoto();
  }

  String _getUserName() {
    final user = FirebaseAuth.instance.currentUser;
    return user?.displayName ?? user?.email?.split('@')[0] ?? 'Allison Blue Hunter';
  }

  void _showSignOutDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                
                Text(
                  'Logout',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
                const SizedBox(height: 16),
                
                Text(
                  'Do you want to exit your account?',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 24),
                
                Row(
                  children: [
                    
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          backgroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          side: BorderSide(color: Colors.grey[300]!),
                        ),
                        child: Text(
                          'Cancel',
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[700],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          Navigator.of(context).pop();
                          await FirebaseAuth.instance.signOut();
                          
                          
                          if (context.mounted) {
                            Navigator.of(context).pushAndRemoveUntil(
                              MaterialPageRoute(
                                builder: (context) => const LoginScreen(),
                              ),
                              (route) => false, 
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          'Confirm',
                          style: GoogleFonts.poppins(
                            fontSize: 15,
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
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          'Account',
          style: GoogleFonts.poppins(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 6),
                  
                  _buildProfileSection(),
                  const SizedBox(height: 12),
                  
                  _buildActionButtons(),
                  const SizedBox(height: 12),
                  
                  _buildPaymentsSection(context),
                  const SizedBox(height: 12),
                  
                  _buildGeneralSettingsSection(context),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileSection() {
    return Column(
      children: [
        Container(
          width: 65,
          height: 65,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.grey[200],
            border: Border.all(color: Colors.grey[300]!, width: 2),
          ),
          child: _profilePhoto != null && _profilePhoto!.existsSync()
              ? ClipOval(
                  child: Image.file(
                    _profilePhoto!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Icon(
                      Icons.person,
                      size: 38,
                      color: Colors.grey[400],
                    ),
                  ),
                )
              : Icon(
            Icons.person,
            size: 38,
            color: Colors.grey[400],
          ),
        ),
        const SizedBox(height: 6),
        Text(
          _getUserName(),
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: _buildActionButton(
              icon: Icons.phone,
              label: 'Help & Support',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const HelpSupportScreen(),
                  ),
                );
              },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildActionButton(
              icon: Icons.card_giftcard,
              label: 'Refer & Earn',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ReferEarnScreen(),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppColors.primary, size: 18),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'Payments',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ),
        const SizedBox(height: 8),
        _buildListTile(
          icon: Icons.credit_card,
          title: 'Bank & Card Info',
          subtitle: 'Update card information and password',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const PaymentMethodsScreen(),
              ),
            );
          },
        ),
        _buildListTile(
          icon: Icons.account_balance_wallet,
          title: 'Payment Method',
          subtitle: 'Update your preferred way to pay',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const PaymentMethodsScreen(),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildGeneralSettingsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'General Settings',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ),
        const SizedBox(height: 8),
        _buildListTile(
          icon: Icons.person_outline,
          title: 'Personal Info',
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const PersonalInfoScreen(),
              ),
            );
            
            _loadProfilePhoto();
          },
        ),
        _buildListTile(
          icon: Icons.location_on_outlined,
          title: 'Manage Address',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const AddressManagementScreen(allowSelection: false),
              ),
            );
          },
        ),
        _buildListTile(
          icon: Icons.shopping_bag_outlined,
          title: 'My Orders',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const OrdersScreen(),
              ),
            );
          },
        ),
        _buildListTile(
          icon: Icons.lock_outline,
          title: 'Security Settings',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const SecuritySettingsScreen(),
              ),
            );
          },
        ),
        _buildListTile(
          icon: Icons.notifications_outlined,
          title: 'Notifications',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const NotificationsScreen(),
              ),
            );
          },
        ),
        _buildListTile(
          icon: Icons.help_outline,
          title: 'Help & Support',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const HelpSupportScreen(),
              ),
            );
          },
        ),
        Divider(
          height: 20,
          thickness: 1,
          color: Colors.grey[300],
          indent: 20,
          endIndent: 20,
        ),
        _buildListTile(
          icon: Icons.logout,
          title: 'Sign Out',
          onTap: () => _showSignOutDialog(context),
          iconColor: Colors.red,
          textColor: Colors.red,
          arrowColor: Colors.red,
        ),
      ],
    );
  }

  Widget _buildListTile({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
    Color? arrowColor,
    Color? iconColor,
    Color? textColor,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: iconColor != null ? iconColor.withValues(alpha: 0.1) : Colors.grey[100],
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(
                icon,
                color: iconColor ?? Colors.black87,
                size: 16,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: textColor ?? Colors.black87,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 1),
                    Text(
                      subtitle,
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        color: Colors.grey[600],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: arrowColor ?? Colors.grey[400],
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

}

