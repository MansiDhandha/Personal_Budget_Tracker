import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'my_chart.dart';

class StatScreen extends StatelessWidget {
  const StatScreen({super.key});

  Future<Map<String, Map<String, double>>> fetchIncomeExpensePerDate() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    final expenseSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('expenses')
        .get();

    final incomeSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('incomes')
        .get();

    final Map<String, Map<String, double>> dateTotals = {};

    for (var doc in expenseSnapshot.docs) {
      final timestamp = doc['date'] as Timestamp;
      final dateTime = timestamp.toDate();
      final dateStr =
          '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}';

      dateTotals[dateStr] ??= {};
      dateTotals[dateStr]!['expense'] =
          (dateTotals[dateStr]!['expense'] ?? 0) + (doc['amount'] as num).toDouble();
    }

    for (var doc in incomeSnapshot.docs) {
      final timestamp = doc['date'] as Timestamp;
      final dateTime = timestamp.toDate();
      final dateStr =
          '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}';

      dateTotals[dateStr] ??= {};
      dateTotals[dateStr]!['income'] =
          (dateTotals[dateStr]!['income'] ?? 0) + (doc['amount'] as num).toDouble();
    }

    return dateTotals;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Transactoins',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              height: 400,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: FutureBuilder<Map<String, Map<String, double>>>(
                future: fetchIncomeExpensePerDate(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return const Center(child: Text('Error loading data'));
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text('No transactions found.'));
                  } else {
                    return MyChart(dateTotals: snapshot.data!,monthlyBudget:  5000,);
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
