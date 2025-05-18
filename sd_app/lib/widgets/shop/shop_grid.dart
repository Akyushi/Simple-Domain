import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../models/category_icon_model.dart'; // Import CategoryIconModel

class ShopGrid extends StatelessWidget {
  final List<Map<String, dynamic>> products;
  final ValueChanged<String> onFavoriteToggle;

  const ShopGrid({
    super.key,
    required this.products,
    required this.onFavoriteToggle,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final crossAxisCount = screenWidth > 1200
        ? 4
        : screenWidth > 800
            ? 3
            : 2; // Adjust columns based on screen width

    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.65,
      ),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        return GestureDetector(
          onTap: () {
            Navigator.pushNamed(
              context,
              '/product_details',
              arguments: product,
            );
          },
          child: Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: AspectRatio(
                        aspectRatio: 1, // Maintain a square aspect ratio
                        child: (product['image'] != null && product['image'].toString().startsWith('http'))
                            ? Image.network(
                                product['image'],
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return const Icon(Icons.broken_image, size: 100, color: Colors.grey);
                                },
                              )
                            : Image.asset(
                                product['image'] ?? 'assets/images/image.png',
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return const Icon(Icons.broken_image, size: 100, color: Colors.grey);
                                },
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    product['name']!.length > 30
                        ? '${product['name']!.substring(0, 30)}...' // Limit to 30 characters
                        : product['name']!,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color.fromARGB(255, 54, 114, 244),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '\u{20B1}${product['price']}', // Properly displayed peso sign
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      SvgPicture.asset(
                        CategoryIconModel.getIcon(product['category']!), // Fetch icon dynamically
                        height: 16,
                        width: 16,
                        placeholderBuilder: (context) => const CircularProgressIndicator(),
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(Icons.broken_image, size: 16, color: Colors.grey);
                        },
                      ),
                      const SizedBox(width: 4),
                      Text(
                        product['category']!.length > 15
                            ? '${product['category']!.substring(0, 15)}...' // Limit to 15 characters
                            : product['category']!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () {
                          onFavoriteToggle(product['id']); // Pass product ID to toggleFavorite
                        },
                        child: Icon(
                          product['isFavorite'] == true // Check if isFavorite is true
                              ? Icons.favorite // Filled heart if true
                              : Icons.favorite_border, // Unfilled heart if false
                          size: 24,
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
