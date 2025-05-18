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
  String selectedSortOption = 'Featured';

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

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'name': data['name'],
          'image': data['image'] ?? 'assets/images/image.png',
          'category': data['category'],
          'isFavorite': favoriteIds.contains(doc.id), // Check if the product is in the user's favorites
          'icon': CategoryIconModel.getIcon(data['category']),
          'price': data['price'],
          'description': data['description'], // Add the description field
        };
      }).toList();
    });
  }

  void toggleFavorite(String productId, Map<String, dynamic> product) async {
    final user = FirebaseAuth.instance.currentUser; // Get the current user
    if (user == null) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (context) => const LoginPopup(), // Use LoginPopup directly
      );
      return;
    }

    setState(() {
      product['isFavorite'] = !(product['isFavorite'] ?? false); // Toggle isFavorite
    });

    final userFavoritesRef = _firestore
        .collection('users')
        .doc(user.uid)
        .collection('favorites'); // Reference to the user's favorites collection

    if (product['isFavorite']) {
      await userFavoritesRef.doc(productId).set(product); // Save to Firestore
      SharedData.wishlist.add(product); // Add to local wishlist
    } else {
      await userFavoritesRef.doc(productId).delete(); // Remove from Firestore
      setState(() {
        product['isFavorite'] = false; // Unfill the heart icon
        SharedData.wishlist.removeWhere((item) => item['id'] == productId); // Remove from local wishlist
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null && args.containsKey('category')) {
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
          Align(
            alignment: Alignment.centerLeft,
            child: ShopFilter(
              selectedSortOption: selectedSortOption,
              onSortChanged: (value) => setState(() => selectedSortOption = value),
              selectedCategory: selectedCategory,
              onCategoryChanged: (value) => setState(() => selectedCategory = value),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: productsStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('No products available.'));
                }
                final products = snapshot.data!.where((product) {
                  return selectedCategory == 'All' || product['category'] == selectedCategory;
                }).toList();
                // Sort products according to selectedSortOption
                switch (selectedSortOption) {
                  case 'Price (low to high)':
                    products.sort((a, b) => (a['price'] as num).compareTo(b['price'] as num));
                    break;
                  case 'Price (high to low)':
                    products.sort((a, b) => (b['price'] as num).compareTo(a['price'] as num));
                    break;
                  case 'Title (A-Z)':
                    products.sort((a, b) => (a['name'] as String).toLowerCase().compareTo((b['name'] as String).toLowerCase()));
                    break;
                  case 'Title (Z-A)':
                    products.sort((a, b) => (b['name'] as String).toLowerCase().compareTo((a['name'] as String).toLowerCase()));
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
                  case 'Featured':
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
                );
              },
            ),
          ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }
}
