part of 'expense_balance_bloc.dart';

// expense_balance_state.dart
@immutable
abstract class ExpenseBalanceState {}

class ExpenseBalancesInitial extends ExpenseBalanceState {}

class ExpenseBalancesLoading extends ExpenseBalanceState {}

class ExpenseBalancesSettled extends ExpenseBalanceState {
  final List<Map<String, dynamic>> transactions;

  ExpenseBalancesSettled(this.transactions);
}



class ExpenseBalancesError extends ExpenseBalanceState {
  final String message;
  ExpenseBalancesError(this.message);
}
