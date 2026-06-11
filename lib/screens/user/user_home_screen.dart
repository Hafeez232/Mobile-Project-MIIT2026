// lib/screens/user/user_home_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import '../../models/menu_package.dart';
import '../../services/firestore_service.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
import '../user/profile_screen.dart';
import '../user/my_reservations_screen.dart';
import '../user/notifications_screen.dart';
import '../../services/menu_service_supabase.dart';

class UserHomeScreen extends StatefulWidget {
  final int initialIndex;

  const UserHomeScreen({super.key, this.initialIndex = 0});

  @override
  State<UserHomeScreen> createState() => _UserHomeScreenState();
}

class _UserHomeScreenState extends State<UserHomeScreen> {
  late int _navIndex;
  final _db = FirestoreService();
  final _auth = AuthService();
  String _selectedCategory = 'All';
  final _categories = ['All', 'Western', 'Asian', 'Fusion', 'Local'];

  @override
  void initState() {
    super.initState();
    _navIndex = widget.initialIndex;
  }

  @override
  void didUpdateWidget(covariant UserHomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialIndex != widget.initialIndex) {
      _navIndex = widget.initialIndex;
    }
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      const _HomeTab(),
      _ReservationsTab(onBrowsePackages: () => setState(() => _navIndex = 0)),
      _ProfileTab(onOpenReservations: () => setState(() => _navIndex = 1)),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _navIndex,
        children: pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _navIndex,
        onTap: (i) => setState(() => _navIndex = i),
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Home'),
          BottomNavigationBarItem(
              icon: Icon(Icons.calendar_today_outlined),
              activeIcon: Icon(Icons.calendar_today),
              label: 'My Bookings'),
          BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Profile'),
        ],
      ),
    );
  }
}

class _HomeTab extends StatefulWidget {
  const _HomeTab();

  @override
  State<_HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<_HomeTab>
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
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () => showNotificationsPanel(context),
          ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => context.push('/home/search'),
          ),
        ],
      ),
      body: Column(
        children: [
          // Category filter
          const SizedBox(height: 12),
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
                  onTap: () => _onCategoryChanged(cat),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: selected
                          ? AppColors.secondary
                          : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: selected
                            ? AppColors.secondary
                            : Colors.grey.shade300,
                      ),
                    ),
                    child: Text(cat,
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: selected
                                ? FontWeight.w600
                                : FontWeight.w400,
                            color: selected
                                ? AppColors.primary
                                : AppColors.textMedium)),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),

          // Most Ordered
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Text('Most Ordered',
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: AppColors.textDark)),
              ],
            ),
          ),
          const SizedBox(height: 8),
          if (_loading)
            SizedBox(
              height: 110,
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
                              borderRadius: BorderRadius.circular(10)))),
                ),
              ),
            )
          else
            SizedBox(
              height: 110,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _mostOrdered.length,
                itemBuilder: (ctx, i) {
                  final pkg = _mostOrdered[i];
                  return GestureDetector(
                    onTap: () => context.push(
                        '/home/package/${pkg.id}',
                        extra: pkg),
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
                      child: pkg.imageUrls.isEmpty
                          ? const Icon(Icons.restaurant, color: Colors.white54)
                          : null,
                    ),
                  );
                },
              ),
            ),
          const SizedBox(height: 16),

          // Menu label
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

          // Package grid
          Expanded(
            child: _loading
                ? const Padding(
                    padding: EdgeInsets.all(16),
                    child: ShimmerList(count: 3))
                : _menuItems.isEmpty
                    ? const Center(
                        child: Text('No packages available',
                            style: TextStyle(color: AppColors.textLight)))
                    : RefreshIndicator(
                        onRefresh: _loadPackages,
                        child: GridView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.65,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                          ),
                          itemCount: _menuItems.length,
                          itemBuilder: (ctx, i) => PackageCard(
                            package: _menuItems[i],
                            onTap: () => context.push('/home/package/${_menuItems[i].id}',
                                extra: _menuItems[i]),
                            onAdd: () => context.push('/home/book',
                                extra: _menuItems[i]),
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

class _ReservationsTab extends StatelessWidget {
  final VoidCallback onBrowsePackages;

  const _ReservationsTab({required this.onBrowsePackages});

  @override
  Widget build(BuildContext context) {
    return MyReservationsScreen(onBrowsePackages: onBrowsePackages);
  }
}

class _ProfileTab extends StatelessWidget {
  final VoidCallback onOpenReservations;

  const _ProfileTab({required this.onOpenReservations});

  @override
  Widget build(BuildContext context) {
    return ProfileScreen(onOpenReservations: onOpenReservations);
  }
}
