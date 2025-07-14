import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:food_app/models/sales_report.dart';

class SalesBarChart extends StatelessWidget {
  final List<ItemSaleInfo> itemSales;

  const SalesBarChart({super.key, required this.itemSales});

  @override
  Widget build(BuildContext context) {
    final topItems = itemSales.take(5).toList();

    return AspectRatio(
      aspectRatio: 1.6,
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        color: const Color(0xff2c4260),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: _calculateMaxY(topItems),
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    final item = topItems[groupIndex];

                    return BarTooltipItem(
                      '${item.itemName}\n',
                      const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        backgroundColor: Colors.blueGrey, // colors behind text
                      ),
                      children: [
                        TextSpan(
                          text: 'Sold: ${rod.toY.toInt()}',
                          style: const TextStyle(
                            color: Colors.yellow,
                            fontWeight: FontWeight.w500,
                            backgroundColor: Colors.blueGrey,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              titlesData: FlTitlesData(
                show: true,
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 30,
                    getTitlesWidget: (value, meta) => Text(
                      value.toInt().toString(),
                      style: const TextStyle(color: Colors.white, fontSize: 10),
                    ),
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    getTitlesWidget: (value, meta) {
                      final index = value.toInt();
                      if (index >= topItems.length) return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          topItems[index].itemName.length > 5
                              ? '${topItems[index].itemName.substring(0, 3)}...'
                              : topItems[index].itemName,
                          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      );
                    },
                  ),
                ),
              ),
              gridData: const FlGridData(show: false),
              borderData: FlBorderData(show: false),
              barGroups: topItems.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                return BarChartGroupData(
                  x: index,
                  barRods: [
                    BarChartRodData(
                      toY: item.quantitySold.toDouble(),
                      color: Colors.lightBlueAccent,
                      width: 16,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }

  double _calculateMaxY(List<ItemSaleInfo> items) {
    if (items.isEmpty) return 10;
    final maxQty = items.map((item) => item.quantitySold).reduce((a, b) => a > b ? a : b);
    return (maxQty * 1.2).ceilToDouble();
  }
}
