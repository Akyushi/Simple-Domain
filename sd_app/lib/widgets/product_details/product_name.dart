import 'package:flutter/material.dart';

class ProductName extends StatelessWidget {
  final String? name;

  const ProductName({super.key, required this.name});

  @override
  Widget build(BuildContext context) {
    return Text(
      name ?? '',
      style: const TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}
