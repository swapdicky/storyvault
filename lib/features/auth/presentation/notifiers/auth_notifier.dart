import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/auth_state.dart';
import '../../domain/repositories/auth_repository.dart';

class AuthNotifier extends StateNotifier<AuthUIState> {
  final AuthRepository _authRepository;

  AuthNotifier(this._authRepository) : super(const AuthUIState()) {
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    final isAuthenticated = await _authRepository.isAuthenticated();
    if (isAuthenticated) {
      final userId = await _authRepository.getCurrentUserId();
      final email = await _authRepository.getCurrentEmail();
      state = state.copyWith(
        isAuthenticated: true,
        userId: userId,
        email: email,
      );
    }
  }

  Future<void> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    
    final result = await _authRepository.signUpWithEmail(
      email: email,
      password: password,
    );

    result.fold(
      (failure) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: failure.message,
        );
      },
      (_) async {
        await _checkAuthStatus();
        state = state.copyWith(isLoading: false);
      },
    );
  }

  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    
    final result = await _authRepository.signInWithEmail(
      email: email,
      password: password,
    );

    result.fold(
      (failure) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: failure.message,
        );
      },
      (_) async {
        await _checkAuthStatus();
        state = state.copyWith(isLoading: false);
      },
    );
  }

  Future<void> signInWithApple() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    
    final result = await _authRepository.signInWithApple();

    result.fold(
      (failure) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: failure.message,
        );
      },
      (_) async {
        await _checkAuthStatus();
        state = state.copyWith(isLoading: false);
      },
    );
  }

  Future<void> signOut() async {
    state = state.copyWith(isLoading: true);
    
    final result = await _authRepository.signOut();

    result.fold(
      (failure) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: failure.message,
        );
      },
      (_) {
        state = const AuthUIState();
      },
    );
  }

  void clearError() {
    state = state.copyWith(errorMessage: null);
  }
}
