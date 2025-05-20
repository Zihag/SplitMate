import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:splitmate/features/data/models/expense_model.dart';
import 'package:splitmate/features/presentation/bloc/auth_bloc/auth_bloc.dart';
import 'package:splitmate/features/presentation/bloc/expense_balance/expense_balance_bloc.dart';
import 'package:splitmate/features/presentation/bloc/expense_bloc/expense_bloc.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        // Logout listener
        BlocListener<AuthBloc, AuthState>(
          listener: (context, state) {
            if (state is AuthInitial) {
              Navigator.pushReplacementNamed(context, '/');
            }
          },
        ),
        // Refresh balances when expenses loaded or deleted
        BlocListener<ExpenseBloc, ExpenseState>(
          listener: (context, state) {
            if (state is ExpenseLoaded || state is ExpenseDeletedSuccess) {
              context.read<ExpenseBalanceBloc>().add(ExpenseLoadBalancesEvent());
            }
            if (state is ExpenseDeletedSuccess) {
              // refetch expenses list
              context.read<ExpenseBloc>().add(GetExpensesEvent());
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Xóa chi tiêu thành công')),
              );
            }
            if (state is ExpenseDeleteError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Lỗi xóa: ${state.message}')),
              );
            }
          },
        ),
      ],
      child: Scaffold(
        appBar: AppBar(
          title: const Text('SplitMate Home'),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Refresh',
              onPressed: () {
                context.read<ExpenseBloc>().add(GetExpensesEvent());
              },
            ),
            IconButton(
              icon: const Icon(Icons.logout),
              tooltip: 'Logout',
              onPressed: () {
                context.read<AuthBloc>().add(GoogleSignOutEvent());
              },
            ),
          ],
        ),
        body: Column(
          children: [
            Expanded(
              flex: 2,
              child: BlocBuilder<ExpenseBloc, ExpenseState>(
                builder: (context, state) {
                  if (state is ExpenseInitial) {
                    context.read<ExpenseBloc>().add(GetExpensesEvent());
                    return const Center(child: CircularProgressIndicator());
                  } else if (state is ExpenseLoading) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (state is ExpenseLoaded) {
                    final expenses = state.expenses;
                    if (expenses.isEmpty) {
                      return const Center(child: Text('Không có chi tiêu nào.'));
                    }
                    return ListView.builder(
                      itemCount: expenses.length,
                      itemBuilder: (context, index) {
                        final e = expenses[index];
                        return ListTile(
                          title: Text(e.description),
                          subtitle: Text(
                            '₫${e.amount} • ${e.createdAt.toLocal().toString().split('.').first}',
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('👥 ${e.participants.length}'),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(Icons.delete),
                                tooltip: 'Xóa',
                                onPressed: () {
                                  context.read<ExpenseBloc>().add(DeleteExpenseEvent(e.id));
                                },
                              ),
                            ],
                          ),
                          onLongPress: () {
                            context.read<ExpenseBalanceBloc>().add(
                              ExpenseSetCheckpointEvent(e.id),
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Marked as checkpoint')),
                            );
                          },
                        );
                      },
                    );
                  } else if (state is GetExpenseError) {
                    return Center(child: Text('Error: ${state.error}'));
                  }
                  return const SizedBox();
                },
              ),
            ),
            const Divider(height: 1),
            Expanded(
              flex: 1,
              child: BlocBuilder<ExpenseBalanceBloc, ExpenseBalanceState>(
                builder: (context, state) {
                  if (state is ExpenseBalancesLoading) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (state is ExpenseBalancesSettled) {
                    final transactions = state.transactions;
                    if (transactions.isEmpty) {
                      return const Center(child: Text('Mọi người đã thanh toán đủ.'));
                    }
                    return ListView.builder(
                      itemCount: transactions.length,
                      itemBuilder: (context, index) {
                        final tx = transactions[index];
                        return ListTile(
                          title: Text('${tx['from']} → ${tx['to']}'),
                          subtitle: Text('₫${tx['amount'].toStringAsFixed(0)}'),
                        );
                      },
                    );
                  } else if (state is ExpenseBalancesError) {
                    return Center(child: Text('Lỗi: ${state.message}'));
                  }
                  return const SizedBox();
                },
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            Navigator.pushNamed(context, '/add-expense');
          },
          tooltip: 'Thêm chi tiêu',
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}
