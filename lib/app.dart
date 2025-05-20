import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:splitmate/features/presentation/bloc/auth_bloc/auth_bloc.dart';
import 'package:splitmate/features/presentation/bloc/expense_balance/expense_balance_bloc.dart';
import 'package:splitmate/features/presentation/bloc/expense_bloc/expense_bloc.dart';
import 'package:splitmate/features/presentation/pages/add_expense_screen.dart';
import 'package:splitmate/features/presentation/pages/home_screen.dart';
import 'package:splitmate/features/presentation/pages/sign_in_screen.dart';

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _isLoggedIn();
  }

  Future<bool> _isLoggedIn() async {
    await Future.delayed(const Duration(seconds: 2));

    User? user = FirebaseAuth.instance.currentUser;

    return user != null;
  }
  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(
          create: (_) => AuthBloc(
            FirebaseAuth.instance,
            FirebaseFirestore.instance,
          ),
        ),
        BlocProvider<ExpenseBloc>(
          create: (_) => ExpenseBloc(
            firestore: FirebaseFirestore.instance,
            auth: FirebaseAuth.instance,
          ),
        ),
        BlocProvider(
          create: (_) => ExpenseBalanceBloc(FirebaseFirestore.instance),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'SplitMate',
        theme: ThemeData(
          primarySwatch: Colors.indigo,
        ),
        home: FutureBuilder<bool>(
          future: _isLoggedIn(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            } else if (snapshot.hasData && snapshot.data == true) {
              return const HomeScreen();
            } else {
              return const SignInScreen();
            }
          },
        ),
        routes: {
          '/home': (_) => const HomeScreen(),
          '/add-expense': (_) => const AddExpenseScreen(),
        },
      ),
    );
  }
}