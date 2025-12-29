class ProductModel {
  final String? id;
  final String name;
  final String description;
  final double originalPrice; 
  final double price; 
  final double discount; 
  final String categoryId;
  final String categoryName; 
  final String? imageUrl; 
  final List<String> imageUrls; 
  final int stock;
  final bool isActive;
  final bool isRecommended; 
  final DateTime? createdAt;
  final DateTime? updatedAt;

  ProductModel({
    this.id,
    required this.name,
    required this.description,
    required this.originalPrice,
    required this.price,
    required this.discount,
    required this.categoryId,
    required this.categoryName,
    this.imageUrl,
    this.imageUrls = const [],
    this.stock = 0,
    this.isActive = true,
    this.isRecommended = false,
    this.createdAt,
    this.updatedAt,
  });

  
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'originalPrice': originalPrice,
      'price': price,
      'discount': discount,
      
      'categoryName': categoryName,
      if (imageUrl != null) 'imageUrl': imageUrl, 
      if (imageUrls.isNotEmpty) 'imageUrls': imageUrls, 
      'stock': stock,
      'isActive': isActive,
      'isRecommended': isRecommended,
      if (createdAt != null) 'createdAt': createdAt,
      if (updatedAt != null) 'updatedAt': updatedAt,
    };
  }

  
  factory ProductModel.fromMap(String id, Map<String, dynamic> map) {
    return ProductModel(
      id: id,
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      originalPrice: (map['originalPrice'] ?? 0.0).toDouble(),
      price: (map['price'] ?? 0.0).toDouble(),
      discount: (map['discount'] ?? 0.0).toDouble(),
      
      categoryId: map['categoryId'] ?? map['categoryName'] ?? '', 
      categoryName: map['categoryName'] ?? '',
      imageUrl: map['imageUrl'],
      imageUrls: map['imageUrls'] != null 
          ? List<String>.from(map['imageUrls'])
          : (map['imageUrl'] != null ? [map['imageUrl'] as String] : []), 
      stock: map['stock'] ?? 0,
      isActive: map['isActive'] ?? true,
      isRecommended: map['isRecommended'] ?? false,
      createdAt: map['createdAt']?.toDate(),
      updatedAt: map['updatedAt']?.toDate(),
    );
  }

  
  double get discountPercentage {
    if (originalPrice <= 0) return 0;
    return ((originalPrice - price) / originalPrice) * 100;
  }

  
  String get formattedPrice => '\$${price.toStringAsFixed(2)}';
  String get formattedOriginalPrice => '\$${originalPrice.toStringAsFixed(2)}';
  String get formattedDiscount => '${discountPercentage.toStringAsFixed(0)}% Off';

  
  ProductModel copyWith({
    String? id,
    String? name,
    String? description,
    double? originalPrice,
    double? price,
    double? discount,
    String? categoryId,
    String? categoryName,
    String? imageUrl,
    List<String>? imageUrls,
    int? stock,
    bool? isActive,
    bool? isRecommended,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ProductModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      originalPrice: originalPrice ?? this.originalPrice,
      price: price ?? this.price,
      discount: discount ?? this.discount,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      imageUrl: imageUrl ?? this.imageUrl,
      imageUrls: imageUrls ?? this.imageUrls,
      stock: stock ?? this.stock,
      isActive: isActive ?? this.isActive,
      isRecommended: isRecommended ?? this.isRecommended,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
