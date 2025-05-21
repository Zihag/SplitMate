import 'package:firebase_auth/firebase_auth.dart';
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
    User user = FirebaseAuth.instance.currentUser!;
    return MultiBlocListener(
      listeners: [
        // Logout listener
        BlocListener<AuthBloc, AuthState>(
          listener: (context, state) {
            if (state is AuthInitial) {
              Navigator.pushReplacementNamed(context, '/sign-in');
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
          title: Row(
            children: [
              CircleAvatar(backgroundImage: NetworkImage(user.photoURL!),),
              SizedBox(width: 10,),
              Text(user.displayName!, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),),
            ],
          ),
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
              flex: 3,
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
                        return Card(
                          color: Colors.cyan[100],
                          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          elevation: 2,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Tiêu đề: ngày và nút xóa
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Container(decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Text(e.createdAt.toLocal().toString().split(' ')[0],
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                        ),),
                                    ),),
                                    Visibility(
                                      visible: e.createdBy == user.displayName,
                                      maintainSize: true,
                                      maintainAnimation: true,
                                      maintainState: true,
                                      child: IconButton(
                                        icon: const Icon(Icons.delete, size: 20),
                                        tooltip: 'Xóa',
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                        onPressed: () async {
                                          final confirm = await showDialog<bool>(
                                            context: context,
                                            builder: (context) => AlertDialog(
                                              title: const Text('Xác nhận'),
                                              content: const Text('Bạn có chắc chắn muốn xóa chi tiêu này?'),
                                              actions: [
                                                TextButton(
                                                  onPressed: () => Navigator.of(context).pop(false),
                                                  child: const Text('Hủy'),
                                                ),
                                                ElevatedButton(
                                                  onPressed: () => Navigator.of(context).pop(true),
                                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                                  child: const Text('Xóa'),
                                                ),
                                              ],
                                            ),
                                          );

                                          if (confirm == true) {
                                            context.read<ExpenseBloc>().add(DeleteExpenseEvent(e.id));
                                          }
                                        },
                                      ),
                                    )


                                  ],
                                ),
                                const SizedBox(height: 6),

                                // Nội dung: description
                                Text(
                                  e.description,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 8),

                                // Số tiền và người chi
                                Row(
                                  children: [
                                    const Icon(Icons.monetization_on, size: 16),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${e.amount.toStringAsFixed(0)} ₫',
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                    const Spacer(),
                                    const Icon(Icons.account_balance_wallet, size: 16),
                                    const SizedBox(width: 4),
                                    Text(
                                      e.createdBy,
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),

                                // Người hưởng
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(Icons.group, size: 16),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        e.participants.join(', '),
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                    ),
                                  ],
                                ),

                                // Checkpoint hint (optional)

                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: IconButton(
                                      onPressed: () {
                                        if (user.email == 'nghia.zihag@gmail.com'){
                                          context
                                              .read<ExpenseBalanceBloc>()
                                              .add(ExpenseSetCheckpointEvent(e.id));
                                          context.read<ExpenseBloc>().add(GetExpensesEvent());
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text('Đã đánh dấu checkpoint')),
                                          );
                                        }
                                      },
                                      icon: Icon(
                                        Icons.done_all,
                                        size: 30,
                                        color: e.isCheckPoint ? Colors.green : Colors.grey,
                                      ),
                                      tooltip: e.isCheckPoint ? 'Đã đánh dấu' : 'Đánh dấu checkpoint',
                                    ),
                                  ),

                              ],
                            ),
                          ),
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
