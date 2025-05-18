import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TrendingProducts extends StatelessWidget {
  const TrendingProducts({super.key});

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
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('products')
              .orderBy('sales', descending: true)
              .limit(10)
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final trendingItems = snapshot.data!.docs;
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
                      return _buildTrendingItem(context, item);
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
                        return _buildTrendingItem(context, item);
                      },
                    ),
                  );
          },
        ),
      ],
    );
  }

  Widget _buildTrendingItem(BuildContext context, Map<String, dynamic> item) {
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
                      Text(
                        item['category'] ?? '',
                        style: const TextStyle(fontSize: 15, color: Colors.grey),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.only(left: 12, right: 12, bottom: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: const [
                  Icon(Icons.favorite_border, color: Colors.red, size: 28),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
