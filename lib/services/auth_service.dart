import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/exercise_access_model.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static UserModel? _currentUser;
  static UserModel? get currentUser => _currentUser;

  // ─── Check login on app start ──────────────────────────────────
  static Future<UserModel?> checkLoginStatus() async {
    try {
      final firebaseUser = _auth.currentUser;
      if (firebaseUser == null) return null;

      final user = await _fetchUserProfile(firebaseUser.uid);
      if (user == null) {
        await _auth.signOut();
        return null;
      }

      // Force logout if deactivated
      if (!user.isActive) {
        await _auth.signOut();
        _currentUser = null;
        return null;
      }

      // Force logout if student not approved
      if (user.isStudent && !user.isApproved) {
        await _auth.signOut();
        _currentUser = null;
        return null;
      }

      return user;
    } catch (_) {
      return null;
    }
  }

  // ─── Login ────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> login(
      String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim().toLowerCase(),
        password: password,
      );

      final user = await _fetchUserProfile(credential.user!.uid);

      if (user == null) {
        await _auth.signOut();
        return {'error': 'User profile not found. Contact admin.'};
      }

      if (!user.isActive) {
        await _auth.signOut();
        return {'error': 'Account is inactive. Contact admin.'};
      }

      // Students must be approved before login
      if (user.isStudent && !user.isApproved) {
        await _auth.signOut();
        return {
          'error':
          'Your account is pending approval. Please wait for admin to approve your account.'
        };
      }

      return {'user': user};
    } on FirebaseAuthException catch (e) {
      return {'error': _errorMessage(e.code)};
    } catch (e) {
      return {'error': 'Something went wrong. Try again.'};
    }
  }

  // ─── Sign Up ──────────────────────────────────────────────────
  static Future<Map<String, dynamic>> signUp({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    required String phone,
    required String branch,
    required String city,
    required String zipCode,
    String? addressLine1,
    String? addressLine2,
  }) async {
    try {
      // Create Firebase Auth account
      final credential =
      await _auth.createUserWithEmailAndPassword(
        email: email.trim().toLowerCase(),
        password: password,
      );

      final uid = credential.user!.uid;
      final now = DateTime.now();

      // Build user model
      final user = UserModel(
        uid:          uid,
        firstName:    firstName.trim(),
        lastName:     lastName.trim(),
        email:        email.trim().toLowerCase(),
        phone:        phone.trim(),
        branch:       branch,
        role:         'student',
        addressLine1: addressLine1?.trim().isEmpty == true
            ? null
            : addressLine1?.trim(),
        addressLine2: addressLine2?.trim().isEmpty == true
            ? null
            : addressLine2?.trim(),
        city:         city.trim(),
        zipCode:      zipCode.trim(),
        createdAt:    now,
        isActive:     true,
        isApproved:   false, // pending approval
      );

      // Write user profile to Firestore
      await _db
          .collection('users')
          .doc(uid)
          .set(user.toFirestore());

      // Write default exercise access
      await _db.collection('users').doc(uid).set(
        ExerciseAccess.defaultStudent().toMap(),
        SetOptions(merge: true),
      );

      // Sign out immediately — must wait for approval
      await _auth.signOut();

      return {'success': true};
    } on FirebaseAuthException catch (e) {
      return {'error': _signUpErrorMessage(e.code)};
    } catch (e) {
      return {'error': 'Something went wrong. Try again.'};
    }
  }

  // ─── Logout ───────────────────────────────────────────────────
  static Future<void> logout() async {
    _currentUser = null;
    await _auth.signOut();
  }

  // ─── Fetch user profile ───────────────────────────────────────
  static Future<UserModel?> _fetchUserProfile(String uid) async {
    try {
      final doc = await _db.collection('users').doc(uid).get();
      if (!doc.exists) return null;
      final user = UserModel.fromFirestore(doc);
      _currentUser = user;
      return user;
    } catch (e) {
      return null;
    }
  }

  // ─── Auth error messages ──────────────────────────────────────
  static String _errorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
        return 'Incorrect password.';
      case 'invalid-email':
        return 'Invalid email address.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many attempts. Try again later.';
      case 'invalid-credential':
        return 'Invalid email or password.';
      default:
        return 'Login failed. Please try again.';
    }
  }

  static String _signUpErrorMessage(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'An account with this email already exists.';
      case 'invalid-email':
        return 'Invalid email address.';
      case 'weak-password':
        return 'Password must be at least 6 characters.';
      default:
        return 'Sign up failed. Please try again.';
    }
  }
}