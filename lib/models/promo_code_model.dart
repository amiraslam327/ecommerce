class PromoCodeModel {
  final String? id;
  final String code;
  final double discountValue; 
  final bool isPercentage; 
  final bool isActive;
  final DateTime? validFrom;
  final DateTime? validUntil;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  PromoCodeModel({
    this.id,
    required this.code,
    required this.discountValue,
    this.isPercentage = true,
    this.isActive = true,
    this.validFrom,
    this.validUntil,
    this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'code': code,
      'discountValue': discountValue,
      'isPercentage': isPercentage,
      'isActive': isActive,
      'validFrom': validFrom?.toIso8601String(),
      'validUntil': validUntil?.toIso8601String(),
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  factory PromoCodeModel.fromMap(String id, Map<String, dynamic> map) {
    return PromoCodeModel(
      id: id,
      code: map['code'] as String,
      discountValue: (map['discountValue'] as num).toDouble(),
      isPercentage: map['isPercentage'] as bool? ?? true,
      isActive: map['isActive'] as bool? ?? true,
      validFrom: map['validFrom'] != null
          ? DateTime.parse(map['validFrom'] as String)
          : null,
      validUntil: map['validUntil'] != null
          ? DateTime.parse(map['validUntil'] as String)
          : null,
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'] as String)
          : null,
      updatedAt: map['updatedAt'] != null
          ? DateTime.parse(map['updatedAt'] as String)
          : null,
    );
  }

  PromoCodeModel copyWith({
    String? id,
    String? code,
    double? discountValue,
    bool? isPercentage,
    bool? isActive,
    DateTime? validFrom,
    DateTime? validUntil,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PromoCodeModel(
      id: id ?? this.id,
      code: code ?? this.code,
      discountValue: discountValue ?? this.discountValue,
      isPercentage: isPercentage ?? this.isPercentage,
      isActive: isActive ?? this.isActive,
      validFrom: validFrom ?? this.validFrom,
      validUntil: validUntil ?? this.validUntil,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

