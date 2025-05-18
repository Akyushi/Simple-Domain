import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class SearchBar extends StatelessWidget {
  final TextEditingController searchController;
  final FocusNode searchFocusNode;
  final ValueChanged<String> onSubmitted;

  const SearchBar({
    super.key,
    required this.searchController,
    required this.searchFocusNode,
    required this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 40, left: 20, right: 20),
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
        focusNode: searchFocusNode,
        controller: searchController,
        onSubmitted: onSubmitted,
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
            onPressed: () {
              if (searchController.text.isNotEmpty) {
                Navigator.pushNamed(
                  context,
                  '/search',
                  arguments: searchController.text,
                );
              }
            },
          ),
          suffixIcon: SizedBox(
            width: 80,
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
                  onPressed: () {},
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
    );
  }
}
