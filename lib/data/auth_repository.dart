import 'package:firebase_auth/firebase_auth.dart';

class AppUser {
  const AppUser({required this.uid, required this.email, required this.emailVerified});

  final String uid;
  final String email;
  final bool emailVerified;
}

/// A friendly, user-facing auth error (the view model shows [message] as is).
class AuthFailure implements Exception {
  const AuthFailure(this.message);

  final String message;

  @override
  String toString() => message;
}

abstract class AuthRepository {
  Stream<AppUser?> authStateChanges();
  Future<void> signIn(String email, String password);

  /// Creates the account and sends the verification email.
  Future<void> register(String email, String password);
  Future<void> resendVerification();

  /// Re-reads the user from Firebase (after they clicked the link) and returns it.
  Future<AppUser?> reload();
  Future<void> signOut();
}

class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository({FirebaseAuth? auth}) : _auth = auth ?? FirebaseAuth.instance;

  final FirebaseAuth _auth;

  AppUser? _map(User? u) =>
      u == null ? null : AppUser(uid: u.uid, email: u.email ?? '', emailVerified: u.emailVerified);

  @override
  Stream<AppUser?> authStateChanges() => _auth.authStateChanges().map(_map);

  @override
  Future<void> signIn(String email, String password) =>
      _guard(() => _auth.signInWithEmailAndPassword(email: email, password: password));

  @override
  Future<void> register(String email, String password) => _guard(() async {
        final cred = await _auth.createUserWithEmailAndPassword(email: email, password: password);
        await cred.user?.sendEmailVerification();
      });

  @override
  Future<void> resendVerification() => _guard(() async {
        await _auth.currentUser?.sendEmailVerification();
      });

  @override
  Future<AppUser?> reload() async {
    await _auth.currentUser?.reload();
    // Force a fresh ID token so Firestore rules and Cloud Functions see email_verified = true.
    await _auth.currentUser?.getIdToken(true);
    return _map(_auth.currentUser);
  }

  @override
  Future<void> signOut() => _auth.signOut();

  Future<void> _guard(Future<void> Function() action) async {
    try {
      await action();
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(_messageFor(e.code));
    }
  }

  String _messageFor(String code) {
    switch (code) {
      case 'invalid-credential':
      case 'wrong-password':
      case 'user-not-found':
        return 'Wrong email or password.';
      case 'email-already-in-use':
        return 'This email already has an account. Sign in instead.';
      case 'weak-password':
        return 'Password is too weak.';
      case 'too-many-requests':
        return 'Too many attempts. Try again later.';
      case 'network-request-failed':
        return 'No network connection.';
      default:
        return 'Could not sign in ($code).';
    }
  }
}
