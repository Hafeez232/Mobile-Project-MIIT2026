// lib/screens/user/my_reservations_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/menu_package.dart';
import '../../models/reservation.dart';
import '../../services/firestore_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
import 'notifications_screen.dart';

class MyReservationsScreen extends StatelessWidget {
  final VoidCallback? onBrowsePackages;

  const MyReservationsScreen({super.key, this.onBrowsePackages});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final db = FirestoreService();

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
      body: StreamBuilder<List<Reservation>>(
        stream: db.userReservationsStream(uid),
        builder: (ctx, snap) {
          final pageTitle = const Text('My Reservation',
              style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 24,
                  color: AppColors.textDark));
          final upcomingTitle = const Text('Upcoming reservations',
              style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: AppColors.textDark));

          if (snap.connectionState == ConnectionState.waiting) {
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                pageTitle,
                const SizedBox(height: 18),
                upcomingTitle,
                const SizedBox(height: 10),
                const ShimmerList(count: 4),
              ],
            );
          }
          if (!snap.hasData || snap.data!.isEmpty) {
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                pageTitle,
                const SizedBox(height: 18),
                upcomingTitle,
                const SizedBox(height: 120),
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.calendar_today_outlined,
                          size: 56, color: AppColors.textLight),
                      const SizedBox(height: 12),
                      const Text('No reservations yet',
                          style: TextStyle(
                              color: AppColors.textLight, fontSize: 16)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: onBrowsePackages ??
                            () {
                              context.go('/home?tab=home');
                            },
                        child: const Text('Browse Packages'),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }

          final upcoming = snap.data!
              .where((r) => r.status == ReservationStatus.upcoming)
              .toList();
          final past = snap.data!
              .where((r) => r.status != ReservationStatus.upcoming)
              .toList();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              pageTitle,
              const SizedBox(height: 18),
              upcomingTitle,
              const SizedBox(height: 10),
              if (upcoming.isNotEmpty)
                ...upcoming.map((r) => ReservationCard(
                      reservation: r,
                      onTap: () => context.push(
                          '/home/reservations/${r.id}',
                          extra: r),
                    ))
              else
                const Padding(
                  padding: EdgeInsets.only(bottom: 16),
                  child: Text('No upcoming reservations',
                      style: TextStyle(
                          color: AppColors.textLight, fontSize: 13)),
                ),
              const SizedBox(height: 16),
              if (past.isNotEmpty) ...[
                const Text('Past reservations',
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: AppColors.textDark)),
                const SizedBox(height: 10),
                ...past.map((r) => ReservationCard(
                      reservation: r,
                      onTap: () => context.push(
                          '/home/reservations/${r.id}',
                          extra: r),
                    )),
              ],
            ],
          );
        },
      ),
    );
  }
}

class ReservationDetailScreen extends StatefulWidget {
  final Reservation reservation;

  const ReservationDetailScreen({super.key, required this.reservation});

  @override
  State<ReservationDetailScreen> createState() =>
      _ReservationDetailScreenState();
}

class _ReservationDetailScreenState
    extends State<ReservationDetailScreen> {
  late Reservation _res;
  final _db = FirestoreService();
  bool _isCancelling = false;

  @override
  void initState() {
    super.initState();
    _res = widget.reservation;
  }

  Future<void> _cancelReservation() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Reservation'),
        content: const Text(
            'Are you sure you want to cancel this booking?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('No')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.cancelRed),
            child: const Text('Yes, Cancel',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;
    setState(() => _isCancelling = true);
    try {
      await _db.cancelReservation(_res.id);
      if (!mounted) return;
      setState(() =>
          _res = _res.copyWith(status: ReservationStatus.cancelled));
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Booking cancelled successfully'),
        backgroundColor: AppColors.success,
      ));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppColors.error));
    } finally {
      if (mounted) setState(() => _isCancelling = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isUpcoming = _res.status == ReservationStatus.upcoming;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('My Reservations'),
        leading: BackButton(onPressed: () => context.pop()),
        actions: isUpcoming
            ? [
                TextButton.icon(
                  onPressed: () async {
                    final package = MenuPackage(
                      id: _res.packageId,
                      name: _res.packageName,
                      description: '',
                      pricePerGuest: _res.pricePerGuest,
                      imageUrls: _res.packageImageUrl.isNotEmpty
                          ? [_res.packageImageUrl]
                          : const [],
                      includes: const [],
                      createdAt: _res.createdAt,
                    );
                    context.push('/home/book', extra: {
                      'package': package,
                      'reservation': _res,
                    });
                  },
                  icon: const Icon(Icons.edit_outlined,
                      color: Colors.white, size: 18),
                  label: const Text('EDIT?',
                      style: TextStyle(color: Colors.white)),
                ),
              ]
            : null,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text('Reservation details',
              style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15)),
          const SizedBox(height: 12),

          // Image
          if (_res.packageImageUrl.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Image.network(
                  _res.packageImageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                      color: AppColors.shimmerBase,
                      child: const Icon(Icons.restaurant,
                          color: Colors.white54, size: 48)),
                ),
              ),
            ),
          const SizedBox(height: 16),

          // Status badge
          Row(children: [
            StatusBadge(status: _res.status.name),
          ]),
          const SizedBox(height: 16),

          // Details
          _card([
            _row('Package', _res.packageName),
            _row('Date',
                '${_res.eventDate.day}/${_res.eventDate.month}/${_res.eventDate.year}'),
            _row('Time', _res.eventTime),
            _row('Guests', '${_res.numGuests}'),
            _row('Price/Guest',
                'RM ${_res.pricePerGuest.toStringAsFixed(2)}'),
            if (_res.customizationTotal > 0)
              _row('Add-ons',
                  'RM ${_res.customizationTotal.toStringAsFixed(2)}'),
            _row('Total',
                'RM ${_res.totalPrice.toStringAsFixed(2)}',
                bold: true,
                valueColor: AppColors.secondary),
          ]),

          if (_res.customizations.isNotEmpty) ...[
            const SizedBox(height: 12),
            _card([
              const Text('Add-on Services',
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13)),
              const SizedBox(height: 6),
              ..._res.customizations.map((c) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(children: [
                      const Icon(Icons.check,
                          color: AppColors.success, size: 14),
                      const SizedBox(width: 6),
                      Text(c.name,
                          style: const TextStyle(fontSize: 13)),
                      const Spacer(),
                      Text(
                          'RM ${c.price.toStringAsFixed(0)}',
                          style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.secondary)),
                    ]),
                  )),
            ]),
          ],

          if (_res.additionalPreferences != null &&
              _res.additionalPreferences!.isNotEmpty) ...[
            const SizedBox(height: 12),
            _card([
              const Text('Special Requests',
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13)),
              const SizedBox(height: 6),
              Text(_res.additionalPreferences!,
                  style: const TextStyle(
                      color: AppColors.textMedium, fontSize: 13)),
            ]),
          ],

          if (isUpcoming) ...[
            const SizedBox(height: 24),
            DangerButton(
              text: 'CANCEL BOOKING',
              onPressed: _cancelReservation,
              isLoading: _isCancelling,
            ),
          ],
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _card(List<Widget> children) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: children),
      );

  Widget _row(String label, String value,
      {bool bold = false, Color? valueColor}) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(children: [
          Text('$label:',
              style: const TextStyle(
                  fontSize: 13, color: AppColors.textMedium)),
          const SizedBox(width: 8),
          Text(value,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight:
                      bold ? FontWeight.w700 : FontWeight.w500,
                  color: valueColor ?? AppColors.textDark)),
        ]),
      );
}
