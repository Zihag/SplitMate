part of 'auth_bloc.dart';

@immutable
sealed class AuthState {}

final class AuthInitial extends AuthState {}

class GoogleSignInLoading extends AuthState {}

class GoogleSignInSuccess extends AuthState {}

class GoogleAuthAuthenticated extends AuthState {}

class GoogleSignInError extends AuthState {
  final String error;

  GoogleSignInError(this.error);
}

class GoogleSignOutSuccess extends AuthState {}
