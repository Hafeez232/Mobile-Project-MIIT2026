class BankCard {
  final String id;
  final String userId;
  final String holderName;
  final String brand;
  final String last4;
  final int expiryMonth;
  final int expiryYear;
  final DateTime createdAt;

  BankCard({
    required this.id,
    required this.userId,
    required this.holderName,
    required this.brand,
    required this.last4,
    required this.expiryMonth,
    required this.expiryYear,
    required this.createdAt,
  });

  factory BankCard.fromMap(Map<String, dynamic> map, String id) {
    return BankCard(
      id: id,
      userId: map['userId'] ?? '',
      holderName: map['holderName'] ?? '',
      brand: map['brand'] ?? 'Card',
      last4: map['last4'] ?? '',
      expiryMonth: map['expiryMonth'] ?? 1,
      expiryYear: map['expiryYear'] ?? DateTime.now().year,
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as dynamic).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'holderName': holderName,
      'brand': brand,
      'last4': last4,
      'expiryMonth': expiryMonth,
      'expiryYear': expiryYear,
      'createdAt': createdAt,
    };
  }

  String get displayNumber => '**** **** **** $last4';
  String get expiryText =>
      '${expiryMonth.toString().padLeft(2, '0')}/${expiryYear.toString().substring(2)}';
}
