import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';

class IconPickerDialog extends StatefulWidget {
  final String selectedIconName;
  final Function(String iconName) onIconSelected;

  const IconPickerDialog({
    super.key,
    required this.selectedIconName,
    required this.onIconSelected,
  });

  @override
  State<IconPickerDialog> createState() => _IconPickerDialogState();
}

class _IconPickerDialogState extends State<IconPickerDialog> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _filteredIcons = [];
  List<Map<String, dynamic>> _allIcons = [];

  @override
  void initState() {
    super.initState();
    _filteredIcons = _allIcons;
    _searchController.addListener(_filterIcons);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }


  void _filterIcons() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredIcons = _allIcons;
      } else {
        _filteredIcons = _allIcons.where((icon) {
          return icon['name'].toString().toLowerCase().contains(query) ||
                 icon['label'].toString().toLowerCase().contains(query);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select Icon',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search icons...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
              style: GoogleFonts.poppins(),
            ),
            const SizedBox(height: 16),
            
            Expanded(
              child: _filteredIcons.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.search_off,
                            size: 48,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'No icons found',
                            style: GoogleFonts.poppins(
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    )
                  : GridView.builder(
                      shrinkWrap: true,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 4,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 0.9,
                      ),
                      itemCount: _filteredIcons.length,
                      itemBuilder: (context, index) {
                        final icon = _filteredIcons[index];
                        final iconName = icon['name'] as String;
                        final iconData = icon['icon'] as IconData;
                        final label = icon['label'] as String;
                        final isSelected = widget.selectedIconName == iconName;

                        return InkWell(
                          onTap: () {
                            widget.onIconSelected(iconName);
                            Navigator.of(context).pop(iconName);
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.primary.withValues(alpha: 0.2)
                                  : Colors.grey[50],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.primary
                                    : Colors.grey[300]!,
                                width: isSelected ? 2 : 1,
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  iconData,
                                  color: isSelected
                                      ? AppColors.primary
                                      : Colors.grey[700],
                                  size: 28,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  label,
                                  style: GoogleFonts.poppins(
                                    fontSize: 10,
                                    color: isSelected
                                        ? AppColors.primary
                                        : Colors.grey[700],
                                    fontWeight: isSelected
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 16),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    'Close',
                    style: GoogleFonts.poppins(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

