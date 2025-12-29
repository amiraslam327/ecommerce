import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/app_colors.dart';

class AdminProfileScreen extends StatelessWidget {
  final Map<String, dynamic>? adminData;

  const AdminProfileScreen({
    super.key,
    required this.adminData,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          
          Center(
            child: Column(
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.primary,
                      width: 3,
                    ),
                  ),
                  child: Icon(
                    Icons.person,
                    size: 50,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  adminData?['name'] ?? 'Admin',
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  adminData?['email'] ?? '',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: (adminData?['isActive'] == true
                            ? Colors.green
                            : Colors.red)
                        .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: adminData?['isActive'] == true
                          ? Colors.green
                          : Colors.red,
                      width: 1,
                    ),
                  ),
                  child: Text(
                    adminData?['isActive'] == true ? 'Active' : 'Inactive',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: adminData?['isActive'] == true
                          ? Colors.green
                          : Colors.red,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          
          Text(
            'Profile Information',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          _buildInfoCard(
            icon: Icons.person,
            label: 'Name',
            value: adminData?['name'] ?? 'N/A',
          ),
          _buildInfoCard(
            icon: Icons.email,
            label: 'Email',
            value: adminData?['email'] ?? 'N/A',
          ),
          _buildInfoCard(
            icon: Icons.phone,
            label: 'Phone',
            value: adminData?['phoneNumber'] ?? 'N/A',
          ),
          _buildInfoCard(
            icon: Icons.badge,
            label: 'Role',
            value: adminData?['role'] ?? 'N/A',
          ),
          _buildInfoCard(
            icon: Icons.calendar_today,
            label: 'Created At',
            value: adminData?['createdAt'] != null
                ? _formatDate(adminData!['createdAt'])
                : 'N/A',
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: AppColors.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
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
      ),
    );
  }

  String _formatDate(dynamic date) {
    if (date == null) return 'N/A';
    try {
      if (date is DateTime) {
        return '${date.day}/${date.month}/${date.year}';
      }
      
      if (date.toString().contains('Timestamp')) {
        return 'Date available';
      }
      return date.toString();
    } catch (e) {
      return 'N/A';
    }
  }
}

