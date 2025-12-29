class OrderModel {
  final String? id;
  final String userId;
  final String userName;
  final String shippingAddress;
  final String phoneNumber;
  final String paymentMethod; 
  final String? paymentMethodType; 
  final String? paymentCardNumber; 
  final List<OrderProduct> products;
  final double totalPrice;
  final double productDiscount;
  final double promoCodeDiscount;
  final double deliveryFee;
  final double finalTotal;
  final String? promoCode;
  final String status; 
  final DateTime createdAt;
  final DateTime? updatedAt;

  OrderModel({
    this.id,
    required this.userId,
    required this.userName,
    required this.shippingAddress,
    required this.phoneNumber,
    required this.paymentMethod,
    this.paymentMethodType,
    this.paymentCardNumber,
    required this.products,
    required this.totalPrice,
    required this.productDiscount,
    required this.promoCodeDiscount,
    required this.deliveryFee,
    required this.finalTotal,
    this.promoCode,
    this.status = 'pending',
    required this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'shippingAddress': shippingAddress,
      'phoneNumber': phoneNumber,
      'paymentMethod': paymentMethod,
      if (paymentMethodType != null) 'paymentMethodType': paymentMethodType,
      if (paymentCardNumber != null) 'paymentCardNumber': paymentCardNumber,
      'products': products.map((p) => p.toMap()).toList(),
      'totalPrice': totalPrice,
      'productDiscount': productDiscount,
      'promoCodeDiscount': promoCodeDiscount,
      'deliveryFee': deliveryFee,
      'finalTotal': finalTotal,
      if (promoCode != null) 'promoCode': promoCode,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
    };
  }

  factory OrderModel.fromMap(String id, Map<String, dynamic> map) {
    return OrderModel(
      id: id,
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      shippingAddress: map['shippingAddress'] ?? '',
      phoneNumber: map['phoneNumber'] ?? '',
      paymentMethod: map['paymentMethod'] ?? '',
      paymentMethodType: map['paymentMethodType'],
      paymentCardNumber: map['paymentCardNumber'],
      products: (map['products'] as List<dynamic>?)
              ?.map((p) => OrderProduct.fromMap(p as Map<String, dynamic>))
              .toList() ??
          [],
      totalPrice: (map['totalPrice'] as num?)?.toDouble() ?? 0.0,
      productDiscount: (map['productDiscount'] as num?)?.toDouble() ?? 0.0,
      promoCodeDiscount: (map['promoCodeDiscount'] as num?)?.toDouble() ?? 0.0,
      deliveryFee: (map['deliveryFee'] as num?)?.toDouble() ?? 0.0,
      finalTotal: (map['finalTotal'] as num?)?.toDouble() ?? 0.0,
      promoCode: map['promoCode'],
      status: map['status'] ?? 'pending',
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null
          ? DateTime.parse(map['updatedAt'])
          : null,
    );
  }

  OrderModel copyWith({
    String? id,
    String? userId,
    String? userName,
    String? shippingAddress,
    String? phoneNumber,
    String? paymentMethod,
    String? paymentMethodType,
    String? paymentCardNumber,
    List<OrderProduct>? products,
    double? totalPrice,
    double? productDiscount,
    double? promoCodeDiscount,
    double? deliveryFee,
    double? finalTotal,
    String? promoCode,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return OrderModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      shippingAddress: shippingAddress ?? this.shippingAddress,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentMethodType: paymentMethodType ?? this.paymentMethodType,
      paymentCardNumber: paymentCardNumber ?? this.paymentCardNumber,
      products: products ?? this.products,
      totalPrice: totalPrice ?? this.totalPrice,
      productDiscount: productDiscount ?? this.productDiscount,
      promoCodeDiscount: promoCodeDiscount ?? this.promoCodeDiscount,
      deliveryFee: deliveryFee ?? this.deliveryFee,
      finalTotal: finalTotal ?? this.finalTotal,
      promoCode: promoCode ?? this.promoCode,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class OrderProduct {
  final String productId;
  final String productName;
  final int quantity;
  final double originalPrice;
  final double price;
  final double discount;
  final String? imageUrl;

  OrderProduct({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.originalPrice,
    required this.price,
    required this.discount,
    this.imageUrl,
  });

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'productName': productName,
      'quantity': quantity,
      'originalPrice': originalPrice,
      'price': price,
      'discount': discount,
      if (imageUrl != null) 'imageUrl': imageUrl,
    };
  }

  factory OrderProduct.fromMap(Map<String, dynamic> map) {
    return OrderProduct(
      productId: map['productId'] ?? '',
      productName: map['productName'] ?? '',
      quantity: map['quantity'] ?? 1,
      originalPrice: (map['originalPrice'] as num?)?.toDouble() ?? 0.0,
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
      discount: (map['discount'] as num?)?.toDouble() ?? 0.0,
      imageUrl: map['imageUrl'],
    );
  }
}

