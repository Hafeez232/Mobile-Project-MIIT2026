// lib/screens/user/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../../services/firestore_service.dart';
import '../../models/menu_package.dart';
import '../../widgets/common_widgets.dart';

class ProfileScreen extends StatefulWidget {
  final VoidCallback? onOpenReservations;

  const ProfileScreen({super.key, this.onOpenReservations});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _auth = AuthService();
  UserModel? _user;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final u = await _auth.getCurrentUserModel();
    if (mounted) setState(() { _user = u; _loading = false; });
  }

  Future<void> _logout() async {
    await _auth.signOut();
    if (!mounted) return;
    context.go('/guest');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Profile')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _user == null
              ? const Center(child: Text('Unable to load profile'))
              : ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    // Avatar + name
                    Center(
                      child: Column(children: [
                        CircleAvatar(
                          radius: 44,
                          backgroundColor: AppColors.primary,
                          backgroundImage: _user!.profileImageUrl != null
                              ? NetworkImage(_user!.profileImageUrl!)
                              : null,
                          child: _user!.profileImageUrl == null
                              ? Text(
                                  _user!.name.isNotEmpty
                                      ? _user!.name[0].toUpperCase()
                                      : '?',
                                  style: const TextStyle(
                                      fontSize: 32,
                                      color: AppColors.secondary,
                                      fontWeight: FontWeight.w700))
                              : null,
                        ),
                        const SizedBox(height: 12),
                        Text(_user!.name,
                            style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textDark)),
                        Text(_user!.email,
                            style: const TextStyle(
                                color: AppColors.textMedium,
                                fontSize: 13)),
                      ]),
                    ),
                    const SizedBox(height: 28),

                    // Info card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(children: [
                        _infoRow(Icons.email_outlined, 'Email',
                            _user!.email),
                        const Divider(height: 20),
                        _infoRow(Icons.phone_outlined, 'Phone',
                            _user!.phone),
                      ]),
                    ),
                    const SizedBox(height: 16),

                    // Menu items
                    _menuItem(Icons.calendar_today_outlined,
                        'My Reservations', () {
                      final onOpenReservations = widget.onOpenReservations;
                      if (onOpenReservations != null) {
                        onOpenReservations();
                      } else {
                        context.push('/home/reservations');
                      }
                    }),
                    const SizedBox(height: 8),
                    _menuItem(Icons.credit_card,
                        'Bank Card Payment', () {
                      context.push('/home/payment-cards');
                    }),
                    const SizedBox(height: 8),
                    _menuItem(
                        Icons.logout, 'Logout', _logout,
                        color: AppColors.cancelRed),
                  ],
                ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) => Row(
        children: [
          Icon(icon, color: AppColors.secondary, size: 20),
          const SizedBox(width: 12),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label,
                style: const TextStyle(
                    fontSize: 11, color: AppColors.textLight)),
            Text(value,
                style: const TextStyle(
                    fontSize: 14, color: AppColors.textDark)),
          ]),
        ],
      );

  Widget _menuItem(IconData icon, String label, VoidCallback onTap,
      {Color? color}) =>
      InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12)),
          child: Row(children: [
            Icon(icon,
                color: color ?? AppColors.primary, size: 22),
            const SizedBox(width: 12),
            Text(label,
                style: TextStyle(
                    fontSize: 15,
                    color: color ?? AppColors.textDark,
                    fontWeight: FontWeight.w500)),
            const Spacer(),
            Icon(Icons.chevron_right,
                color: color ?? AppColors.textLight),
          ]),
        ),
      );
}

