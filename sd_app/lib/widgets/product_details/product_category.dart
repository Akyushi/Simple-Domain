import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class ProductCategory extends StatelessWidget {
  final String? icon;
  final String? category;

  const ProductCategory({super.key, required this.icon, required this.category});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SvgPicture.asset(
          icon ?? '',
          height: 24,
          width: 24,
          placeholderBuilder: (context) => const CircularProgressIndicator(),
          errorBuilder: (context, error, stackTrace) {
            return const Icon(Icons.broken_image, size: 24, color: Colors.grey);
          },
        ),
        const SizedBox(width: 8),
        Text(
          category ?? '',
          style: const TextStyle(
            fontSize: 16,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }
}
