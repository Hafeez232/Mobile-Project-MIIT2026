// lib/services/firestore_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/app_notification.dart';
import '../models/bank_card.dart';
import '../models/menu_package.dart';
import '../models/reservation.dart';
import '../models/user_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<List<MenuPackage>> packagesStream({String? category}) {
    Query query = _db
        .collection('packages')
        .where('isAvailable', isEqualTo: true)
        .orderBy('orderCount', descending: true);

    if (category != null && category != 'All') {
      query = query.where('category', isEqualTo: category);
    }

    return query.snapshots().map((snap) => snap.docs
        .map((d) => MenuPackage.fromMap(d.data() as Map<String, dynamic>, d.id))
        .toList());
  }

  // All packages including unavailable (for admin)
  Stream<List<MenuPackage>> allPackagesStream() {
    return _db
        .collection('packages')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) =>
                MenuPackage.fromMap(d.data() as Map<String, dynamic>, d.id))
            .toList());
  }

  Future<MenuPackage?> getPackageById(String id) async {
    final doc = await _db.collection('packages').doc(id).get();
    if (!doc.exists) return null;
    return MenuPackage.fromMap(doc.data()!, id);
  }

  Future<String> addPackage(MenuPackage pkg) async {
    final ref = await _db.collection('packages').add(pkg.toMap());
    return ref.id;
  }

  Future<void> updatePackage(MenuPackage pkg) async {
    await _db.collection('packages').doc(pkg.id).update(pkg.toMap());
  }

  Future<void> deletePackage(String id) async {
    await _db.collection('packages').doc(id).delete();
  }

  // Most ordered packages (top 5)
  Future<List<MenuPackage>> getMostOrdered() async {
    final snap = await _db
        .collection('packages')
        .where('isAvailable', isEqualTo: true)
        .orderBy('orderCount', descending: true)
        .limit(5)
        .get();
    return snap.docs
        .map((d) => MenuPackage.fromMap(d.data(), d.id))
        .toList();
  }

  // Search packages by name
  Future<List<MenuPackage>> searchPackages(String query) async {
    final snap = await _db
        .collection('packages')
        .where('isAvailable', isEqualTo: true)
        .get();
    final q = query.toLowerCase();
    return snap.docs
        .map((d) => MenuPackage.fromMap(d.data(), d.id))
        .where((p) =>
            p.name.toLowerCase().contains(q) ||
            p.description.toLowerCase().contains(q) ||
            p.category.toLowerCase().contains(q))
        .toList();
  }

  // Reservation images fetched from Supabase
  Future<String> createReservation(Reservation res) async {
    final ref = await _db.collection('reservations').add(res.toMap());
    final packageRef = _db.collection('packages').doc(res.packageId);
    final packageDoc = await packageRef.get();
    if (packageDoc.exists) {
      await packageRef.update({
        'orderCount': FieldValue.increment(1),
      });
    }
    await _createNotification(
      userId: res.userId,
      title: 'Reservation booked',
      message: '${res.packageName} has been booked for ${_formatDate(res.eventDate)}.',
      type: 'booked',
      reservationId: ref.id,
    );
    return ref.id;
  }

  // User's reservations
  Stream<List<Reservation>> userReservationsStream(String userId) {
    return _db
        .collection('reservations')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snap) {
      final reservations = snap.docs
          .map((d) =>
              Reservation.fromMap(d.data() as Map<String, dynamic>, d.id))
          .toList();
      reservations.sort((a, b) => b.eventDate.compareTo(a.eventDate));
      return reservations;
    });
  }

  // All reservations (admin)
  Stream<List<Reservation>> allReservationsStream() {
    return _db
        .collection('reservations')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) =>
                Reservation.fromMap(d.data() as Map<String, dynamic>, d.id))
            .toList());
  }

  Future<void> updateReservation(Reservation res) async {
    await _db.collection('reservations').doc(res.id).update({
      'numGuests': res.numGuests,
      'eventDate': res.eventDate,
      'eventTime': res.eventTime,
      'additionalPreferences': res.additionalPreferences,
      'customizations': res.customizations.map((c) => c.toMap()).toList(),
      'totalPrice': res.totalPrice,
      'packageId': res.packageId,
      'packageName': res.packageName,
      'packageImageUrl': res.packageImageUrl,
      'pricePerGuest': res.pricePerGuest,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    await _createNotification(
      userId: res.userId,
      title: 'Reservation edited',
      message: '${res.packageName} was updated for ${_formatDate(res.eventDate)}.',
      type: 'edited',
      reservationId: res.id,
    );
  }

  Future<void> cancelReservation(String id) async {
    final doc = await _db.collection('reservations').doc(id).get();
    final res = doc.exists
        ? Reservation.fromMap(doc.data() as Map<String, dynamic>, doc.id)
        : null;
    await _db.collection('reservations').doc(id).update({
      'status': 'cancelled',
      'updatedAt': FieldValue.serverTimestamp(),
    });
    if (res != null) {
      await _createNotification(
        userId: res.userId,
        title: 'Reservation cancelled',
        message: '${res.packageName} on ${_formatDate(res.eventDate)} was cancelled.',
        type: 'cancelled',
        reservationId: id,
      );
    }
  }

  Future<void> rateReservation(String id, double rating) async {
    await _db.collection('reservations').doc(id).update({'rating': rating});
  }

  // Users (in admin)
  Stream<List<UserModel>> usersStream() {
    return _db
        .collection('users')
        .where('role', isEqualTo: 'user')
        .snapshots()
        .map((snap) {
      final users = snap.docs
          .map((d) => UserModel.fromMap(d.data() as Map<String, dynamic>, d.id))
          .toList();
      users.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return users;
    });
  }

  Future<void> updateUserByAdmin(String uid, Map<String, dynamic> data) async {
    await _db.collection('users').doc(uid).update(data);
  }

  Future<void> deleteUser(String uid) async {
    await _db.collection('users').doc(uid).delete();
  }

  Stream<List<BankCard>> bankCardsStream(String userId) {
    return _db
        .collection('users')
        .doc(userId)
        .collection('paymentCards')
        .snapshots()
        .map((snap) {
      final cards = snap.docs
          .map((d) => BankCard.fromMap(d.data(), d.id))
          .toList();
      cards.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return cards;
    });
  }

  Future<void> addBankCard(BankCard card) async {
    final cardRef = _db
        .collection('users')
        .doc(card.userId)
        .collection('paymentCards')
        .doc();

    await cardRef.set(card.toMap());

    final savedCard = await cardRef.get(const GetOptions(source: Source.server));
    if (!savedCard.exists) {
      throw Exception('Card was saved locally but not confirmed on Firestore.');
    }
  }

  Future<void> deleteBankCard(String userId, String cardId) async {
    await _db
        .collection('users')
        .doc(userId)
        .collection('paymentCards')
        .doc(cardId)
        .delete();
  }

  Stream<List<AppNotification>> notificationsStream(String userId) {
    return _db
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snap) {
      final notifications = snap.docs
          .map((d) => AppNotification.fromMap(d.data(), d.id))
          .toList();
      notifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return notifications;
    });
  }

  Future<void> markNotificationsRead(String userId) async {
    final snap = await _db
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .get();

    final batch = _db.batch();
    for (final doc in snap.docs) {
      if (doc.data()['isRead'] == false) {
        batch.update(doc.reference, {'isRead': true});
      }
    }
    await batch.commit();
  }

  Future<void> _createNotification({
    required String userId,
    required String title,
    required String message,
    required String type,
    String? reservationId,
  }) async {
    await _db.collection('notifications').add(AppNotification(
          id: '',
          userId: userId,
          title: title,
          message: message,
          type: type,
          reservationId: reservationId,
          createdAt: DateTime.now(),
        ).toMap());
  }

  String _formatDate(DateTime date) =>
      '${date.day}/${date.month}/${date.year}';
}
