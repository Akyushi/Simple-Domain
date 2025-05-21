import 'package:flutter/material.dart';

class ShopFilter extends StatelessWidget {
  final String selectedSortOption;
  final ValueChanged<String> onSortChanged;
  final String selectedCategory;
  final ValueChanged<String> onCategoryChanged;
  final List<String> sortOptions;
  final int? selectedRating;
  final ValueChanged<int?> onRatingChanged;

  const ShopFilter({
    super.key,
    required this.selectedSortOption,
    required this.onSortChanged,
    required this.selectedCategory,
    required this.onCategoryChanged,
    required this.sortOptions,
    required this.selectedRating,
    required this.onRatingChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // First row: Sort by and Rating filter
          Row(
            children: [
              // Sort by dropdown
              Expanded(
                child: Row(
                  children: [
                    const Text(
                      'Sort by:',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButton<String>(
                        value: selectedSortOption,
                        isExpanded: true,
                        items: sortOptions.map((option) {
                          return DropdownMenuItem(
                            value: option,
                            child: Text(
                              option,
                              style: const TextStyle(fontSize: 14),
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            onSortChanged(value);
                          }
                        },
                        underline: Container(),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              // Rating filter
              Row(
                children: [
                  const Text(
                    'Rating:',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  DropdownButton<int?>(
                    value: selectedRating,
                    hint: const Text('All'),
                    items: [
                      const DropdownMenuItem<int?>(
                        value: null,
                        child: Text('All'),
                      ),
                      ...List.generate(
                        5,
                        (i) => DropdownMenuItem<int?>(
                          value: 5 - i,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ...List.generate(
                                5,
                                (j) => Icon(
                                  j < 5 - i ? Icons.star : Icons.star_border,
                                  color: Colors.amber,
                                  size: 16,
                                ),
                              ),
                              Text(' ${5 - i}'),
                            ],
                          ),
                        ),
                      ),
                    ],
                    onChanged: onRatingChanged,
                    underline: Container(),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Second row: Category filter button
          ElevatedButton.icon(
            onPressed: () => _showCategoryFilterDialog(context),
            icon: const Icon(Icons.filter_list, size: 18),
            label: Text(
              'Category: $selectedCategory',
              style: const TextStyle(fontSize: 14),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color.fromARGB(255, 54, 114, 244),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              minimumSize: const Size(200, 45),
            ),
          ),
        ],
      ),
    );
  }

  void _showCategoryFilterDialog(BuildContext context) {
    final categories = [
      {'name': 'All', 'icon': Icons.category},
      {'name': 'Electronics', 'icon': Icons.electrical_services},
      {'name': 'Clothing', 'icon': Icons.checkroom},
      {'name': 'Food', 'icon': Icons.fastfood},
      {'name': 'Books', 'icon': Icons.book},
      {'name': 'Others', 'icon': Icons.more_horiz},
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: categories.map((category) {
              return RadioListTile<String>(
                title: Row(
                  children: [
                    Icon(category['icon'] as IconData, size: 24, color: Colors.blue),
                    const SizedBox(width: 8),
                    Text(category['name'] as String),
                  ],
                ),
                value: category['name'] as String,
                groupValue: selectedCategory,
                onChanged: (value) {
                  if (value != null) {
                    onCategoryChanged(value);
                    Navigator.pop(context);
                  }
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }
}
