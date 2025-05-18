import 'package:flutter/material.dart';

class ProductImage extends StatelessWidget {
  final String? image;

  const ProductImage({super.key, required this.image});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: (image != null && image!.startsWith('http'))
            ? Image.network(
                image ?? 'assets/images/image.png',
                fit: BoxFit.cover,
                width: double.infinity,
                height: 200,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(Icons.broken_image, size: 200, color: Colors.grey);
                },
              )
            : Image.asset(
                image ?? 'assets/images/image.png',
                fit: BoxFit.cover,
                width: double.infinity,
                height: 200,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(Icons.broken_image, size: 200, color: Colors.grey);
                },
              ),
      ),
    );
  }
}
