import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/finance_bloc.dart';
import '../bloc/finance_event.dart';
import '../bloc/finance_state.dart';

class SourceBreakdownChart extends StatelessWidget {
  final List<MerchantSummary> data;

  const SourceBreakdownChart({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final touchedIndex = context.select<FinanceBloc, int>(
      (b) => b.state.sourceBreakdownTouchedIndex,
    );

    if (data.isEmpty) {
      return const Center(child: Text('No matching data'));
    }

    // Process data: Take top 5, group rest as "Others"
    final topSources = data.take(5).toList();
    final otherSources = data.skip(5).toList();

    double otherTotal = 0;
    for (var s in otherSources) {
      otherTotal += s.total;
    }

    final chartItems = <_ChartItem>[];
    for (var i = 0; i < topSources.length; i++) {
      chartItems.add(
        _ChartItem(
          label: topSources[i].name,
          value: topSources[i].total,
          color: _getColor(i),
        ),
      );
    }

    if (otherTotal > 0) {
      chartItems.add(
        _ChartItem(
          label: 'Others',
          value: otherTotal,
          color: const Color(0xFF94A3B8), // Slate 400
        ),
      );
    }

    final total = chartItems.fold(0.0, (sum, item) => sum + item.value);

    return Row(
      children: [
        // Pie Chart
        Expanded(
          flex: 4,
          child: AspectRatio(
            aspectRatio: 1,
            child: PieChart(
              PieChartData(
                pieTouchData: PieTouchData(
                  touchCallback: (FlTouchEvent event, pieTouchResponse) {
                    if (!event.isInterestedForInteractions ||
                        pieTouchResponse == null ||
                        pieTouchResponse.touchedSection == null) {
                      context.read<FinanceBloc>().add(
                            const SetSourceBreakdownTouchedIndex(-1),
                          );
                      return;
                    }
                    context.read<FinanceBloc>().add(
                          SetSourceBreakdownTouchedIndex(
                            pieTouchResponse.touchedSection!.touchedSectionIndex,
                          ),
                        );
                  },
                ),
                borderData: FlBorderData(show: false),
                sectionsSpace: 2,
                centerSpaceRadius: 30,
                sections: List.generate(chartItems.length, (i) {
                  final isTouched = i == touchedIndex;
                  final fontSize = isTouched ? 14.0 : 12.0;
                  final radius = isTouched ? 50.0 : 40.0;
                  final item = chartItems[i];
                  final percent = (item.value / total * 100).toStringAsFixed(0);

                  return PieChartSectionData(
                    color: item.color,
                    value: item.value,
                    title: '$percent%',
                    radius: radius,
                    titleStyle: TextStyle(
                      fontSize: fontSize,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      shadows: const [
                        Shadow(color: Colors.black26, blurRadius: 2),
                      ],
                    ),
                  );
                }),
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        // Legend
        Expanded(
          flex: 3,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: chartItems.asMap().entries.map((e) {
              final index = e.key;
              final item = e.value;
              final isTouched = index == touchedIndex;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: item.color,
                        shape: BoxShape.circle,
                        boxShadow: isTouched
                            ? [
                                BoxShadow(
                                  color: item.color.withOpacity(0.4),
                                  blurRadius: 6,
                                  spreadRadius: 2,
                                ),
                              ]
                            : null,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        item.label,
                        style: isTouched
                            ? Theme.of(context).textTheme.labelMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              )
                            : Theme.of(context).textTheme.labelSmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Color _getColor(int index) {
    // Professional palette for sources
    const colors = [
      Color(0xFF0891B2), // Brand teal
      Color(0xFF16A34A), // Brand green
      Color(0xFFF59E0B), // Brand gold
      Color(0xFF0EA5E9), // Sky blue
      Color(0xFF0D9488), // Deep teal
    ];
    return colors[index % colors.length];
  }
}

class _ChartItem {
  final String label;
  final double value;
  final Color color;

  _ChartItem({required this.label, required this.value, required this.color});
}
