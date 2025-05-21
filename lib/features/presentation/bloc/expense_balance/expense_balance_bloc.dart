import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:meta/meta.dart';
import 'package:splitmate/features/data/models/expense_model.dart';

part 'expense_balance_event.dart';
part 'expense_balance_state.dart';

class ExpenseBalanceBloc extends Bloc<ExpenseBalanceEvent, ExpenseBalanceState> {
  final FirebaseFirestore firestore;

  ExpenseBalanceBloc(this.firestore) : super(ExpenseBalancesInitial()) {
    on<ExpenseLoadBalancesEvent>(_onExpenseLoadBalances);
    on<ExpenseSetCheckpointEvent>(_onExpenseSetCheckpoint);
  }

  FutureOr<void> _onExpenseLoadBalances(
      ExpenseLoadBalancesEvent event,
      Emitter<ExpenseBalanceState> emit,
      ) async {
    emit(ExpenseBalancesLoading());
    try {
      final snapshot = await firestore
          .collection('expenses')
          .orderBy('createdAt', descending: false)
          .get();

      final all = snapshot.docs
          .map((d) => Expense.fromMap(d.id, d.data()))
          .toList();

      // Find last checkpoint
      final checkpoint = all.lastWhere(
            (e) => e.isCheckPoint,
        orElse: () => Expense(
          id: '',
          amount: 0,
          description: '',
          createdAt: DateTime.fromMillisecondsSinceEpoch(0),
          createdBy: '',
          participants: [],
        ),
      );

      // Filter expenses after checkpoint
      final toCompute = all.where(
            (e) => e.createdAt.isAfter(checkpoint.createdAt),
      );

      // Compute net balances
      final Map<String, double> balances = {};
      for (var exp in toCompute) {
        final share = exp.amount / exp.participants.length;
        final creator = exp.createdBy;

        // Trừ share cho tất cả người tham gia
        for (var p in exp.participants) {
          balances[p] = (balances[p] ?? 0) - share;
        }

        // Người tạo được cộng tổng share của tất cả người tham gia
        balances[creator] = (balances[creator] ?? 0) + share * exp.participants.length;
      }

      // Tách người nợ và người nhận
      final debtors = <MapEntry<String, double>>[];
      final creditors = <MapEntry<String, double>>[];
      balances.forEach((user, amount) {
        if (amount > 0.01) {
          creditors.add(MapEntry(user, amount));
        } else if (amount < -0.01) {
          debtors.add(MapEntry(user, -amount));
        }
      });

      // Sắp xếp từ lớn đến nhỏ
      creditors.sort((a, b) => b.value.compareTo(a.value));
      debtors.sort((a, b) => b.value.compareTo(a.value));

      final List<Map<String, dynamic>> transactions = [];
      int i = 0, j = 0;

      while (i < debtors.length && j < creditors.length) {
        final debtor = debtors[i];
        final creditor = creditors[j];
        final common = (debtor.value < creditor.value) ? debtor.value : creditor.value;

        transactions.add({
          'from': debtor.key,
          'to': creditor.key,
          'amount': double.parse(common.toStringAsFixed(2)),
        });

        debtors[i] = MapEntry(debtor.key, debtor.value - common);
        creditors[j] = MapEntry(creditor.key, creditor.value - common);

        if (debtors[i].value < 0.01) i++;
        if (creditors[j].value < 0.01) j++;
      }

      emit(ExpenseBalancesSettled(transactions));
    } catch (e) {
      emit(ExpenseBalancesError(e.toString()));
    }
  }

  FutureOr<void> _onExpenseSetCheckpoint(
      ExpenseSetCheckpointEvent event,
      Emitter<ExpenseBalanceState> emit,
      ) async {
    final docRef = firestore.collection('expenses').doc(event.expenseId);
    final snapshot = await docRef.get();

    final currentValue = snapshot.data()?['isCheckPoint'];

    final newValue = !(currentValue == true); // nếu là true → false, ngược lại → true

    await docRef.update({'isCheckPoint': newValue});

    add(ExpenseLoadBalancesEvent());
  }

}
