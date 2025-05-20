part of 'expense_balance_bloc.dart';

// expense_balance_event.dart
@immutable
abstract class ExpenseBalanceEvent {}

/// Tải và tính toán cân bằng từ checkpoint (nếu có) đến giờ
class ExpenseLoadBalancesEvent extends ExpenseBalanceEvent {}

/// Đánh dấu một expense làm checkpoint
class ExpenseSetCheckpointEvent extends ExpenseBalanceEvent {
  final String expenseId;
  ExpenseSetCheckpointEvent(this.expenseId);
}


