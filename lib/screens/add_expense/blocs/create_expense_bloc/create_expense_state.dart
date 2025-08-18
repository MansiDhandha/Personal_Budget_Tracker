part of 'create_expense_bloc.dart';

abstract class CreateExpenseState extends Equatable {
  const CreateExpenseState();

  @override
  List<Object> get props => [];
}

class CreateExpenseInitial extends CreateExpenseState {}
class CreateExpenseLoading extends CreateExpenseState {}
class CreateExpenseSuccess extends CreateExpenseState {}
class CreateExpenseFailure extends CreateExpenseState {}
class CreateExpenseOverBudget extends CreateExpenseState {}
