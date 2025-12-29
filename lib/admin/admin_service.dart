import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static Future<bool> checkFirestoreConnection() async {
    try {
      await _firestore.collection('admins').limit(1).get().timeout(
        const Duration(seconds: 5),
      );
      return true;
    } catch (e) {
      print('Firestore connection check failed: $e');
      return false;
    }
  }

  static Future<bool> createAdmin({
    required String email,
    required String password,
    required String name,
    String? phoneNumber,
  }) async {
    try {
      try {
        await _firestore.collection('admins').limit(1).get().timeout(
          const Duration(seconds: 5),
        );
      } catch (e) {
        throw Exception(
          'Cannot connect to Firestore. Please ensure:\n'
          '1. Firestore is enabled in Firebase Console\n'
          '2. You have an active internet connection\n'
          '3. Firestore security rules allow access\n'
          '4. Restart the app after enabling Firestore'
        );
      }

      final querySnapshot = await _firestore
          .collection('admins')
          .where('email', isEqualTo: email)
          .limit(1)
          .get()
          .timeout(const Duration(seconds: 10));

      if (querySnapshot.docs.isNotEmpty) {
        throw Exception('Admin with this email already exists');
      }

      final adminDocRef = _firestore.collection('admins').doc();

      await adminDocRef.set({
        'uid': adminDocRef.id,
        'email': email,
        'password': password,
        'name': name,
        'phoneNumber': phoneNumber ?? '',
        'role': 'admin',
        'createdAt': FieldValue.serverTimestamp(),
        'isActive': true,
      }).timeout(const Duration(seconds: 10));

      return true;
    } catch (e) {
      print('Error creating admin: $e');
      String errorMessage = 'Failed to create admin';
      
      final errorString = e.toString().toLowerCase();
      
      if (errorString.contains('unable to establish connection') || 
          errorString.contains('connection') ||
          errorString.contains('channel')) {
        errorMessage = 'Cannot connect to Firestore. Please:\n'
            '1. Go to Firebase Console and enable Firestore Database\n'
            '2. Wait a few minutes for Firestore to initialize\n'
            '3. Restart the app completely\n'
            '4. Check your internet connection';
      } else if (errorString.contains('permission-denied') || 
                 errorString.contains('permission denied')) {
        errorMessage = 'Permission denied. Please check Firestore security rules in Firebase Console.';
      } else if (errorString.contains('unavailable') || 
                 errorString.contains('unavailable')) {
        errorMessage = 'Firestore is unavailable. Please check your internet connection and ensure Firestore is enabled in Firebase Console.';
      } else if (errorString.contains('deadline-exceeded') || 
                 errorString.contains('timeout')) {
        errorMessage = 'Request timed out. Please check your internet connection.';
      } else if (e is Exception) {
        errorMessage = e.toString().replaceFirst('Exception: ', '');
      } else {
        errorMessage = 'Firestore error: ${e.toString()}';
      }
      throw Exception(errorMessage);
    }
  }

  static Future<bool> isAdmin(String identifier, {bool isEmail = false}) async {
    try {
      if (isEmail) {
        final querySnapshot = await _firestore
            .collection('admins')
            .where('email', isEqualTo: identifier)
            .limit(1)
            .get()
            .timeout(const Duration(seconds: 10));
        return querySnapshot.docs.isNotEmpty && 
               querySnapshot.docs.first.data()['role'] == 'admin';
      } else {
        final doc = await _firestore.collection('admins').doc(identifier).get()
            .timeout(const Duration(seconds: 10));
        if (doc.exists) {
          final data = doc.data();
          return data != null && data['role'] == 'admin';
        }
        final querySnapshot = await _firestore
            .collection('admins')
            .where('uid', isEqualTo: identifier)
            .limit(1)
            .get()
            .timeout(const Duration(seconds: 10));
        return querySnapshot.docs.isNotEmpty && 
               querySnapshot.docs.first.data()['role'] == 'admin';
      }
    } catch (e) {
      print('Error checking admin status: $e');
      return false;
    }
  }

  static Future<Map<String, dynamic>?> getAdminData(String identifier, {bool isEmail = false}) async {
    try {
      if (isEmail) {
        final querySnapshot = await _firestore
            .collection('admins')
            .where('email', isEqualTo: identifier)
            .limit(1)
            .get()
            .timeout(const Duration(seconds: 10));
        if (querySnapshot.docs.isNotEmpty) {
          return querySnapshot.docs.first.data();
        }
      } else {
        final doc = await _firestore.collection('admins').doc(identifier).get()
            .timeout(const Duration(seconds: 10));
        if (doc.exists) {
          return doc.data();
        }
        final querySnapshot = await _firestore
            .collection('admins')
            .where('uid', isEqualTo: identifier)
            .limit(1)
            .get()
            .timeout(const Duration(seconds: 10));
        if (querySnapshot.docs.isNotEmpty) {
          return querySnapshot.docs.first.data();
        }
      }
      return null;
    } catch (e) {
      print('Error getting admin data: $e');
      return null;
    }
  }

  static Future<Map<String, dynamic>?> adminLogin({
    required String email,
    required String password,
  }) async {
    try {
      final querySnapshot = await _firestore
          .collection('admins')
          .where('email', isEqualTo: email)
          .limit(1)
          .get()
          .timeout(const Duration(seconds: 10));

      if (querySnapshot.docs.isEmpty) {
        throw Exception('Admin not found with this email');
      }

      final adminDoc = querySnapshot.docs.first;
      final adminData = adminDoc.data();

      if (adminData['password'] != password) {
        throw Exception('Invalid password');
      }

      final isActive = adminData['isActive'];
      if (isActive != true) {
        throw Exception('Admin account is not active');
      }

      try {
        await _auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
      } on FirebaseAuthException catch (e) {
        if (e.code == 'user-not-found') {
          try {
            await _auth.createUserWithEmailAndPassword(
              email: email,
              password: password,
            );
          } catch (createError) {
            print('Warning: Could not create Firebase Auth account: $createError');
          }
        } else if (e.code == 'invalid-credential' || e.code == 'wrong-password') {
          print('Warning: Firebase Auth credentials don\'t match, but Firestore validation passed. Continuing with login.');
          
          try {
            await _auth.signOut();
          } catch (signOutError) {
            print('Warning: Could not sign out: $signOutError');
          }
          
          try {
            await _auth.createUserWithEmailAndPassword(
              email: email,
              password: password,
            );
          } catch (createError) {
            print('Note: Firebase Auth account exists but password differs. Login allowed via Firestore validation.');
          }
        } else {
          print('Warning: Firebase Auth error: ${e.code} - ${e.message}. Login allowed via Firestore validation.');
        }
      } catch (e) {
        print('Warning: Firebase Auth error (non-blocking): $e');
      }

      final currentUser = _auth.currentUser;
      if (currentUser != null && adminData['uid'] != currentUser.uid) {
        await adminDoc.reference.update({
          'uid': currentUser.uid,
        }).timeout(const Duration(seconds: 10));
        adminData['uid'] = currentUser.uid;
      }

      return adminData;
    } catch (e) {
      print('Error in admin login: $e');
      String errorMessage = 'Failed to login';
      if (e.toString().contains('permission-denied') || 
          e.toString().contains('PERMISSION_DENIED')) {
        errorMessage = 'Permission denied. Please check Firestore security rules.';
      } else if (e.toString().contains('unavailable') || 
                 e.toString().contains('UNAVAILABLE')) {
        errorMessage = 'Firestore is unavailable. Please check your internet connection and ensure Firestore is enabled in Firebase Console.';
      } else if (e.toString().contains('deadline-exceeded') || 
                 e.toString().contains('DEADLINE_EXCEEDED')) {
        errorMessage = 'Request timed out. Please check your internet connection.';
      } else if (e is Exception) {
        errorMessage = e.toString().replaceFirst('Exception: ', '');
      } else {
        errorMessage = 'Firestore error: ${e.toString()}. Please check Firestore rules and enable Firestore in Firebase Console.';
      }
      throw Exception(errorMessage);
    }
  }
}

