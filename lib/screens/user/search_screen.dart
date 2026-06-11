// lib/screens/user/search_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../models/menu_package.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
import '../../services/menu_service_supabase.dart';

class SearchScreen extends StatefulWidget {
  final bool isAdmin;
  const SearchScreen({super.key, this.isAdmin = false});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _ctrl = TextEditingController();
  final _menuService = MenuService();
  List<MenuPackage> _results = [];
  bool _loading = false;
  bool _searched = false;
  String? _errorText;
  String _filterCategory = 'All';
  final _categories = ['All', 'Western', 'Asian', 'Fusion', 'Local'];

  Future<void> _search(String q) async {
    final query = q.trim();
    if (query.isEmpty) {
      setState(() {
        _results = [];
        _searched = false;
        _loading = false;
        _errorText = null;
      });
      return;
    }

    setState(() {
      _loading = true;
      _searched = true;
      _errorText = null;
    });

    try {
      final results = await _menuService.searchPackages(query);
      if (mounted) {
        setState(() {
          _results = _filterCategory == 'All'
              ? results
              : results.where((p) => p.category == _filterCategory).toList();
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _results = [];
          _loading = false;
          _errorText = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: TextField(
          controller: _ctrl,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'Search packages...',
            hintStyle: TextStyle(color: Colors.white60),
            border: InputBorder.none,
            filled: false,
          ),
          onSubmitted: _search,
        ),
        actions: [
          if (_ctrl.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                _ctrl.clear();
                setState(() {
                  _results = [];
                  _searched = false;
                  _errorText = null;
                });
              },
            ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => _search(_ctrl.text.trim()),
          ),
        ],
      ),
      body: Column(
        children: [
          // Category filter chips
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
            child: SizedBox(
              height: 34,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _categories.length,
                itemBuilder: (ctx, i) {
                  final cat = _categories[i];
                  final sel = cat == _filterCategory;
                  return GestureDetector(
                    onTap: () {
                      setState(() => _filterCategory = cat);
                      if (_searched) _search(_ctrl.text.trim());
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: sel ? AppColors.secondary : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: sel
                              ? AppColors.secondary
                              : Colors.grey.shade300,
                        ),
                      ),
                      child: Text(cat,
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: sel
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                              color: sel
                                  ? AppColors.primary
                                  : AppColors.textMedium)),
                    ),
                  );
                },
              ),
            ),
          ),

          Expanded(
            child: _loading
                ? const Padding(
                    padding: EdgeInsets.all(16),
                    child: ShimmerList(count: 4))
                : _errorText != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.error_outline,
                                  size: 44, color: AppColors.cancelRed),
                              const SizedBox(height: 12),
                              const Text('Search failed',
                                  style: TextStyle(
                                      color: AppColors.textDark,
                                      fontWeight: FontWeight.w700)),
                              const SizedBox(height: 8),
                              Text(
                                _errorText!,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                    color: AppColors.textMedium,
                                    fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      )
                : !_searched
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.search,
                                size: 60,
                                color: AppColors.textLight.withOpacity(0.5)),
                            const SizedBox(height: 10),
                            const Text('Search menu packages',
                                style: TextStyle(
                                    color: AppColors.textLight,
                                    fontSize: 15)),
                          ],
                        ),
                      )
                    : _results.isEmpty
                        ? Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.search_off,
                    size: 60,
                                    color: AppColors.textLight
                                        .withOpacity(0.5)),
                const SizedBox(height: 10),
                const Text('No packages found',
                    style: TextStyle(
                        color: AppColors.textLight,
                        fontSize: 15)),
              ],
            ),
          )
                        : GridView.builder(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 0.72,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                            ),
                            itemCount: _results.length,
                            itemBuilder: (ctx, i) => PackageCard(
                              package: _results[i],
                              onTap: () {
                                final route = widget.isAdmin
                                    ? '/admin/packages/edit'
                                    : '/home/package/${_results[i].id}';
                                context.push(route, extra: _results[i]);
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}
