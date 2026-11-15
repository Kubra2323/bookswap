import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/validators.dart';
import '../data/auth_repository.dart';

class AuthViewModel extends ChangeNotifier {
  AuthViewModel(this._repo) {
    _sub = _repo.authStateChanges().listen((user) {
      _user = user;
      notifyListeners();
    });
  }

  final AuthRepository _repo;
  late final StreamSubscription<AppUser?> _sub;

  AppUser? _user;
  bool _busy = false;
  String? _error;

  AppUser? get user => _user;
  bool get busy => _busy;
  String? get error => _error;

  Future<void> signIn(String email, String password) =>
      _submit(email, password, () => _repo.signIn(email.trim(), password));

  Future<void> register(String email, String password) =>
      _submit(email, password, () => _repo.register(email.trim(), password));

  Future<void> resendVerification() => _run(_repo.resendVerification);

  /// Called by the "I verified my email" button.
  Future<void> refreshUser() => _run(() async {
        _user = await _repo.reload();
      });

  Future<void> signOut() => _repo.signOut();

  Future<void> _submit(String email, String password, Future<void> Function() action) async {
    final problem = validateUniversityEmail(email) ?? validatePassword(password);
    if (problem != null) {
      _error = problem;
      notifyListeners();
      return;
    }
    await _run(action);
  }

  Future<void> _run(Future<void> Function() action) async {
    _busy = true;
    _error = null;
    notifyListeners();
    try {
      await action();
    } on AuthFailure catch (e) {
      _error = e.message;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}
