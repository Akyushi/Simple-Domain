import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/category_icon_model.dart';

class SearchPage extends StatefulWidget {
  final String query;

  const SearchPage({super.key, required this.query});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  late TextEditingController _searchController;
  Map<String, bool> _filters = {
    'Price: Low to High': false,
    'Price: High to Low': false,
    'Newest First': false,
    'Oldest First': false,
  };
  List<Map<String, dynamic>> _searchResults = [];
  bool _isLoading = false;
  String _selectedCategory = 'All';

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.query);
    _performSearch(widget.query);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showFilterModal(BuildContext context) {
    Map<String, bool> tempFilters = Map.from(_filters);

    showModalBottomSheet(
      context: context,
      isDismissible: true,
      enableDrag: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Filter Options',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ...tempFilters.keys.map((filter) {
                    return CheckboxListTile(
                      title: Text(filter),
                      value: tempFilters[filter],
                      onChanged: (bool? value) {
                        setModalState(() {
                          tempFilters[filter] = value ?? false;
                          if (value == true) {
                            tempFilters.forEach((key, val) {
                              if (key != filter) tempFilters[key] = false;
                            });
                          }
                        });
                      },
                    );
                  }),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _filters = Map.from(tempFilters);
                          _applyFilters();
                        });
                        Navigator.pop(context);
                      },
                      child: const Text('Apply Filters'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _applyFilters() {
    if (_searchResults.isEmpty) return;

    List<Map<String, dynamic>> filteredResults = List.from(_searchResults);
    String activeFilter = _filters.entries.firstWhere((entry) => entry.value, orElse: () => MapEntry('', false)).key;

    switch (activeFilter) {
      case 'Price: Low to High':
        filteredResults.sort((a, b) => (a['price'] as num).compareTo(b['price'] as num));
        break;
      case 'Price: High to Low':
        filteredResults.sort((a, b) => (b['price'] as num).compareTo(a['price'] as num));
        break;
      case 'Newest First':
        // Assuming there's a timestamp field, add if needed
        break;
      case 'Oldest First':
        // Assuming there's a timestamp field, add if needed
        break;
    }

    setState(() {
      _searchResults = filteredResults;
    });
  }

  Future<void> _performSearch(String query) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final results = await _fetchSearchResults(query);
      setState(() {
        _searchResults = results;
        _applyFilters();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error performing search: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<List<Map<String, dynamic>>> _fetchSearchResults(String query) async {
    if (query.trim().isEmpty) return [];

    final firestore = FirebaseFirestore.instance;
    final lowerQuery = query.toLowerCase();
    final queryWords = lowerQuery.split(' ').where((word) => word.isNotEmpty).toList();
    
    final productsSnapshot = await firestore.collection('products').get();
    // Fetch all users for seller name search
    final usersSnapshot = await firestore.collection('users').get();
    final users = {for (var doc in usersSnapshot.docs) doc.id: doc.data()};
    
    return productsSnapshot.docs.map((doc) {
      final data = doc.data();
      final name = (data['name'] ?? '').toString().toLowerCase();
      final category = (data['category'] ?? '').toString().toLowerCase();
      final tags = (data['tags'] as List<dynamic>? ?? [])
          .map((t) => t.toString().toLowerCase())
          .toList();
      final sellerId = data['sellerId'] ?? '';
      final sellerData = users[sellerId] ?? {};
      final sellerName = (sellerData['nickname'] ?? '').toString().toLowerCase();
      final sellerAvatar = sellerData['avatarUrl'] ?? null;
      // Calculate relevance score
      int relevanceScore = 0;
      List<String> matchedTerms = [];

      // Check name matches
      if (name.contains(lowerQuery)) {
        relevanceScore += 10;
        matchedTerms.add('name');
      }
      // Check category matches
      if (category.contains(lowerQuery)) {
        relevanceScore += 8;
        matchedTerms.add('category');
      }
      // Check tag matches
      for (final tag in tags) {
        if (tag.contains(lowerQuery)) {
          relevanceScore += 5;
          matchedTerms.add('tag');
          break;
        }
      }
      // Check seller name matches
      if (sellerName.isNotEmpty && sellerName.contains(lowerQuery)) {
        relevanceScore += 12;
        matchedTerms.add('seller');
      }
      // Check individual word matches
      for (final word in queryWords) {
        if (name.contains(word)) relevanceScore += 3;
        if (category.contains(word)) relevanceScore += 2;
        if (tags.any((tag) => tag.contains(word))) relevanceScore += 1;
        if (sellerName.isNotEmpty && sellerName.contains(word)) relevanceScore += 4;
      }
      return {
        'id': doc.id,
        'name': data['name'],
        'image': data['image'] ?? 'https://via.placeholder.com/150',
        'price': data['price'],
        'category': data['category'],
        'tags': data['tags'],
        'description': data['description'],
        'icon': CategoryIconModel.getIcon(data['category']),
        'relevanceScore': relevanceScore,
        'matchedTerms': matchedTerms,
        'sellerId': sellerId,
        'sellerName': sellerData['nickname'] ?? '',
        'sellerAvatar': sellerAvatar,
      };
    })
    .where((item) => item['relevanceScore'] > 0)
    .toList()
    ..sort((a, b) => b['relevanceScore'].compareTo(a['relevanceScore']));
  }

  @override
  Widget build(BuildContext context) {
    // Get all unique categories from search results
    final categories = ['All', ...{
      for (final item in _searchResults)
        if (item['category'] != null && item['category'].toString().isNotEmpty)
          item['category']
    }];
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Results'),
      ),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: const Color(0xff1D1617).withOpacity(0.11),
                  blurRadius: 40,
                  spreadRadius: 0,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              onSubmitted: _performSearch,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.all(15),
                hintText: 'Search products, categories, or tags',
                hintStyle: TextStyle(
                  color: const Color(0xff1D1617).withOpacity(0.5),
                  fontSize: 16,
                ),
                prefixIcon: IconButton(
                  icon: SvgPicture.asset('assets/icons/search.svg'),
                  onPressed: () => _performSearch(_searchController.text),
                ),
                suffixIcon: IconButton(
                  icon: SvgPicture.asset('assets/icons/filter.svg'),
                  onPressed: () => _showFilterModal(context),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          // Category filter dropdown
          if (_searchResults.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              child: Row(
                children: [
                  const Text('Category:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(width: 8),
                  DropdownButton<String>(
                    value: _selectedCategory,
                    items: categories.map((cat) => DropdownMenuItem<String>(
                      value: cat,
                      child: Text(cat),
                    )).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedCategory = value;
                        });
                      }
                    },
                  ),
                ],
              ),
            ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _searchResults.isEmpty
                    ? Center(
                        child: Text(
                          _searchController.text.isEmpty
                              ? 'Enter a search term'
                              : 'No results found',
                          style: const TextStyle(fontSize: 16),
                        ),
                      )
                    : ListView.builder(
                        itemCount: (_selectedCategory == 'All'
                            ? _searchResults.length
                            : _searchResults.where((item) => item['category'] == _selectedCategory).length) + 1,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemBuilder: (context, index) {
                          // Show seller card at the top if a seller matches
                          if (index == 0) {
                            // Find the first unique seller that matches the search
                            final sellerSet = <String>{};
                            Map<String, dynamic>? sellerInfo;
                            final filteredResults = _selectedCategory == 'All'
                                ? _searchResults
                                : _searchResults.where((item) => item['category'] == _selectedCategory).toList();
                            for (final product in filteredResults) {
                              final sellerId = product['sellerId'];
                              final sellerName = product['sellerName'] ?? '';
                              if (sellerId != null && sellerName.isNotEmpty && !sellerSet.contains(sellerId)) {
                                sellerSet.add(sellerId);
                                // Only show if the seller name matches the search
                                if (sellerName.toLowerCase().contains(_searchController.text.toLowerCase())) {
                                  sellerInfo = {
                                    'sellerId': sellerId,
                                    'sellerName': product['sellerName'],
                                    'sellerAvatar': product['sellerAvatar'],
                                  };
                                  break;
                                }
                              }
                            }
                            if (sellerInfo != null) {
                              return Card(
                                color: Colors.blue[50],
                                margin: const EdgeInsets.only(bottom: 15),
                                elevation: 2,
                                child: ListTile(
                                  leading: sellerInfo['sellerAvatar'] != null && sellerInfo['sellerAvatar'].toString().isNotEmpty
                                      ? CircleAvatar(backgroundImage: NetworkImage(sellerInfo['sellerAvatar']))
                                      : const CircleAvatar(child: Icon(Icons.person)),
                                  title: Text(sellerInfo['sellerName'], style: const TextStyle(fontWeight: FontWeight.bold)),
                                  subtitle: const Text('Seller'),
                                  onTap: () {
                                    Navigator.pushNamed(
                                      context,
                                      '/seller_store',
                                      arguments: {'sellerId': sellerInfo!['sellerId']},
                                    );
                                  },
                                ),
                              );
                            } else {
                              return const SizedBox.shrink();
                            }
                          }
                          final filteredResults = _selectedCategory == 'All'
                              ? _searchResults
                              : _searchResults.where((item) => item['category'] == _selectedCategory).toList();
                          final product = filteredResults[index - 1];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 15),
                            elevation: 2,
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(10),
                              leading: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  product['image'],
                                  width: 80,
                                  height: 80,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      width: 80,
                                      height: 80,
                                      color: Colors.grey[200],
                                      child: const Icon(Icons.image_not_supported),
                                    );
                                  },
                                ),
                              ),
                              title: Text(
                                product['name'] ?? 'Unknown Product',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Price: ₱${product['price']?.toStringAsFixed(2) ?? 'N/A'}',
                                    style: const TextStyle(
                                      color: Colors.green,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  if (product['category'] != null)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: product['matchedTerms'].contains('category')
                                            ? Colors.blue[100]
                                            : Colors.grey[200],
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        product['category'],
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: product['matchedTerms'].contains('category')
                                              ? Colors.blue[900]
                                              : Colors.black87,
                                        ),
                                      ),
                                    ),
                                  if (product['tags'] != null &&
                                      (product['tags'] as List).isNotEmpty)
                                    Wrap(
                                      spacing: 4,
                                      children: (product['tags'] as List)
                                          .map<Widget>((tag) => Container(
                                                margin: const EdgeInsets.only(top: 4),
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: 6,
                                                  vertical: 2,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: product['matchedTerms'].contains('tag')
                                                      ? Colors.green[100]
                                                      : Colors.grey[200],
                                                  borderRadius: BorderRadius.circular(12),
                                                ),
                                                child: Text(
                                                  '#$tag',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: product['matchedTerms'].contains('tag')
                                                        ? Colors.green[900]
                                                        : Colors.black87,
                                                  ),
                                                ),
                                              ))
                                          .toList(),
                                    ),
                                  // Seller info
                                  const SizedBox(height: 8),
                                  GestureDetector(
                                    onTap: () {
                                      Navigator.pushNamed(
                                        context,
                                        '/seller_store',
                                        arguments: {
                                          'sellerId': product['sellerId'],
                                        },
                                      );
                                    },
                                    child: Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 16,
                                          backgroundImage: product['sellerAvatar'] != null && product['sellerAvatar'].toString().isNotEmpty
                                              ? NetworkImage(product['sellerAvatar'])
                                              : null,
                                          child: (product['sellerAvatar'] == null || product['sellerAvatar'].toString().isEmpty)
                                              ? const Icon(Icons.person, size: 18)
                                              : null,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          product['sellerName'] ?? 'Seller',
                                          style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
                                        ),
                                        const Icon(Icons.storefront, size: 16, color: Colors.blueGrey),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              onTap: () {
                                Navigator.pushNamed(
                                  context,
                                  '/product_details',
                                  arguments: product,
                                );
                              },
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}