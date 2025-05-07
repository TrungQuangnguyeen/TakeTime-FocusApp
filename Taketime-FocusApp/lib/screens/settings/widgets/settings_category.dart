import 'package:flutter/material.dart';

class SettingsCategory extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const SettingsCategory({
    super.key,
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16, bottom: 8),
          child: Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: theme.colorScheme.outline.withOpacity(0.2),
            ),
          ),
          child: Column(
            children: List.generate(
              children.length * 2 - 1,
              (index) {
                if (index.isOdd) {
                  return const Divider(height: 1, indent: 16, endIndent: 16);
                }
                return children[index ~/ 2];
              },
            ),
          ),
        ),
      ],
    );
  }
}