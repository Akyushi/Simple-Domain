import 'package:flutter/material.dart';

class ProductPrice extends StatelessWidget {
  final String price;

  const ProductPrice({super.key, required this.price});

  @override
  Widget build(BuildContext context) {
    return Text(
      '₱$price', // Updated to peso
      style: const TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: Colors.black,
      ),
    );
  }
}
