import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class WishlistPage extends StatefulWidget {
  const WishlistPage({super.key});

  @override
  State<WishlistPage> createState() => _WishlistPageState();
}

class _WishlistPageState extends State<WishlistPage> {
  final Set<int> selectedItems = {}; // Track selected items for deletion
  bool showCheckboxes = false; // Control visibility of checkboxes

  void _toggleCheckboxes() {
    setState(() {
      showCheckboxes = !showCheckboxes; // Toggle checkbox visibility
      if (!showCheckboxes) {
        selectedItems.clear(); // Clear selections when hiding checkboxes
      }
    });
  }

  void _confirmDeletion(List<Map<String, dynamic>> wishlistItems) {
    if (selectedItems.isEmpty) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Deletion'),
        content: const Text('Are you sure you want to remove the selected items from the wishlist?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), // Cancel
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final user = FirebaseAuth.instance.currentUser;
              if (user == null) return;

              final wishlistRef = FirebaseFirestore.instance
                  .collection('users')
                  .doc(user.uid)
                  .collection('favorites');

              final itemsToDelete = selectedItems
                  .map((index) => wishlistItems[index]['id'])
                  .toList();

              try {
                for (var itemId in itemsToDelete) {
                  await wishlistRef.doc(itemId).delete();
                }
                setState(() {
                  selectedItems.clear();
                  showCheckboxes = false;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Selected items removed from wishlist')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error deleting items: $e')),
                );
              }

              Navigator.pop(context); // Close dialog
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Stream<List<Map<String, dynamic>>> get wishlistStream {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Stream.empty();
    }
    return FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('favorites')
        .snapshots()
        .asyncMap((snapshot) async {
          final List<Map<String, dynamic>> items = [];
          for (var doc in snapshot.docs) {
            // Get the product data from the products collection to ensure we have all fields
            final productDoc = await FirebaseFirestore.instance
                .collection('products')
                .doc(doc.id)
                .get();
            
            if (productDoc.exists) {
              final productData = productDoc.data()!;
              items.add({
                'id': doc.id,
                'name': productData['name'],
                'price': productData['price'],
                'description': productData['description'],
                'category': productData['category'],
                'image': productData['image'] ?? 'assets/images/image.png',
                'icon': productData['icon'],
                'tags': productData['tags'],
              });
            } else {
              // If product no longer exists, use the data from favorites
              final data = doc.data();
              items.add({
                'id': doc.id,
                ...data,
              });
            }
          }
          return items;
        });
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser; // Get the current user

    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text(
            'Wishlist',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 22,
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
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.favorite_border,
                size: 80,
                color: Colors.grey,
              ),
              const SizedBox(height: 20),
              const Text(
                'Please log in to view your wishlist.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Navigator.pushNamed(context, '/login'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Log in',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text(
          'Wishlist',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        centerTitle: true,
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: wishlistStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.favorite_border,
                    size: 80,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Your wishlist is empty. Start adding\nitems you love!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            );
          }
          final wishlistItems = snapshot.data!;
          return Column(
            children: [
              if (wishlistItems.isNotEmpty)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: showCheckboxes ? _toggleCheckboxes : () => setState(() => showCheckboxes = true),
                      child: Text(
                        showCheckboxes ? 'Cancel' : 'Delete',
                        style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                      ),
                    ),
                    if (showCheckboxes)
                      ElevatedButton(
                        onPressed: () => _confirmDeletion(wishlistItems),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        ),
                        child: const Text(
                          'Confirm',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16.0),
                  itemCount: wishlistItems.length,
                  itemBuilder: (context, index) {
                    final wishlistItem = wishlistItems[index];
                    return GestureDetector(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (showCheckboxes)
                            Checkbox(
                              value: selectedItems.contains(index),
                              onChanged: (isSelected) {
                                setState(() {
                                  if (isSelected == true) {
                                    selectedItems.add(index);
                                  } else {
                                    selectedItems.remove(index);
                                  }
                                });
                              },
                            ),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: (wishlistItem['image'] != null && wishlistItem['image'].toString().startsWith('http'))
                                ? Image.network(
                                    wishlistItem['image'],
                                    width: 100,
                                    height: 100,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return const Icon(Icons.broken_image, size: 100, color: Colors.grey);
                                    },
                                  )
                                : Image.asset(
                                    wishlistItem['image'] ?? 'assets/images/image.png',
                                    width: 100,
                                    height: 100,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return const Icon(Icons.broken_image, size: 100, color: Colors.grey);
                                    },
                                  ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  wishlistItem['name'],
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '₱${wishlistItem['price']}',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                  separatorBuilder: (context, index) => const Divider(
                    thickness: 1,
                    color: Colors.grey,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
