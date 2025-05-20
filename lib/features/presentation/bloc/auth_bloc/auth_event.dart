part of 'auth_bloc.dart';

@immutable
sealed class AuthEvent {}

final class GoogleSignInEvent extends AuthEvent {}

final class GoogleSignOutEvent extends AuthEvent {}