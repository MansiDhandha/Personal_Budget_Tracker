part of 'create_income_bloc.dart';

abstract class CreateIncomeState extends Equatable {
  const CreateIncomeState();

  @override
  List<Object> get props => [];
}

class CreateIncomeInitial extends CreateIncomeState {}

class CreateIncomeLoading extends CreateIncomeState {}

class CreateIncomeSuccess extends CreateIncomeState {}

class CreateIncomeFailure extends CreateIncomeState {}
