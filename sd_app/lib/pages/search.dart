import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

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

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.query);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showFilterModal(BuildContext context) {
    // Create a copy of the current filters to work with in the modal
    Map<String, bool> tempFilters = Map.from(_filters);

    showModalBottomSheet(
      context: context,
      isDismissible: true,
      enableDrag: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20),
        ),
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
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
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
                          // Ensure only one filter is selected at a time
                          if (value == true) {
                            tempFilters.forEach((key, val) {
                              if (key != filter) {
                                tempFilters[key] = false;
                              }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Results'),
      ),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 20, left: 20, right: 20),
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
              onSubmitted: (newQuery) {
                setState(() {
                  // Update the query dynamically
                });
              },
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.all(5),
                hintText: 'Search',
                hintStyle: TextStyle(
                  color: const Color(0xff1D1617).withOpacity(0.5),
                  fontSize: 16,
                ),
                prefixIcon: IconButton(
                  icon: SvgPicture.asset('assets/icons/search.svg'),
                  onPressed: () {},
                ),
                suffixIcon: SizedBox(
                  width: 80, // Adjust width to fit the icons properly
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 1,
                        height: 20,
                        color: const Color.fromARGB(255, 83, 83, 83),
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                      IconButton(
                        icon: SvgPicture.asset('assets/icons/filter.svg'),
                        onPressed: () => _showFilterModal(context),
                      ),
                    ],
                  ),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          // Display active filters
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Wrap(
              spacing: 8,
              children: _filters.entries
                  .where((entry) => entry.value)
                  .map((entry) => Chip(
                        label: Text(entry.key),
                        onDeleted: () {
                          setState(() {
                            _filters[entry.key] = false;
                          });
                        },
                      ))
                  .toList(),
            ),
          ),
          Expanded(
            child: Center(
              child: Text(
                'You searched for: ${_searchController.text}',
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ),
        ],
      ),
    );
  }
}