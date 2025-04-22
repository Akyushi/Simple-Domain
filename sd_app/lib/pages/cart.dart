import 'package:flutter/material.dart';
import '../widgets/bottom_navbar.dart';

class CartPage extends StatelessWidget {
  const CartPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Cart',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 22,
          ),
        ),
        centerTitle: true,
        backgroundColor: Color.fromARGB(255, 195, 205, 253),
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(16),
          ),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.shopping_cart_outlined,
              size: 80,
              color: Colors.grey,
            ),
            const SizedBox(height: 20),
            const Text(
              'Your cart looks lonely. Why not add\nsomething fun?',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Unlock free shipping when you spend \$50 or more!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: 1,
        onTap: (index) => Navigator.pushNamed(context, ['/home', '/cart', '/wishlist', '/shop', '/profile'][index]), // Added '/shop'
      ),
    );
  }
}
