class SpecialOfferModel {
  final String? id;
  final String title;
  final String subtitle;
  final String badgeText;
  final String discountText;
  final String buttonText;
  final String imageUrl;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  SpecialOfferModel({
    this.id,
    required this.title,
    required this.subtitle,
    required this.badgeText,
    required this.discountText,
    required this.buttonText,
    required this.imageUrl,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'subtitle': subtitle,
      'badgeText': badgeText,
      'discountText': discountText,
      'buttonText': buttonText,
      'imageUrl': imageUrl,
      'isActive': isActive,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  factory SpecialOfferModel.fromMap(String id, Map<String, dynamic> map) {
    return SpecialOfferModel(
      id: id,
      title: map['title'] ?? '',
      subtitle: map['subtitle'] ?? '',
      badgeText: map['badgeText'] ?? '',
      discountText: map['discountText'] ?? '',
      buttonText: map['buttonText'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      isActive: map['isActive'] ?? true,
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : null,
      updatedAt: map['updatedAt'] != null
          ? DateTime.parse(map['updatedAt'])
          : null,
    );
  }

  SpecialOfferModel copyWith({
    String? id,
    String? title,
    String? subtitle,
    String? badgeText,
    String? discountText,
    String? buttonText,
    String? imageUrl,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SpecialOfferModel(
      id: id ?? this.id,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      badgeText: badgeText ?? this.badgeText,
      discountText: discountText ?? this.discountText,
      buttonText: buttonText ?? this.buttonText,
      imageUrl: imageUrl ?? this.imageUrl,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

