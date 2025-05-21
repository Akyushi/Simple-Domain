import 'package:flutter/material.dart';
import '../models/category_model.dart';
import '../models/ads_model.dart';
import '../widgets/home/search_bar.dart' as custom; // Alias the custom SearchBar import
import '../widgets/home/categories.dart';
import '../widgets/home/featured_products.dart';
import '../widgets/home/trending_products.dart'; // Import TrendingProducts widget
import 'admin_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'notification_page.dart';
import 'admin_login.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final List<CategoryModel> categories;
  late final List<AdsModel> ads;
  final List<String> searchSuggestions = ['Shoes', 'Bags', 'Watches', 'Clothes', 'Accessories'];
  List<String> filteredSuggestions = [];
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  int _secretTapCount = 0;
  DateTime? _lastTapTime;

  @override
  void initState() {
    super.initState();
    categories = CategoryModel.getCategories();
    ads = AdsModel.getAds();
    _searchController.addListener(_filterSuggestions);
    _searchFocusNode.addListener(() {
      if (!_searchFocusNode.hasFocus) {
        setState(() {
          filteredSuggestions.clear();
        });
      }
    });
  }

  void _filterSuggestions() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      filteredSuggestions = searchSuggestions
          .where((suggestion) => suggestion.toLowerCase().contains(query))
          .toList();
    });
  }

  void _handleSecretTap() {
    final now = DateTime.now();
    if (_lastTapTime == null || now.difference(_lastTapTime!) > const Duration(seconds: 2)) {
      _secretTapCount = 1;
    } else {
      _secretTapCount++;
    }
    _lastTapTime = now;
    if (_secretTapCount == 9) {
      _secretTapCount = 0;
      Navigator.pushNamed(context, '/admin-login');
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _showNotifications() {
    final user = FirebaseAuth.instance.currentUser;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SizedBox(
        height: 400,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text('Notifications', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
            ),
            const Divider(),
            Expanded(
              child: user == null
                  ? const Center(child: Text('Please log in to see notifications.'))
                  : StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('users')
                          .doc(user.uid)
                          .collection('notifications')
                          .orderBy('timestamp', descending: true)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                          return const Center(child: Text('No notifications yet.'));
                        }
                        final notifications = snapshot.data!.docs;
                        return ListView.separated(
                          itemCount: notifications.length,
                          separatorBuilder: (context, index) => const Divider(),
                          itemBuilder: (context, index) {
                            final data = notifications[index].data() as Map<String, dynamic>;
                            final title = data['title'] ?? '';
                            final body = data['body'] ?? '';
                            final timestamp = data['timestamp'] as Timestamp?;
                            final date = timestamp?.toDate();
                            return ListTile(
                              leading: const Icon(Icons.notifications),
                              title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(body),
                                  if (date != null)
                                    Text(
                                      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}',
                                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                                    ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const NotificationPage()),
                    );
                  },
                  child: const Text('Show more'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isWideScreen = MediaQuery.of(context).size.width > 600;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: GestureDetector(
          onTap: _handleSecretTap,
          child: const Text(
            'Simple Domain',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        centerTitle: true,
        actions: [
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseAuth.instance.currentUser == null
                ? null
                : FirebaseFirestore.instance
                    .collection('users')
                    .doc(FirebaseAuth.instance.currentUser!.uid)
                    .collection('notifications')
                    .where('read', isEqualTo: false)
                    .snapshots(),
            builder: (context, snapshot) {
              int unreadCount = 0;
              if (snapshot.hasData) {
                unreadCount = snapshot.data!.docs.length;
              }
              return Material(
                color: Colors.transparent,
                child: Stack(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.notifications),
                      onPressed: _showNotifications,
                      tooltip: 'Notifications',
                    ),
                    if (unreadCount > 0)
                      Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 20,
                            minHeight: 20,
                          ),
                          child: Text(
                            unreadCount > 99 ? '99+' : unreadCount.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: ListView(
        children: [
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isWideScreen ? 40 : 20,
            ),
            child: Column(
              children: [
                custom.SearchBar(
                  searchController: _searchController,
                  searchFocusNode: _searchFocusNode,
                  onSubmitted: (query) {
                    if (query.isNotEmpty) {
                      Navigator.pushNamed(context, '/search', arguments: query);
                    }
                  },
                ),
                const SizedBox(height: 30),
                Categories(
                  categories: categories,
                  onCategorySelected: (selectedCategory) {
                    Navigator.pushNamed(
                      context,
                      '/shop',
                      arguments: {'category': selectedCategory}, // Pass selected category
                    );
                  },
                ),
                const SizedBox(height: 30),
                FeaturedProducts(ads: ads),
                const SizedBox(height: 30),
                TrendingProducts(
                ), // Added Trending Products section
                const SizedBox(height: 30),
              ],
            ),
          ),
          // Footer Section
          Container(
            color: const Color.fromARGB(255, 195, 205, 253),
            padding: const EdgeInsets.all(16.0),
            child: const Text(
              '© 2023 Simple Domain. All rights reserved.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.black54,
              ),
            ),
          ),
          const SizedBox(height: 100)
        ],
      ),
    );
  }
}