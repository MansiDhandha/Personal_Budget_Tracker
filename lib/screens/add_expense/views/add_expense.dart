import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:expense_repository/expense_repository.dart';
import 'package:budget_tracker/screens/add_expense/blocs/create_expense_bloc/create_expense_bloc.dart';
import 'package:budget_tracker/screens/add_expense/blocs/create_income_bloc/create_income_bloc.dart';
import 'package:budget_tracker/screens/add_expense/blocs/get_categories_bloc/get_categories_bloc.dart';
import 'package:budget_tracker/screens/add_expense/views/category_creation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

class AddExpense extends StatefulWidget {
  const AddExpense({super.key});

  @override
  State<AddExpense> createState() => _AddExpenseState();
}

class _AddExpenseState extends State<AddExpense> {
  final TextEditingController expenseController = TextEditingController();
  final TextEditingController dateController = TextEditingController();
  final TextEditingController incomeController = TextEditingController();
  final TextEditingController incomeDateController = TextEditingController();

  int? initialBudget;
  int currentBudget = 0;

  final List<Category> predefinedCategories = [
    Category(categoryId: 'food', name: 'Food', icon: 'food', color: 0xFF4CAF50),
    Category(categoryId: 'shopping', name: 'Shopping', icon: 'shopping', color: 0xFF9C27B0),
    Category(categoryId: 'travel', name: 'Travel', icon: 'travel', color: 0xFF03A9F4),
    Category(categoryId: 'entertainment', name: 'Entertainment', icon: 'entertainment', color: 0xFFFF9800),
  ];

  final List<Category> customCategories = [];
  Category? selectedCategory;

  bool isLoading = false;
  bool isIncomeLoading = false;

  @override
  void initState() {
    super.initState();
    dateController.text = DateFormat('dd/MM/yyyy').format(DateTime.now());
    incomeDateController.text = DateFormat('dd/MM/yyyy').format(DateTime.now());

    expenseController.addListener(_handleExpenseChange);
    incomeController.addListener(_handleIncomeChange);

    _loadRemainingBudget();
  }

  @override
  void dispose() {
    expenseController.removeListener(_handleExpenseChange);
    incomeController.removeListener(_handleIncomeChange);
    super.dispose();
  }

  Future<void> _loadRemainingBudget() async {
    final int budget = await fetchRemainingBudgetFromDb();
    if (mounted) {
      setState(() {
        initialBudget = budget;
        currentBudget = budget;
      });
    }
  }

  Future<int> fetchRemainingBudgetFromDb() async {
    final userId = FirebaseAuth.instance.currentUser?.uid; // TODO: Replace with FirebaseAuth.instance.currentUser?.uid
    final doc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
    if (doc.exists) {
      final data = doc.data();
      return (data?['remaining_budget'] ?? 0).toInt();
    }
    return 0;
  }


  void _handleExpenseChange() {
    final enteredAmount = int.tryParse(expenseController.text) ?? 0;
    if (initialBudget != null) {
      if (enteredAmount > initialBudget!) {
        // Reset to max allowed
        expenseController.text = initialBudget!.toString();
        expenseController.selection = TextSelection.fromPosition(
          TextPosition(offset: expenseController.text.length),
        );
        currentBudget = 0;
      } else {
        currentBudget = initialBudget! - enteredAmount;
      }
      setState(() {});
    }
  }


  void _handleIncomeChange() {
    final enteredAmount = int.tryParse(incomeController.text) ?? 0;
    if (initialBudget != null) {
      setState(() {
        currentBudget = initialBudget! + enteredAmount;
      });
    }
  }

  Future<void> _updateRemainingBudgetInDb(int newBudget) async {
    final userId = 'userId'; // TODO: Replace with FirebaseAuth.instance.currentUser?.uid
    final docRef = FirebaseFirestore.instance.collection('users').doc(userId);
    await docRef.set({'remaining_budget': newBudget}, SetOptions(merge: true));
  }


