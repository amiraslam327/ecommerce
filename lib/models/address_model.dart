class AddressModel {
  final int? id;
  final String label;
  final String fullAddress;
  final String phone;
  final bool isDefault;

  AddressModel({
    this.id,
    required this.label,
    required this.fullAddress,
    required this.phone,
    this.isDefault = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'label': label,
      'fullAddress': fullAddress,
      'phone': phone,
      'isDefault': isDefault ? 1 : 0,
    };
  }

  factory AddressModel.fromMap(Map<String, dynamic> map) {
    return AddressModel(
      id: map['id'] as int?,
      label: map['label'] as String,
      fullAddress: map['fullAddress'] as String,
      phone: map['phone'] as String,
      isDefault: (map['isDefault'] as int) == 1,
    );
  }

  AddressModel copyWith({
    int? id,
    String? label,
    String? fullAddress,
    String? phone,
    bool? isDefault,
  }) {
    return AddressModel(
      id: id ?? this.id,
      label: label ?? this.label,
      fullAddress: fullAddress ?? this.fullAddress,
      phone: phone ?? this.phone,
      isDefault: isDefault ?? this.isDefault,
    );
  }
}

