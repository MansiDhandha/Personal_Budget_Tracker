import 'package:expense_repository/expense_repository.dart';

import '../entities/income_entity.dart';

class Income {
  final String incomeId;
  final int amount;
  final DateTime date;

  Income({
    required this.incomeId,
    required this.amount,
    required this.date,
  });

  static final empty = Income(
    incomeId: '',
    date: DateTime.now(),
    amount: 0,
  );

  IncomeEntity toEntity() {
    return IncomeEntity(
      incomeId: incomeId,
      date: date,
      amount: amount,
    );
  }
    static Income fromEntity(IncomeEntity entity) {
      return Income(
        incomeId: entity.incomeId,
        date: entity.date,
        amount: entity.amount,
      );
    }
}