  @override
  Widget build(BuildContext context) {
    if (initialBudget == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: Theme.of(context).colorScheme.background,
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.background,
          title: const Text('Add Transaction'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Expense'),
              Tab(text: 'Add Money'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            expenseTab(context),
            incomeTab(context),
          ],
        ),
      ),
    );
  }

  Widget expenseTab(BuildContext context) {
    return BlocBuilder<GetCategoriesBloc, GetCategoriesState>(
      builder: (context, state) {
        final dynamicCategories = state is GetCategoriesSuccess ? state.categories : [];
        final allCategories = [...predefinedCategories, ...customCategories, ...dynamicCategories];

        return BlocListener<CreateExpenseBloc, CreateExpenseState>(
          listener: (context, state) {
            if (state is CreateExpenseSuccess) {
              if (mounted) {
                setState(() {
                  isLoading = false;
                  expenseController.clear();
                  selectedCategory = null;
                  dateController.text = DateFormat('dd/MM/yyyy').format(DateTime.now());
                  initialBudget = currentBudget; // ✅ keep budget updated!
                });
                _updateRemainingBudgetInDb(currentBudget);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Expense added!')),
                );
                Navigator.pop(context);
              }
            } else if (state is CreateExpenseLoading) {
              setState(() => isLoading = true);
            } else if (state is CreateExpenseFailure) {
              setState(() => isLoading = false);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Something went wrong.')),
              );
            }
          },
          child: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  padding: EdgeInsets.only(
                    left: 16,
                    right: 16,
                    top: 16,
                    bottom: MediaQuery.of(context).viewInsets.bottom + 16,
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: constraints.maxHeight),
                    child: IntrinsicHeight(
                      child: Column(
                        children: [
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: expenseController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Colors.white,
                              prefixIcon: const Icon(
                                FontAwesomeIcons.indianRupeeSign,
                                size: 16,
                                color: Colors.grey,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(30),
                                borderSide: BorderSide.none,
                              ),
                              hintText: "Amount",
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Remaining Budget: ₹${currentBudget}',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: currentBudget < 50 ? Colors.red : Colors.black,
                            ),
                          ),
                          if (currentBudget < 50)
                            const Text(
                              '⚠️ You are low on budget!',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.red,
                                fontWeight: FontWeight.w500,
                              ),
                            ),

                          const SizedBox(height: 16),
                          SizedBox(
                            height: 80,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: allCategories.length + 1,
                              itemBuilder: (context, i) {
                                if (i < allCategories.length) {
                                  final cat = allCategories[i];
                                  final isSelected = selectedCategory?.categoryId == cat.categoryId;
                                  return categoryChip(cat, isSelected);
                                } else {
                                  return GestureDetector(
                                    onTap: () async {
                                      final newCategory = await getCategoryCreation(context);
                                      if (newCategory != null) {
                                        setState(() {
                                          customCategories.add(newCategory);
                                          selectedCategory = newCategory;
                                        });
                                      }
                                    },
                                    child: Container(
                                      width: 80,
                                      margin: const EdgeInsets.only(right: 12),
                                      decoration: BoxDecoration(
                                        color: Colors.grey[300],
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: Colors.black26),
                                      ),
                                      child: const Center(
                                        child: Icon(Icons.add, size: 32),
                                      ),
                                    ),
                                  );
                                }
                              },
                            ),
                          ),
                          const SizedBox(height: 32),
                          TextFormField(
                            controller: dateController,
                            readOnly: true,
                            onTap: () async {
                              DateTime? newDate = await showDatePicker(
                                context: context,
                                initialDate: DateTime.now(),
                                firstDate: DateTime(2000),
                                lastDate: DateTime.now().add(const Duration(days: 365)),
                              );
                              if (newDate != null) {
                                setState(() {
                                  dateController.text = DateFormat('dd/MM/yyyy').format(newDate);
                                });
                              }
                            },
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Colors.white,
                              prefixIcon: const Icon(
                                FontAwesomeIcons.clock,
                                size: 16,
                                color: Colors.grey,
                              ),
                              hintText: 'Date',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(30),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                          const SizedBox(height: 32),
                          SizedBox(
                            width: double.infinity,
                            height: kToolbarHeight,
                            child: isLoading
                                ? const Center(child: CircularProgressIndicator())
                                : TextButton(
                              onPressed: () {
                                final enteredAmount = int.tryParse(expenseController.text) ?? 0;
                                if (selectedCategory == null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Please select a category.')),
                                  );
                                  return;
                                }
                                if (enteredAmount <= 0) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Amount must be greater than zero.')),
                                  );
                                  return;
                                }
                                final expense = Expense(
                                  expenseId: const Uuid().v1(),
                                  amount: enteredAmount,
                                  date: DateTime.now(),
                                  category: selectedCategory!,

                                );
                                context.read<CreateExpenseBloc>().add(CreateExpense(expense));
                              },
                              style: TextButton.styleFrom(
                                backgroundColor: Colors.black,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                'Save',
                                style: TextStyle(fontSize: 22, color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget incomeTab(BuildContext context) {
    return BlocListener<CreateIncomeBloc, CreateIncomeState>(
      listener: (context, state) {
        if (state is CreateIncomeLoading) {
          setState(() => isIncomeLoading = true);
        } else {
          setState(() => isIncomeLoading = false);
        }
        if (state is CreateIncomeSuccess) {
          _updateRemainingBudgetInDb(currentBudget);
          if (mounted) {
            setState(() {
              incomeController.clear();
              incomeDateController.text = DateFormat('dd/MM/yyyy').format(DateTime.now());
              initialBudget = currentBudget; // ✅ keep budget updated!
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Income added!')),
            );
            Navigator.pop(context);
          }
        } else if (state is CreateIncomeFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to add income.')),
          );
        }
      },
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    children: [
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: incomeController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.white,
                          prefixIcon: const Icon(
                            FontAwesomeIcons.indianRupeeSign,
                            size: 16,
                            color: Colors.grey,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                            borderSide: BorderSide.none,
                          ),
                          hintText: "Amount",
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Remaining Budget: ₹${currentBudget}',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 32),
                      TextFormField(
                        controller: incomeDateController,
                        readOnly: true,
                        onTap: () async {
                          DateTime? newDate = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime(2000),
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                          );
                          if (newDate != null) {
                            setState(() {
                              incomeDateController.text = DateFormat('dd/MM/yyyy').format(newDate);
                            });
                          }
                        },
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.white,
                          prefixIcon: const Icon(
                            FontAwesomeIcons.clock,
                            size: 16,
                            color: Colors.grey,
                          ),
                          hintText: 'Date',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        height: kToolbarHeight,
                        child: isIncomeLoading
                            ? const Center(child: CircularProgressIndicator())
                            : TextButton(
                          onPressed: () {
                            final enteredAmount = int.tryParse(incomeController.text) ?? 0;
                            if (enteredAmount <= 0) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Amount must be greater than zero.')),
                              );
                              return;
                            }
                            final income = Income(
                              incomeId: const Uuid().v1(),
                              amount: enteredAmount,
                              date: DateTime.now(),
                            );
                            context.read<CreateIncomeBloc>().add(CreateIncome(income));
                          },
                          style: TextButton.styleFrom(
                            backgroundColor: Colors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Save',
                            style: TextStyle(fontSize: 22, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget categoryChip(Category cat, bool isSelected) {
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedCategory = cat;
        });
      },
      child: Container(
        width: 80,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: Color(cat.color),
          borderRadius: BorderRadius.circular(12),
          border: isSelected ? Border.all(color: Colors.black, width: 2) : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/${cat.icon}.png', scale: 2, color: Colors.white),
            const SizedBox(height: 4),
            Text(
              cat.name,
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
