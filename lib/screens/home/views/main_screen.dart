import 'dart:math';
import 'package:budget_tracker/screens/home/views/view_all.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:expense_repository/expense_repository.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';

class MainScreen extends StatefulWidget {
  final List<Expense> expenses;
  final List<Income> incomes;

  const MainScreen({
    super.key,
    required this.expenses,
    required this.incomes,
  });

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  double? _lastRemaining;

  String _sortOption = 'Newest to Oldest';

  Future<Map<String, dynamic>> getUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (doc.exists) {
        final data = doc.data() ?? {};
        return {
          'name': data['name'] ?? 'User',
          'monthly_budget': (data['monthly_budget'] ?? 0).toDouble(),
          'monthly_income': (data['monthly_income'] ?? 0).toDouble(),
        };
      }
    }
    return {
      'name': 'User',
      'monthly_budget': 0.0,
      'monthly_income': 0.0,
    };
  }

  Stream<double> watchTotalExpenses() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      return FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('expenses')
          .snapshots()
          .map((snapshot) {
        double total = 0.0;
        for (var doc in snapshot.docs) {
          total += (doc['amount'] ?? 0).toDouble();
        }
        return total;
      });
    }
    return const Stream.empty();
  }

  Stream<double> watchTotalIncomes() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      return FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('incomes')
          .snapshots()
          .map((snapshot) {
        double total = 0.0;
        for (var doc in snapshot.docs) {
          total += (doc['amount'] ?? 0).toDouble();
        }
        return total;
      });
    }
    return const Stream.empty();
  }

  String getFriendlyDateLabel(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final txDate = DateTime(date.year, date.month, date.day);

    if (txDate == today) {
      return 'Today • ${DateFormat('HH:mm').format(date)}';
    } else if (txDate == yesterday) {
      return 'Yesterday • ${DateFormat('HH:mm').format(date)}';
    } else {
      return DateFormat('dd/MM/yyyy • HH:mm').format(date);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: FutureBuilder<Map<String, dynamic>>(
        future: getUserData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final name = snapshot.data?['name'] ?? 'User';
          final monthlyBudget = snapshot.data?['monthly_budget'] ?? 0.0;

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 25.0, vertical: 10),
            child: Column(
              children: [
                // Existing header row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.yellow[700],
                              ),
                            ),
                            Icon(
                              CupertinoIcons.person_fill,
                              color: Colors.yellow[800],
                            ),
                          ],
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Welcome!",
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).colorScheme.outline,
                              ),
                            ),
                            Text(
                              name,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.onBackground,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.logout),
                      onPressed: () async {
                        final shouldLogout = await showDialog<bool>(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: const Text('Confirm Logout'),
                              content: const Text('Are you sure you want to logout?'),
                              actions: [
                                TextButton(
                                  child: const Text('Cancel'),
                                  onPressed: () {
                                    Navigator.of(context).pop(false);
                                  },
                                ),
                                TextButton(
                                  child: const Text('Logout'),
                                  onPressed: () {
                                    Navigator.of(context).pop(true);
                                  },
                                ),
                              ],
                            );
                          },
                        );

                        if (shouldLogout == true) {
                          await FirebaseAuth.instance.signOut();
                          if (context.mounted) {
                            Navigator.pushReplacementNamed(context, '/login');
                          }
                        }
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                Container(
                  width: MediaQuery.of(context).size.width,
                  height: MediaQuery.of(context).size.width / 2,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Theme.of(context).colorScheme.primary,
                        Theme.of(context).colorScheme.secondary,
                        Theme.of(context).colorScheme.tertiary,
                      ],
                      transform: const GradientRotation(pi / 4),
                    ),
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [
                      BoxShadow(
                        blurRadius: 4,
                        color: Colors.grey.shade300,
                        offset: const Offset(5, 5),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              'Monthly Budget',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              '₹ ${monthlyBudget.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 40,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 12,
                                horizontal: 20,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        width: 25,
                                        height: 25,
                                        decoration: const BoxDecoration(
                                          color: Colors.white30,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Center(
                                          child: Icon(
                                            CupertinoIcons.arrow_up,
                                            size: 12,
                                            color: Colors.greenAccent,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Added Money',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.white,
                                              fontWeight: FontWeight.w400,
                                            ),
                                          ),
                                          StreamBuilder<double>(
                                            stream: watchTotalIncomes(),
                                            builder: (context, snapshot) {
                                              final total = snapshot.data ?? 0.0;
                                              return Text(
                                                '₹ ${total.toStringAsFixed(2)}',
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              );
                                            },
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      Container(
                                        width: 25,
                                        height: 25,
                                        decoration: const BoxDecoration(
                                          color: Colors.white30,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Center(
                                          child: Icon(
                                            CupertinoIcons.arrow_down,
                                            size: 12,
                                            color: Colors.red,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Expenses',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.white,
                                              fontWeight: FontWeight.w400,
                                            ),
                                          ),
                                          StreamBuilder<double>(
                                            stream: watchTotalExpenses(),
                                            builder: (context, snapshot) {
                                              final total = snapshot.data ?? 0.0;
                                              return Text(
                                                '₹ ${total.toStringAsFixed(2)}',
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              );
                                            },
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: IconButton(
                          icon: const Icon(Icons.edit, color: Colors.white),
                          onPressed: () async {
                            final controller = TextEditingController();
                            final newBudget = await showDialog<double>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Edit Monthly Budget'),
                                content: TextField(
                                  controller: controller,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    labelText: 'New Budget Amount',
                                  ),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('Cancel'),
                                  ),
                                  ElevatedButton(
                                    onPressed: () {
                                      final input = controller.text.trim();
                                      final amount = double.tryParse(input) ?? 0.0;
                                      Navigator.pop(context, amount);
                                    },
                                    child: const Text('Save'),
                                  ),
                                ],
                              ),
                            );

                            if (newBudget != null && newBudget > 0) {
                              final user = FirebaseAuth.instance.currentUser;
                              if (user != null) {
                                await FirebaseFirestore.instance
                                    .collection('users')
                                    .doc(user.uid)
                                    .update({'monthly_budget': newBudget});
                              }
                              if (mounted) {
                                setState(() {});
                              }
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Row for Transactions and Sort
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Transactions',
                      style: TextStyle(
                        fontSize: 16,
                        color: Theme.of(context).colorScheme.onBackground,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    DropdownButton<String>(
                      value: _sortOption,
                      items: [
                        'Newest to Oldest',
                        'Oldest to Newest',
                        'Highest to Lowest',
                        'Lowest to Highest'
                      ].map((value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value, style: const TextStyle(fontSize: 12)),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _sortOption = value!;
                        });
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                Expanded(
                  child: Builder(
                    builder: (context) {
                      final allTransactions = [
                        ...widget.expenses.map((e) => {'type': 'expense', 'item': e}),
                        ...widget.incomes.map((i) => {'type': 'income', 'item': i}),
                      ];

                      // Apply sort
                      if (_sortOption == 'Newest to Oldest') {
                        allTransactions.sort((a, b) {
                          final aDate = a['item'] is Expense ? (a['item'] as Expense).date : (a['item'] as Income).date;
                          final bDate = b['item'] is Expense ? (b['item'] as Expense).date : (b['item'] as Income).date;
                          return bDate.compareTo(aDate);
                        });
                      } else if (_sortOption == 'Oldest to Newest') {
                        allTransactions.sort((a, b) {
                          final aDate = a['item'] is Expense ? (a['item'] as Expense).date : (a['item'] as Income).date;
                          final bDate = b['item'] is Expense ? (b['item'] as Expense).date : (b['item'] as Income).date;
                          return aDate.compareTo(bDate);
                        });
                      } else if (_sortOption == 'Highest to Lowest') {
                        allTransactions.sort((a, b) {
                          final aAmount = a['item'] is Expense ? (a['item'] as Expense).amount : (a['item'] as Income).amount;
                          final bAmount = b['item'] is Expense ? (b['item'] as Expense).amount : (b['item'] as Income).amount;
                          return bAmount.compareTo(aAmount);
                        });
                      } else if (_sortOption == 'Lowest to Highest') {
                        allTransactions.sort((a, b) {
                          final aAmount = a['item'] is Expense ? (a['item'] as Expense).amount : (a['item'] as Income).amount;
                          final bAmount = b['item'] is Expense ? (b['item'] as Expense).amount : (b['item'] as Income).amount;
                          return aAmount.compareTo(bAmount);
                        });
                      }

                      return ListView.builder(
                        itemCount: allTransactions.length,
                        itemBuilder: (context, index) {
                          final tx = allTransactions[index];
                          if (tx['type'] == 'expense') {
                            final e = tx['item'] as Expense;
                            return transactionTile(
                              context,
                              title: e.category.name,
                              amount: e.amount,
                              date: e.date,
                              isExpense: true,
                              icon: e.category.icon,
                              color: e.category.color,
                            );
                          } else {
                            final i = tx['item'] as Income;
                            return transactionTile(
                              context,
                              title: 'Add Money',
                              amount: i.amount,
                              date: i.date,
                              isExpense: false,
                            );
                          }
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget transactionTile(
      BuildContext context, {
        required String title,
        required int amount,
        required DateTime date,
        required bool isExpense,
        String? icon,
        int? color,
      }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  if (isExpense)
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: Color(color!),
                            shape: BoxShape.circle,
                          ),
                        ),
                        Image.asset(
                          'assets/$icon.png',
                          scale: 2,
                          color: Colors.white,
                        ),
                      ],
                    )
                  else
                    const Icon(
                      CupertinoIcons.arrow_up_circle_fill,
                      color: Colors.green,
                      size: 40,
                    ),
                  const SizedBox(width: 12),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).colorScheme.onBackground,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  RichText(
                    text: TextSpan(
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).colorScheme.onBackground,
                        fontWeight: FontWeight.w400,
                      ),
                      children: [
                        WidgetSpan(
                          child: Icon(
                            FontAwesomeIcons.indianRupeeSign,
                            size: 12,
                            color: Theme.of(context).colorScheme.onBackground,
                          ),
                          alignment: PlaceholderAlignment.middle,
                        ),
                        TextSpan(text: "$amount.00"),
                      ],
                    ),
                  ),
                  Text(
                    getFriendlyDateLabel(date),
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).colorScheme.outline,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
