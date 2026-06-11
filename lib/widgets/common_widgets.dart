// lib/widgets/package_card.dart
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import '../models/menu_package.dart';
import '../theme/app_theme.dart';

class PackageCard extends StatelessWidget {
  final MenuPackage package;
  final VoidCallback onTap;
  final VoidCallback? onAdd;
  final bool showAdd;

  const PackageCard({
    super.key,
    required this.package,
    required this.onTap,
    this.onAdd,
    this.showAdd = true,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.07),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(12)),
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: package.imageUrls.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: package.imageUrls.first,
                            fit: BoxFit.cover,
                            placeholder: (ctx, url) => _shimmer(),
                            errorWidget: (ctx, url, err) =>
                                _placeholder(),
                          )
                        : _placeholder(),
                  ),
                ),
                if (showAdd && onAdd != null)
                  Positioned(
                    right: 8,
                    bottom: 8,
                    child: GestureDetector(
                      onTap: onAdd,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: const Icon(Icons.add,
                            size: 20, color: AppColors.primary),
                      ),
                    ),
                  ),
              ],
            ),
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    package.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: AppColors.textDark,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'RM ${package.pricePerGuest.toStringAsFixed(0)}/pax',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.secondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            //Mission abort for this
            /*Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,    // ← add this
              children: [
                Text(
                  package.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: AppColors.textDark,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  'RM ${package.pricePerGuest.toStringAsFixed(0)}/pax',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.secondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),*/

          ],
        ),
      ),
    );
  }

  Widget _shimmer() => Shimmer.fromColors(
        baseColor: AppColors.shimmerBase,
        highlightColor: AppColors.shimmerHighlight,
        child: Container(color: AppColors.shimmerBase),
      );

  Widget _placeholder() => Container(
        color: AppColors.shimmerBase,
        child: const Icon(Icons.restaurant, color: Colors.white54, size: 48),
      );
}

class ReservationCard extends StatelessWidget {
  final dynamic reservation;
  final VoidCallback onTap;

  const ReservationCard(
      {super.key, required this.reservation, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 6,
                offset: const Offset(0, 2)),
          ],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius:
                  const BorderRadius.horizontal(left: Radius.circular(12)),
              child: SizedBox(
                width: 100,
                height: 90,
                child: reservation.packageImageUrl.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: reservation.packageImageUrl,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Shimmer.fromColors(
                          baseColor: AppColors.shimmerBase,
                          highlightColor: AppColors.shimmerHighlight,
                          child: Container(color: AppColors.shimmerBase),
                        ),
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
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(reservation.packageName,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: AppColors.textDark),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    _infoRow(Icons.calendar_today_outlined,
                        _formatDate(reservation.eventDate)),
                    const SizedBox(height: 2),
                    _infoRow(Icons.people_outline,
                        '${reservation.numGuests} guests'),
                    const SizedBox(height: 2),
                    _infoRow(Icons.attach_money,
                        'RM ${reservation.totalPrice.toStringAsFixed(2)}'),
                  ],
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(right: 12),
              child: Icon(Icons.chevron_right, color: AppColors.textLight),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) => Row(
        children: [
          Icon(icon, size: 12, color: AppColors.textLight),
          const SizedBox(width: 4),
          Text(text,
              style:
                  const TextStyle(fontSize: 12, color: AppColors.textMedium)),
        ],
      );

  String _formatDate(DateTime d) =>
      '${d.day}/${d.month}/${d.year}';
}

class GoldButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final double? width;

  const GoldButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width ?? double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.secondary,
          foregroundColor: AppColors.primary,
          disabledBackgroundColor: AppColors.secondary.withOpacity(0.5),
        ),
        child: isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: AppColors.primary),
              )
            : Text(text,
                style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                    fontSize: 14)),
      ),
    );
  }
}

class DangerButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;

  const DangerButton(
      {super.key,
      required this.text,
      this.onPressed,
      this.isLoading = false});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.cancelRed,
          foregroundColor: Colors.white,
        ),
        child: isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white),
              )
            : Text(text,
                style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                    fontSize: 14)),
      ),
    );
  }
}

// Shimmer loading list
class ShimmerList extends StatelessWidget {
  final int count;
  const ShimmerList({super.key, this.count = 4});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.shimmerBase,
      highlightColor: AppColors.shimmerHighlight,
      child: Column(
        children: List.generate(
          count,
          (_) => Container(
            margin: const EdgeInsets.only(bottom: 12),
            height: 90,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
    );
  }
}

class StatusBadge extends StatelessWidget {
  final String status;
  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    String label;

    switch (status) {
      case 'upcoming':
        bg = const Color(0xFFE8F5E9);
        fg = const Color(0xFF2E7D32);
        label = 'Upcoming';
        break;
      case 'cancelled':
        bg = const Color(0xFFFFEBEE);
        fg = AppColors.cancelRed;
        label = 'Cancelled';
        break;
      default:
        bg = const Color(0xFFF3E5F5);
        fg = const Color(0xFF6A1B9A);
        label = 'Completed';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(label,
          style:
              TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }
}
