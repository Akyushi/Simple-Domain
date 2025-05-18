import 'package:flutter/material.dart';

class AddToCartButton extends StatelessWidget {
  final VoidCallback onAddToCart;

  const AddToCartButton({super.key, required this.onAddToCart});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onAddToCart,
      icon: const Icon(Icons.shopping_cart, color: Colors.white),
      label: const Text(
        'Add to Cart',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue, // Blue background
        minimumSize: const Size(double.infinity, 50),
      ),
    );
  }
}
