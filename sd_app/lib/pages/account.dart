import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:badges/badges.dart' as badges;
import 'order_status.dart';
import 'order_history.dart';


class AccountPage extends StatelessWidget {
  const AccountPage({super.key});

  // Helper widget for status with badge
  Widget _buildPurchaseStatus(IconData icon, String label, int count) {
    return Column(
      children: [
        badges.Badge(
          showBadge: count > 0,
          badgeContent: Text('$count', style: TextStyle(color: Colors.white, fontSize: 10)),
          badgeStyle: badges.BadgeStyle(
            badgeColor: Colors.red,
            padding: EdgeInsets.all(5),
          ),
          child: Icon(icon, size: 32),
        ),
        SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 13)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser; // Get the current user

    Widget buildStatusRow(Map<String, int> counts) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => OrderStatusPage(initialTab: 1),
                ),
              );
            },
            child: _buildPurchaseStatus(Icons.local_shipping_outlined, "To Deliver", counts['To Deliver'] ?? 0),
          ),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => OrderStatusPage(initialTab: 2),
                ),
              );
            },
            child: _buildPurchaseStatus(Icons.local_mall_outlined, "To Receive", counts['To Receive'] ?? 0),
          ),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => OrderStatusPage(initialTab: 3),
                ),
              );
            },
            child: _buildPurchaseStatus(Icons.star_border, "To Rate", counts['Order Completed'] ?? 0),
          ),
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text(
          'Account',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Section
            Row(
              children: [
                user == null
                    ? CircleAvatar(
                        radius: 40,
                        backgroundColor: Colors.grey[200],
                        child: SvgPicture.asset(
                          'assets/icons/avatar.svg',
                          width: 50,
                          height: 50,
                        ),
                      )
                    : FutureBuilder<DocumentSnapshot>(
                        future: FirebaseFirestore.instance
                            .collection('users')
                            .doc(user.uid)
                            .get(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const CircleAvatar(
                              radius: 40,
                              backgroundColor: Colors.grey,
                              child: CircularProgressIndicator(),
                            );
                          }
                          if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.exists) {
                            return CircleAvatar(
                              radius: 40,
                              backgroundColor: Colors.grey[200],
                              child: SvgPicture.asset(
                                'assets/icons/avatar.svg',
                                width: 50,
                                height: 50,
                              ),
                            );
                          }
                          final data = snapshot.data!.data() as Map<String, dynamic>?;
                          final avatarUrl = data != null && data['avatarUrl'] != null && data['avatarUrl'].toString().isNotEmpty
                              ? data['avatarUrl'] as String
                              : null;
                          if (avatarUrl != null) {
                            return CircleAvatar(
                              radius: 40,
                              backgroundImage: NetworkImage(avatarUrl),
                            );
                          } else {
                            return CircleAvatar(
                              radius: 40,
                              backgroundColor: Colors.grey[200],
                              child: SvgPicture.asset(
                                'assets/icons/avatar.svg',
                                width: 50,
                                height: 50,
                              ),
                            );
                          }
                        },
                      ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    user == null
                        ? const Text(
                            'no account connected',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        : FutureBuilder<DocumentSnapshot>(
                            future: FirebaseFirestore.instance.collection('users').doc(user.uid).get(),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState == ConnectionState.waiting) {
                                return const Text('Loading...', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold));
                              }
                              if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.exists) {
                                return const Text('no account connected', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold));
                              }
                              final data = snapshot.data!.data() as Map<String, dynamic>?;
                              final nickname = data != null && data['nickname'] != null && data['nickname'].toString().isNotEmpty
                                  ? data['nickname'] as String
                                  : 'No nickname set';
                              return Text(
                                nickname,
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              );
                            },
                          ),
                    const SizedBox(height: 4),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),

            // My Purchases Section
            Card(
              elevation: 0,
              margin: EdgeInsets.only(bottom: 8),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: const [
                            Icon(Icons.shopping_bag_outlined, color: Colors.blue),
                            SizedBox(width: 8),
                            Text('My Purchases', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  user == null
                      ? buildStatusRow({'To Deliver': 0, 'To Receive': 0})
                      : StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('users')
                              .doc(user.uid)
                              .collection('orders')
                              .snapshots(),
                          builder: (context, snapshot) {
                            int toDeliver = 0;
                            int toReceive = 0;
                            int orderCompleted = 0;
                            if (snapshot.hasData) {
                              for (var doc in snapshot.data!.docs) {
                                final data = doc.data() as Map<String, dynamic>;
                                final items = data['items'] as List<dynamic>? ?? [];
                                for (var item in items) {
                                  final status = item['status'] ?? data['status'];
                                  if (status == 'To Deliver') toDeliver++;
                                  if (status == 'To Receive') toReceive++;
                                  if (status == 'Order Completed') orderCompleted++;
                                }
                              }
                            }
                            return buildStatusRow({'To Deliver': toDeliver, 'To Receive': toReceive, 'Order Completed': orderCompleted});
                          },
                        ),
                ],
              ),
            ),
            const Divider(height: 32, thickness: 1), // Separation line

            // Account Settings Section
            const SizedBox(height: 10),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Account Settings'),
              onTap: () {
                Navigator.pushNamed(context, '/account_settings'); // Ensure '/account_settings' is registered
              },
            ),
            ListTile(
              leading: const Icon(Icons.store),
              title: const Text('Seller Page'),
              onTap: () {
                Navigator.pushNamed(context, '/seller'); // Ensure '/seller' is registered
              },
            ),
            ListTile(
              leading: const Icon(Icons.history),
              title: const Text('Order History'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const OrderHistoryPage()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.assignment_turned_in),
              title: const Text('Order Status'),
              onTap: () {
                Navigator.pushNamed(context, '/order_status'); // Ensure '/order_status' is registered
              },
            ),
            ListTile(
              leading: const Icon(Icons.info),
              title: const Text('About Us'),
              onTap: () {
                Navigator.pushNamed(context, '/about_us'); // Ensure '/about_us' is registered
              },
            ),
            ListTile(
              leading: const Icon(Icons.policy),
              title: const Text('Terms and Policy'),
              onTap: () {
                Navigator.pushNamed(context, '/terms'); // Ensure '/terms' is registered
              },
            ),
            const SizedBox(height: 24),

            ElevatedButton(
              onPressed: () async {
                try {
                  await FirebaseAuth.instance.signOut(); // Log out the user
                  Navigator.pushReplacementNamed(context, '/'); // Navigate to HomePage
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Logged out successfully')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error logging out: $e')),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 255, 55, 55), // Red background
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30), // Rounded corners
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.logout, // Log out icon
                    color: Colors.white,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Log Out',
                    style: TextStyle(
                      color: Color.fromARGB(255, 255, 255, 255), // White text
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 100),
          ],
          
        ),
      ),
    );
  }
}
