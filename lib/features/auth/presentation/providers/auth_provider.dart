import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/services/auth_api_service.dart';
import '../../domain/models/auth_user.dart';

final authApiServiceProvider = Provider<AuthApiService>((ref) {
  return AuthApiService();
});

class AuthState {
  final AuthUser? user;
  final bool isLoading;
  final String? errorMessage;
  final bool isOfflineMode;

  const AuthState({
    this.user,
    this.isLoading = false,
    this.errorMessage,
    this.isOfflineMode = false,
  });

  bool get isAuthenticated => user != null;

  AuthState copyWith({
    AuthUser? Function()? user,
    bool? isLoading,
    String? Function()? errorMessage,
    bool? isOfflineMode,
  }) {
    return AuthState(
      user: user != null ? user() : this.user,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage != null ? errorMessage() : this.errorMessage,
      isOfflineMode: isOfflineMode ?? this.isOfflineMode,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthApiService _authService;

  AuthNotifier(this._authService) : super(const AuthState()) {
    checkInitialSession();
  }

  Future<void> checkInitialSession() async {
    state = state.copyWith(isLoading: true, errorMessage: () => null);
    try {
      final user = await _authService.getStoredUser();
      state = state.copyWith(
        user: () => user,
        isLoading: false,
        isOfflineMode: user == null,
      );
    } catch (_) {
      state = state.copyWith(isLoading: false, isOfflineMode: true);
    }
  }

  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true, errorMessage: () => null);
    try {
      final user = await _authService.login(email, password);
      state = state.copyWith(
        user: () => user,
        isLoading: false,
        isOfflineMode: false,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: () => e.toString(),
      );
      return false;
    }
  }

  Future<bool> register({
    required String name,
    required String email,
    required String password,
    String role = 'OPERATOR',
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: () => null);
    try {
      final user = await _authService.register(
        name: name,
        email: email,
        password: password,
        role: role,
      );
      state = state.copyWith(
        user: () => user,
        isLoading: false,
        isOfflineMode: false,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: () => e.toString(),
      );
      return false;
    }
  }

  Future<void> logout() async {
    await _authService.logout();
    state = const AuthState(isOfflineMode: true);
  }

  void continueOffline() {
    state = state.copyWith(isOfflineMode: true, errorMessage: () => null);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final service = ref.watch(authApiServiceProvider);
  return AuthNotifier(service);
});
