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
  String _sortOption = 'Newest to Oldest';

  // Currency symbols
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
      currencySymbols[widget.selectedCurrency] ?? widget.selectedCurrency;

  double _convert(double amount) {
    return amount * (widget.conversionRates[widget.selectedCurrency] ?? 1.0);
  }

  String getFriendlyDateLabel(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final txDate = DateTime(date.year, date.month, date.day);

    if (txDate == today) {
      return 'Today at ${DateFormat('HH:mm').format(date)}';
    } else if (txDate == yesterday) {
      return 'Yesterday at ${DateFormat('HH:mm').format(date)}';
    } else {
      return DateFormat('dd/MM/yyyy • HH:mm').format(date);
    }
  }

  List<Map<String, dynamic>> getSortedCombined() {
    final combined = [
      ...widget.expenses.map((e) => {'type': 'expense', 'data': e}),
      ...widget.incomes.map((i) => {'type': 'income', 'data': i}),
    ];

    combined.sort((a, b) {
      final aData = a['data'];
      final bData = b['data'];

      if (_sortOption == 'Newest to Oldest') {
        final aDate = a['type'] == 'expense'
            ? (aData as Expense).date
            : (aData as Income).date;
        final bDate = b['type'] == 'expense'
            ? (bData as Expense).date
            : (bData as Income).date;
        return bDate.compareTo(aDate);
      } else if (_sortOption == 'Oldest to Newest') {
        final aDate = a['type'] == 'expense'
            ? (aData as Expense).date
            : (aData as Income).date;
        final bDate = b['type'] == 'expense'
            ? (bData as Expense).date
            : (bData as Income).date;
        return aDate.compareTo(bDate);
      } else if (_sortOption == 'Highest to Lowest') {
        final aAmount = a['type'] == 'expense'
            ? (aData as Expense).amount
            : (aData as Income).amount;
        final bAmount = b['type'] == 'expense'
            ? (bData as Expense).amount
            : (bData as Income).amount;
        return bAmount.compareTo(aAmount);
      } else {
        final aAmount = a['type'] == 'expense'
            ? (aData as Expense).amount
            : (aData as Income).amount;
        final bAmount = b['type'] == 'expense'
            ? (bData as Expense).amount
            : (bData as Income).amount;
        return aAmount.compareTo(bAmount);
      }
    });

    return combined;
  }

  Future<void> _exportTransactions() async {
    final combined = getSortedCombined();

    // Build CSV rows
    List<List<String>> rows = [
      ['Type', 'Category', 'Amount ($symbol)', 'Date'],
    ];

    for (var item in combined) {
      if (item['type'] == 'expense') {
        final e = item['data'] as Expense;
        rows.add([
          'Expense',
          e.category.name,
          '-${_convert(e.amount.toDouble()).toStringAsFixed(2)} $symbol',
          DateFormat('yyyy-MM-dd HH:mm').format(e.date),
        ]);
      } else {
        final iData = item['data'] as Income;
        rows.add([
          'Income',
          'Income',
          '+${_convert(iData.amount.toDouble()).toStringAsFixed(2)} $symbol',
          DateFormat('yyyy-MM-dd HH:mm').format(iData.date),
        ]);
      }
    }

    String csvData = const ListToCsvConverter().convert(rows);

    final directory = await getApplicationDocumentsDirectory();
    final path = '${directory.path}/transactions.csv';

    final file = File(path);
    await file.writeAsString(csvData);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Transactions exported!')),
    );

    await Share.shareXFiles([XFile(path)], text: 'My exported transactions');
  }

  @override
  Widget build(BuildContext context) {
    final combined = getSortedCombined();

    return Scaffold(
      appBar: AppBar(
        title: const Text('All Transactions'),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 10),
            child: IconButton(
              icon: const Icon(Icons.download),
              tooltip: 'Export CSV',
              onPressed: _exportTransactions,
            ),
          ),
          Container(
            margin: const EdgeInsets.only(right: 20),
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceVariant,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
              ),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _sortOption,
                icon: const Icon(Icons.arrow_drop_down, size: 20),
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onBackground,
                ),
                dropdownColor: Theme.of(context).colorScheme.surface,
                items: [
                  'Newest to Oldest',
                  'Oldest to Newest',
                  'Highest to Lowest',
                  'Lowest to Highest',
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
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView.builder(
          itemCount: combined.length,
          itemBuilder: (context, i) {
            final item = combined[i];

            if (item['type'] == 'expense') {
              final e = item['data'] as Expense;
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Color(e.category.color),
                    child: Image.asset(
                      'assets/${e.category.icon}.png',
                      color: Colors.white,
                      scale: 2,
                    ),
                  ),
                  title: Text(e.category.name),
                  subtitle: Text(getFriendlyDateLabel(e.date)),
                  trailing: Text(
                    '- $symbol ${_convert(e.amount.toDouble()).toStringAsFixed(2)} ',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                ),
              );
            } else {
              final iData = item['data'] as Income;
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Colors.green,
                    child: Icon(
                      CupertinoIcons.arrow_down_circle_fill,
                      color: Colors.white,
                    ),
                  ),
                  title: const Text('Income'),
                  subtitle: Text(getFriendlyDateLabel(iData.date)),
                  trailing: Text(
                    '+ $symbol ${_convert(iData.amount.toDouble()).toStringAsFixed(2)} ',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ),
              );
            }
          },
        ),
      ),
    );
  }
}
