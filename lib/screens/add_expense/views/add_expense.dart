// add_expense_screen.dart
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
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'pick_location_screen.dart';

String _selectedCurrency = "INR"; // default
double _exchangeRate = 1.0;

class AddExpense extends StatefulWidget {
  final String selectedCurrency;

  const AddExpense({
    super.key,
    required this.selectedCurrency,
  });

  @override
  State<AddExpense> createState() => _AddExpenseState();
}

class _AddExpenseState extends State<AddExpense> {
  final TextEditingController expenseController = TextEditingController();
  final TextEditingController dateController = TextEditingController();
  final TextEditingController incomeController = TextEditingController();
  final TextEditingController incomeDateController = TextEditingController();
  final TextEditingController locationController = TextEditingController();

  @override
  void dispose() {
    expenseController.removeListener(_updateRemainingBudgetPreview);
    incomeController.removeListener(_updateRemainingBudgetPreview);
    expenseController.dispose();
    incomeController.dispose();
    dateController.dispose();
    incomeDateController.dispose();
    locationController.dispose();
    super.dispose();
  }

  int _convertToInr(int amountInSelectedCurrency) {
    // Converts from currently selected currency to INR (rounded int)
    if (_exchangeRate == 0) return amountInSelectedCurrency; // fallback
    return (amountInSelectedCurrency / _exchangeRate).round();
  }

  int _convertFromInrToSelected(int amountInInr) {
    // Converts from INR to selected currency (rounded int)
    return (amountInInr * _exchangeRate).round();
  }

  static const Map<String, String> currencySymbols = {
    "INR": "₹",
    "USD": "\$",
    "EUR": "€",
    "GBP": "£",
    "JPY": "¥",
    "AUD": "A\$",
    "CAD": "C\$",
    "CHF": "CHF",
    "CNY": "¥",
  };

  String get symbol =>
      _AddExpenseState.currencySymbols[_selectedCurrency] ?? _selectedCurrency;

  int? initialBudget; // stored in INR
  int currentBudget = 0; // in INR

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

    // load preferences (currency, exchange rate, remaining budget)
    _loadUserPreferences();

