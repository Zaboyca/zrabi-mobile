import 'package:flutter/material.dart';

/// App bar brand: checkmark mark + zrabi.by (matches web header).
class ZrabiBrandTitle extends StatelessWidget {
  const ZrabiBrandTitle({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF2F9B7A), Color(0xFF1C5C4A)],
            ),
          ),
          child: const Icon(
            Icons.check_rounded,
            color: Color(0xFFF4FBF7),
            size: 18,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          'zrabi.by',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: scheme.primary,
          ),
        ),
      ],
    );
  }
}
