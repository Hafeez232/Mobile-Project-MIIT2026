// lib/models/menu_package.dart
class MenuPackage {
  final String id;
  final String name;
  final String description;
  final double pricePerGuest;
  final List<String> imageUrls;
  final List<String> includes;
  final String category;
  final int minGuests;
  final int maxGuests;
  final bool isAvailable;
  final int orderCount;      // kept as original
  final int favoriteCount;   // added for Supabase view
  final DateTime createdAt;

  MenuPackage({
    required this.id,
    required this.name,
    required this.description,
    required this.pricePerGuest,
    required this.imageUrls,
    required this.includes,
    this.category = 'All',
    this.minGuests = 10,
    this.maxGuests = 200,
    this.isAvailable = true,
    this.orderCount = 0,       // kept as original
    this.favoriteCount = 0,
    required this.createdAt,
  });

  // Original Firebase signature — kept so existing files don't break
  factory MenuPackage.fromMap(Map<String, dynamic> map, String id) {
    return MenuPackage(
      id: id,
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      pricePerGuest: (map['pricePerGuest'] ?? 0.0).toDouble(),
      imageUrls: List<String>.from(map['imageUrls'] ?? []),
      includes: List<String>.from(map['includes'] ?? []),
      category: map['category'] ?? 'All',
      minGuests: map['minGuests'] ?? 10,
      maxGuests: map['maxGuests'] ?? 200,
      isAvailable: map['isAvailable'] ?? true,
      orderCount: map['orderCount'] ?? 0,
      favoriteCount: map['favorite_count'] ?? 0,
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as dynamic).toDate()
          : DateTime.now(),
    );
  }

  // Supabase-specific constructor — use this for Supabase calls
  factory MenuPackage.fromSupabase(Map<String, dynamic> map) {
    // handle both single image_url and array image_urls
    List<String> imageUrls = [];
    if (map['image_urls'] != null) {
      imageUrls = List<String>.from(map['image_urls']);
    } else if (map['image_url'] != null) {
      imageUrls = [map['image_url'] as String];
    }

    return MenuPackage(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      pricePerGuest: (map['price'] ?? 0.0).toDouble(),
      imageUrls: imageUrls,   // ← uses the fixed list above
      includes: List<String>.from(map['includes'] ?? []),
      category: map['category'] ?? 'All',
      minGuests: map['min_guests'] ?? 10,
      maxGuests: map['max_guests'] ?? 200,
      isAvailable: map['is_available'] ?? true,
      orderCount: map['order_count'] ?? 0,
      favoriteCount: map['favorite_count'] ?? 0,
      createdAt: DateTime.parse(map['created_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'pricePerGuest': pricePerGuest,
      'imageUrls': imageUrls,
      'includes': includes,
      'category': category,
      'minGuests': minGuests,
      'maxGuests': maxGuests,
      'isAvailable': isAvailable,
      'orderCount': orderCount,
      'createdAt': createdAt,
    };
  }

  MenuPackage copyWith({
    String? name,
    String? description,
    double? pricePerGuest,
    List<String>? imageUrls,
    List<String>? includes,
    String? category,
    int? minGuests,
    int? maxGuests,
    bool? isAvailable,
    int? orderCount,
    int? favoriteCount,
  }) {
    return MenuPackage(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      pricePerGuest: pricePerGuest ?? this.pricePerGuest,
      imageUrls: imageUrls ?? this.imageUrls,
      includes: includes ?? this.includes,
      category: category ?? this.category,
      minGuests: minGuests ?? this.minGuests,
      maxGuests: maxGuests ?? this.maxGuests,
      isAvailable: isAvailable ?? this.isAvailable,
      orderCount: orderCount ?? this.orderCount,
      favoriteCount: favoriteCount ?? this.favoriteCount,
      createdAt: createdAt,
    );
  }
}