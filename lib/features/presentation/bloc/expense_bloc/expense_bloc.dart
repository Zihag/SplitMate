import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:meta/meta.dart';
import 'package:splitmate/features/data/models/expense_model.dart';

part 'expense_event.dart';

part 'expense_state.dart';

class ExpenseBloc extends Bloc<ExpenseEvent, ExpenseState> {
  final FirebaseFirestore firestore;
  final FirebaseAuth auth;

  ExpenseBloc({
    required this.firestore,
    required this.auth,
  }) : super(ExpenseInitial()) {
    on<AddExpenseEvent>(_onAddExpense);
    on<GetExpensesEvent>(_onGetExpenses);
    on<DeleteExpenseEvent>(_onDeleteExpense);
  }

  Future<void> _onAddExpense(
    AddExpenseEvent event,
    Emitter<ExpenseState> emit,
  ) async {
    emit(ExpenseAdding());
    try {
      final user = auth.currentUser;
      if (user == null) {
        emit(ExpenseAddError('User not signed in.'));
        return;
      }

      await firestore.collection('expenses').add({
        'amount': event.amount,
        'description': event.description,
        'createdAt': FieldValue.serverTimestamp(),
        'createdBy': user.displayName,
        'participants': event.participants,
      });

      emit(ExpenseAddedSuccess());
    } catch (e) {
      emit(ExpenseAddError(e.toString()));
    }
  }

  FutureOr<void> _onGetExpenses(
      GetExpensesEvent event, Emitter<ExpenseState> emit) async {
    emit(ExpenseLoading());
    try {
      final snapshot = await firestore
          .collection('expenses')
          .orderBy('createdAt', descending: true)
          .get();

      final expenses = snapshot.docs
          .map((doc) => Expense.fromMap(doc.id, doc.data()))
          .toList();

      emit(ExpenseLoaded(expenses));
    } catch (e) {
      emit(GetExpenseError('Failed to load expenses: $e'));
    }
  }

  FutureOr<void> _onDeleteExpense(
    DeleteExpenseEvent event,
    Emitter<ExpenseState> emit,
  ) async {
    emit(ExpenseDeleting());
    final user = auth.currentUser;
    if (user == null) {
      emit(ExpenseDeleteError('User not signed in.'));
      return;
    }

    try {
      final docRef = firestore.collection('expenses').doc(event.expenseId);
      final doc = await docRef.get();
      if (!doc.exists) {
        emit(ExpenseDeleteError('Expense not found.'));
        return;
      }

      final data = doc.data()!;
      final createdBy = data['createdBy'] as String;
      final displayName = user.displayName ?? '';

      if (createdBy != displayName) {
        emit(ExpenseDeleteError(
            'You do not have permission to delete this expense.'));
        return;
      }

      await docRef.delete();
      emit(ExpenseDeletedSuccess(event.expenseId));
    } catch (e) {
      emit(ExpenseDeleteError(e.toString()));
    }
  }
}
