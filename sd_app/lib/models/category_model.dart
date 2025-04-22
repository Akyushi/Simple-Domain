import 'package:flutter/material.dart';

class CategoryModel {
  String name;
  String iconPath;
  Color boxColor;

  CategoryModel ({
    required this.name,
    required this.iconPath,
    required this.boxColor,
  });

  static List<CategoryModel> getCategories() {
    List<CategoryModel> categories = [];
    categories.add(CategoryModel(
      name: 'Electronics',
      iconPath: 'assets/icons/electronic.svg',
      boxColor: Color(0xffFCE8E4),
    ));

    categories.add(CategoryModel(
      name: 'Clothing',
      iconPath: 'assets/icons/clothing.svg',
      boxColor: Color(0xffE8FCE8),
    ));

    categories.add(CategoryModel(
      name: 'Home & Kitchen',
      iconPath: 'assets/icons/kitchen.svg',
      boxColor: Color(0xffE8E4FC),
    ));

    categories.add(CategoryModel(
      name: 'Books',
      iconPath: 'assets/icons/book.svg',
      boxColor: Color(0xffFCE8E4),
    ));

    categories.add(CategoryModel(
      name: 'Sports',
      iconPath: 'assets/icons/sports.svg',
      boxColor: Color(0xffE8FCE8),
    ));

    return categories;
  }
}