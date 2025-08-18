import 'dart:math';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class MyChart extends StatelessWidget {
  final Map<String, Map<String, double>> dateTotals;
  final double monthlyBudget;

  const MyChart({
    super.key,
    required this.dateTotals,
    required this.monthlyBudget,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 0,
    );

    if (dateTotals.isEmpty) {
      return const Center(child: Text('No data'));
    }

    final allDates = dateTotals.keys
        .map((e) {
      final parts = e.split('-');
      return DateTime(
        int.parse(parts[0]),
        int.parse(parts[1]),
        int.parse(parts[2]),
      );
    })
        .toList()
      ..sort();

    final firstDate = allDates.first;
    final lastDate = allDates.last;

    final List<String> continuousDates = [];
    DateTime currentDate = firstDate;
    while (!currentDate.isAfter(lastDate)) {
      final key = "${currentDate.year.toString().padLeft(4, '0')}-${currentDate.month.toString().padLeft(2, '0')}-${currentDate.day.toString().padLeft(2, '0')}";
      continuousDates.add(key);

      dateTotals.putIfAbsent(key, () => {'expense': 0.0, 'income': 0.0});

      currentDate = currentDate.add(const Duration(days: 1));
    }
    final displayDates = continuousDates.length > 10
        ? continuousDates.sublist(continuousDates.length - 10)
        : continuousDates;

    final List<FlSpot> expenseSpots = [];
    final List<FlSpot> incomeSpots = [];

    double maxAmount = 0;

    for (int i = 0; i < displayDates.length; i++) {
      final date = displayDates[i];
      final expense = dateTotals[date]!['expense'] ?? 0;
      final income = dateTotals[date]!['income'] ?? 0;

      expenseSpots.add(FlSpot(i.toDouble(), expense));
      incomeSpots.add(FlSpot(i.toDouble(), income));

      maxAmount = max(maxAmount, expense);
      maxAmount = max(maxAmount, income);
    }
    final safeMaxY = monthlyBudget <= 0 ? 100.0 : monthlyBudget;
    final interval = (safeMaxY / 5).ceilToDouble();

    return LineChart(
      LineChartData(
        minY: 0,
        maxY: safeMaxY,
        lineBarsData: [
          LineChartBarData(
            spots: expenseSpots,
            isCurved: true,
            barWidth: 3,
            color: Colors.redAccent,
            dotData: FlDotData(show: true),
            belowBarData: BarAreaData(show: false),
          ),
          LineChartBarData(
            spots: incomeSpots,
            isCurved: true,
            barWidth: 3,
            color: Colors.green,
            dotData: FlDotData(show: true),
            belowBarData: BarAreaData(show: false),
          ),
        ],
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 50,
              interval: interval,
              getTitlesWidget: (value, meta) {
                return Text(
                  currencyFormatter.format(value),
                  style: const TextStyle(fontSize: 10),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 42,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index >= 0 && index < displayDates.length) {
                  final parts = displayDates[index].split('-');
                  final date = DateTime(
                    int.parse(parts[0]),
                    int.parse(parts[1]),
                    int.parse(parts[2]),
                  );
                  final formatted = DateFormat('d MMM').format(date);
                  return SideTitleWidget(
                    meta: meta,
                    space: 8,
                    child: Transform.rotate(
                      angle: -0.5,
                      child: Text(
                        formatted,
                        style: const TextStyle(fontSize: 10),
                      ),
                    ),
                  );
                }
                return const Text('');
              },
            ),
          ),
        ),
        gridData: FlGridData(show: true),
        borderData: FlBorderData(show: true),
      ),
    );
  }

}
