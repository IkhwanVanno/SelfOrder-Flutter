import 'package:flutter/material.dart';

class SummaryRow extends StatelessWidget {
  final String title;
  final int value;
  final bool bold;

  const SummaryRow({
    super.key,
    required this.title,
    required this.value,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontSize: 14,
      fontWeight: bold ? FontWeight.bold : FontWeight.normal,
    );
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: style),
        Text('Rp $value', style: style),
      ],
    );
  }
}