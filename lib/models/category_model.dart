import 'package:flutter/material.dart';
import 'package:flutter_iconpicker/Serialization/icondata_serialization.dart' as icon_serialization;

class CategoryModel {
  final String? id;
  final String name;
  final String iconName;
  final Map<String, dynamic>? iconData;

  CategoryModel({
    this.id,
    required this.name,
    required this.iconName,
    this.iconData,
  });

  
  IconData getIcon() {
    
    if (iconData != null && iconData!.isNotEmpty) {
      try {
        final iconPickerIcon = icon_serialization.deserializeIcon(iconData!);
        if (iconPickerIcon != null) {
          return iconPickerIcon.data;
        }
      } catch (e) {
        debugPrint('Error deserializing iconData: $e');
        
      }
    }
    
    
    return Icons.sports_esports;
  }

  
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'iconName': iconName,
      if (iconData != null) 'iconData': iconData,
    };
  }

  
  factory CategoryModel.fromMap(String id, Map<String, dynamic> map) {
    Map<String, dynamic>? iconData;
    if (map['iconData'] != null) {
      if (map['iconData'] is Map) {
        iconData = Map<String, dynamic>.from(map['iconData'] as Map);
      } else if (map['iconData'] is Map<String, dynamic>) {
        iconData = map['iconData'] as Map<String, dynamic>;
      }
    }
    
    return CategoryModel(
      id: id,
      name: map['name'] ?? '',
      iconName: map['iconName'] ?? 'sports_esports',
      iconData: iconData,
    );
  }

}

