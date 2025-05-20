part of 'expense_bloc.dart';

@immutable
sealed class ExpenseEvent {}

class AddExpenseEvent extends ExpenseEvent {
  final int amount;
  final String description;
  final List<String> participants;

  AddExpenseEvent(
      {required this.amount,
      required this.description,
      required this.participants});
}

class GetExpensesEvent extends ExpenseEvent{}

class DeleteExpenseEvent extends ExpenseEvent {
  final String expenseId;
  DeleteExpenseEvent(this.expenseId);
}