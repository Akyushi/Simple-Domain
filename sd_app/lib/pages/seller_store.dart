import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/shop/shop_filter.dart';

class SellerStorePage extends StatelessWidget {
  final String sellerId;
  const SellerStorePage({Key? key, required this.sellerId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return _SellerStorePageBody(sellerId: sellerId);
  }
}

class _SellerStorePageBody extends StatefulWidget {
  final String sellerId;
  const _SellerStorePageBody({Key? key, required this.sellerId}) : super(key: key);
  @override
  State<_SellerStorePageBody> createState() => _SellerStorePageBodyState();
}

class _SellerStorePageBodyState extends State<_SellerStorePageBody> {
  String selectedSortOption = 'Release date';
  String selectedCategory = 'All';
  int? selectedRating;
  bool _mounted = true;

  @override
  void dispose() {
    _mounted = false;
    super.dispose();
  }

  Future<Map<String, dynamic>?> _fetchSellerProfile() async {
    if (!_mounted) return null;
    // Fetch from users for avatar/nickname, and seller_profile for cover image
    final userDoc = await FirebaseFirestore.instance.collection('users').doc(widget.sellerId).get();
    final sellerProfileDoc = await FirebaseFirestore.instance.collection('seller_profile').doc(widget.sellerId).get();
    if (!_mounted) return null;
    if (!userDoc.exists) return null;
    final userData = userDoc.data()!;
    final profileData = sellerProfileDoc.data() ?? {};
    return {
      'nickname': userData['nickname'] ?? 'Seller',
      'avatarUrl': userData['avatarUrl'] ?? '',
      'coverImageUrl': profileData['coverImageUrl'] ?? '',
    };
  }

  Stream<List<Map<String, dynamic>>> _sellerProductsStream() {
    return FirebaseFirestore.instance
        .collection('products')
        .where('sellerId', isEqualTo: widget.sellerId)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data();
              return {
                'id': doc.id,
                'name': data['name'],
                'image': data['image'] ?? 'assets/images/image.png',
                'category': data['category'],
                'price': data['price'],
                'description': data['description'],
              };
            }).toList());
  }

  void _handleSortChange(String value) {
    if (_mounted) {
      setState(() => selectedSortOption = value);
    }
  }

  void _handleCategoryChange(String value) {
    if (_mounted) {
      setState(() => selectedCategory = value);
    }
  }

  void _handleRatingChange(int? val) {
    if (_mounted) {
      setState(() => selectedRating = val);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Seller Store',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        centerTitle: true,
      ),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: _fetchSellerProfile(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final seller = snapshot.data;
          if (seller == null) {
            return const Center(child: Text('Seller not found.'));
          }
          return RefreshIndicator(
            onRefresh: () async {
              await Future.delayed(const Duration(milliseconds: 700));
              setState(() {});
            },
            child: ListView(
              children: [
                // Cover photo section
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      height: 180,
                      width: double.infinity,
                      color: Colors.grey[300],
                      child: seller['coverImageUrl'] != null && seller['coverImageUrl'].toString().isNotEmpty
                          ? Image.network(seller['coverImageUrl'], fit: BoxFit.cover)
                          : Container(color: Colors.white),
                    ),
                    // Profile image (centered, frontmost)
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: -56,
                      child: Center(
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 4),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black12,
                                blurRadius: 8,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: CircleAvatar(
                            radius: 48,
                            backgroundColor: Colors.white,
                            child: CircleAvatar(
                              radius: 44,
                              backgroundImage: seller['avatarUrl'] != null && seller['avatarUrl'].toString().isNotEmpty
                                  ? NetworkImage(seller['avatarUrl'])
                                  : const AssetImage('assets/images/default_profile.png') as ImageProvider,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 72),
                // Seller name
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        seller['nickname'] ?? 'Seller',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 24,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Seller',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                // Sorting and filter
                ShopFilter(
                  selectedSortOption: selectedSortOption,
                  onSortChanged: _handleSortChange,
                  selectedCategory: selectedCategory,
                  onCategoryChanged: _handleCategoryChange,
                  sortOptions: const [
                    'Release date',
                    'Price (high to low)',
                    'Price (low to high)',
                  ],
                  selectedRating: selectedRating,
                  onRatingChanged: _handleRatingChange,
                ),
                // Products grid
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: StreamBuilder<List<Map<String, dynamic>>>(
                    stream: _sellerProductsStream(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      var products = snapshot.data ?? [];
                      // Filter by category
                      if (selectedCategory != 'All') {
                        products = products.where((p) => p['category'] == selectedCategory).toList();
                      }
                      // Sort
                      switch (selectedSortOption) {
                        case 'Price (low to high)':
                          products.sort((a, b) => (a['price'] as num).compareTo(b['price'] as num));
                          break;
                        case 'Price (high to low)':
                          products.sort((a, b) => (b['price'] as num).compareTo(a['price'] as num));
                          break;
                        case 'Title (A-Z)':
                          products.sort((a, b) => (a['name'] as String).compareTo(b['name'] as String));
                          break;
                        case 'Title (Z-A)':
                          products.sort((a, b) => (b['name'] as String).compareTo(a['name'] as String));
                          break;
                        case 'Release date':
                          // If you have a timestamp field, sort by it here
                          break;
                        case 'Featured':
                        default:
                          break;
                      }
                      if (products.isEmpty) {
                        return const Center(child: Text('No products found for this seller.'));
                      }
                      return GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.7,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
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
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ClipRRect(
                                    borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(12),
                                      topRight: Radius.circular(12),
                                    ),
                                    child: SizedBox(
                                      height: 120, // Set a fixed height for the image area
                                      child: product['image'] != null && product['image'].toString().startsWith('http')
                                          ? Image.network(
                                              product['image'],
                                              width: double.infinity,
                                              height: 120,
                                              fit: BoxFit.contain,
                                              errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, size: 80, color: Colors.grey),
                                            )
                                          : Image.asset(
                                              product['image'] ?? 'assets/images/image.png',
                                              width: double.infinity,
                                              height: 120,
                                              fit: BoxFit.contain,
                                              errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, size: 80, color: Colors.grey),
                                            ),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          product['name'] ?? 'Product',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '₱${product['price']?.toStringAsFixed(2) ?? 'N/A'}',
                                          style: const TextStyle(
                                            color: Colors.green,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        if (product['category'] != null)
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: Colors.blue[100],
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              product['category'],
                                              style: const TextStyle(fontSize: 12, color: Colors.blue),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(height: 100),
              ],
            ),
          );
        },
      ),
    );
  }
}