import 'package:flutter/material.dart';

class AdsModel {
  String name;
  String imagePath;
  Color boxColor;
  String description;
  bool selected;

  AdsModel({
    required this.name,
    required this.imagePath,
    required this.boxColor,
    required this.description,
    required this.selected,
  });

  static List<AdsModel> getAds() {
    return [
      AdsModel(
        name: 'Headphones',
        imagePath: 'assets/images/earphone.jpg',
        boxColor: Color(0xffFCE8E4),
        description: 'Hear Me Out',
        selected: false,
      ),
      AdsModel(
        name: 'Smartphones',
        imagePath: 'assets/images/iphone.jpg',
        boxColor: Color(0xffE8FCE8),
        description: 'Trendy and Stylish',
        selected: false,
      ),
      AdsModel(
        name: 'Laptops',
        imagePath: 'assets/images/Laptop.jpg',
        boxColor: Color(0xffE4E8FC),
        description: 'Powerful Performance',
        selected: false,
      ),
      AdsModel(
        name: 'Shoes',
        imagePath: 'assets/images/Shoes.jpg',
        boxColor: Color.fromARGB(255, 252, 228, 228),
        description: 'Stay Connected',
        selected: false,
      ),
    ];
  }
}
