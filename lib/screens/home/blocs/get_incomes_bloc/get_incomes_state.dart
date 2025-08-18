part of 'get_incomes_bloc.dart';

abstract class GetIncomesState extends Equatable {
  const GetIncomesState();

  @override
  List<Object> get props => [];
}

class GetIncomesInitial extends GetIncomesState {}

class GetIncomesLoading extends GetIncomesState {}

class GetIncomesSuccess extends GetIncomesState {
  final List<Income> incomes;

  const GetIncomesSuccess(this.incomes);

  @override
  List<Object> get props => [incomes];
}

class GetIncomesFailure extends GetIncomesState {}
