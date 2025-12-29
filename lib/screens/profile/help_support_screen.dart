import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../constants/app_colors.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri uri = Uri.parse('tel:$phoneNumber');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _sendEmail(String email) async {
    final Uri uri = Uri.parse('mailto:$email');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Help & Support',
          style: GoogleFonts.poppins(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            
            Center(
              child: Column(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.help_outline,
                      size: 40,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'We\'re here to help!',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Get in touch with our support team',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            
            _buildSectionTitle('Contact Us'),
            const SizedBox(height: 16),
            _buildContactCard(
              icon: Icons.phone,
              title: 'Call Us',
              subtitle: '+1 234 567 8900',
              onTap: () => _makePhoneCall('+12345678900'),
              color: AppColors.primary,
            ),
            const SizedBox(height: 12),
            _buildContactCard(
              icon: Icons.email,
              title: 'Email Us',
              subtitle: 'support@ecommerce.com',
              onTap: () => _sendEmail('support@ecommerce.com'),
              color: AppColors.primary,
            ),
            const SizedBox(height: 12),
            _buildContactCard(
              icon: Icons.chat_bubble_outline,
              title: 'Live Chat',
              subtitle: 'Available 24/7',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Live chat feature coming soon!',
                      style: GoogleFonts.poppins(),
                    ),
                    backgroundColor: AppColors.info,
                  ),
                );
              },
              color: AppColors.primary,
            ),
            const SizedBox(height: 40),
            
            _buildSectionTitle('Frequently Asked Questions'),
            const SizedBox(height: 16),
            _buildFAQItem(
              question: 'How do I track my order?',
              answer: 'You can track your order by going to "My Orders" in your account. Click on any order to see detailed tracking information.',
            ),
            _buildFAQItem(
              question: 'What is your return policy?',
              answer: 'We offer a 30-day return policy. Items must be in original condition with tags attached. Please contact support for return authorization.',
            ),
            _buildFAQItem(
              question: 'How long does shipping take?',
              answer: 'Standard shipping takes 5-7 business days. Express shipping (3-day delivery) is available for eligible items.',
            ),
            _buildFAQItem(
              question: 'How do I change my password?',
              answer: 'Go to "Security Settings" in your account to change your password. You\'ll need to verify your current password first.',
            ),
            _buildFAQItem(
              question: 'Can I cancel my order?',
              answer: 'Orders can be cancelled within 24 hours of placement. After that, you can request a return once the order is delivered.',
            ),
            const SizedBox(height: 40),
            
            _buildSectionTitle('Additional Resources'),
            const SizedBox(height: 16),
            _buildResourceCard(
              icon: Icons.description_outlined,
              title: 'Terms & Conditions',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Terms & Conditions page coming soon!',
                      style: GoogleFonts.poppins(),
                    ),
                    backgroundColor: AppColors.info,
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            _buildResourceCard(
              icon: Icons.privacy_tip_outlined,
              title: 'Privacy Policy',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Privacy Policy page coming soon!',
                      style: GoogleFonts.poppins(),
                    ),
                    backgroundColor: AppColors.info,
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            _buildResourceCard(
              icon: Icons.info_outline,
              title: 'About Us',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'About Us page coming soon!',
                      style: GoogleFonts.poppins(),
                    ),
                    backgroundColor: AppColors.info,
                  ),
                );
              },
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.poppins(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildContactCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required Color color,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: color,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: Colors.grey[400],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFAQItem({
    required String question,
    required String answer,
  }) {
    return ExpansionTile(
      tilePadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
      childrenPadding: const EdgeInsets.only(bottom: 16),
      title: Text(
        question,
        style: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      ),
      iconColor: AppColors.primary,
      collapsedIconColor: Colors.grey[400],
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Padding(
            padding: const EdgeInsets.only(left: 16, right: 16),
            child: Text(
              answer,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: Colors.grey[700],
                height: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResourceCard({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: AppColors.primary,
              size: 24,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: Colors.grey[400],
            ),
          ],
        ),
      ),
    );
  }
}

