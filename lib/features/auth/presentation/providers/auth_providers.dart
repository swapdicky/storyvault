import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/entities/auth_state.dart';
import '../notifiers/auth_notifier.dart';

// Auth Repository Provider
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(Supabase.instance.client);
});

// Auth Notifier Provider
final authNotifierProvider = StateNotifierProvider<AuthNotifier, AuthUIState>((ref) {
  return AuthNotifier(ref.watch(authRepositoryProvider));
});

// Convenience providers
final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(authNotifierProvider).isAuthenticated;
});

final currentUserIdProvider = Provider<String?>((ref) {
  return ref.watch(authNotifierProvider).userId;
});

final currentUserEmailProvider = Provider<String?>((ref) {
  return ref.watch(authNotifierProvider).email;
});

final authLoadingProvider = Provider<bool>((ref) {
  return ref.watch(authNotifierProvider).isLoading;
});

final authErrorProvider = Provider<String?>((ref) {
  return ref.watch(authNotifierProvider).errorMessage;
});
