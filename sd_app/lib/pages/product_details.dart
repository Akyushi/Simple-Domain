import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/product_details/product_image.dart';
import '../widgets/product_details/product_name.dart';
import '../widgets/product_details/product_category.dart';
import '../widgets/auth/login_popup.dart'; // Import the reusable LoginPopup widget
import '../pages/checkout_page.dart'; // Add this import

class ProductDetailsPage extends StatefulWidget {
  final Map<String, dynamic> product;

  const ProductDetailsPage({super.key, required this.product});

  @override
  State<ProductDetailsPage> createState() => _ProductDetailsPageState();
}

class _ProductDetailsPageState extends State<ProductDetailsPage> {
  int quantity = 1;
  int? _filterRating;

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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('Filter by rating: '),
            DropdownButton<int?>(
              value: _filterRating,
              hint: const Text('All'),
              items: [
                const DropdownMenuItem<int?>(value: null, child: Text('All')),
                ...List.generate(5, (i) => DropdownMenuItem<int?>(
                  value: 5 - i,
                  child: Row(
                    children: [
                      ...List.generate(5, (j) => Icon(j < 5 - i ? Icons.star : Icons.star_border, color: Colors.amber, size: 16)),
                      Text(' ${5 - i}')
                    ],
                  ),
                )),
              ],
              onChanged: (val) => setState(() => _filterRating = val),
            ),
          ],
        ),
        StreamBuilder<QuerySnapshot>(
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
            final comments = snapshot.data!.docs.where((doc) => _filterRating == null || doc['rating'] == _filterRating).toList();
            if (comments.isEmpty) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 16.0),
                child: Text('No comments for this rating.', style: TextStyle(color: Colors.grey)),
              );
            }
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
                                      Row(
                                        children: [
                                          ...List.generate(5, (i) => Icon(
                                            i < (data['rating'] ?? 0) ? Icons.star : Icons.star_border,
                                            color: Colors.amber,
                                            size: 16,
                                          )),
                                        ],
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
        ),
      ],
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
            GestureDetector(
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) => Dialog(
                    backgroundColor: Colors.transparent,
                    child: InteractiveViewer(
                      child: ProductImage(image: product['image']),
                    ),
                  ),
                );
              },
              child: ProductImage(image: product['image']),
            ),
            _buildAverageRating(product['id'] is String && product['id'] != null ? product['id'] : ''),
            const SizedBox(height: 16),
            ProductName(name: product['name']),
            FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance.collection('users').doc(product['sellerId']).get(),
              builder: (context, snapshot) {
                if (!snapshot.hasData || !snapshot.data!.exists) {
                  return const SizedBox.shrink();
                }
                final seller = snapshot.data!.data() as Map<String, dynamic>?;
                final avatarUrl = seller?['avatarUrl'] ?? '';
                final nickname = seller?['nickname'] ?? 'Seller';
                return Padding(
                  padding: const EdgeInsets.only(top: 4, bottom: 8),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundImage: avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
                        child: avatarUrl.isEmpty ? const Icon(Icons.person) : null,
                      ),
                      const SizedBox(width: 8),
                      Text(nickname, style: const TextStyle(fontWeight: FontWeight.w500)),
                    ],
                  ),
                );
              },
            ),
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
                        fontSize: 18,
                        color: (product['description'] != null && product['description'].toString().isNotEmpty)
                            ? Colors.black87
                            : Colors.black54,
                        fontStyle: (product['description'] != null && product['description'].toString().isNotEmpty)
                            ? FontStyle.normal
                            : FontStyle.italic,
                        fontWeight: FontWeight.w500,
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
            _buildComments(product['id'] is String && product['id'] != null ? product['id'] : ''),
            const SizedBox(height: 24),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  Text(
                    '₱${(product['price'] * quantity).toStringAsFixed(2)}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 28, color: Colors.green),
                  ),
                ],
              ),
            ),
            Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove),
                        onPressed: quantity > 1 ? () => setState(() => quantity--) : null,
                      ),
                      Text('$quantity', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: () => setState(() => quantity++),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 48, // Increased height for better touch area
                          child: ElevatedButton(
                            onPressed: () => _addToCart(product, quantity),
                            style: ElevatedButton.styleFrom(
                              textStyle: const TextStyle(fontSize: 15), // Adjusted text size
                              padding: const EdgeInsets.symmetric(vertical: 10), // Adjusted padding
                            ),
                            child: const Text('Add to Cart'),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: SizedBox(
                          height: 48,
                          child: ElevatedButton(
                            onPressed: () {
                              // Navigate to checkout page with this product and quantity
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => CheckoutPage(
                                    cartItems: [
                                      {
                                        'product': product,
                                        'quantity': quantity,
                                      }
                                    ],
                                  ),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                            ),
                            child: const Text('Buy Now'),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
