import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const BottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8), // Increased vertical margin
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.all(Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 16,
            spreadRadius: 0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _NavBarItem(
            icon: 'assets/icons/home.svg',
            isActive: currentIndex == 0,
            onTap: () => Navigator.pushReplacementNamed(context, '/home'),
          ),
          _NavBarItem(
            icon: 'assets/icons/cart.svg',
            isActive: currentIndex == 1,
            onTap: () => Navigator.pushReplacementNamed(context, '/cart'),
          ),
          _NavBarItem(
            icon: 'assets/icons/heart.svg',
            isActive: currentIndex == 2,
            onTap: () => Navigator.pushReplacementNamed(context, '/wishlist'),
          ),
          _NavBarItem(
            icon: 'assets/icons/shop.svg', // New shop button
            isActive: currentIndex == 3,
            onTap: () => Navigator.pushReplacementNamed(context, '/shop'),
          ),
          _NavBarItem(
            icon: 'assets/icons/avatar.svg',
            isActive: currentIndex == 4,
            onTap: () => onTap(4),
          ),
        ],
      ),
    );
  }
}

class _NavBarItem extends StatelessWidget {
  final String icon;
  final bool isActive;
  final VoidCallback onTap;

  const _NavBarItem({
    required this.icon,
    required this.isActive,
    required this.onTap,
  });

  /// This widget is used to display each item in the bottom navigation bar.
  /// It takes an icon, a boolean to indicate if it's active, and a callback function for the tap event
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (icon == 'assets/icons/avatar.svg') {
          showModalBottomSheet(
            context: context,
            backgroundColor: Colors.transparent,
            isScrollControlled: true,
            builder: (context) => Stack(
              clipBehavior: Clip.none,
              children: [
              Positioned(
                bottom: 0,
                left: 16,
                right: 16,
                child: Container(
                padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 24), // Adjusted padding
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                  ),
                  boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 16,
                    spreadRadius: 0,
                    offset: const Offset(0, -4),
                  ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                  const SizedBox(height: 60), // Increased space for floating button
                  Container(
                    padding: const EdgeInsets.all(24), // Adjusted padding
                    decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xff2196F3), Color(0xff21CBF3)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                    children: [
                        Container(
                        padding: const EdgeInsets.all(8), // Add padding to make the circle bigger
                        decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        ),
                        child: SvgPicture.asset(
                        'assets/icons/logo.svg',
                        height: 59, // Adjusted icon size
                        width: 59, // Adjusted icon size
                        ),
                        ),
                      const SizedBox(height: 12), // Adjusted spacing
                      const Text(
                      'With your account, you will be able to do more!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                      fontSize: 24, // Adjusted font size
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      ),
                      ),
                      const SizedBox(height: 24), // Adjusted spacing
                      Column(
                      crossAxisAlignment: CrossAxisAlignment.start, // Align rows to the left
                      children: const [
                      Row(
                      children: [
                        Icon(Icons.card_giftcard, size: 24, color: Colors.white),
                        SizedBox(width: 8),
                        Text(
                        'Get Vouchers',
                        style: TextStyle(color: Colors.white),
                        ),
                      ],
                      ),
                      SizedBox(height: 8), // Add spacing between rows
                      Row(
                      children: [
                        Icon(Icons.favorite, size: 24, color: Colors.white),
                        SizedBox(width: 8),
                        Text(
                        'Save a Wishlist',
                        style: TextStyle(color: Colors.white),
                        ),
                      ],
                      ),
                      SizedBox(height: 8), // Add spacing between rows
                      Row(
                      children: [
                        Icon(Icons.shopping_cart, size: 24, color: Colors.white),
                        SizedBox(width: 8),
                        Text(
                        'Order',
                        style: TextStyle(color: Colors.white),
                        ),
                      ],
                      ),
                      ],
                      ),
                    ],
                    ),
                  ),
                  const SizedBox(height: 32), // Increased spacing
                    ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/login'); // Navigate to LoginPage
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      minimumSize: const Size(double.infinity, 56), // Adjusted button height
                    ),
                    child: const Text(
                      'Log in',
                      style: TextStyle(
                      fontWeight: FontWeight.bold, // Made text bolder
                      fontSize: 18, // Increased font size for clarity
                      color: Colors.white, // Ensured text is clear on blue background
                      ),
                    ),
                    ),
                    const SizedBox(height: 16), // Increased spacing
                    OutlinedButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/sign_up'); // Navigate to SignUpPage
                    },
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 56), // Adjusted button height
                    ),
                    child: const Text(
                      'Sign up',
                      style: TextStyle(
                      fontWeight: FontWeight.bold, // Made text bolder
                      fontSize: 18, // Increased font size for clarity
                      color: Colors.black, // Ensured text is clear on outlined button
                      ),
                    ),
                    ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        } else {
          onTap();
        }
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            decoration: BoxDecoration(
              color: isActive ? const Color(0xffF8F8F8) : Colors.transparent,
              borderRadius: BorderRadius.circular(16),
            ),
            child: SizedBox(
              height: 40, // Ensure consistent height
              width: 40, // Ensure consistent width
              child: Center(
                child: SvgPicture.asset(
                  icon,
                  height: 24,
                  width: 24,
                  color: isActive ? const Color(0xff1D1617) : const Color(0xff7B6F72),
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          if (isActive)
            Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                color: Color(0xff1D1617),
                shape: BoxShape.circle,
              ),
            ),
        ],
      ),
    );
  }
}