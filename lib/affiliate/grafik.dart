import 'package:fl_chart/fl_chart.dart';

// import 'package/fl_chart.dart';
import 'package:flutter/material.dart';

class MinimalSalesChart extends StatelessWidget {
  final List<FlSpot> data;

  const MinimalSalesChart({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final bool hasData = data.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6)],
      ),
      child: SizedBox(
        height: 200,
        child: LineChart(
          LineChartData(
            minX: 0,
            maxX: 23.99,
            minY: 0,
            maxY: 200,
            titlesData: FlTitlesData(
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    if (value == 0) {
                      return const Text("00:00", style: TextStyle(fontSize: 10, color: Colors.grey));
                    } else if (value == 23.99) {
                      return const Text("23:59", style: TextStyle(fontSize: 10, color: Colors.grey));
                    } else {
                      return const SizedBox.shrink();
                    }
                  },
                  interval: 1,
                  reservedSize: 32,
                ),
              ),
              rightTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  interval: 40,
                  reservedSize: 32,
                  getTitlesWidget: (value, meta) {
                    return Text(value.toInt().toString(),
                        style: const TextStyle(fontSize: 10, color: Colors.grey));
                  },
                ),
              ),
              leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            gridData: FlGridData(
              show: true,
              drawVerticalLine: true,
              verticalInterval: 1,
              horizontalInterval: 40,
              getDrawingHorizontalLine: (_) => FlLine(color: Colors.grey.withOpacity(0.2), strokeWidth: 1),
              getDrawingVerticalLine: (_) => FlLine(color: Colors.grey.withOpacity(0.2), strokeWidth: 1),
            ),
            borderData: FlBorderData(show: false),
            lineBarsData: [
              LineChartBarData(
                isCurved: false,
                color: hasData ? Colors.green : Colors.transparent,
                barWidth: 2,
                dotData: FlDotData(show: hasData),
                spots: hasData ? data : [const FlSpot(0, 0)],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
