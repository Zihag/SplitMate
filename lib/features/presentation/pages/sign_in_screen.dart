import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:splitmate/features/presentation/bloc/auth_bloc/auth_bloc.dart';

class SignInScreen extends StatelessWidget {
  const SignInScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('SplitMate Login')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: BlocConsumer<AuthBloc, AuthState>(
          listener: (context, state) {
            if (state is GoogleSignInError) {
              ScaffoldMessenger.of(context)
                  .showSnackBar(SnackBar(content: Text(state.error)));
            } else if (state is GoogleAuthAuthenticated) {
              Navigator.pushReplacementNamed(context, '/home');
            }
          },
          builder: (context, state) {
            if (state is GoogleSignInLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            return Center(
              child: ElevatedButton.icon(
                onPressed: () {
                  context.read<AuthBloc>().add(GoogleSignInEvent());
                },
                icon: const Icon(Icons.login),
                label: const Text('Login with Google'),
              ),
            );
          },
        ),
      ),
    );
  }
}
