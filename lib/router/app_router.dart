// lib/router/app_router.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/menu_package.dart';
import '../models/reservation.dart';
import '../screens/guest/guest_home_screen.dart';
import '../screens/guest/package_detail_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/user/user_home_screen.dart';
import '../screens/user/booking_form_screen.dart';
import '../screens/user/booking_confirm_screen.dart';
import '../screens/user/booking_success_screen.dart';
import '../screens/user/my_reservations_screen.dart';
import '../screens/user/notifications_screen.dart';
import '../screens/user/payment_cards_screen.dart';
import '../screens/user/reservation_detail_screen.dart';
import '../screens/user/profile_screen.dart';
import '../screens/user/search_screen.dart';
import '../screens/admin/admin_home_screen.dart';
import '../screens/admin/admin_reservations_screen.dart';
import '../screens/admin/admin_reservation_detail_screen.dart';
import '../screens/admin/admin_packages_screen.dart';
import '../screens/admin/admin_package_form_screen.dart';
import '../screens/admin/admin_users_screen.dart';
import '../screens/admin/admin_user_detail_screen.dart';
import '../services/auth_service.dart';

final _authService = AuthService();

final GoRouter appRouter = GoRouter(
  initialLocation: '/guest',
  redirect: (context, state) async {
    final user = FirebaseAuth.instance.currentUser;
    final loc = state.matchedLocation;
    final isAuthRoute = loc.startsWith('/auth');
    final isGuestRoute = loc.startsWith('/guest');

    if (user == null && !isAuthRoute && !isGuestRoute) {
      return '/auth/login';
    }
    if (user != null && isAuthRoute) {
      return '/home';
    }
    return null;
  },
  routes: [
    // ── Guest Routes ──────────────────────────────────────────────
    GoRoute(
      path: '/guest',
      builder: (context, state) => const GuestHomeScreen(),
      routes: [
        GoRoute(
          path: 'package/:id',
          builder: (context, state) {
            final pkg = state.extra as MenuPackage;
            return PackageDetailScreen(package: pkg, isGuest: true);
          },
        ),
      ],
    ),

    // ── Auth Routes ───────────────────────────────────────────────
    GoRoute(
      path: '/auth/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/auth/register',
      builder: (context, state) => const RegisterScreen(),
    ),

    // ── User Routes ───────────────────────────────────────────────
    GoRoute(
      path: '/home',
      builder: (context, state) {
        final tab = state.uri.queryParameters['tab'];
        final initialIndex = switch (tab) {
          'bookings' => 1,
          'profile' => 2,
          _ => 0,
        };
        return UserHomeScreen(initialIndex: initialIndex);
      },
      routes: [
        GoRoute(
          path: 'package/:id',
          builder: (context, state) {
            final pkg = state.extra as MenuPackage;
            return PackageDetailScreen(package: pkg, isGuest: false);
          },
        ),
        GoRoute(
          path: 'search',
          builder: (context, state) => const SearchScreen(),
        ),
        GoRoute(
          path: 'notifications',
          builder: (context, state) => const NotificationsScreen(),
        ),
        GoRoute(
          path: 'payment-cards',
          builder: (context, state) => const PaymentCardsScreen(),
        ),
        GoRoute(
          path: 'book',
          builder: (context, state) {
            final extra = state.extra;
            if (extra is Map<String, dynamic>) {
              return BookingFormScreen(
                package: extra['package'] as MenuPackage,
                reservation: extra['reservation'] as Reservation?,
              );
            }
            final pkg = extra as MenuPackage;
            return BookingFormScreen(package: pkg);
          },
        ),
        GoRoute(
          path: 'confirm',
          builder: (context, state) {
            final data = state.extra as Map<String, dynamic>;
            return BookingConfirmScreen(
              package: data['package'] as MenuPackage,
              reservation: data['reservation'] as Reservation,
            );
          },
        ),
        GoRoute(
          path: 'success',
          builder: (context, state) => const BookingSuccessScreen(),
        ),
        GoRoute(
          path: 'reservations',
          builder: (context, state) => const MyReservationsScreen(),
          routes: [
            GoRoute(
              path: ':id',
              builder: (context, state) {
                final res = state.extra as Reservation;
                return ReservationDetailScreen(reservation: res);
              },
            ),
          ],
        ),
        GoRoute(
          path: 'profile',
          builder: (context, state) => const ProfileScreen(),
        ),
      ],
    ),

    // ── Admin Routes ──────────────────────────────────────────────
    GoRoute(
      path: '/admin',
      builder: (context, state) => const AdminHomeScreen(),
      routes: [
        GoRoute(
          path: 'reservations',
          builder: (context, state) => const AdminReservationsScreen(),
          routes: [
            GoRoute(
              path: ':id',
              builder: (context, state) {
                final res = state.extra as Reservation;
                return AdminReservationDetailScreen(reservation: res);
              },
            ),
          ],
        ),
        GoRoute(
          path: 'packages',
          builder: (context, state) => const AdminPackagesScreen(),
          routes: [
            GoRoute(
              path: 'add',
              builder: (context, state) =>
                  const AdminPackageFormScreen(package: null),
            ),
            GoRoute(
              path: 'edit',
              builder: (context, state) {
                final pkg = state.extra as MenuPackage;
                return AdminPackageFormScreen(package: pkg);
              },
            ),
          ],
        ),
        GoRoute(
          path: 'users',
          builder: (context, state) => const AdminUsersScreen(),
          routes: [
            GoRoute(
              path: ':id',
              builder: (context, state) {
                final data = state.extra as Map<String, dynamic>;
                return AdminUserDetailScreen(
                  user: data['user'],
                  isEdit: data['isEdit'] ?? false,
                );
              },
            ),
          ],
        ),
        GoRoute(
          path: 'search',
          builder: (context, state) => const SearchScreen(isAdmin: true),
        ),
      ],
    ),
  ],
  errorBuilder: (context, state) => Scaffold(
    body: Center(child: Text('Page not found: ${state.error}')),
  ),
);
