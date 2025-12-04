import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:expense_repository/src/entities/entities.dart';
import '../models/models.dart';

class ExpenseEntity {
  String expenseId;
  Category category;
  DateTime date;
  int amount;
  String location;   // ✅ added back

  ExpenseEntity({
    required this.expenseId,
    required this.category,
    required this.date,
    required this.amount,
    required this.location,   // ✅
  });

  Map<String, Object?> toDocument() {
    return {
      'expenseId': expenseId,
      'category': category.toEntity().toDocument(),
      'date': date,   // Firestore can store DateTime directly
      'amount': amount,
      'location': location,   // ✅
    };
  }

  static ExpenseEntity fromDocument(Map<String, dynamic> doc) {
    return ExpenseEntity(
      expenseId: doc['expenseId'] as String,
      category: Category.fromEntity(
        CategoryEntity.fromDocument(doc['category'] as Map<String, dynamic>),
      ),
      date: (doc['date'] as Timestamp).toDate(),
      amount: doc['amount'] as int,
      location: doc['location'] as String? ?? '',   // ✅ fallback
    );
  }
}
