import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/product_details/product_image.dart';
import '../widgets/product_details/product_name.dart';
import '../widgets/product_details/product_category.dart';
import '../widgets/product_details/product_price.dart';
import '../widgets/product_details/quantity_selector.dart';
import '../widgets/product_details/add_to_cart_button.dart';
import '../widgets/auth/login_popup.dart'; // Import the reusable LoginPopup widget

class ProductDetailsPage extends StatefulWidget {
  final Map<String, dynamic> product;

  const ProductDetailsPage({super.key, required this.product});

  @override
  State<ProductDetailsPage> createState() => _ProductDetailsPageState();
}

class _ProductDetailsPageState extends State<ProductDetailsPage> {
  int quantity = 1;

  void _addToCart(Map<String, dynamic> product, int quantity) async {
    final user = FirebaseAuth.instance.currentUser; // Get the current user
    if (user == null) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        backgroundColor: Colors.transparent,
        builder: (context) => const LoginPopup(), // Show the reusable LoginPopup
      );
      return;
    }

    final cartRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('cart'); // Reference to the user's cart collection

    await cartRef.doc(product['id']).set({
      'productId': product['id'],
      'quantity': quantity,
      'sellerId': product['sellerId'], // Ensure sellerId is saved in cart
    }); // Save productId, quantity, and sellerId to Firestore

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Added to cart successfully!')),
    );
  }

  Widget _buildAverageRating(String productId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('products')
          .doc(productId)
          .collection('comments')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Row(
            children: [
              ...List.generate(5, (i) => Icon(Icons.star_border, color: Colors.amber, size: 22)),
              const SizedBox(width: 8),
              const Text('0.0', style: TextStyle(fontWeight: FontWeight.bold)),
              const Text(' (0 reviews)', style: TextStyle(color: Colors.grey)),
            ],
          );
        }
        final comments = snapshot.data!.docs;
        final ratings = comments.map((doc) => (doc['rating'] ?? 0) as int).toList();
        final avg = ratings.isNotEmpty ? ratings.reduce((a, b) => a + b) / ratings.length : 0.0;
        return Row(
          children: [
            ...List.generate(5, (i) => Icon(
              i < avg.round() ? Icons.star : Icons.star_border,
              color: Colors.amber,
              size: 22,
            )),
            const SizedBox(width: 8),
            Text(avg.toStringAsFixed(1), style: const TextStyle(fontWeight: FontWeight.bold)),
            Text(' (${ratings.length} reviews)', style: const TextStyle(color: Colors.grey)),
          ],
        );
      },
    );
  }

  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return '';
    final dt = timestamp.toDate();
    return '${dt.day.toString().padLeft(2, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.year} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildComments(String productId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('products')
          .doc(productId)
          .collection('comments')
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16.0),
            child: Text('No comments yet.', style: TextStyle(color: Colors.grey)),
          );
        }
        final comments = snapshot.data!.docs;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: Text('Comments', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
            ...[for (int i = 0; i < comments.length; i++) ...[
              if (i > 0) const Divider(),
              (() {
                final doc = comments[i];
                final data = doc.data() as Map<String, dynamic>? ?? {};
                final userName = data['userName'] ?? 'User';
                final comment = data['comment'] ?? '';
                final photoUrls = (data['photoUrls'] as List?)?.whereType<String>().toList() ?? [];
                final userPhotoUrl = data['userPhotoUrl'];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              radius: 18,
                              backgroundImage: userPhotoUrl != null ? NetworkImage(userPhotoUrl) : null,
                              child: userPhotoUrl == null ? const Icon(Icons.person) : null,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        userName,
                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                      const SizedBox(width: 8),
                                      if (data['timestamp'] != null)
                                        Text(
                                          _formatTimestamp(data['timestamp']),
                                          style: const TextStyle(
                                            color: Colors.grey,
                                            fontSize: 12,
                                          ),
                                        ),
                                    ],
                                  ),
                                  const Text(
                                    'Via App',
                                    style: TextStyle(color: Colors.grey, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(comment),
                        if (photoUrls.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          SizedBox(
                            height: 60,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: photoUrls.length,
                              separatorBuilder: (context, i) => const SizedBox(width: 8),
                              itemBuilder: (context, i) => GestureDetector(
                                onTap: () {
                                  showDialog(
                                    context: context,
                                    builder: (context) {
                                      int currentIndex = i;
                                      return StatefulBuilder(
                                        builder: (context, setState) {
                                          return Dialog(
                                            backgroundColor: Colors.transparent,
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Container(
                                                  constraints: BoxConstraints(maxHeight: 400, maxWidth: 400),
                                                  child: ClipRRect(
                                                    borderRadius: BorderRadius.circular(16),
                                                    child: Image.network(
                                                      photoUrls[currentIndex],
                                                      fit: BoxFit.contain,
                                                      errorBuilder: (c, e, s) => const Icon(Icons.broken_image, size: 120),
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(height: 16),
                                                Row(
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  children: [
                                                    IconButton(
                                                      icon: const Icon(Icons.arrow_back_ios),
                                                      onPressed: currentIndex > 0
                                                          ? () => setState(() => currentIndex--)
                                                          : null,
                                                    ),
                                                    const SizedBox(width: 24),
                                                    IconButton(
                                                      icon: const Icon(Icons.arrow_forward_ios),
                                                      onPressed: currentIndex < photoUrls.length - 1
                                                          ? () => setState(() => currentIndex++)
                                                          : null,
                                                    ),
                                                  ],
                                                ),
                                                TextButton(
                                                  onPressed: () => Navigator.of(context).pop(),
                                                  child: const Text('Close'),
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                      );
                                    },
                                  );
                                },
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    photoUrls[i],
                                    width: 60,
                                    height: 60,
                                    fit: BoxFit.cover,
                                    errorBuilder: (c, e, s) => const Icon(Icons.broken_image),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              })(),
            ]],
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    if (product['id'] == null || (product['id'] is String && (product['id'] as String).isEmpty)) {
      return Scaffold(
        appBar: AppBar(title: const Text('Product Details')),
        body: const Center(child: Text('Error: Product not found or missing ID.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(product['name']),
        centerTitle: true,
        backgroundColor: const Color.fromARGB(255, 195, 205, 253),
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(16),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ProductImage(image: product['image']),
            _buildAverageRating(product['id'] is String && product['id'] != null ? product['id'] : ''),
            const SizedBox(height: 16),
            ProductName(name: product['name']),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Description',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      (product['description'] != null && product['description'].toString().isNotEmpty)
                          ? product['description']
                          : 'No description available.',
                      style: TextStyle(
                        fontSize: 15,
                        color: (product['description'] != null && product['description'].toString().isNotEmpty)
                            ? Colors.black87
                            : Colors.black54,
                        fontStyle: (product['description'] != null && product['description'].toString().isNotEmpty)
                            ? FontStyle.normal
                            : FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            ProductCategory(
              icon: product['icon'],
              category: product['category'],
            ),
            const SizedBox(height: 16),
            ProductPrice(price: '${product['price']}'), // Updated to peso
            const SizedBox(height: 16),
            QuantitySelector(
              quantity: quantity,
              onIncrease: () => setState(() => quantity++),
              onDecrease: () => setState(() {
                if (quantity > 1) quantity--;
              }),
            ),
            const SizedBox(height: 24),
            _buildComments(product['id'] is String && product['id'] != null ? product['id'] : ''),
            const SizedBox(height: 24),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Row(
          children: [
            Expanded(
              child: AddToCartButton(
                onAddToCart: () => _addToCart(product, quantity),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  // Handle buy now action
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: const Text(
                  'Buy Now',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
