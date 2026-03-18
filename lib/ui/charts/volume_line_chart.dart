import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../providers/exercise_records_provider.dart';

class VolumeLineChart extends StatelessWidget {
  final List<ExerciseRecord> records;

  const VolumeLineChart({super.key, required this.records});

  @override
  Widget build(BuildContext context) {
    if (records.isEmpty) {
      return const Center(
        child: Text('No hay datos suficientes para el gráfico.'),
      );
    }

    // Grouping records by date to calculate daily volume
    final volumeByDate = <DateTime, double>{};
    for (var record in records) {
      // Normalize to day to avoid multiple dots per day
      final dateOnly = DateTime(
          record.timestamp.year, record.timestamp.month, record.timestamp.day);
      volumeByDate[dateOnly] = (volumeByDate[dateOnly] ?? 0) + record.volume;
    }

    // Sort by date
    final sortedDates = volumeByDate.keys.toList()..sort();

    // Prepare spots for chart
    final spots = <FlSpot>[];
    double maxVolume = 0;

    for (int i = 0; i < sortedDates.length; i++) {
      final volume = volumeByDate[sortedDates[i]]!.toDouble();
      if (volume > maxVolume) maxVolume = volume;
      spots.add(FlSpot(i.toDouble(), volume));
    }

    // If there's only one data point, add a dummy zero or copy it so the line chart can render a line or single dot
    if (spots.length == 1) {
      spots.add(FlSpot(1.0, spots[0].y));
    }

    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: false),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index >= 0 && index < sortedDates.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      DateFormat('dd/MM').format(sortedDates[index]),
                      style: const TextStyle(fontSize: 10),
                    ),
                  );
                }
                return const Text('');
              },
            ),
          ),
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(
                showTitles: false), // Hide left titles to keep it clean
          ),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: Theme.of(context).colorScheme.primary,
            barWidth: 4,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 4,
                  color: Theme.of(context).colorScheme.primary,
                  strokeWidth: 2,
                  strokeColor: Theme.of(context).colorScheme.surface,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              color: Theme.of(context).colorScheme.primary.withAlpha(51),
            ),
          ),
        ],
        minX: 0,
        maxX: spots.length > 1 ? (spots.length - 1).toDouble() : 1,
        minY: 0,
        maxY: maxVolume * 1.2, // Add 20% headroom
      ),
    );
  }
}
