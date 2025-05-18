import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/auth/login_popup.dart'; // Import the reusable LoginPopup widget
import 'package:cloud_firestore/cloud_firestore.dart';

class BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const BottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  Widget _buildAvatarIcon() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return CircleAvatar(
        radius: 14,
        backgroundColor: Colors.grey[200],
        child: SvgPicture.asset(
          'assets/icons/avatar.svg',
          width: 21,
          height: 21,
        ),
      );
    }
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(user.uid).get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircleAvatar(
            radius: 14,
            backgroundColor: Colors.grey,
            child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
          );
        }
        if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.exists) {
          return CircleAvatar(
            radius: 14,
            backgroundColor: Colors.grey[200],
            child: SvgPicture.asset(
              'assets/icons/avatar.svg',
              width: 21,
              height: 21,
            ),
          );
        }
        final data = snapshot.data!.data() as Map<String, dynamic>?;
        final avatarUrl = data != null && data['avatarUrl'] != null && data['avatarUrl'].toString().isNotEmpty
            ? data['avatarUrl'] as String
            : null;
        if (avatarUrl != null) {
          return CircleAvatar(
            radius: 14,
            backgroundImage: NetworkImage(avatarUrl),
          );
        } else {
          return CircleAvatar(
            radius: 14,
            backgroundColor: Colors.grey[200],
            child: SvgPicture.asset(
              'assets/icons/avatar.svg',
              width: 21,
              height: 21,
            ),
          );
        }
      },
    );
  }

  Widget _buildCartNavBarItem() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return _NavBarItem(
        icon: 'assets/icons/cart.svg',
        isActive: currentIndex == 1,
        onTap: onTap,
        index: 1,
        badgeCount: 0,
      );
    }
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('cart')
          .snapshots(),
      builder: (context, snapshot) {
        int count = 0;
        if (snapshot.hasData) {
          count = snapshot.data!.docs.length;
        }
        return _NavBarItem(
          icon: 'assets/icons/cart.svg',
          isActive: currentIndex == 1,
          onTap: onTap,
          index: 1,
          badgeCount: count,
        );
      },
    );
  }

  Widget _buildWishlistNavBarItem() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return _NavBarItem(
        icon: 'assets/icons/heart.svg',
        isActive: currentIndex == 2,
        onTap: onTap,
        index: 2,
        badgeCount: 0,
      );
    }
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('favorites')
          .snapshots(),
      builder: (context, snapshot) {
        int count = 0;
        if (snapshot.hasData) {
          count = snapshot.data!.docs.length;
        }
        return _NavBarItem(
          icon: 'assets/icons/heart.svg',
          isActive: currentIndex == 2,
          onTap: onTap,
          index: 2,
          badgeCount: count,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      margin: const EdgeInsets.only(bottom: 24, right: 10, left: 10), // Increased vertical margin
      decoration: BoxDecoration(
        color: Color(0xFFF2F2F2), // Fully opaque
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
            onTap: onTap,
            index: 0,
          ),
          _buildCartNavBarItem(),
          _buildWishlistNavBarItem(),
          _NavBarItem(
            icon: 'assets/icons/shop.svg', // New shop button
            isActive: currentIndex == 3,
            onTap: onTap,
            index: 3,
          ),
          GestureDetector(
            onTap: () => _NavBarItem.handleTap(context, 'assets/icons/avatar.svg', onTap, 4),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  decoration: BoxDecoration(
                    color: currentIndex == 4 ? const Color(0xffF8F8F8) : Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: SizedBox(
                    height: 40,
                    width: 40,
                    child: Center(
                      child: _buildAvatarIcon(),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                if (currentIndex == 4)
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
          ),
        ],
      ),
    );
  }
}

class _NavBarItem extends StatelessWidget {
  final String icon;
  final bool isActive;
  final Function(int) onTap;
  final int index;
  final int badgeCount;

  const _NavBarItem({
    required this.icon,
    required this.isActive,
    required this.onTap,
    required this.index,
    this.badgeCount = 0,
  });

  static void handleTap(BuildContext context, String icon, Function(int) onTap, int index) async {
    final user = FirebaseAuth.instance.currentUser;
    if (icon == 'assets/icons/home.svg' || icon == 'assets/icons/shop.svg') {
      onTap(index);
    } else if (user == null) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        backgroundColor: Colors.transparent,
        builder: (context) => const LoginPopup(),
      );
    } else {
      onTap(index);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => handleTap(context, icon, onTap, index),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                decoration: BoxDecoration(
                  color: isActive ? const Color(0xffF8F8F8) : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: SizedBox(
                  height: 40,
                  width: 40,
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
              if (badgeCount > 0)
                Positioned(
                  right: -2,
                  top: -2,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 18,
                      minHeight: 18,
                    ),
                    child: Text(
                      badgeCount > 99 ? '99+' : badgeCount.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
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