import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class OrderHistoryPage extends StatelessWidget {
  const OrderHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Order History'), centerTitle: true),
        body: const Center(child: Text('Please log in to view your order history.')),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Order History'), centerTitle: true),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('orders')
            .where('status', isEqualTo: 'Order Completed')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No order history found.'));
          }
          final orders = snapshot.data!.docs;
          // Group orders by date
          Map<String, List<QueryDocumentSnapshot>> grouped = {};
          for (var doc in orders) {
            final data = doc.data() as Map<String, dynamic>;
            final timestamp = data['timestamp'] as Timestamp?;
            final date = timestamp != null ? timestamp.toDate() : DateTime.now();
            final dateKey = DateFormat('MMMM dd, yyyy').format(date);
            grouped.putIfAbsent(dateKey, () => []).add(doc);
          }
          final sortedKeys = grouped.keys.toList()
            ..sort((a, b) => DateFormat('MMMM dd, yyyy').parse(b).compareTo(DateFormat('MMMM dd, yyyy').parse(a)));
          return ListView.builder(
            itemCount: sortedKeys.length,
            itemBuilder: (context, index) {
              final dateKey = sortedKeys[index];
              final dayOrders = grouped[dateKey]!;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
                    child: Text(
                      dateKey,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                  ),
                  ...dayOrders.map((orderDoc) {
                    final data = orderDoc.data() as Map<String, dynamic>;
                    final orderId = orderDoc.id;
                    final total = data['total'] ?? 0;
                    final paymentMethod = data['paymentMethod'] ?? 'Unknown';
                    final items = data['items'] as List<dynamic>? ?? [];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Order #$orderId', style: const TextStyle(fontWeight: FontWeight.bold)),
                            Text('Payment: $paymentMethod'),
                            Text('Total: ₱$total'),
                            const SizedBox(height: 4),
                            ...items.map((item) {
                              final name = item['name'] ?? 'Item';
                              final qty = item['quantity'] ?? 1;
                              final price = item['price'];
                              return Row(
                                children: [
                                  Expanded(child: Text(name)),
                                  Text('₱$price x $qty'),
                                ],
                              );
                            }).toList(),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ],
              );
            },
          );
        },
      ),
    );
  }
} 