    // listen for input changes to preview remaining budget
    expenseController.addListener(_updateRemainingBudgetPreview);
    incomeController.addListener(_updateRemainingBudgetPreview);
  }

  Future<void> _loadUserPreferences() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists) {
        final data = doc.data() ?? {};
        setState(() {
          _selectedCurrency = data['selected_currency'] ?? widget.selectedCurrency ?? "INR";
          _exchangeRate = (data['currency_rate'] ?? 1.0).toDouble();
          initialBudget = (data['remaining_budget'] ?? 0).toInt();
          currentBudget = initialBudget ?? 0;
        });
      } else {
        // Ensure defaults if user doc missing
        setState(() {
          _selectedCurrency = widget.selectedCurrency;
          _exchangeRate = 1.0;
          initialBudget = 0;
          currentBudget = 0;
        });
      }
    } else {
      // no user signed in
      setState(() {
        _selectedCurrency = widget.selectedCurrency;
        _exchangeRate = 1.0;
        initialBudget = 0;
        currentBudget = 0;
      });
    }
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location services are disabled.')),
      );
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location permissions are denied')),
        );
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location permissions are permanently denied.')),
      );
      return;
    }

    Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);

    List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);

    if (placemarks.isNotEmpty) {
      final place = placemarks.first;
      setState(() {
        locationController.text = "${place.locality}, ${place.administrativeArea}, ${place.country}";
      });
    }
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
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return 0;
    final doc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
    if (doc.exists) {
      final data = doc.data();
      return (data?['remaining_budget'] ?? 0).toInt();
    }
    return 0;
  }

  void _updateRemainingBudgetPreview() {
    // Called when user types in amount fields to preview remaining budget
    int expense = int.tryParse(expenseController.text) ?? 0;
    int income = int.tryParse(incomeController.text) ?? 0;

    final expenseInInr = _convertToInr(expense);
    final incomeInInr = _convertToInr(income);

    setState(() {
      currentBudget = (initialBudget ?? 0) - expenseInInr + incomeInInr;
    });
  }

  Future<void> _updateRemainingBudgetInDb(int newBudgetInInr) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;
    final docRef = FirebaseFirestore.instance.collection('users').doc(userId);
    await docRef.set({'remaining_budget': newBudgetInInr}, SetOptions(merge: true));
  }

  @override
  Widget build(BuildContext context) {
    if (initialBudget == null) {
      // still loading
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
        final firestoreCategories = state is GetCategoriesSuccess ? state.categories : <Category>[];
        final allCategories = [...predefinedCategories, ...customCategories, ...firestoreCategories];

        return BlocListener<CreateExpenseBloc, CreateExpenseState>(
          listener: (context, state) async {
            if (state is CreateExpenseSuccess) {
              if (mounted) {
                setState(() {
                  isLoading = false;
                  expenseController.clear();
                  selectedCategory = null;
                  dateController.text = DateFormat('dd/MM/yyyy').format(DateTime.now());
                  // initialBudget already updated before dispatching event
                });
                // Persist remaining budget already done in save flow, but ensure sync:
                await _loadRemainingBudget();
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
                              prefixIcon: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Text(
                                  symbol,
                                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                                ),
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
                            'Remaining Budget: $symbol${_convertFromInrToSelected(currentBudget)}',
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
                                      child: const Center(child: Icon(Icons.add, size: 32)),
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

                          const SizedBox(height: 16),
                          TextFormField(
                            controller: locationController,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Colors.white,
                              prefixIcon: const Icon(Icons.location_on, color: Colors.grey),
                              suffixIcon: IconButton(
                                icon: const Icon(Icons.my_location, color: Colors.blue),
                                onPressed: () async {
                                  // Use current location as initial camera position
                                  Position currentPosition = await Geolocator.getCurrentPosition(
                                      desiredAccuracy: LocationAccuracy.high);

                                  LatLng? selectedLatLng = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => PickLocationScreen(
                                        initialLocation: LatLng(currentPosition.latitude, currentPosition.longitude),
                                      ),
                                    ),
                                  );

                                  if (selectedLatLng != null) {
                                    List<Placemark> placemarks = await placemarkFromCoordinates(
                                        selectedLatLng.latitude, selectedLatLng.longitude);

                                    if (placemarks.isNotEmpty) {
                                      final place = placemarks.first;
                                      setState(() {
                                        locationController.text =
                                        "${place.locality}, ${place.administrativeArea}, ${place.country}";
                                      });
                                    }
                                  }
                                },
                              ),
                              hintText: 'Enter location',
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
                              onPressed: () async {
                                // Save expense flow with clamp logic
                                final enteredAmountSelectedCurrency = int.tryParse(expenseController.text) ?? 0;

                                if (selectedCategory == null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Please select a category.')),
                                  );
                                  return;
                                }
                                if (enteredAmountSelectedCurrency <= 0) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Amount must be greater than zero.')),
                                  );
                                  return;
                                }

                                // Convert entered amount (selected currency) -> INR for comparison & storage
                                int amountInInr = _convertToInr(enteredAmountSelectedCurrency);

                                // If remaining budget is less than entered amount, clamp:
                                final int remaining = currentBudget; // in INR
                                if (remaining <= 0) {
                                  // No budget left: do not allow expense > 0 (you can also allow but we'll set to 0)
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('No remaining budget to deduct.')),
                                  );
                                  return;
                                }

                                if (amountInInr > remaining) {
                                  // Auto-reduce amount to remaining budget (as user chose option A)
                                  amountInInr = remaining;

                                  // Update the expense textfield to show reduced amount in selected currency
                                  final int reducedAmountInSelectedCurrency = _convertFromInrToSelected(amountInInr);
                                  // set controller text (this triggers preview update)
                                  expenseController.text = reducedAmountInSelectedCurrency.toString();
                                  // Update currentBudget and initialBudget to zero (will be persisted below)
                                  setState(() {
                                    currentBudget = 0;
                                    initialBudget = 0;
                                  });
                                } else {
                                  // Normal case: subtract
                                  setState(() {
                                    currentBudget = (initialBudget ?? 0) - amountInInr;
                                    initialBudget = currentBudget;
                                  });
                                }

                                // Build Expense object (amount stored in INR)
                                final expense = Expense(
                                  expenseId: const Uuid().v1(),
                                  amount: amountInInr,
                                  date: DateTime.now(),
                                  category: selectedCategory!,
                                  location: locationController.text,
                                );

                                try {
                                  // Persist remaining budget to Firestore BEFORE dispatching event
                                  await _updateRemainingBudgetInDb(currentBudget);

                                  // Dispatch create expense event to your Bloc (amount already adjusted)
                                  context.read<CreateExpenseBloc>().add(CreateExpense(expense));
                                } catch (e) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Failed to save expense: $e')),
                                  );
                                }
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
                          )
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
          // After income saved, update remaining budget in DB (we did the update earlier below too)
          if (mounted) {
            setState(() {
              incomeController.clear();
              incomeDateController.text = DateFormat('dd/MM/yyyy').format(DateTime.now());
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
                          prefixIcon: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Text(
                              symbol,
                              style: const TextStyle(fontSize: 16, color: Colors.grey),
                            ),
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
                        'Remaining Budget: $symbol${_convertFromInrToSelected(currentBudget)}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: currentBudget < 50 ? Colors.red : Colors.black,
                        ),
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
                          onPressed: () async {
                            final enteredAmount = int.tryParse(incomeController.text) ?? 0;
                            if (enteredAmount <= 0) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Amount must be greater than zero.')),
                              );
                              return;
                            }

                            final amountInInr = _convertToInr(enteredAmount);

                            // Update remaining budget (INR)
                            setState(() {
                              currentBudget = (initialBudget ?? 0) + amountInInr;
                              initialBudget = currentBudget;
                            });

                            try {
                              // Persist remaining budget to Firestore
                              await _updateRemainingBudgetInDb(currentBudget);

                              // Create Income entity and dispatch
                              final income = Income(
                                incomeId: const Uuid().v1(),
                                amount: amountInInr,
                                date: DateTime.now(),
                              );
                              context.read<CreateIncomeBloc>().add(CreateIncome(income));
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Failed to add income: $e')),
                              );
                            }
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
      onTap: () => setState(() => selectedCategory = cat),
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
            cat.icon.startsWith('http')
                ? Image.network(cat.icon, height: 32, width: 32, fit: BoxFit.cover)
                : Image.asset('assets/${cat.icon}.png', scale: 2, color: Colors.white),
            const SizedBox(height: 4),
            Text(cat.name, style: const TextStyle(color: Colors.white, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
