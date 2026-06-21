import 'package:equatable/equatable.dart';

class AuthUIState extends Equatable {
  final bool isAuthenticated;
  final String? userId;
  final String? email;
  final bool isLoading;
  final String? errorMessage;

  const AuthUIState({
    this.isAuthenticated = false,
    this.userId,
    this.email,
    this.isLoading = false,
    this.errorMessage,
  });

  AuthUIState copyWith({
    bool? isAuthenticated,
    String? userId,
    String? email,
    bool? isLoading,
    String? errorMessage,
  }) {
    return AuthUIState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      userId: userId ?? this.userId,
      email: email ?? this.email,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [isAuthenticated, userId, email, isLoading, errorMessage];
}
