// lib/screens/user/booking_confirm_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/bank_card.dart';
import '../../models/menu_package.dart';
import '../../models/reservation.dart';
import '../../services/firestore_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
import 'payment_cards_screen.dart';

class BookingConfirmScreen extends StatefulWidget {
  final MenuPackage package;
  final Reservation reservation;

  const BookingConfirmScreen(
      {super.key, required this.package, required this.reservation});

  @override
  State<BookingConfirmScreen> createState() => _BookingConfirmScreenState();
}

class _BookingConfirmScreenState extends State<BookingConfirmScreen> {
  bool _isLoading = false;
  BankCard? _selectedCard;
  final _db = FirestoreService();
  final _uid = FirebaseAuth.instance.currentUser?.uid ?? '';

  Future<void> _confirm() async {
    if (_selectedCard == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please choose or add a bank card first'),
        backgroundColor: AppColors.error,
      ));
      return;
    }

    setState(() => _isLoading = true);
    try {
      if (widget.reservation.id.isEmpty) {
        await _db.createReservation(widget.reservation);
      } else {
        await _db.updateReservation(widget.reservation);
      }
      if (!mounted) return;
      context.go('/home/success');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error: $e'),
        backgroundColor: AppColors.error,
      ));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final res = widget.reservation;
    final fmt = DateFormat('dd MMMM yyyy');

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Confirm Reservation'),
        leading: BackButton(onPressed: () => context.pop()),
        actions: [
          TextButton.icon(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.edit_outlined,
                color: Colors.white, size: 18),
            label: const Text('EDIT?',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text('Review booking detail',
              style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textMedium,
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 16),

          // Package card
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(children: [
              ClipRRect(
                borderRadius: const BorderRadius.horizontal(
                    left: Radius.circular(12)),
                child: SizedBox(
                  width: 100,
                  height: 90,
                  child: res.packageImageUrl.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: res.packageImageUrl,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => Container(
                              color: AppColors.shimmerBase),
                          errorWidget: (_, __, ___) => Container(
                              color: AppColors.shimmerBase,
                              child: const Icon(Icons.restaurant,
                                  color: Colors.white54)),
                        )
                      : Container(
                          color: AppColors.shimmerBase,
                          child: const Icon(Icons.restaurant,
                              color: Colors.white54)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(res.packageName,
                          style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15)),
                      const SizedBox(height: 4),
                      _detailRow(Icons.people_outline,
                          '${res.numGuests} guests'),
                      _detailRow(Icons.calendar_today_outlined,
                          fmt.format(res.eventDate)),
                      _detailRow(
                          Icons.access_time, res.eventTime),
                    ],
                  ),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 16),

          // Customizations
          if (res.customizations.isNotEmpty) ...[
            const Text('Add-on Services',
                style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14)),
            const SizedBox(height: 8),
            ...res.customizations.map((c) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(children: [
                    const Icon(Icons.check_circle,
                        color: AppColors.success, size: 14),
                    const SizedBox(width: 6),
                    Text(c.name,
                        style: const TextStyle(fontSize: 13)),
                    const Spacer(),
                    Text(
                        '+ RM ${c.price.toStringAsFixed(0)}',
                        style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.secondary)),
                  ]),
                )),
            const SizedBox(height: 12),
          ],

          // Price breakdown
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(children: [
              _priceRow(
                  'Base price (${res.numGuests} × RM ${res.pricePerGuest.toStringAsFixed(0)})',
                  'RM ${res.basePrice.toStringAsFixed(2)}'),
              if (res.customizationTotal > 0) ...[
                const SizedBox(height: 6),
                _priceRow('Add-on services',
                    'RM ${res.customizationTotal.toStringAsFixed(2)}'),
              ],
              const Divider(height: 16),
              Row(children: [
                const Text('TOTAL',
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15)),
                const Spacer(),
                Text(
                    'RM ${res.totalPrice.toStringAsFixed(2)}',
                    style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 20,
                        color: AppColors.secondary)),
              ]),
            ]),
          ),
          const SizedBox(height: 16),

          _paymentCardSection(res),
          const SizedBox(height: 24),

          GoldButton(
            text: 'BOOK NOW',
            onPressed: _confirm,
            isLoading: _isLoading,
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _detailRow(IconData icon, String text) => Padding(
        padding: const EdgeInsets.only(top: 3),
        child: Row(children: [
          Icon(icon, size: 13, color: AppColors.textLight),
          const SizedBox(width: 4),
          Text(text,
              style: const TextStyle(
                  fontSize: 12, color: AppColors.textMedium)),
        ]),
      );

  Widget _priceRow(String label, String value) => Row(children: [
        Text(label,
            style: const TextStyle(
                fontSize: 13, color: AppColors.textMedium)),
        const Spacer(),
        Text(value,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
      ]);

  Widget _paymentCardSection(Reservation res) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: StreamBuilder<List<BankCard>>(
        stream: _db.bankCardsStream(_uid),
        builder: (context, snap) {
          final cards = snap.data ?? [];
          if (_selectedCard == null && cards.isNotEmpty) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted && _selectedCard == null) {
                setState(() => _selectedCard = cards.first);
              }
            });
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.payment_outlined,
                      color: AppColors.textMedium),
                  const SizedBox(width: 8),
                  const Text('Payment card',
                      style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.textDark)),
                  const Spacer(),
                  Text('RM ${res.totalPrice.toStringAsFixed(2)}',
                      style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.textDark)),
                ],
              ),
              const SizedBox(height: 12),
              if (snap.connectionState == ConnectionState.waiting)
                const Center(child: CircularProgressIndicator())
              else if (cards.isEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text('No card saved yet.',
                        style: TextStyle(
                            fontSize: 13, color: AppColors.textMedium)),
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: _addCard,
                      icon: const Icon(Icons.add_card),
                      label: const Text('Add Bank Card'),
                    ),
                  ],
                )
              else ...[
                ...cards.map((card) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: InkWell(
                        onTap: () => setState(() => _selectedCard = card),
                        borderRadius: BorderRadius.circular(10),
                        child: BankCardTile(
                          card: card,
                          selected: _selectedCard?.id == card.id,
                          trailing: Radio<String>(
                            value: card.id,
                            groupValue: _selectedCard?.id,
                            onChanged: (_) =>
                                setState(() => _selectedCard = card),
                          ),
                        ),
                      ),
                    )),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: _addCard,
                    icon: const Icon(Icons.add),
                    label: const Text('Use another card'),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  Future<void> _addCard() async {
    final card = await showAddBankCardDialog(context);
    if (card != null && mounted) {
      setState(() => _selectedCard = null);
    }
  }
}
