import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../widgets/bottom_navbar.dart';
import '../utils/shared_data.dart'; // Import SharedData for wishlist

class ShopPage extends StatefulWidget {
  const ShopPage({super.key});

  @override
  State<ShopPage> createState() => _ShopPageState();
}

class _ShopPageState extends State<ShopPage> {
  final List<Map<String, dynamic>> products = [
    {'name': 'Product 1', 'image': 'assets/images/image.png', 'isFavorite': false, 'category': 'Hardware', 'icon': 'assets/icons/electronic.svg'},
    {'name': 'Product 2', 'image': 'assets/images/image.png', 'isFavorite': false, 'category': 'Sports', 'icon': 'assets/icons/sports.svg'},
    {'name': 'Product 3', 'image': 'assets/images/image.png', 'isFavorite': false, 'category': 'Accessories', 'icon': 'assets/icons/clothing.svg'},
    {'name': 'Product 4', 'image': 'assets/images/image.png', 'isFavorite': false, 'category': 'Hardware', 'icon': 'assets/icons/electronic.svg'},
    {'name': 'Product 5', 'image': 'assets/images/image.png', 'isFavorite': false, 'category': 'Books', 'icon': 'assets/icons/book.svg'},
    {'name': 'Product 6', 'image': 'assets/images/image.png', 'isFavorite': false, 'category': 'Hardware', 'icon': 'assets/icons/electronic.svg'},
    {'name': 'Product 7', 'image': 'assets/images/image.png', 'isFavorite': false, 'category': 'Accessories', 'icon': 'assets/icons/clothing.svg'},
    {'name': 'Product 8', 'image': 'assets/images/image.png', 'isFavorite': false, 'category': 'Hardware', 'icon': 'assets/icons/electronic.svg'},
  ];

  String selectedCategory = 'All';

  List<Map<String, dynamic>> get filteredProducts {
    return products.where((product) {
      return selectedCategory == 'All' || product['category'] == selectedCategory;
    }).toList();
  }

  void toggleFavorite(String productName) {
    final originalIndex = products.indexWhere((product) => product['name'] == productName);
    if (originalIndex != -1) {
      setState(() {
        products[originalIndex]['isFavorite'] = !products[originalIndex]['isFavorite'];
        if (products[originalIndex]['isFavorite']) {
          SharedData.wishlist.add(products[originalIndex]); // Add to shared wishlist
        } else {
          SharedData.wishlist.removeWhere((item) => item['name'] == products[originalIndex]['name']); // Remove from shared wishlist
        }
      });
    }
  }

  @override
  void initState() {
    super.initState();
    // Sync product states with the shared wishlist
    for (var product in products) {
      product['isFavorite'] = SharedData.wishlist.any((item) => item['name'] == product['name']);
    }
  }

  void showCategoryFilterDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Filter by Category',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Column(
                children: ['All', 'Hardware', 'Accessories', 'Books', 'Kitchen', 'Sports']
                    .map((category) => RadioListTile<String>(
                          title: Text(category),
                          value: category,
                          groupValue: selectedCategory,
                          onChanged: (value) {
                            setState(() {
                              selectedCategory = value!;
                            });
                            Navigator.pop(context);
                          },
                        ))
                    .toList(),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Shop',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color.fromARGB(255, 195, 205, 253),
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(16),
          ),
        ),
        actions: [
          IconButton(
            icon: SvgPicture.asset('assets/icons/filter.svg', height: 24, width: 24),
            onPressed: showCategoryFilterDialog,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2, // 2 products per row
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 0.65, // Adjusted aspect ratio for product cards
          ),
          itemCount: filteredProducts.length,
          itemBuilder: (context, index) {
            final product = filteredProducts[index];
            return GestureDetector(
              onTap: () {
                Navigator.pushNamed(
                  context,
                  '/product_details',
                  arguments: product, // Pass the product as an argument
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
                          child: Image.asset(
                            product['image']!,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(Icons.broken_image, size: 100, color: Colors.grey);
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        product['name']!,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color.fromARGB(255, 54, 114, 244), // Title color
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        '\$44.99', // Placeholder price
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          SvgPicture.asset(
                            product['icon']!,
                            height: 16,
                            width: 16,
                            placeholderBuilder: (context) => const CircularProgressIndicator(),
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(Icons.broken_image, size: 16, color: Colors.grey);
                            },
                          ),
                          const SizedBox(width: 4),
                          Text(
                            product['category']!,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                          const Spacer(),
                          GestureDetector(
                            onTap: () => toggleFavorite(product['name']),
                            child: Icon(
                              product['isFavorite']
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              size: 20,
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
        ),
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: 3,
        onTap: (index) => Navigator.pushNamed(context, ['/home', '/cart', '/wishlist', '/shop', '/profile'][index]),
      ),
    );
  }
}
