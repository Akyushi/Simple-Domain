import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/shop/shop_header.dart';
import '../widgets/shop/shop_filter.dart';
import '../widgets/shop/shop_grid.dart';
import '../utils/shared_data.dart';
import '../models/category_icon_model.dart';
import '../widgets/auth/login_popup.dart'; // Import LoginPopup

class ShopPage extends StatefulWidget {
  const ShopPage({super.key});

  @override
  State<ShopPage> createState() => _ShopPageState();
}

class _ShopPageState extends State<ShopPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String selectedCategory = 'All';
  String selectedSortOption = 'Release date';
  int? selectedRating; // null means all ratings
  bool _mounted = true;

  @override
  void dispose() {
    _mounted = false;
    super.dispose();
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

  Stream<List<Map<String, dynamic>>> get productsStream {
    final user = FirebaseAuth.instance.currentUser; // Get the current user

    return _firestore.collection('products').snapshots().asyncMap((snapshot) async {
      Set<String> favoriteIds = {};

      if (user != null) {
        final userFavorites = await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('favorites')
            .get(); // Get the user's favorites

        favoriteIds = userFavorites.docs.map((doc) => doc.id).toSet(); // Extract favorite product IDs
      }

      // Fetch average ratings for each product
      List<Map<String, dynamic>> products = await Future.wait(snapshot.docs.map((doc) async {
        final data = doc.data();
        // Fetch comments for rating
        final commentsSnap = await _firestore.collection('products').doc(doc.id).collection('comments').get();
        final ratings = commentsSnap.docs.map((c) => (c['rating'] ?? 0) as int).toList();
        final avgRating = ratings.isNotEmpty ? ratings.reduce((a, b) => a + b) / ratings.length : 0.0;
        return {
          'id': doc.id,
          'name': data['name'],
          'image': data['image'] ?? 'assets/images/image.png',
          'category': data['category'],
          'isFavorite': favoriteIds.contains(doc.id), // Check if the product is in the user's favorites
          'icon': CategoryIconModel.getIcon(data['category']),
          'price': data['price'],
          'description': data['description'], // Add the description field
          'avgRating': avgRating,
          'numRatings': ratings.length,
        };
      }).toList());

      return products;
    });
  }

  void toggleFavorite(String productId, Map<String, dynamic> product) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (!_mounted) return;
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (context) => const LoginPopup(),
      );
      return;
    }

    if (_mounted) {
      setState(() {
        product['isFavorite'] = !(product['isFavorite'] ?? false);
      });
    }

    final userFavoritesRef = _firestore
        .collection('users')
        .doc(user.uid)
        .collection('favorites');

    if (product['isFavorite']) {
      await userFavoritesRef.doc(productId).set(product);
      SharedData.wishlist.add(product);
    } else {
      await userFavoritesRef.doc(productId).delete();
      if (_mounted) {
        setState(() {
          product['isFavorite'] = false;
          SharedData.wishlist.removeWhere((item) => item['id'] == productId);
        });
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null && args.containsKey('category') && _mounted) {
      setState(() {
        selectedCategory = args['category'];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ShopHeader(),
      body: Column(
        children: [
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
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                await Future.delayed(const Duration(milliseconds: 700));
                setState(() {});
              },
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: productsStream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text('No products available.'));
                  }
                  var products = snapshot.data!.where((product) {
                    return (selectedCategory == 'All' || product['category'] == selectedCategory) &&
                      (selectedRating == null || (product['avgRating'] as double).round() == selectedRating);
                  }).toList();
                  // Sort products according to selectedSortOption
                  switch (selectedSortOption) {
                    case 'Price (low to high)':
                      products.sort((a, b) => (a['price'] as num).compareTo(b['price'] as num));
                      break;
                    case 'Price (high to low)':
                      products.sort((a, b) => (b['price'] as num).compareTo(a['price'] as num));
                      break;
                    case 'Release date':
                      products.sort((a, b) {
                        final aTime = a['createdAt'] ?? a['timestamp'];
                        final bTime = b['createdAt'] ?? b['timestamp'];
                        if (aTime == null && bTime == null) return 0;
                        if (aTime == null) return 1;
                        if (bTime == null) return -1;
                        final aMillis = aTime is Timestamp ? aTime.millisecondsSinceEpoch : (aTime is DateTime ? aTime.millisecondsSinceEpoch : 0);
                        final bMillis = bTime is Timestamp ? bTime.millisecondsSinceEpoch : (bTime is DateTime ? bTime.millisecondsSinceEpoch : 0);
                        return bMillis.compareTo(aMillis); // Newest first
                      });
                      break;
                    default:
                      break;
                  }
                  return ShopGrid(
                    products: products,
                    onFavoriteToggle: (productId) {
                      final product = products.firstWhere(
                        (p) => p['id'] == productId,
                        orElse: () => {'id': '', 'name': '', 'image': '', 'category': '', 'icon': '', 'price': 0, 'isFavorite': false}, // Return a valid empty map
                      );
                      if (product['id'] != '') {
                        toggleFavorite(productId, product);
                      }
                    },
                    showRatings: true,
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }
}
