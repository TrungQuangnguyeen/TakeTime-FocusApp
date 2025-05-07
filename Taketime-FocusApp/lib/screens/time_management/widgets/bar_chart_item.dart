import 'package:flutter/material.dart';

class BarChartItem extends StatelessWidget {
  final String appName;
  final double usage;
  final double maxUsage;
  final Color color;

  const BarChartItem({
    super.key,
    required this.appName,
    required this.usage,
    required this.maxUsage,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              appName,
              style: theme.textTheme.bodyMedium,
            ),
          ),
          Expanded(
            child: Container(
              height: 20,
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[800] : Colors.grey[200],
                borderRadius: BorderRadius.circular(10),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: usage / maxUsage,
                child: Container(
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${usage.toStringAsFixed(1)} giờ',
            style: theme.textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}