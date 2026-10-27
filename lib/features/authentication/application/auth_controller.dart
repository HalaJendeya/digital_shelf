import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/app_exception.dart';
import '../../../core/providers.dart';
import '../data/auth_repository.dart';
import '../data/customer.dart';

enum AuthStatus { unknown, authenticated, guest }

class AuthState {
  const AuthState(this.status, {this.customer, this.sessionExpired = false});

  const AuthState.unknown() : this(AuthStatus.unknown);
  const AuthState.guest({bool sessionExpired = false}) : this(AuthStatus.guest, sessionExpired: sessionExpired);

  final AuthStatus status;
  final Customer? customer;

  /// True when the server revoked the session (401), as opposed to a logout.
  final bool sessionExpired;

  bool get isAuthenticated => status == AuthStatus.authenticated;
}

class AuthController extends Notifier<AuthState> {
  AuthRepository get _repo => ref.read(authRepositoryProvider);

  @override
  AuthState build() {
    final signal = ref.watch(unauthorizedSignalProvider);
    void onUnauthorized() {
      if (state.isAuthenticated) _clearSession(expired: true);
    }

    signal.addListener(onUnauthorized);
    ref.onDispose(() => signal.removeListener(onUnauthorized));
    return const AuthState.unknown();
  }

  /// Restores a saved session at startup. A network failure keeps the user
  /// signed in (offline-tolerant); only a 401 discards the token.
  Future<void> restore() async {
    final token = await ref.read(tokenStorageProvider).read();
    if (token == null || token.isEmpty) {
      state = const AuthState.guest();
      return;
    }
    ref.read(sessionTokenProvider.notifier).set(token);
    state = const AuthState(AuthStatus.authenticated);
    try {
      final customer = await _repo.me();
      state = AuthState(AuthStatus.authenticated, customer: customer);
    } on AppException catch (e) {
      if (e.isUnauthorized) await _clearSession(expired: true);
    }
  }

  Future<void> login({required String email, required String password}) async {
    final result = await _repo.login(email: email, password: password);
    await _startSession(result);
  }

  Future<void> register({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String passwordConfirmation,
  }) async {
    final result = await _repo.register(
      name: name,
      email: email,
      phone: phone,
      password: password,
      passwordConfirmation: passwordConfirmation,
    );
    await _startSession(result);
  }

  Future<void> refreshProfile() async {
    if (!state.isAuthenticated) return;
    final customer = await _repo.me();
    state = AuthState(AuthStatus.authenticated, customer: customer);
  }

  Future<void> updateProfile({required String name, required String phone, String? email}) async {
    final updated = await _repo.updateProfile(name: name, phone: phone, email: email);
    if (updated != null && updated.id != 0) {
      state = AuthState(AuthStatus.authenticated, customer: updated);
    } else {
      await refreshProfile();
    }
  }

  /// Revokes the token server-side when possible; the local session is always cleared.
  Future<void> logout() async {
    try {
      await _repo.logout();
    } on AppException {
      // Token may already be invalid or the device offline — still sign out locally.
    }
    await _clearSession();
  }

  Future<void> _startSession(AuthResult result) async {
    await ref.read(tokenStorageProvider).write(result.token);
    ref.read(sessionTokenProvider.notifier).set(result.token);
    state = AuthState(AuthStatus.authenticated, customer: result.customer);
    if (result.customer == null) {
      try {
        await refreshProfile();
      } on AppException {
        // Profile can be loaded later from the account tab.
      }
    }
  }

  Future<void> _clearSession({bool expired = false}) async {
    ref.read(sessionTokenProvider.notifier).set(null);
    state = AuthState.guest(sessionExpired: expired);
    await ref.read(tokenStorageProvider).clear();
  }
}

final authControllerProvider = NotifierProvider<AuthController, AuthState>(AuthController.new);

/// Convenience selector used by data providers that depend on the session.
final isAuthenticatedProvider = Provider<bool>(
  (ref) => ref.watch(authControllerProvider.select((s) => s.isAuthenticated)),
);
