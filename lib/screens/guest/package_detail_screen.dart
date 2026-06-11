// lib/screens/guest/package_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/menu_package.dart';
import '../../services/firestore_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
import '../../services/menu_service_supabase.dart';

class PackageDetailScreen extends StatefulWidget {
  final MenuPackage package;
  final bool isGuest;

  const PackageDetailScreen(
      {super.key, required this.package, this.isGuest = false});

  @override
  State<PackageDetailScreen> createState() => _PackageDetailScreenState();
}

class _PackageDetailScreenState extends State<PackageDetailScreen> {
  int _currentImage = 0;
  final _menuService = MenuService();

  @override
  Widget build(BuildContext context) {
    final pkg = widget.package;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            backgroundColor: AppColors.primary,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => context.pop(),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                children: [
                  if (pkg.imageUrls.isNotEmpty)
                    PageView.builder(
                      itemCount: pkg.imageUrls.length,
                      onPageChanged: (i) =>
                          setState(() => _currentImage = i),
                      itemBuilder: (ctx, i) => CachedNetworkImage(
                        imageUrl: pkg.imageUrls[i],
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(
                            color: AppColors.shimmerBase),
                        errorWidget: (_, __, ___) =>
                            Container(color: AppColors.shimmerBase,
                                child: const Icon(Icons.restaurant,
                                    color: Colors.white54, size: 60)),
                      ),
                    )
                  else
                    Container(
                      color: AppColors.primary,
                      child: const Icon(Icons.restaurant_menu,
                          color: AppColors.secondary, size: 80),
                    ),
                  if (pkg.imageUrls.length > 1)
                    Positioned(
                      bottom: 12,
                      left: 0,
                      right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          pkg.imageUrls.length,
                          (i) => AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            width: i == _currentImage ? 16 : 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: i == _currentImage
                                  ? AppColors.secondary
                                  : Colors.white54,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(pkg.name,
                                style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textDark)),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.secondary.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(pkg.category,
                                  style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.secondary,
                                      fontWeight: FontWeight.w500)),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'RM ${pkg.pricePerGuest.toStringAsFixed(0)}',
                            style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                color: AppColors.secondary),
                          ),
                          const Text('per guest',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textMedium)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Guest range
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.people_outline,
                            color: AppColors.secondary, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Suitable for ${pkg.minGuests}–${pkg.maxGuests} guests',
                          style: const TextStyle(
                              color: AppColors.textMedium, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Description
                  const Text('About this package',
                      style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: AppColors.textDark)),
                  const SizedBox(height: 8),
                  Text(pkg.description,
                      style: const TextStyle(
                          color: AppColors.textMedium,
                          height: 1.5,
                          fontSize: 14)),
                  const SizedBox(height: 16),

                  // Includes
                  if (pkg.includes.isNotEmpty) ...[
                    const Text("What's Included",
                        style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: AppColors.textDark)),
                    const SizedBox(height: 8),
                    ...pkg.includes.map((item) => Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(children: [
                            const Icon(Icons.check_circle,
                                color: AppColors.success, size: 16),
                            const SizedBox(width: 8),
                            Text(item,
                                style: const TextStyle(
                                    fontSize: 14,
                                    color: AppColors.textMedium)),
                          ]),
                        )),
                    const SizedBox(height: 16),
                  ],

                  // People also view
                  const Text('People also view',
                      style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: AppColors.textDark)),
                  const SizedBox(height: 10),
                  FutureBuilder<List<MenuPackage>>(
                    future: _menuService.getMostFavorited(),
                    builder: (ctx, snap) {
                      if (!snap.hasData) {
                        return const SizedBox(height: 100);
                      }
                      final others = snap.data!
                          .where((p) => p.id != pkg.id)
                          .take(3)
                          .toList();
                      return SizedBox(
                        height: 110,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: others.length,
                          itemBuilder: (ctx, i) => GestureDetector(
                            onTap: () {
                              final route = widget.isGuest
                                  ? '/guest/package/${others[i].id}'
                                  : '/home/package/${others[i].id}';
                              context.push(route, extra: others[i]);
                            },
                            child: Container(
                              width: 100,
                              margin: const EdgeInsets.only(right: 10),
                              child: Column(children: [
                                Expanded(
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: others[i].imageUrls.isNotEmpty
                                        ? CachedNetworkImage(
                                            imageUrl:
                                                others[i].imageUrls.first,
                                            fit: BoxFit.cover,
                                            width: double.infinity)
                                        : Container(
                                            color: AppColors.shimmerBase),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(others[i].name,
                                    style: const TextStyle(
                                        fontSize: 11,
                                        color: AppColors.textDark),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis),
                              ]),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: widget.isGuest
              ? GoldButton(
                  text: 'LOGIN TO BOOK',
                  onPressed: () => context.go('/auth/login'),
                )
              : GoldButton(
                  text: 'SELECT PACKAGE',
                  onPressed: () =>
                      context.push('/home/book', extra: pkg),
                ),
        ),
      ),
    );
  }
}
