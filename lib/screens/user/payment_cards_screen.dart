import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/bank_card.dart';
import '../../services/firestore_service.dart';
import '../../theme/app_theme.dart';

class PaymentCardsScreen extends StatefulWidget {
  const PaymentCardsScreen({super.key});

  @override
  State<PaymentCardsScreen> createState() => _PaymentCardsScreenState();
}

class _PaymentCardsScreenState extends State<PaymentCardsScreen> {
  final _db = FirestoreService();
  final _uid = FirebaseAuth.instance.currentUser?.uid ?? '';

  Future<void> _addCard() async {
    await showAddBankCardDialog(context);
  }

  Future<void> _deleteCard(BankCard card) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Delete card?'),
        content: Text(
          'Remove ${card.brand} ending in ${card.last4} from your saved payment cards?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.cancelRed,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (shouldDelete != true) return;
    await _db.deleteBankCard(_uid, card.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Card deleted'),
        backgroundColor: AppColors.cancelRed,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Bank Card Payment')),
      floatingActionButton: FloatingActionButton(
        onPressed: _addCard,
        backgroundColor: AppColors.secondary,
        foregroundColor: AppColors.primary,
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<List<BankCard>>(
        stream: _db.bankCardsStream(_uid),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final cards = snap.data ?? [];
          if (cards.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.credit_card,
                    size: 56,
                    color: AppColors.textLight,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'No saved cards yet',
                    style: TextStyle(color: AppColors.textLight, fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _addCard,
                    child: const Text('Add Card'),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: cards.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final card = cards[index];
              return BankCardTile(
                card: card,
                trailing: IconButton(
                  icon: const Icon(
                    Icons.delete_outline,
                    color: AppColors.cancelRed,
                  ),
                  onPressed: () => _deleteCard(card),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class BankCardTile extends StatelessWidget {
  final BankCard card;
  final Widget? trailing;
  final bool selected;

  const BankCardTile({
    super.key,
    required this.card,
    this.trailing,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: selected
            ? Border.all(color: AppColors.secondary, width: 1.5)
            : null,
      ),
      child: Row(
        children: [
          const Icon(Icons.credit_card, color: AppColors.secondary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${card.brand} ${card.displayNumber}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${card.holderName} - Exp ${card.expiryText}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textMedium,
                  ),
                ),
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

Future<BankCard?> showAddBankCardDialog(BuildContext context) async {
  final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
  if (uid.isEmpty) return null;

  final db = FirestoreService();
  final holderCtrl = TextEditingController();
  final numberCtrl = TextEditingController();
  final expiryCtrl = TextEditingController();
  final cvvCtrl = TextEditingController();
  String? errorText;
  bool isSaving = false;

  return showDialog<BankCard>(
    context: context,
    barrierDismissible: !isSaving,
    builder: (context) => StatefulBuilder(
      builder: (context, setDialogState) {
        final cardDigits = numberCtrl.text.replaceAll(RegExp(r'\D'), '');
        final previewBrand = cardDigits.isEmpty
            ? 'CARD'
            : _detectCardBrand(cardDigits).toUpperCase();
        final previewLast4 = cardDigits.length >= 4
            ? cardDigits.substring(cardDigits.length - 4)
            : '0000';
        final previewName = holderCtrl.text.trim().isEmpty
            ? 'CARDHOLDER NAME'
            : holderCtrl.text.trim().toUpperCase();
        final previewExpiry = expiryCtrl.text.trim().isEmpty
            ? 'MM/YY'
            : expiryCtrl.text.trim();

        return AlertDialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 20),
          contentPadding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: AppColors.secondary.withOpacity(0.16),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.credit_card,
                            color: AppColors.secondary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Add Bank Card',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textDark,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Never input real card details in this app',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textMedium,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.credit_card,
                                color: AppColors.secondary,
                              ),
                              const Spacer(),
                              Text(
                                previewBrand,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 22),
                          Text(
                            '**** **** **** $previewLast4',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 19,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.8,
                            ),
                          ),
                          const SizedBox(height: 18),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  previewName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              Text(
                                previewExpiry,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    TextField(
                      controller: holderCtrl,
                      enabled: !isSaving,
                      textCapitalization: TextCapitalization.words,
                      onChanged: (_) => setDialogState(() {}),
                      decoration: const InputDecoration(
                        labelText: 'Cardholder name',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: numberCtrl,
                      enabled: !isSaving,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(16),
                        _CardNumberInputFormatter(),
                      ],
                      onChanged: (_) => setDialogState(() {}),
                      decoration: const InputDecoration(
                        labelText: 'Card number',
                        hintText: '1234 5678 9101 1121',
                        prefixIcon: Icon(Icons.credit_card),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: expiryCtrl,
                            enabled: !isSaving,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(4),
                              _ExpiryInputFormatter(),
                            ],
                            onChanged: (_) => setDialogState(() {}),
                            decoration: const InputDecoration(
                              labelText: 'Expiry',
                              hintText: 'MM/YY',
                              prefixIcon: Icon(Icons.calendar_today_outlined),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: cvvCtrl,
                            enabled: !isSaving,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(4),
                            ],
                            obscureText: true,
                            decoration: const InputDecoration(
                              labelText: 'CVV',
                              hintText: '123',
                              prefixIcon: Icon(Icons.lock_outline),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (errorText != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.error.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          errorText!,
                          style: const TextStyle(
                            color: AppColors.error,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: isSaving
                                ? null
                                : () => Navigator.pop(context),
                            child: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: isSaving
                                ? null
                                : () async {
                                    final card = _buildCardFromInput(
                                      uid: uid,
                                      holderName: holderCtrl.text,
                                      cardNumber: numberCtrl.text,
                                      expiry: expiryCtrl.text,
                                      cvv: cvvCtrl.text,
                                    );
                                    if (card == null) {
                                      setDialogState(() {
                                        errorText =
                                            'Enter card number, expiry as MM/YY, and 3-digit CVV.';
                                      });
                                      return;
                                    }
                                    try {
                                      setDialogState(() {
                                        isSaving = true;
                                        errorText = null;
                                      });
                                      await db.addBankCard(card);
                                      if (!context.mounted) return;
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Card saved successfully',
                                          ),
                                          backgroundColor: AppColors.success,
                                        ),
                                      );
                                      Navigator.pop(context, card);
                                    } catch (e) {
                                      if (!context.mounted) return;
                                      setDialogState(() {
                                        isSaving = false;
                                        errorText = 'Could not save card: $e';
                                      });
                                    }
                                  },
                            child: isSaving
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text('Save'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    ),
  );
}

BankCard? _buildCardFromInput({
  required String uid,
  required String holderName,
  required String cardNumber,
  required String expiry,
  required String cvv,
}) {
  final digits = cardNumber.replaceAll(RegExp(r'\D'), '');
  final cvvDigits = cvv.replaceAll(RegExp(r'\D'), '');
  final expiryParts = expiry.split('/');
  if (holderName.trim().isEmpty ||
      digits.length < 12 ||
      cvvDigits.length < 3 ||
      expiryParts.length != 2) {
    return null;
  }

  final month = int.tryParse(expiryParts[0].trim());
  final yearPart = int.tryParse(expiryParts[1].trim());
  if (month == null || yearPart == null || month < 1 || month > 12) {
    return null;
  }

  final year = yearPart < 100 ? 2000 + yearPart : yearPart;
  return BankCard(
    id: '',
    userId: uid,
    holderName: holderName.trim(),
    brand: _detectCardBrand(digits),
    last4: digits.substring(digits.length - 4),
    expiryMonth: month,
    expiryYear: year,
    createdAt: DateTime.now(),
  );
}

String _detectCardBrand(String digits) {
  if (digits.startsWith('4')) return 'Visa';
  if (digits.startsWith('5')) return 'Mastercard';
  if (digits.startsWith('3')) return 'Amex';
  return 'Card';
}

class _CardNumberInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && i % 4 == 0) buffer.write(' ');
      buffer.write(digits[i]);
    }
    final text = buffer.toString();
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

class _ExpiryInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final text = digits.length <= 2
        ? digits
        : '${digits.substring(0, 2)}/${digits.substring(2)}';
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}
