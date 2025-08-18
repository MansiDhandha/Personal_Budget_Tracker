import 'dart:math';

import 'package:expense_repository/expense_repository.dart';
import 'package:budget_tracker/screens/add_expense/blocs/create_categorybloc/create_category_bloc.dart';
import 'package:budget_tracker/screens/add_expense/blocs/get_categories_bloc/get_categories_bloc.dart';
import 'package:budget_tracker/screens/add_expense/views/add_expense.dart';
import 'package:budget_tracker/screens/home/blocs/get_expenses_bloc/get_expenses_bloc.dart';
import 'package:budget_tracker/screens/home/views/main_screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:budget_tracker/screens/add_expense/blocs/create_expense_bloc/create_expense_bloc.dart';
import 'package:budget_tracker/screens/add_expense/blocs/create_income_bloc/create_income_bloc.dart';
import 'package:budget_tracker/screens/stats/stat_screen.dart';
import '../blocs/get_incomes_bloc/get_incomes_bloc.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int index = 0;
  late Color selectedItem = Colors.blue;
  Color unselectedItem = Colors.grey;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) =>
          GetExpensesBloc(FirebaseExpenseRepo())..add(GetExpenses()),
        ),
        BlocProvider(
          create: (_) =>
          GetIncomesBloc(FirebaseExpenseRepo())..add(GetIncomes()),
        ),
      ],
      child: BlocBuilder<GetExpensesBloc, GetExpensesState>(
        builder: (context, expenseState) {
          return BlocBuilder<GetIncomesBloc, GetIncomesState>(
            builder: (context, incomeState) {
              if (expenseState is GetExpensesSuccess &&
                  incomeState is GetIncomesSuccess) {
                int totalIncome = incomeState.incomes.fold(
                    0, (sum, income) => sum + income.amount);
                int totalExpenses = expenseState.expenses.fold(
                    0, (sum, expense) => sum + expense.amount);
                int remainingBudget =  totalIncome - totalExpenses;

                return Scaffold(
                  bottomNavigationBar: ClipRRect(
                    borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(30)),
                    child: BottomNavigationBar(
                      onTap: (value) {
                        setState(() {
                          index = value;
                        });
                      },
                      showSelectedLabels: false,
                      showUnselectedLabels: false,
                      elevation: 3,
                      items: [
                        BottomNavigationBarItem(
                          icon: Icon(
                            CupertinoIcons.home,
                            color: index == 0 ? selectedItem : unselectedItem,
                          ),
                          label: 'Home',
                        ),
                        BottomNavigationBarItem(
                          icon: Icon(
                            CupertinoIcons.graph_square_fill,
                            color: index == 1 ? selectedItem : unselectedItem,
                          ),
                          label: 'Stats',
                        ),
                      ],
                    ),
                  ),
                  floatingActionButtonLocation:
                  FloatingActionButtonLocation.centerDocked,
                  floatingActionButton: FloatingActionButton(
                    onPressed: () async {
                      await showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        shape: const RoundedRectangleBorder(
                          borderRadius:
                          BorderRadius.vertical(top: Radius.circular(25)),
                        ),
                        builder: (BuildContext context) {
                          return DraggableScrollableSheet(
                            expand: false,
                            initialChildSize: 0.7,
                            minChildSize: 0.5,
                            maxChildSize: 0.9,
                            builder: (_, controller) {
                              return ClipRRect(
                                borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(25)),
                                child: Container(
                                  color: Theme.of(context).colorScheme.background,
                                  padding: EdgeInsets.only(
                                    left: 16,
                                    right: 16,
                                    bottom: MediaQuery.of(context).viewInsets.bottom,
                                  ),
                                  child: MultiBlocProvider(
                                    providers: [
                                      BlocProvider(
                                        create: (context) => CreateCategoryBloc(
                                            FirebaseExpenseRepo()),
                                      ),
                                      BlocProvider(
                                        create: (context) => GetCategoriesBloc(
                                            FirebaseExpenseRepo())
                                          ..add(GetCategories()),
                                      ),
                                      BlocProvider(
                                        create: (context) => CreateExpenseBloc(
                                            FirebaseExpenseRepo()),
                                      ),
                                      BlocProvider(
                                        create: (context) => CreateIncomeBloc(
                                            FirebaseExpenseRepo()),
                                      ),
                                    ],

                                    child: AddExpense(),

                                  ),
                                ),
                              );
                            },
                          );
                        },
                      );
                      print(remainingBudget);
                      // Refresh state after adding expense/income
                      context.read<GetExpensesBloc>().add(GetExpenses());
                      context.read<GetIncomesBloc>().add(GetIncomes());
                    },
                    shape: const CircleBorder(),
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            Theme.of(context).colorScheme.tertiary,
                            Theme.of(context).colorScheme.secondary,
                            Theme.of(context).colorScheme.primary,
                          ],
                          transform: const GradientRotation(pi / 4),
                        ),
                      ),
                      child: const Icon(CupertinoIcons.add),
                    ),
                  ),
                  body: index == 0
                      ? MainScreen(
                    expenses: expenseState.expenses,
                    incomes: incomeState.incomes,
                  )
                      : const StatScreen(),
                );
              } else {
                return const Scaffold(
                  body: Center(
                    child: CircularProgressIndicator(),
                  ),
                );
              }
            },
          );
        },
      ),
    );
  }
}
