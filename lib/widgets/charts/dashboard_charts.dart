import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class ChartPoint {
  final String label;
  final double value;

  const ChartPoint(this.label, this.value);
}

class DonutChartCard extends StatelessWidget {
  const DonutChartCard({
    super.key,
    required this.title,
    required this.points,
    this.height = 250,
  });

  final String title;
  final List<ChartPoint> points;
  final double height;

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) {
      return _ChartShell(title: title, child: const _ChartEmptyState());
    }

    return _ChartShell(
      title: title,
      child: SizedBox(
        height: height,
        child: SfCircularChart(
          legend: const Legend(
            isVisible: true,
            position: LegendPosition.bottom,
            overflowMode: LegendItemOverflowMode.wrap,
            textStyle: TextStyle(color: Colors.white70, fontSize: 11),
          ),
          series: <DoughnutSeries<ChartPoint, String>>[
            DoughnutSeries<ChartPoint, String>(
              dataSource: points,
              xValueMapper: (point, _) => point.label,
              yValueMapper: (point, _) => point.value,
              dataLabelMapper: (point, _) => '${point.value.toInt()}',
              dataLabelSettings: const DataLabelSettings(
                isVisible: true,
                textStyle: TextStyle(color: Colors.white, fontSize: 10),
              ),
              radius: '80%',
            ),
          ],
        ),
      ),
    );
  }
}

class ColumnChartCard extends StatelessWidget {
  const ColumnChartCard({
    super.key,
    required this.title,
    required this.points,
    this.height = 280,
    this.yAxisTitle,
  });

  final String title;
  final List<ChartPoint> points;
  final double height;
  final String? yAxisTitle;

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) {
      return _ChartShell(title: title, child: const _ChartEmptyState());
    }

    return _ChartShell(
      title: title,
      child: SizedBox(
        height: height,
        child: SfCartesianChart(
          primaryXAxis: CategoryAxis(
            labelStyle: const TextStyle(color: Colors.white70, fontSize: 11),
            majorGridLines: const MajorGridLines(width: 0),
          ),
          primaryYAxis: NumericAxis(
            title: AxisTitle(
              text: yAxisTitle ?? '',
              textStyle: const TextStyle(color: Colors.white70, fontSize: 11),
            ),
            labelStyle: const TextStyle(color: Colors.white70, fontSize: 11),
            majorGridLines:
                const MajorGridLines(width: 0.5, color: Colors.white12),
          ),
          tooltipBehavior: TooltipBehavior(enable: true),
          series: <ColumnSeries<ChartPoint, String>>[
            ColumnSeries<ChartPoint, String>(
              dataSource: points,
              xValueMapper: (point, _) => point.label,
              yValueMapper: (point, _) => point.value,
              borderRadius: const BorderRadius.all(Radius.circular(6)),
              dataLabelSettings: const DataLabelSettings(
                isVisible: true,
                textStyle: TextStyle(color: Colors.white, fontSize: 10),
              ),
              pointColorMapper: (point, index) {
                const colors = [
                  Color(0xFF22C55E),
                  Color(0xFF38BDF8),
                  Color(0xFFF59E0B),
                  Color(0xFFEF4444),
                  Color(0xFFA78BFA),
                  Color(0xFF10B981),
                  Color(0xFFF97316),
                ];
                return colors[index % colors.length];
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ChartShell extends StatelessWidget {
  const _ChartShell({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFF1E293B),
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            child,
          ],
        ),
      ),
    );
  }
}

class _ChartEmptyState extends StatelessWidget {
  const _ChartEmptyState();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 140,
      child: Center(
        child: Text(
          'No data available',
          style: TextStyle(color: Colors.white70),
        ),
      ),
    );
  }
}
