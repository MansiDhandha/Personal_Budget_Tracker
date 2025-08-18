import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:expense_repository/expense_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

part 'create_expense_event.dart';
part 'create_expense_state.dart';

class CreateExpenseBloc extends Bloc<CreateExpenseEvent, CreateExpenseState> {
  final ExpenseRepository expenseRepository;

  CreateExpenseBloc(this.expenseRepository) : super(CreateExpenseInitial()) {
    on<CreateExpense>((event, emit) async {
      emit(CreateExpenseLoading());

      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) {
          emit(CreateExpenseFailure());
          return;
        }

        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        final monthlyBudget = (userDoc.data()?['monthly_budget'] ?? 0).toDouble();

        final expensesSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('expenses')
            .get();

        double totalExpenses = 0;
        for (var doc in expensesSnapshot.docs) {
          final expenseAmount = (doc['amount'] ?? 0).toDouble();
          totalExpenses += expenseAmount;
        }

        final newTotal = totalExpenses + event.expense.amount;

        if (newTotal > monthlyBudget) {
          emit(CreateExpenseOverBudget());
          return;
        }

        await expenseRepository.createExpense(event.expense);
        emit(CreateExpenseSuccess());

      } catch (e) {
        emit(CreateExpenseFailure());
      }
    });
  }
}
