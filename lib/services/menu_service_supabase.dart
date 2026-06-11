// lib/services/menu_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/menu_package.dart';

class MenuService {
  final _supabase = Supabase.instance.client;

  Future<List<MenuPackage>> getMenuItems({String? category}) async {
    var query = _supabase
        .from('menu_items_with_favorites')
        .select()
        .eq('is_available', true);
    if (category != null) query = query.eq('category', category);
    final data = await query.order('name', ascending: true);

    print('RAW DATA: $data');

    return (data as List).map((e) => MenuPackage.fromSupabase(e)).toList();
  }

  Future<List<MenuPackage>> getMostFavorited() async {
    final data = await _supabase
        .from('menu_items_with_favorites')
        .select()
        .eq('is_available', true)
        .order('favorite_count', ascending: false)
        .limit(10);
    return (data as List).map((e) => MenuPackage.fromSupabase(e)).toList();
  }

  Future<List<MenuPackage>> getAllPackages() async {
    final data = await _supabase
        .from('menu_items_with_favorites')
        .select()
        .order('created_at', ascending: false);
    return (data as List).map((e) => MenuPackage.fromSupabase(e)).toList();
  }

  Future<List<MenuPackage>> searchPackages(String query) async {
    final q = query.trim();
    if (q.isEmpty) return [];

    final data = await _supabase
        .from('menu_items_with_favorites')
        .select()
        .or('name.ilike.%$q%,description.ilike.%$q%,category.ilike.%$q%')
        .eq('is_available', true);
    return (data as List).map((e) => MenuPackage.fromSupabase(e)).toList();
  }

  Future<void> addPackage(MenuPackage pkg) async {
    await _supabase.from('menu_items').insert({
      'name': pkg.name,
      'description': pkg.description,
      'price': pkg.pricePerGuest,
      'image_url': pkg.imageUrls.isNotEmpty ? pkg.imageUrls.first : null,
      'image_urls': pkg.imageUrls,
      'includes': pkg.includes,
      'category': pkg.category,
      'min_guests': pkg.minGuests,
      'max_guests': pkg.maxGuests,
      'is_available': pkg.isAvailable,
    });
  }

  Future<void> updatePackage(MenuPackage pkg) async {
    await _supabase.from('menu_items').update({
      'name': pkg.name,
      'description': pkg.description,
      'price': pkg.pricePerGuest,
      'image_url': pkg.imageUrls.isNotEmpty ? pkg.imageUrls.first : null,
      'image_urls': pkg.imageUrls,
      'includes': pkg.includes,
      'category': pkg.category,
      'min_guests': pkg.minGuests,
      'max_guests': pkg.maxGuests,
      'is_available': pkg.isAvailable,
    }).eq('id', pkg.id);
  }

  Future<void> deletePackage(String id) async {
    await _supabase.from('menu_items').delete().eq('id', id);
  }
}
