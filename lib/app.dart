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

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;
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
        home: SignInScreen(), // Gọi màn login ở đây
        routes: {
          '/home': (_) => HomeScreen(), // ✅ định nghĩa route ở đây
          '/add-expense': (_) => AddExpenseScreen(), // ✅ định nghĩa route ở đây'
        },
      ),
    );
  }
}