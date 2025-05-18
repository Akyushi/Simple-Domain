import 'package:flutter/material.dart';

class ShopFilter extends StatelessWidget {
  final String selectedSortOption;
  final ValueChanged<String> onSortChanged;
  final String selectedCategory;
  final ValueChanged<String> onCategoryChanged;

  const ShopFilter({
    super.key,
    required this.selectedSortOption,
    required this.onSortChanged,
    required this.selectedCategory,
    required this.onCategoryChanged,
  });

  @override
  Widget build(BuildContext context) {
    final sortOptions = [
      'Featured',
      'Release date',
      'Title (A-Z)',
      'Title (Z-A)',
      'Price (high to low)',
      'Price (low to high)',
    ];

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Sort by:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 8),
              DropdownButton<String>(
                value: selectedSortOption,
                items: sortOptions.map((option) {
                  return DropdownMenuItem(
                    value: option,
                    child: Text(option, style: const TextStyle(fontSize: 16)),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    onSortChanged(value); // Ensure non-null value is passed
                  }
                },
                underline: Container(),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: () => _showCategoryFilterDialog(context),
            icon: const Icon(Icons.filter_list, size: 18),
            label: const Text('Filter', style: TextStyle(fontSize: 16)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color.fromARGB(255, 54, 114, 244),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                  onCategoryChanged(value!); // Ensure callback is triggered
                  Navigator.pop(context);
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }
}
