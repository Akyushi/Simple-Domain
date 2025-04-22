import 'package:flutter/material.dart';
import '../models/category_model.dart';
import '../models/ads_model.dart';
import '../widgets/bottom_navbar.dart';
import '../widgets/home/search_bar.dart' as custom; // Alias the custom SearchBar import
import '../widgets/home/categories.dart';
import '../widgets/home/featured_products.dart';
import '../widgets/home/trending_products.dart'; // Import TrendingProducts widget

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final List<CategoryModel> categories;
  late final List<AdsModel> ads;
  int _currentIndex = 0;
  final List<String> searchSuggestions = ['Shoes', 'Bags', 'Watches', 'Clothes', 'Accessories'];
  List<String> filteredSuggestions = [];
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

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

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Simple Domain',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          ListView(
            children: [
              custom.SearchBar(
                searchController: _searchController,
                searchFocusNode: _searchFocusNode,
                onSubmitted: (query) {
                  Navigator.pushNamed(context, '/search', arguments: query);
                },
              ),
              const SizedBox(height: 40),
              Categories(categories: categories),
              const SizedBox(height: 40),
              FeaturedProducts(ads: ads),
              const SizedBox(height: 40),
              TrendingProducts(), // Added Trending Products section
              const SizedBox(height: 40),
            ],
          ),
          if (filteredSuggestions.isNotEmpty && _searchFocusNode.hasFocus)
            Positioned(
              top: kToolbarHeight + 20,
              left: 20,
              right: 20,
              child: Material(
                elevation: 4,
                borderRadius: BorderRadius.circular(15),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(25),
                        blurRadius: 10,
                        spreadRadius: 2,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  constraints: const BoxConstraints(
                    maxHeight: 200,
                  ),
                  child: ListView.builder(
                    shrinkWrap: true,
                    physics: const ClampingScrollPhysics(),
                    itemCount: filteredSuggestions.length,
                    itemBuilder: (context, index) {
                      return ListTile(
                        title: Text(filteredSuggestions[index]),
                        onTap: () {
                          _searchController.text = filteredSuggestions[index];
                          _searchFocusNode.unfocus();
                          setState(() {
                            filteredSuggestions.clear();
                          });
                        },
                      );
                    },
                  ),
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() => _currentIndex = index);
          Navigator.pushNamed(context, ['/home', '/cart', '/wishlist', '/shop', '/profile'][index]); // Added '/shop'
        },
      ),
    );
  }
}