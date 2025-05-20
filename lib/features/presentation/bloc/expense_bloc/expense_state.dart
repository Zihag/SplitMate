part of 'expense_bloc.dart';

@immutable
sealed class ExpenseState {}

final class ExpenseInitial extends ExpenseState {}

class ExpenseAdding extends ExpenseState{}

class ExpenseAddedSuccess extends ExpenseState {}

class ExpenseAddError extends ExpenseState {
  final String error;
  ExpenseAddError(this.error);
}

class ExpenseLoading extends ExpenseState {}

class ExpenseLoaded extends ExpenseState {
  final List<Expense> expenses;

  ExpenseLoaded(this.expenses);

}

class GetExpenseError extends ExpenseState {
  final String error;
  GetExpenseError(this.error);
}


//Delete expense
class ExpenseDeleting extends ExpenseState {}
class ExpenseDeletedSuccess extends ExpenseState {
  final String expenseId;
  ExpenseDeletedSuccess(this.expenseId);
}
class ExpenseDeleteError extends ExpenseState {
  final String message;
  ExpenseDeleteError(this.message);
}