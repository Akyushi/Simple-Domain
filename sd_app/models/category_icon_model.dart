class CategoryIconModel {
  static const Map<String, String> categoryIcons = {
    'food': 'assets/icons/food.svg',
    'books': 'assets/icons/book.svg',
    'clothing': 'assets/icons/clothing.svg',
    'electronics': 'assets/icons/electronic.svg',
    'others': 'assets/icons/others.svg',
  };

  static String getIcon(String category) {
    return categoryIcons[category.toLowerCase()] ?? 'assets/icons/default.svg';
  }
}
