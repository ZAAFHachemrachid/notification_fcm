import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Get auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign up with email password
  Future<UserCredential> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      debugPrint('📝 Starting sign up process...');
      debugPrint('📧 Email: $email');
      debugPrint('👤 Display Name: $displayName');

      // Check if Firebase Auth is initialized
      if (_auth.app == null) {
        debugPrint('❌ Firebase Auth is not initialized!');
        throw Exception('Firebase Auth is not initialized');
      }

      // Check if we can access Firebase Auth configuration
      debugPrint('🔍 Checking Firebase Auth configuration...');
      debugPrint('📱 App name: ${_auth.app.name}');
      debugPrint('🔑 Auth instance: ${_auth.toString()}');

      // Create user with email and password
      debugPrint('👥 Creating user account...');
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      debugPrint('✅ User account created successfully');

      // Update display name
      debugPrint('📝 Updating display name...');
      await userCredential.user?.updateDisplayName(displayName);

      // Create user document in Firestore
      debugPrint('📄 Creating user document in Firestore...');
      await _createUserDocument(userCredential.user!, displayName);

      debugPrint('✅ Sign up process completed successfully');
      return userCredential;
    } catch (e) {
      debugPrint('❌ Error during sign up: $e');
      if (e is FirebaseAuthException) {
        debugPrint('🔥 Firebase Auth Error Code: ${e.code}');
        debugPrint('🔥 Firebase Auth Error Message: ${e.message}');
      }
      rethrow;
    }
  }

  // Sign in with email password
  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    try {
      debugPrint('🔐 Starting sign in process...');
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      debugPrint('❌ Error during sign in: $e');
      rethrow;
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Create user document in Firestore
  Future<void> _createUserDocument(User user, String displayName) async {
    await _firestore.collection('users').doc(user.uid).set({
      'uid': user.uid,
      'email': user.email,
      'displayName': displayName,
      'photoUrl': user.photoURL,
      'lastSeen': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // Update user's last seen
  Future<void> updateUserLastSeen() async {
    if (currentUser != null) {
      await _firestore.collection('users').doc(currentUser!.uid).update({
        'lastSeen': FieldValue.serverTimestamp(),
      });
    }
  }
}
