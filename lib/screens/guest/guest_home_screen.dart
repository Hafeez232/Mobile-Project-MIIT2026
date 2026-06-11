// lib/screens/guest/guest_home_screen.dart
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:go_router/go_router.dart';
import '../../models/menu_package.dart';
import '../../services/firestore_service.dart';
import '../../services/menu_service_supabase.dart';        // add this
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';

class GuestHomeScreen extends StatefulWidget {
  const GuestHomeScreen({super.key});

  @override
  State<GuestHomeScreen> createState() => _GuestHomeScreenState();
}

class _GuestHomeScreenState extends State<GuestHomeScreen>
    with WidgetsBindingObserver {
  final _menuService = MenuService();
  String _selectedCategory = 'All';
  final _categories = ['All', 'Western', 'Asian', 'Fusion', 'Local'];

  List<MenuPackage> _mostOrdered = [];
  List<MenuPackage> _menuItems = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadPackages();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _loadPackages();
  }

  Future<void> _loadPackages() async {
    try {
      final results = await Future.wait([
        _menuService.getMostFavorited(),
        _menuService.getMenuItems(
            category: _selectedCategory == 'All' ? null : _selectedCategory),
      ]);
      if (mounted) {
        setState(() {
          _mostOrdered = results[0];
          _menuItems = results[1];
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _onCategoryChanged(String cat) async {
    setState(() => _selectedCategory = cat);
    final items = await _menuService.getMenuItems(
        category: cat == 'All' ? null : cat);
    if (mounted) setState(() => _menuItems = items);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.restaurant_menu, color: AppColors.secondary, size: 22),
            SizedBox(width: 8),
            Text('Fine-Dine'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.login),
            onPressed: () => context.go('/auth/login'),
            tooltip: 'Login',
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, Color(0xFF2D2D4E)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Book Your Private Event',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 15)),
                      SizedBox(height: 4),
                      Text('Login or register to make a reservation',
                          style: TextStyle(color: Colors.white70, fontSize: 12)),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: () => context.go('/auth/login'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondary,
                    foregroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Login'),
                ),
              ],
            ),
          ),

          SizedBox(
            height: 36,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _categories.length,
              itemBuilder: (ctx, i) {
                final cat = _categories[i];
                final selected = cat == _selectedCategory;
                return GestureDetector(
                  onTap: () => _onCategoryChanged(cat),   // changed
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: selected ? AppColors.secondary : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: selected ? AppColors.secondary : Colors.grey.shade300,
                      ),
                    ),
                    child: Text(cat,
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                            color: selected ? AppColors.primary : AppColors.textMedium)),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(children: [
              const Text('Most Ordered',
                  style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: AppColors.textDark)),
              const Spacer(),
            ]),
          ),
          const SizedBox(height: 8),
          if (_loading)
            SizedBox(
              height: 120,
              child: Shimmer.fromColors(
                baseColor: AppColors.shimmerBase,
                highlightColor: AppColors.shimmerHighlight,
                child: Row(
                  children: List.generate(
                    3,
                    (_) => Container(
                      margin: const EdgeInsets.only(left: 16),
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ),
            )
          else
            SizedBox(
              height: 120,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _mostOrdered.length,
                itemBuilder: (ctx, i) {
                  final pkg = _mostOrdered[i];
                  return GestureDetector(
                    onTap: () => context.push('/guest/package/${pkg.id}', extra: pkg),
                    child: Container(
                      width: 105,
                      margin: const EdgeInsets.only(right: 10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        image: pkg.imageUrls.isNotEmpty
                            ? DecorationImage(
                                image: NetworkImage(pkg.imageUrls.first),
                                fit: BoxFit.cover)
                            : null,
                        color: AppColors.shimmerBase,
                      ),
                    ),
                  );
                },
              ),
            ),
          const SizedBox(height: 16),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(children: [
              const Text('Menu',
                  style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: AppColors.textDark)),
            ]),
          ),
          const SizedBox(height: 8),

          Expanded(
            child: _loading
                ? const Padding(
                    padding: EdgeInsets.all(16),
                    child: ShimmerList(count: 3),
                  )
                : _menuItems.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.restaurant_menu, size: 48, color: AppColors.textLight),
                            SizedBox(height: 8),
                            Text('No packages available',
                                style: TextStyle(color: AppColors.textLight)),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadPackages,
                        child: GridView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.65,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                          ),
                          itemCount: _menuItems.length,
                          itemBuilder: (ctx, i) => PackageCard(
                            package: _menuItems[i],
                            onTap: () => context.push('/guest/package/${_menuItems[i].id}', extra: _menuItems[i]),
                            onAdd: () => context.go('/auth/login'),
                            showAdd: true,
                          ),
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}