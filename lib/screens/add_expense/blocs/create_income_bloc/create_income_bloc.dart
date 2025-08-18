import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:expense_repository/expense_repository.dart';

part 'create_income_event.dart';
part 'create_income_state.dart';

class CreateIncomeBloc extends Bloc<CreateIncomeEvent, CreateIncomeState> {
  final ExpenseRepository expenseRepository;

  CreateIncomeBloc(this.expenseRepository) : super(CreateIncomeInitial()) {
    on<CreateIncome>(_onCreateIncome);
  }

  Future<void> _onCreateIncome(CreateIncome event, Emitter<CreateIncomeState> emit) async {
    emit(CreateIncomeLoading());
    try {
      await expenseRepository.createIncome(event.income);
      emit(CreateIncomeSuccess());
    } catch (e) {
      emit(CreateIncomeFailure());
    }
  }
}
