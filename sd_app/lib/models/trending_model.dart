import 'package:flutter/material.dart';

class TrendingModel {
  String name;
  String imagePath;
  String description;
  Color boxColor;
  bool isSelected;

  TrendingModel({
    required this.name,
    required this.imagePath,
    required this.description,
    required this.boxColor,
    this.isSelected = false, // Default value for isSelected
  });

  static List<TrendingModel> gettrending() {
    List<TrendingModel> trending = [];

    trending.add(
      TrendingModel(
        name: 'Trending 1',
        imagePath: 'assets/images/earphone.png',
        description: 'Description of trending 1',
        boxColor: Colors.red,
        isSelected: false,
      ),
    );

    trending.add(
      TrendingModel(
        name: 'Trending 2',
        imagePath: 'assets/images/iphone.png',
        description: 'Description of trending 2',
        boxColor: Colors.blue,
        isSelected: false,
      ),
    );

    trending.add(
      TrendingModel(
        name: 'Trending 3',
        imagePath: 'assets/images/shoes.png',
        description: '₱Description of trending 3', // Updated to peso
        boxColor: Colors.green,
        isSelected: false,
      ),
    );

    return trending; // Return the list
  }
}
