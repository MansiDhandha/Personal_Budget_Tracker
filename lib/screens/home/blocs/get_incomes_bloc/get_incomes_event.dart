part of 'get_incomes_bloc.dart';

abstract class GetIncomesEvent extends Equatable {
  const GetIncomesEvent();

  @override
  List<Object> get props => [];
}

class GetIncomes extends GetIncomesEvent {}
