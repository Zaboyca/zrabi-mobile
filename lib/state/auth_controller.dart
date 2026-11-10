import 'package:flutter/foundation.dart';

import '../core/api_exception.dart';
import '../models/user.dart';
import '../services/auth_service.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthController extends ChangeNotifier {
  AuthController(
    this._auth, {
    this.onAuthenticated,
    this.onLoggedOut,
  });

  final AuthService _auth;
  final Future<void> Function()? onAuthenticated;
  final VoidCallback? onLoggedOut;

  AuthStatus status = AuthStatus.unknown;
  User? user;
  String? errorMessage;
  bool busy = false;

  Future<void> bootstrap() async {
    final token = await _auth.savedToken();
    if (token == null || token.isEmpty) {
      status = AuthStatus.unauthenticated;
      user = null;
      onLoggedOut?.call();
      notifyListeners();
      return;
    }

    try {
      user = await _auth.me();
      status = AuthStatus.authenticated;
      notifyListeners();
      await onAuthenticated?.call();
      return;
    } on ApiException {
      try {
        await _auth.logout();
      } catch (_) {}
      status = AuthStatus.unauthenticated;
      user = null;
    } catch (_) {
      status = AuthStatus.unauthenticated;
      user = null;
    }
    onLoggedOut?.call();
    notifyListeners();
  }

  Future<bool> login({
    required String email,
    required String password,
  }) {
    return _runAuth(() async {
      final session = await _auth.login(email: email, password: password);
      user = session.user;
      status = AuthStatus.authenticated;
    });
  }

  Future<bool> loginWithSocialToken(String token) {
    return _runAuth(() async {
      final session = await _auth.loginWithToken(token);
      user = session.user;
      status = AuthStatus.authenticated;
    });
  }

  Future<bool> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
  }) {
    return _runAuth(() async {
      final session = await _auth.register(
        name: name,
        email: email,
        password: password,
        passwordConfirmation: passwordConfirmation,
      );
      user = session.user;
      status = AuthStatus.authenticated;
    });
  }

  Future<void> refreshMe() async {
    errorMessage = null;
    busy = true;
    notifyListeners();

    try {
      user = await _auth.me();
      status = AuthStatus.authenticated;
    } on ApiException catch (e) {
      if (e.statusCode == 401) {
        errorMessage = null;
        status = AuthStatus.unauthenticated;
        user = null;
        onLoggedOut?.call();
      } else {
        errorMessage = e.displayMessage;
      }
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Future<bool> updateProfile({
    required String name,
    required String email,
    String? phone,
  }) async {
    errorMessage = null;
    busy = true;
    notifyListeners();

    try {
      user = await _auth.updateProfile(
        name: name,
        email: email,
        phone: phone,
      );
      status = AuthStatus.authenticated;
      return true;
    } on ApiException catch (e) {
      errorMessage = e.displayMessage;
      if (e.statusCode == 401) {
        status = AuthStatus.unauthenticated;
        user = null;
      }
      return false;
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    busy = true;
    notifyListeners();

    try {
      await _auth.logout();
    } on ApiException {
      // Token already cleared in AuthService.finally
    } finally {
      user = null;
      status = AuthStatus.unauthenticated;
      busy = false;
      onLoggedOut?.call();
      notifyListeners();
    }
  }

  Future<bool> deleteAccount({required String password}) async {
    errorMessage = null;
    busy = true;
    notifyListeners();

    try {
      await _auth.deleteAccount(password: password);
      errorMessage = null;
      user = null;
      status = AuthStatus.unauthenticated;
      onLoggedOut?.call();
      return true;
    } on ApiException catch (e) {
      errorMessage = e.displayMessage;
      return false;
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Future<bool> _runAuth(Future<void> Function() action) async {
    errorMessage = null;
    busy = true;
    notifyListeners();

    try {
      await action();
      await onAuthenticated?.call();
      return true;
    } on ApiException catch (e) {
      errorMessage = e.displayMessage;
      return false;
    } finally {
      busy = false;
      notifyListeners();
    }
  }
}
