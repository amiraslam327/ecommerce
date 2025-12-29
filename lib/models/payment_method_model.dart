class PaymentMethodModel {
  final int? id;
  final String type; 
  final String cardNumber; 
  final String cardHolderName;
  final String expiryDate; 
  final String? cvv; 
  final bool isDefault;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  PaymentMethodModel({
    this.id,
    required this.type,
    required this.cardNumber,
    required this.cardHolderName,
    required this.expiryDate,
    this.cvv,
    this.isDefault = false,
    this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'cardNumber': cardNumber,
      'cardHolderName': cardHolderName,
      'expiryDate': expiryDate,
      'cvv': cvv,
      'isDefault': isDefault ? 1 : 0,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  factory PaymentMethodModel.fromMap(Map<String, dynamic> map) {
    return PaymentMethodModel(
      id: map['id'] as int?,
      type: map['type'] as String,
      cardNumber: map['cardNumber'] as String,
      cardHolderName: map['cardHolderName'] as String,
      expiryDate: map['expiryDate'] as String,
      cvv: map['cvv'] as String?,
      isDefault: (map['isDefault'] as int) == 1,
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'] as String)
          : null,
      updatedAt: map['updatedAt'] != null
          ? DateTime.parse(map['updatedAt'] as String)
          : null,
    );
  }

  PaymentMethodModel copyWith({
    int? id,
    String? type,
    String? cardNumber,
    String? cardHolderName,
    String? expiryDate,
    String? cvv,
    bool? isDefault,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PaymentMethodModel(
      id: id ?? this.id,
      type: type ?? this.type,
      cardNumber: cardNumber ?? this.cardNumber,
      cardHolderName: cardHolderName ?? this.cardHolderName,
      expiryDate: expiryDate ?? this.expiryDate,
      cvv: cvv ?? this.cvv,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  
  String get maskedCardNumber {
    if (cardNumber.length <= 4) return cardNumber;
    return '**** **** **** ${cardNumber.substring(cardNumber.length - 4)}';
  }

  
  String get cardTypeIcon {
    switch (type.toLowerCase()) {
      case 'visa':
        return '💳';
      case 'mastercard':
        return '💳';
      case 'amex':
        return '💳';
      default:
        return '💳';
    }
  }
}

