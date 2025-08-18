import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:expense_repository/expense_repository.dart';
import 'package:intl/intl.dart';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class AllExpensesPage extends StatefulWidget {
  final List<Expense> expenses;
  final List<Income> incomes;
  final String selectedCurrency;
  final Map<String, double> conversionRates;

  const AllExpensesPage({
    super.key,
    required this.expenses,
    required this.incomes,
    required this.selectedCurrency,
    required this.conversionRates,
  });

  @override
  State<AllExpensesPage> createState() => _AllExpensesPageState();
}

class _AllExpensesPageState extends State<AllExpensesPage> {
  final Map<String, String> _currencySymbols = {
    'INR': '₹',
    'USD': '\$',
    'EUR': '€',
    'GBP': '£',
    'JPY': '¥',
    'AUD': 'A\$',
    'CAD': 'C\$',
  };

  @override
  Widget build(BuildContext context) {
    final double conversionRate =
        widget.conversionRates[widget.selectedCurrency] ?? 1.0;
    final String currencySymbol =
        _currencySymbols[widget.selectedCurrency] ?? '';

    final List<Map<String, dynamic>> allTransactions = [
      ...widget.expenses.map((expense) => {
        'type': 'expense',
        'amount': expense.amount,
        'category': expense.category,
        'date': expense.date,
      }),
      ...widget.incomes.map((income) => {
        'type': 'income',
        'amount': income.amount,
        'date': income.date,
      }),
    ];

    allTransactions.sort((a, b) => b['date'].compareTo(a['date']));

    return Scaffold(
      appBar: AppBar(
        title: const Text('All Transactions'),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () async {
              await _exportToCSV(allTransactions, conversionRate);
            },
          ),
        ],
      ),
      body: allTransactions.isEmpty
          ? const Center(
        child: Text('No transactions available'),
      )
          : ListView.builder(
        itemCount: allTransactions.length,
        itemBuilder: (context, index) {
          final transaction = allTransactions[index];
          final bool isExpense = transaction['type'] == 'expense';
          final Color color = isExpense ? Colors.red : Colors.green;
          final double convertedAmount =
              transaction['amount'] * conversionRate;

          return ListTile(
            leading: Icon(
              isExpense ? Icons.remove_circle : Icons.add_circle,
              color: color,
            ),
            title: Text(
              '${isExpense ? 'Expense' : 'Income'} - ${transaction['category']}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              'Date: ${DateFormat.yMMMd().format(transaction['date'])}',
            ),
            trailing: Text(
              '$currencySymbol${convertedAmount.toStringAsFixed(2)}',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _exportToCSV(
      List<Map<String, dynamic>> transactions, double conversionRate) async {
    final String currencySymbol =
        _currencySymbols[widget.selectedCurrency] ?? '';
    final List<List<dynamic>> rows = [
      ['Type', 'Amount (${widget.selectedCurrency})', 'Category', 'Date'],
      ...transactions.map((tx) {
        final isExpense = tx['type'] == 'expense';
        final double converted = tx['amount'] * conversionRate;
        return [
          tx['type'],
          '$currencySymbol${converted.toStringAsFixed(2)}',
          tx['category'],
          DateFormat.yMMMd().format(tx['date']),
        ];
      }),
    ];

    final String csvData = const ListToCsvConverter().convert(rows);
    final directory = await getApplicationDocumentsDirectory();
    final path = '${directory.path}/transactions.csv';
    final file = File(path);
    await file.writeAsString(csvData);

    await Share.shareXFiles([XFile(file.path)],
        text: 'Here is my exported transaction history.');
  }
}
