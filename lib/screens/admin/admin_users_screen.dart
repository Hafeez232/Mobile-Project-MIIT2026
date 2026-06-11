// lib/screens/admin/admin_users_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../models/user_model.dart';
import '../../services/firestore_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  final _db = FirestoreService();
  String _search = '';

  Future<void> _deleteUser(UserModel user) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete User'),
        content: Text('Delete user "${user.name}"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.cancelRed),
            child: const Text('Delete',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (ok == true) await _db.deleteUser(user.uid);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Manage Users'),
        leading: context.canPop()
            ? BackButton(onPressed: () => context.pop())
            : null,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search users...',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (v) =>
                  setState(() => _search = v.toLowerCase()),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<UserModel>>(
              stream: _db.usersStream(),
              builder: (ctx, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Padding(
                      padding: EdgeInsets.all(16),
                      child: ShimmerList(count: 5));
                }

                if (snap.hasError) {
                  final errorText = snap.error.toString();
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            color: AppColors.cancelRed,
                            size: 40,
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Failed to load users',
                            style: TextStyle(
                              color: AppColors.textDark,
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            errorText,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: AppColors.textMedium,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                var users = snap.data ?? [];
                if (_search.isNotEmpty) {
                  users = users
                      .where((u) =>
                          u.name.toLowerCase().contains(_search) ||
                          u.email.toLowerCase().contains(_search))
                      .toList();
                }

                if (users.isEmpty) {
                  return const Center(
                      child: Text('No users found.',
                          style: TextStyle(
                              color: AppColors.textLight)));
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 4),
                  itemCount: users.length,
                  itemBuilder: (ctx, i) {
                    final u = users[i];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor:
                              AppColors.primary.withOpacity(0.1),
                          child: Text(
                            u.name.isNotEmpty
                                ? u.name[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w700),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(u.name,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14)),
                              Text(u.email,
                                  style: const TextStyle(
                                      color: AppColors.textMedium,
                                      fontSize: 12),
                                  overflow: TextOverflow.ellipsis),
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: () =>
                              context.push('/admin/users/${u.uid}',
                                  extra: {
                                    'user': u,
                                    'isEdit': true
                                  }),
                          style: TextButton.styleFrom(
                            backgroundColor:
                                AppColors.primary.withOpacity(0.08),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                          ),
                          child: const Text('EDIT',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w700)),
                        ),
                        const SizedBox(width: 6),
                        TextButton(
                          onPressed: () => _deleteUser(u),
                          style: TextButton.styleFrom(
                            backgroundColor:
                                AppColors.cancelRed.withOpacity(0.1),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                          ),
                          child: const Text('DELETE',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.cancelRed,
                                  fontWeight: FontWeight.w700)),
                        ),
                      ]),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

// lib/screens/admin/admin_user_detail_screen.dart
