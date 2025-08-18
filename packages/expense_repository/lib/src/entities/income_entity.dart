import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:expense_repository/src/entities/entities.dart';

import '../models/models.dart';

class IncomeEntity {
  String incomeId;
  DateTime date;
  int amount;

  IncomeEntity({
    required this.incomeId,
    required this.date,
    required this.amount,
  });

  Map<String, Object?> toDocument() {
    return {
      'expenseId': incomeId,
      'date': date,
      'amount': amount,
    };
  }

  static IncomeEntity fromDocument(Map<String, dynamic> doc) {
    return IncomeEntity(
      incomeId: doc['expenseId'],
      date: (doc['date'] as Timestamp).toDate(),
      amount: doc['amount'],
    );
  }
}