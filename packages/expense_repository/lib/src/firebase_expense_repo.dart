import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:expense_repository/expense_repository.dart';

import 'entities/income_entity.dart';

class FirebaseExpenseRepo implements ExpenseRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>> get _userCategoryCollection {
    final uid = _auth.currentUser!.uid;
    return FirebaseFirestore.instance.collection('users').doc(uid).collection('categories');
  }

  CollectionReference<Map<String, dynamic>> get _userExpenseCollection {
    final uid = _auth.currentUser!.uid;
    return FirebaseFirestore.instance.collection('users').doc(uid).collection('expenses');
  }
  CollectionReference<Map<String, dynamic>> get _userIncomeCollection {
    final uid = _auth.currentUser!.uid;
    return FirebaseFirestore.instance.collection('users').doc(uid).collection('incomes');
  }

  @override
  Future<void> createCategory(Category category) async {
    try {
      await _userCategoryCollection
          .doc(category.categoryId)
          .set(category.toEntity().toDocument());
    } catch (e) {
      log(e.toString());
      rethrow;
    }
  }

  @override
  Future<List<Category>> getCategory() async {
    try {
      final snapshot = await _userCategoryCollection.get();
      return snapshot.docs
          .map((doc) => Category.fromEntity(CategoryEntity.fromDocument(doc.data())))
          .toList();
    } catch (e) {
      log(e.toString());
      rethrow;
    }
  }

  @override
  Future<void> createExpense(Expense expense) async {
    try {
      await _userExpenseCollection
          .doc(expense.expenseId)
          .set(expense.toEntity().toDocument());
    } catch (e) {
      log(e.toString());
      rethrow;
    }
  }
  @override
  Future<void> createIncome(Income income) async {
    try {
      await _userIncomeCollection
          .doc(income.incomeId)
          .set(income.toEntity().toDocument());
    } catch (e) {
      log(e.toString());
      rethrow;
    }
  }

  @override
  Future<List<Expense>> getExpenses() async {
    try {
      final snapshot = await _userExpenseCollection.get();
      return snapshot.docs
          .map((doc) => Expense.fromEntity(ExpenseEntity.fromDocument(doc.data())))
          .toList();
    } catch (e) {
      log(e.toString());
      rethrow;
    }
  }
  @override
  Future<List<Income>> getIncomes() async {
    try {
      final snapshot = await _userIncomeCollection.get();
      return snapshot.docs
          .map((doc) =>
          Income.fromEntity(IncomeEntity.fromDocument(doc.data())))
          .toList();
    } catch (e){
      log(e.toString());
      rethrow;

    }

  }

}

