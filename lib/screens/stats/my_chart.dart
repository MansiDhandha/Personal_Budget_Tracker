import 'dart:math';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class MyChart extends StatefulWidget {
  final Map<String, Map<String, double>> dateTotals;
  final double monthlyBudget;

  const MyChart({
    super.key,
    required this.dateTotals,
    required this.monthlyBudget,
  });

  @override
  State<MyChart> createState() => _MyChartState();
}

class _MyChartState extends State<MyChart> {
  String selectedChart = "Line Chart";

  @override
  Widget build(BuildContext context) {
    if (widget.dateTotals.isEmpty) {
      return const Center(child: Text('No data'));
    }

    // Sort dates
    List<String> allDates = widget.dateTotals.keys.toList()..sort();

    // Show weekly dates
    List<String> displayDates = [];
    for (int i = 0; i < allDates.length; i += 7) {
      displayDates.add(allDates[i]);
    }
    if (allDates.isNotEmpty && displayDates.last != allDates.last) {
      displayDates.add(allDates.last); // include last day
    }

    double totalExpense = widget.dateTotals.values
        .fold(0.0, (sum, e) => sum + (e['expense'] ?? 0.0));
    double totalIncome = widget.dateTotals.values
        .fold(0.0, (sum, e) => sum + (e['income'] ?? 0.0));
    double total = totalIncome + totalExpense;
    double expensePercent = total == 0 ? 0 : (totalExpense / total) * 100;
    double incomePercent = total == 0 ? 0 : (totalIncome / total) * 100;

    // Wrap heavy chart building inside a method for clarity
    Widget buildChart() {
      if (selectedChart == "Line Chart") {
        double avgExpense = allDates.isEmpty ? 0 : totalExpense / allDates.length;
        double avgIncome = allDates.isEmpty ? 0 : totalIncome / allDates.length;

        final List<FlSpot> expenseSpots = [];
        final List<FlSpot> incomeSpots = [];

        for (int i = 0; i < allDates.length; i++) {
          expenseSpots.add(FlSpot(i.toDouble(),
              widget.dateTotals[allDates[i]]?['expense'] ?? 0.0));
          incomeSpots.add(FlSpot(i.toDouble(),
              widget.dateTotals[allDates[i]]?['income'] ?? 0.0));
        }

        return RepaintBoundary(
          child: LineChart(
            LineChartData(
              minY: 0,
              maxY: widget.monthlyBudget,
              lineBarsData: [
                LineChartBarData(
                  spots: expenseSpots,
                  isCurved: true,
                  color: Colors.redAccent,
                  barWidth: 3,
                  dotData: const FlDotData(show: true),
                ),
                LineChartBarData(
                  spots: incomeSpots,
                  isCurved: true,
                  color: Colors.green,
                  barWidth: 3,
                  dotData: const FlDotData(show: true),
                ),
              ],
              titlesData: FlTitlesData(
                topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    interval: widget.monthlyBudget / 6,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        '₹${value.toInt()}',
                        style: const TextStyle(fontSize: 10),
                      );
                    },
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 38,
                    interval: 7,
                    getTitlesWidget: (value, meta) {
                      int index = value.toInt();
                      if (index >= 0 && index < allDates.length) {
                        String date = allDates[index];
                        return Text(
                          DateFormat('dd MMM').format(DateTime.parse(date)),
                          style: const TextStyle(fontSize: 10),
                        );
                      }
                      return const Text('');
                    },
                  ),
                ),
              ),
              gridData: FlGridData(show: true),
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  getTooltipItems: (spots) {
                    return spots.map((spot) {
                      return LineTooltipItem(
                          '${allDates[spot.x.toInt()]}\n₹${spot.y.toStringAsFixed(2)}',
                          const TextStyle(color: Colors.black, fontSize: 12));
                    }).toList();
                  },
                ),
              ),
              extraLinesData: ExtraLinesData(horizontalLines: [
                HorizontalLine(
                  y: avgExpense,
                  color: Colors.redAccent.withOpacity(0.3),
                  strokeWidth: 1,
                  dashArray: [5, 5],
                  label: HorizontalLineLabel(
                      show: true,
                      alignment: Alignment.topLeft,
                      labelResolver: (_) =>
                      'Avg Expense ₹${avgExpense.toStringAsFixed(0)}'),
                ),
                HorizontalLine(
                  y: avgIncome,
                  color: Colors.green.withOpacity(0.3),
                  strokeWidth: 1,
                  dashArray: [5, 5],
                  label: HorizontalLineLabel(
                      show: true,
                      alignment: Alignment.topLeft,
                      labelResolver: (_) =>
                      'Avg Income ₹${avgIncome.toStringAsFixed(0)}'),
                ),
              ]),
            ),
          ),
        );
      } else if (selectedChart == "Bar Chart") {
        final List<BarChartGroupData> barGroups = [];
        for (int i = 0; i < allDates.length; i++) {
          barGroups.add(
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: widget.dateTotals[allDates[i]]?['expense'] ?? 0.0,
                  color: Colors.redAccent,
                  width: 6,
                  borderRadius: BorderRadius.circular(3),
                ),
                BarChartRodData(
                  toY: widget.dateTotals[allDates[i]]?['income'] ?? 0.0,
                  color: Colors.green,
                  width: 6,
                  borderRadius: BorderRadius.circular(3),
                ),
              ],
            ),
          );
        }

        return RepaintBoundary(
          child: BarChart(
            BarChartData(
              maxY: widget.monthlyBudget,
              barGroups: barGroups,
              titlesData: FlTitlesData(
                rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    interval: widget.monthlyBudget / 6,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        '₹${value.toInt()}',
                        style: const TextStyle(fontSize: 10),
                      );
                    },
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 38,
                    interval: 7,
                    getTitlesWidget: (value, meta) {
                      int index = value.toInt();
                      if (index >= 0 && index < allDates.length) {
                        String date = allDates[index];
                        return Text(
                          DateFormat('dd MMM').format(DateTime.parse(date)),
                          style: const TextStyle(fontSize: 10),
                        );
                      }
                      return const Text('');
                    },
                  ),
                ),
              ),
              barTouchData: BarTouchData(
                enabled: true,
                touchTooltipData: BarTouchTooltipData(
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    String type = rodIndex == 0 ? "Expense" : "Income";
                    return BarTooltipItem(
                        '${allDates[group.x.toInt()]}\n$type: ₹${rod.toY.toStringAsFixed(2)}',
                        const TextStyle(color: Colors.black, fontSize: 12));
                  },
                ),
              ),
            ),
          ),
        );
      } else {
        return RepaintBoundary(
          child: PieChart(
            PieChartData(
              sections: [
                PieChartSectionData(
                  value: totalExpense,
                  color: Colors.redAccent,
                  title: "${expensePercent.toStringAsFixed(1)}%",
                ),
                PieChartSectionData(
                  value: totalIncome,
                  color: Colors.green,
                  title: "${incomePercent.toStringAsFixed(1)}%",
                ),
              ],
            ),
          ),
        );
      }
    }

    // Header + dropdown remains lightweight
    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.grey.shade100,
        body: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          selectedChart == "Line Chart"
                              ? "Income vs Expense Trend"
                              : selectedChart == "Bar Chart"
                              ? "Daily Income vs Expense"
                              : "Income vs Expense Breakdown",
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          selectedChart == "Line Chart"
                              ? "Track your daily income and expenses over time."
                              : selectedChart == "Bar Chart"
                              ? "Compare your daily expenses and income side by side."
                              : "See how your total income compares with expenses.",
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                  DropdownButton<String>(
                    value: selectedChart,
                    isDense: true,
                    items: const [
                      DropdownMenuItem(
                          value: "Line Chart", child: Text("Line")),
                      DropdownMenuItem(value: "Bar Chart", child: Text("Bar")),
                      DropdownMenuItem(value: "Pie Chart", child: Text("Pie")),
                    ],
                    onChanged: (value) {
                      setState(() {
                        selectedChart = value!;
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: buildChart(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
