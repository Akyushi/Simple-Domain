import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TrendingProducts extends StatelessWidget {
  const TrendingProducts({super.key});

  Future<Set<String>> _getFavoriteIds() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return {};
    final favs = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('favorites')
        .get();
    return favs.docs.map((doc) => doc.id).toSet();
  }

  @override
  Widget build(BuildContext context) {
    final isWideScreen = MediaQuery.of(context).size.width > 600;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 20),
          child: Text(
            'TOP SELLING',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 16),
        FutureBuilder<Set<String>>(
          future: _getFavoriteIds(),
          builder: (context, favSnapshot) {
            return StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('products')
                  .orderBy('sales', descending: true)
                  .limit(10)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData || favSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final trendingItems = snapshot.data!.docs;
                final favoriteIds = favSnapshot.data ?? {};
                if (trendingItems.isEmpty) {
                  return const Center(child: Text('No trending products yet.'));
                }
                return isWideScreen
                    ? GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 0.8,
                        ),
                        itemCount: trendingItems.length,
                        itemBuilder: (context, index) {
                          final doc = trendingItems[index];
                          final item = doc.data() as Map<String, dynamic>;
                          item['id'] = doc.id;
                          final isFavorite = favoriteIds.contains(doc.id);
                          return TrendingItemWidget(item: item, isFavorite: isFavorite);
                        },
                      )
                    : SizedBox(
                        height: 300,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: trendingItems.length,
                          itemBuilder: (context, index) {
                            final doc = trendingItems[index];
                            final item = doc.data() as Map<String, dynamic>;
                            item['id'] = doc.id;
                            final isFavorite = favoriteIds.contains(doc.id);
                            return TrendingItemWidget(item: item, isFavorite: isFavorite);
                          },
                        ),
                      );
              },
            );
          },
        ),
      ],
    );
  }
}

class TrendingItemWidget extends StatefulWidget {
  final Map<String, dynamic> item;
  final bool isFavorite;
  const TrendingItemWidget({super.key, required this.item, required this.isFavorite});

  @override
  State<TrendingItemWidget> createState() => _TrendingItemWidgetState();
}

class _TrendingItemWidgetState extends State<TrendingItemWidget> {
  late bool _isFavorite;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _isFavorite = widget.isFavorite;
  }

  Future<void> _toggleFavorite() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (context) => const SizedBox(
          height: 200,
          child: Center(child: Text('Please log in to use wishlist.')),
        ),
      );
      return;
    }
    setState(() => _loading = true);
    final favRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('favorites')
        .doc(widget.item['id']);
    if (_isFavorite) {
      await favRef.delete();
    } else {
      await favRef.set(widget.item);
    }
    setState(() {
      _isFavorite = !_isFavorite;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(
          context,
          '/product_details',
          arguments: {
            'id': item['id'],
            'name': item['name'],
            'image': item['image'],
            'price': item['price'],
            'category': item['category'],
            'description': item['description'],
            'icon': item['icon'],
            'sellerId': item['sellerId'],
          },
        );
      },
      child: Container(
        width: 220,
        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.10),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
              child: (item['image'] != null && item['image'].toString().startsWith('http'))
                  ? Image.network(
                      item['image'],
                      height: 140,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(Icons.broken_image, size: 80, color: Colors.grey);
                      },
                    )
                  : Image.asset(
                      item['image'] ?? 'assets/images/image.png',
                      height: 140,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(Icons.broken_image, size: 80, color: Colors.grey);
                      },
                    ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['name'] ?? '',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Text('₱', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                      Text(
                        item['price'] != null ? item['price'].toString() : '',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.restaurant, size: 18, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          item['category'] ?? '',
                          style: const TextStyle(fontSize: 15, color: Colors.grey),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      _loading
                          ? const SizedBox(
                              width: 28,
                              height: 28,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : IconButton(
                              icon: Icon(
                                _isFavorite ? Icons.favorite : Icons.favorite_border,
                                color: Colors.red,
                                size: 22,
                              ),
                              onPressed: _toggleFavorite,
                              tooltip: _isFavorite ? 'Remove from wishlist' : 'Add to wishlist',
                            ),
                    ],
                  ),
                ],
              ),
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}
