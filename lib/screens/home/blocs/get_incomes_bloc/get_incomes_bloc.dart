import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:expense_repository/expense_repository.dart';

part 'get_incomes_event.dart';
part 'get_incomes_state.dart';

class GetIncomesBloc extends Bloc<GetIncomesEvent, GetIncomesState> {
  final ExpenseRepository expenseRepository;

  GetIncomesBloc(this.expenseRepository) : super(GetIncomesInitial()) {
    on<GetIncomes>(_onGetIncomes);
  }

  Future<void> _onGetIncomes(
      GetIncomes event, Emitter<GetIncomesState> emit) async {
    emit(GetIncomesLoading());
    try {
      final incomes = await expenseRepository.getIncomes();
      emit(GetIncomesSuccess(incomes));
    } catch (e) {
      emit(GetIncomesFailure());
    }
  }
}
