import 'dart:convert';
import 'dart:math';
import 'package:budget_tracker/screens/home/views/view_all.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:expense_repository/expense_repository.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

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

  final List<String> _currencies = ['INR', 'USD', 'EUR', 'GBP', 'JPY', 'AUD', 'CAD'];
  String _selectedCurrency = 'INR';

  Map<String, double> _conversionRates = {
    'INR': 1.0,
    'USD': 0.012,
    'EUR': 0.011,
    'GBP': 0.010,
    'JPY': 1.80,
    'AUD': 0.018,
    'CAD': 0.016,
  };

  /// Load saved currency on app start
  Future<void> _loadCurrency() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedCurrency = prefs.getString('selected_currency') ?? 'INR';
    });
  }

  /// Save currency when user changes it
  Future<void> _saveCurrency(String currency) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_currency', currency);
  }

  // 🔄 Fetch live conversion rates
  Future<void> fetchLiveRates() async {
    final baseCurrency = 'INR'; // Keep INR as base internally
    final url = Uri.parse('https://api.exchangerate.host/latest?base=$baseCurrency');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _conversionRates['INR'] = 1.0;
          _conversionRates['USD'] = data['rates']['USD'] ?? _conversionRates['USD']!;
          _conversionRates['EUR'] = data['rates']['EUR'] ?? _conversionRates['EUR']!;
          _conversionRates['GBP'] = data['rates']['GBP'] ?? _conversionRates['GBP']!;
          _conversionRates['JPY'] = data['rates']['JPY'] ?? _conversionRates['JPY']!;
          _conversionRates['AUD'] = data['rates']['AUD'] ?? _conversionRates['AUD']!;
          _conversionRates['CAD'] = data['rates']['CAD'] ?? _conversionRates['CAD']!;
        });
      } else {
        debugPrint('Failed to fetch exchange rates');
      }
    } catch (e) {
      debugPrint('Error fetching exchange rates: $e');
    }
  }

  double _convert(double amount) {
    return amount * (_conversionRates[_selectedCurrency] ?? 1.0);
  }

  Future<Map<String, dynamic>> getUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists) {
        final data = doc.data() ?? {};
        return {
          'name': data['name'] ?? 'User',
          'monthly_budget': (data['monthly_budget'] ?? 0).toDouble()
        };
      }
    }
    return {'name': 'User', 'monthly_budget': 0.0};
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
  void initState() {
    super.initState();
    _loadCurrency(); // Load saved currency
    fetchLiveRates(); // 📡 Get latest currency conversion rates
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
            padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 10),
            child: Column(
              children: [
                // 🔐 Profile + Logout
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 25,
                          backgroundColor: Colors.yellow[700],
                          child: Icon(CupertinoIcons.person_fill, color: Colors.yellow[800]),
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Welcome!", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.outline)),
                            Text(name, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onBackground)),
                          ],
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.logout),
                      onPressed: () async {
                        await FirebaseAuth.instance.signOut();
                        if (context.mounted) {
                          Navigator.pushReplacementNamed(context, '/login');
                        }
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    const Text('Currency: ', style: TextStyle(fontSize: 14)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Colors.black, width: 0.5),
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedCurrency,
                          icon: const Icon(Icons.arrow_drop_down, color: Colors.black),
                          style: const TextStyle(fontSize: 12, color: Colors.black),
                          dropdownColor: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          isDense: true,
                          items: _currencies.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                          onChanged: (value) async {
                            if (value != null) {
                              setState(() => _selectedCurrency = value);
                              await _saveCurrency(value);
                              await fetchLiveRates();
                            }
                          },
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                // 💳 Budget Card
                Container(
                  width: double.infinity,
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
                    boxShadow: [BoxShadow(blurRadius: 4, color: Colors.grey.shade300, offset: const Offset(5, 5))],
                  ),
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('Monthly Budget', style: TextStyle(fontSize: 16, color: Colors.white)),
                            const SizedBox(height: 12),
                            Text(
                              ' ${_convert(monthlyBudget).toStringAsFixed(2)} $_selectedCurrency',
                              style: const TextStyle(fontSize: 40, color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  StreamBuilder<double>(
                                    stream: watchTotalIncomes(),
                                    builder: (_, snap) => _infoTile(icon: CupertinoIcons.arrow_up, label: 'Added Money', color: Colors.green, amount: snap.data ?? 0.0),
                                  ),
                                  StreamBuilder<double>(
                                    stream: watchTotalExpenses(),
                                    builder: (_, snap) => _infoTile(icon: CupertinoIcons.arrow_down, label: 'Expenses', color: Colors.red, amount: snap.data ?? 0.0),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // 🧮 Remaining Budget
                StreamBuilder<double>(
                  stream: watchTotalIncomes(),
                  builder: (context, incomeSnap) {
                    final income = incomeSnap.data ?? 0.0;
                    return StreamBuilder<double>(
                      stream: watchTotalExpenses(),
                      builder: (context, expSnap) {
                        final expense = expSnap.data ?? 0.0;
                        final remaining = monthlyBudget + income - expense;

                        return Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(color: Colors.blueGrey.shade50, borderRadius: BorderRadius.circular(12)),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Remaining Budget', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                              Text(
                                '${_convert(remaining).toStringAsFixed(2)} $_selectedCurrency',
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: remaining >= 0 ? Colors.green : Colors.red),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),

                const SizedBox(height: 20),

                // 📜 Transactions Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Transactions', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          height: 36,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(color: Colors.black, width: 0.5),
                            borderRadius: BorderRadius.circular(50),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _sortOption,
                              icon: const Icon(Icons.arrow_drop_down, color: Colors.black),
                              style: const TextStyle(fontSize: 12, color: Colors.black),
                              dropdownColor: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              isDense: true,
                              items: ['Newest to Oldest', 'Oldest to Newest', 'Highest to Lowest', 'Lowest to Highest'].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
                              onChanged: (v) => setState(() => _sortOption = v!),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AllExpensesPage(
                                expenses: widget.expenses,
                                incomes: widget.incomes,
                                selectedCurrency: _selectedCurrency,
                                conversionRates: _conversionRates,
                              ),
                            ),
                          ),
                          child: const Text('View All', style: TextStyle(fontSize: 14)),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // 📋 Transactions List
                Expanded(
                  child: Builder(builder: (_) {
                    final allTxs = [
                      ...widget.expenses.map((e) => {'type': 'expense', 'item': e}),
                      ...widget.incomes.map((i) => {'type': 'income', 'item': i}),
                    ];

                    if (_sortOption == 'Newest to Oldest') {
                      allTxs.sort((a, b) {
                        final ad = a['item'] is Expense ? (a['item'] as Expense).date : (a['item'] as Income).date;
                        final bd = b['item'] is Expense ? (b['item'] as Expense).date : (b['item'] as Income).date;
                        return bd.compareTo(ad);
                      });
                    } else if (_sortOption == 'Oldest to Newest') {
                      allTxs.sort((a, b) {
                        final ad = a['item'] is Expense ? (a['item'] as Expense).date : (a['item'] as Income).date;
                        final bd = b['item'] is Expense ? (b['item'] as Expense).date : (b['item'] as Income).date;
                        return ad.compareTo(bd);
                      });
                    } else if (_sortOption == 'Highest to Lowest') {
                      allTxs.sort((a, b) {
                        final aa = a['item'] is Expense ? (a['item'] as Expense).amount : (a['item'] as Income).amount;
                        final ba = b['item'] is Expense ? (b['item'] as Expense).amount : (b['item'] as Income).amount;
                        return ba.compareTo(aa);
                      });
                    } else {
                      allTxs.sort((a, b) {
                        final aa = a['item'] is Expense ? (a['item'] as Expense).amount : (a['item'] as Income).amount;
                        final ba = b['item'] is Expense ? (b['item'] as Expense).amount : (b['item'] as Income).amount;
                        return aa.compareTo(ba);
                      });
                    }

                    return ListView.builder(
                      itemCount: allTxs.length,
                      itemBuilder: (context, index) {
                        final tx = allTxs[index];
                        if (tx['type'] == 'expense') {
                          final e = tx['item'] as Expense;
                          return _txTile(e.category.name, e.amount, e.date, true, e.category.icon, e.category.color);
                        } else {
                          final i = tx['item'] as Income;
                          return _txTile('Add Money', i.amount, i.date, false, null, null);
                        }
                      },
                    );
                  }),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _infoTile({required IconData icon, required String label, required Color color, required double amount}) {
    return Row(
      children: [
        CircleAvatar(radius: 12, backgroundColor: Colors.white30, child: Icon(icon, size: 12, color: color)),
        const SizedBox(width: 8),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(fontSize: 14, color: Colors.white)),
          Text('${_convert(amount).toStringAsFixed(2)} $_selectedCurrency', style: const TextStyle(fontSize: 14, color: Colors.white)),
        ]),
      ],
    );
  }

  Widget _txTile(String title, int amount, DateTime date, bool isExpense, String? icon, int? color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Row(children: [
              if (isExpense)
                CircleAvatar(radius: 25, backgroundColor: Color(color!), child: Image.asset('assets/$icon.png', scale: 2, color: Colors.white))
              else
                const Icon(CupertinoIcons.arrow_up_circle_fill, color: Colors.green, size: 40),
              const SizedBox(width: 12),
              Text(title, style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onBackground)),
            ]),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              RichText(
                text: TextSpan(style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onBackground), children: [
                  WidgetSpan(child: Icon(FontAwesomeIcons.indianRupeeSign, size: 12)),
                  TextSpan(text: '${_convert(amount.toDouble()).toStringAsFixed(2)}'),
                ]),
              ),
              Text(getFriendlyDateLabel(date), style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.outline)),
            ]),
          ]),
        ),
      ),
    );
  }
}
