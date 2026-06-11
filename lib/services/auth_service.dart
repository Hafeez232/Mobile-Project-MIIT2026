// lib/services/auth_service.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  // Register new user
  Future<UserModel?> registerUser({
    required String email,
    required String password,
    required String name,
    required String phone,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final user = UserModel(
      uid: cred.user!.uid,
      email: email,
      name: name,
      phone: phone,
      role: 'user',
      createdAt: DateTime.now(),
    );
    await _db.collection('users').doc(user.uid).set(user.toMap());
    return user;
  }

  // Login
  Future<UserModel?> login({
    required String email,
    required String password,
  }) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return await getUserById(cred.user!.uid);
  }

  // Get user data
  Future<UserModel?> getUserById(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (!doc.exists) return null;
    return UserModel.fromMap(doc.data()!, uid);
  }

  // Get current user
  Future<UserModel?> getCurrentUserModel() async {
    if (currentUser == null) return null;
    return await getUserById(currentUser!.uid);
  }

  // Sign out
  Future<void> signOut() async => await _auth.signOut();

  // Update user profile
  Future<void> updateUser(UserModel user) async {
    await _db.collection('users').doc(user.uid).update({
      'name': user.name,
      'phone': user.phone,
      if (user.profileImageUrl != null)
        'profileImageUrl': user.profileImageUrl,
    });
  }
}
