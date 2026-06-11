// lib/screens/user/booking_form_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../models/menu_package.dart';
import '../../models/reservation.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';

class BookingFormScreen extends StatefulWidget {
  final MenuPackage package;
  final Reservation? reservation;

  const BookingFormScreen({
    super.key,
    required this.package,
    this.reservation,
  });

  @override
  State<BookingFormScreen> createState() => _BookingFormScreenState();
}

class _BookingFormScreenState extends State<BookingFormScreen> {
  int _numGuests = 10;
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 7));
  TimeOfDay _selectedTime = const TimeOfDay(hour: 19, minute: 0);
  late final TextEditingController _guestCtrl;
  final _notesCtrl = TextEditingController();
  final _auth = AuthService();

  // Service customizations
  final List<Map<String, dynamic>> _availableCustomizations = [
    {'name': 'Floral Decoration', 'price': 500.0},
    {'name': 'Live Band', 'price': 1500.0},
    {'name': 'Photography Package', 'price': 800.0},
    {'name': 'Cake & Dessert Table', 'price': 300.0},
    {'name': 'Valet Parking', 'price': 200.0},
  ];
  final Set<int> _selectedCustomizations = {};

  double get _basePrice =>
      widget.package.pricePerGuest * _numGuests;

  double get _customizationTotal => _availableCustomizations
      .asMap()
      .entries
      .where((e) => _selectedCustomizations.contains(e.key))
      .fold(0.0, (sum, e) => sum + (e.value['price'] as double));

  double get _totalPrice => _basePrice + _customizationTotal;

  @override
  void initState() {
    super.initState();
    _guestCtrl = TextEditingController(text: '$_numGuests');
    final reservation = widget.reservation;
    if (reservation == null) return;

    _numGuests = reservation.numGuests;
    _guestCtrl.text = '$_numGuests';
    _selectedDate = reservation.eventDate;
    final timeParts = reservation.eventTime.split(':');
    if (timeParts.length == 2) {
      _selectedTime = TimeOfDay(
        hour: int.tryParse(timeParts[0]) ?? _selectedTime.hour,
        minute: int.tryParse(timeParts[1]) ?? _selectedTime.minute,
      );
    }
    _notesCtrl.text = reservation.additionalPreferences ?? '';
    for (final custom in reservation.customizations) {
      final index = _availableCustomizations
          .indexWhere((item) => item['name'] == custom.name);
      if (index != -1) _selectedCustomizations.add(index);
    }
  }

  @override
  void dispose() {
    _guestCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  void _setGuestCount(int value) {
    final clamped = value.clamp(
      widget.package.minGuests,
      widget.package.maxGuests,
    ) as int;
    setState(() {
      _numGuests = clamped;
      _guestCtrl.text = '$_numGuests';
      _guestCtrl.selection = TextSelection.fromPosition(
        TextPosition(offset: _guestCtrl.text.length),
      );
    });
  }

  void _syncGuestInput() {
    final value = int.tryParse(_guestCtrl.text);
    if (value == null) return;
    _setGuestCount(value);
  }

  Future<void> _pickDate() async {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    final firstDate =
        _selectedDate.isBefore(tomorrow) ? _selectedDate : tomorrow;
    final d = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: firstDate,
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppColors.primary,
            onPrimary: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (d != null) setState(() => _selectedDate = d);
  }

  Future<void> _pickTime() async {
    final t = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppColors.primary,
            onPrimary: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (t != null) setState(() => _selectedTime = t);
  }

  Future<void> _reviewReservation() async {
    _syncGuestInput();
    if (_guestCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please enter the number of guests.'),
        backgroundColor: AppColors.error,
      ));
      return;
    }
    if (_numGuests < widget.package.minGuests) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
            'Minimum ${widget.package.minGuests} guests required.'),
        backgroundColor: AppColors.error,
      ));
      return;
    }

    final user = await _auth.getCurrentUserModel();
    if (user == null || !mounted) return;

    final selectedCustoms = _availableCustomizations
        .asMap()
        .entries
        .where((e) => _selectedCustomizations.contains(e.key))
        .map((e) => ServiceCustomization(
              name: e.value['name'] as String,
              price: e.value['price'] as double,
            ))
        .toList();

    final timeStr =
        '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}';

    final reservation = Reservation(
      id: widget.reservation?.id ?? '',
      userId: user.uid,
      userName: user.name,
      userEmail: user.email,
      userPhone: user.phone,
      packageId: widget.package.id,
      packageName: widget.package.name,
      packageImageUrl: widget.package.imageUrls.isNotEmpty
          ? widget.package.imageUrls.first
          : '',
      pricePerGuest: widget.package.pricePerGuest,
      numGuests: _numGuests,
      eventDate: _selectedDate,
      eventTime: timeStr,
      additionalPreferences: _notesCtrl.text.trim(),
      customizations: selectedCustoms,
      totalPrice: _totalPrice,
      status: widget.reservation?.status ?? ReservationStatus.upcoming,
      rating: widget.reservation?.rating,
      createdAt: widget.reservation?.createdAt ?? DateTime.now(),
      updatedAt: widget.reservation == null ? null : DateTime.now(),
    );

    context.push('/home/confirm', extra: {
      'package': widget.package,
      'reservation': reservation,
    });
  }

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd/MM/yyyy');

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Reserve an Event'),
        leading: BackButton(onPressed: () => context.pop()),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Package preview
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(children: [
              const Icon(Icons.restaurant_menu,
                  color: AppColors.secondary),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.package.name,
                          style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: AppColors.textDark)),
                      Text(
                          'RM ${widget.package.pricePerGuest.toStringAsFixed(0)} per guest',
                          style: const TextStyle(
                              color: AppColors.secondary,
                              fontSize: 13)),
                    ]),
              ),
            ]),
          ),
          const SizedBox(height: 20),

          // Number of guests
          const Text('Number of Guests',
              style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                  color: AppColors.textDark)),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                IconButton(
                  onPressed: () {
                    if (_numGuests > widget.package.minGuests) {
                      _setGuestCount(_numGuests - 1);
                    }
                  },
                  icon: const Icon(Icons.remove_circle_outline,
                      color: AppColors.primary),
                ),
                Expanded(
                  child: TextField(
                    controller: _guestCtrl,
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    onSubmitted: (_) => _syncGuestInput(),
                    onEditingComplete: _syncGuestInput,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      filled: false,
                      contentPadding: EdgeInsets.zero,
                    ),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () {
                    if (_numGuests < widget.package.maxGuests) {
                      _setGuestCount(_numGuests + 1);
                    }
                  },
                  icon: const Icon(Icons.add_circle_outline,
                      color: AppColors.primary),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
              'Min ${widget.package.minGuests} – Max ${widget.package.maxGuests} guests',
              style: const TextStyle(
                  fontSize: 12, color: AppColors.textLight)),
          const SizedBox(height: 20),

          // Date
          const Text('Event Date',
              style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                  color: AppColors.textDark)),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: _pickDate,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(children: [
                const Icon(Icons.calendar_today_outlined,
                    color: AppColors.secondary),
                const SizedBox(width: 12),
                Text(fmt.format(_selectedDate),
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w500)),
                const Spacer(),
                const Icon(Icons.chevron_right,
                    color: AppColors.textLight),
              ]),
            ),
          ),
          const SizedBox(height: 16),

          // Time
          const Text('Event Time',
              style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                  color: AppColors.textDark)),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: _pickTime,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(children: [
                const Icon(Icons.access_time,
                    color: AppColors.secondary),
                const SizedBox(width: 12),
                Text(_selectedTime.format(context),
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w500)),
                const Spacer(),
                const Icon(Icons.chevron_right,
                    color: AppColors.textLight),
              ]),
            ),
          ),
          const SizedBox(height: 20),

          // Customizations
          const Text('Add-on Services (Optional)',
              style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                  color: AppColors.textDark)),
          const SizedBox(height: 10),
          ..._availableCustomizations.asMap().entries.map((entry) {
            final i = entry.key;
            final item = entry.value;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: _selectedCustomizations.contains(i)
                    ? Border.all(color: AppColors.secondary, width: 1.5)
                    : null,
              ),
              child: CheckboxListTile(
                title: Text(item['name'] as String,
                    style: const TextStyle(fontSize: 14)),
                subtitle: Text(
                    '+ RM ${(item['price'] as double).toStringAsFixed(0)}',
                    style: const TextStyle(
                        color: AppColors.secondary, fontSize: 12)),
                value: _selectedCustomizations.contains(i),
                activeColor: AppColors.secondary,
                checkColor: AppColors.primary,
                onChanged: (v) {
                  setState(() {
                    if (v == true) {
                      _selectedCustomizations.add(i);
                    } else {
                      _selectedCustomizations.remove(i);
                    }
                  });
                },
              ),
            );
          }),
          const SizedBox(height: 16),

          // Additional preferences
          const Text('Additional Preferences',
              style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                  color: AppColors.textDark)),
          const SizedBox(height: 10),
          TextField(
            controller: _notesCtrl,
            maxLines: 4,
            decoration: const InputDecoration(
              hintText:
                  'Dietary requirements, special requests...',
            ),
          ),
          const SizedBox(height: 24),

          // Price summary
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(children: [
              _priceRow(
                  'Base price ($_numGuests guests)',
                  'RM ${_basePrice.toStringAsFixed(2)}',
                  Colors.white70,
                  Colors.white),
              if (_customizationTotal > 0) ...[
                const SizedBox(height: 6),
                _priceRow(
                    'Add-on services',
                    '+ RM ${_customizationTotal.toStringAsFixed(2)}',
                    Colors.white70,
                    Colors.white),
              ],
              const Divider(color: Colors.white24, height: 16),
              _priceRow(
                  'Total',
                  'RM ${_totalPrice.toStringAsFixed(2)}',
                  Colors.white,
                  AppColors.secondary,
                  bold: true),
            ]),
          ),
          const SizedBox(height: 24),

          GoldButton(
            text: 'REVIEW RESERVATION',
            onPressed: _reviewReservation,
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _priceRow(String label, String value, Color labelColor,
      Color valueColor,
      {bool bold = false}) {
    return Row(children: [
      Text(label,
          style: TextStyle(
              color: labelColor,
              fontSize: bold ? 15 : 13,
              fontWeight:
                  bold ? FontWeight.w700 : FontWeight.w400)),
      const Spacer(),
      Text(value,
          style: TextStyle(
              color: valueColor,
              fontSize: bold ? 18 : 13,
              fontWeight:
                  bold ? FontWeight.w700 : FontWeight.w500)),
    ]);
  }
}
