import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'comments_page.dart';

class OrderStatusPage extends StatelessWidget {
  final int initialTab;
  final List<String>? productIds;
  const OrderStatusPage({super.key, this.initialTab = 0, this.productIds});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Order Status'), centerTitle: true),
        body: const Center(child: Text('Please log in to view your orders.')),
      );
    }
    final List<String> statuses = [
      'Order Placed',
      'To Deliver',
      'To Receive',
      'Order Completed',
    ];
    return DefaultTabController(
      length: statuses.length,
      initialIndex: initialTab,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Order Status'),
          centerTitle: true,
          bottom: TabBar(
            isScrollable: true,
            tabs: statuses.map((s) => Tab(text: s)).toList(),
          ),
        ),
        body: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .collection('orders')
              .orderBy('timestamp', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return TabBarView(
                children: statuses.map((_) => const Center(child: Text('No orders in this status.'))).toList(),
              );
            }
            final orders = snapshot.data!.docs;
            // Map status -> List of item info (with order info)
            Map<String, List<Map<String, dynamic>>> statusItems = {
              for (var s in statuses) s: []
            };
            for (var orderDoc in orders) {
              final data = orderDoc.data() as Map<String, dynamic>;
              final items = data['items'] as List<dynamic>? ?? [];
              final total = data['total'] ?? 0;
              final paymentMethod = data['paymentMethod'] ?? 'Unknown';
              final timestamp = data['timestamp'] as Timestamp?;
              final date = timestamp?.toDate();
              final orderId = orderDoc.id;
              final address = data['address'] ?? '';
              for (var item in items) {
                final itemStatus = item['status'] ?? data['status'] ?? 'Order Placed';
                // Only add filterComment flag for Order Completed status
                if (itemStatus == 'Order Completed') {
                  statusItems[itemStatus]!.add({
                    'orderId': orderId,
                    'date': date,
                    'paymentMethod': paymentMethod,
                    'total': total,
                    'address': address,
                    'item': item,
                    'filterComment': true,
                  });
                } else if (statusItems.containsKey(itemStatus)) {
                  statusItems[itemStatus]!.add({
                    'orderId': orderId,
                    'date': date,
                    'paymentMethod': paymentMethod,
                    'total': total,
                    'address': address,
                    'item': item,
                  });
                }
              }
            }
            return TabBarView(
              children: statuses.map((status) {
                // Group items by orderId for this status
                final items = statusItems[status]!;
                if (items.isEmpty) {
                  return const Center(child: Text('No orders in this status.'));
                }
                // Group by orderId
                final Map<String, List<Map<String, dynamic>>> ordersById = {};
                for (final info in items) {
                  final orderId = info['orderId'];
                  ordersById.putIfAbsent(orderId, () => []).add(info);
                }
                final orderIds = ordersById.keys.toList();
                return ListView.builder(
                  itemCount: orderIds.length,
                  itemBuilder: (context, idx) {
                    final orderId = orderIds[idx];
                    final orderItems = ordersById[orderId]!;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Order #$orderId:', style: const TextStyle(fontWeight: FontWeight.bold)),
                        ...orderItems.map((info) {
                          // Use the same card/item style as before, but for each item
                          final date = info['date'];
                          final paymentMethod = info['paymentMethod'];
                          final total = info['total'];
                          final address = info['address'] ?? '';
                          final item = info['item'] as Map<String, dynamic>;
                          final name = item['name'] ?? 'Item';
                          final qty = item['quantity'] ?? 1;
                          final image = item['image'];
                          final price = item['price'];
                          final itemStatus = item['status'] ?? status;
                          final productId = item['productId'] ?? 'N/A';
                          if (productIds != null && productIds!.isNotEmpty && !productIds!.contains(productId)) {
                            return const SizedBox.shrink();
                          }
                          return _OrderItemCard(
                            date: date,
                            paymentMethod: paymentMethod,
                            total: total,
                            address: address,
                            item: item,
                            name: name,
                            qty: qty,
                            image: image,
                            price: price,
                            itemStatus: itemStatus,
                            productId: productId,
                            status: status,
                            orderId: orderId,
                            user: user,
                          );
                        }).toList(),
                      ],
                    );
                  },
                );
              }).toList(),
            );
          },
        ),
      ),
    );
  }
}

class _OrderItemCard extends StatefulWidget {
  final dynamic date;
  final String paymentMethod;
  final dynamic total;
  final String address;
  final Map<String, dynamic> item;
  final String name;
  final int qty;
  final dynamic image;
  final dynamic price;
  final String itemStatus;
  final String productId;
  final String status;
  final String orderId;
  final User user;
  const _OrderItemCard({
    Key? key,
    required this.date,
    required this.paymentMethod,
    required this.total,
    required this.address,
    required this.item,
    required this.name,
    required this.qty,
    required this.image,
    required this.price,
    required this.itemStatus,
    required this.productId,
    required this.status,
    required this.orderId,
    required this.user,
  }) : super(key: key);
  @override
  State<_OrderItemCard> createState() => _OrderItemCardState();
}

class _OrderItemCardState extends State<_OrderItemCard> {
  bool loading = false;
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Product ID: ${widget.productId}', style: const TextStyle(color: Colors.red, fontSize: 12)),
            if (widget.date != null)
              Text(
                '${widget.date.year}-${widget.date.month.toString().padLeft(2, '0')}-${widget.date.day.toString().padLeft(2, '0')} ${widget.date.hour.toString().padLeft(2, '0')}:${widget.date.minute.toString().padLeft(2, '0')}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            Text('Payment: ${widget.paymentMethod}'),
            Text('Total: ₱${widget.total}'),
            if (widget.address.isNotEmpty)
              Text('Address: ${widget.address}', style: const TextStyle(color: Colors.blueGrey)),
            const SizedBox(height: 4),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: widget.image != null && widget.image.toString().startsWith('http')
                  ? Image.network(widget.image, width: 40, height: 40, fit: BoxFit.cover)
                  : Image.asset(widget.image ?? 'assets/images/image.png', width: 40, height: 40, fit: BoxFit.cover),
              title: Text(widget.name, style: const TextStyle(fontWeight: FontWeight.w500)),
              subtitle: Text('₱${widget.price} x ${widget.qty}'),
              dense: true,
            ),
            if (widget.status == 'Order Completed')
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton.icon(
                    icon: const Icon(Icons.rate_review),
                    label: const Text('Rate/Comment'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                    onPressed: () async {
                      final productId = widget.item['productId'];
                      if (productId != null && productId is String && productId.isNotEmpty) {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CommentsPage(productId: productId),
                          ),
                        );
                        // After returning from CommentsPage, update status to 'History'
                        setState(() => loading = true);
                        final orderRef = FirebaseFirestore.instance
                            .collection('users')
                            .doc(widget.user.uid)
                            .collection('orders')
                            .doc(widget.orderId);
                        final orderSnap = await orderRef.get();
                        if (orderSnap.exists) {
                          final orderData = orderSnap.data() as Map<String, dynamic>;
                          final orderItems = List<Map<String, dynamic>>.from(orderData['items'] ?? []);
                          for (var i = 0; i < orderItems.length; i++) {
                            if (orderItems[i]['name'] == widget.name && orderItems[i]['status'] == widget.itemStatus) {
                              orderItems[i] = {
                                ...orderItems[i],
                                'status': 'History',
                              };
                            }
                          }
                          await orderRef.update({'items': orderItems});
                        }
                        // Update the item's status in the global orders collection (for seller page)
                        final topOrderRef = FirebaseFirestore.instance.collection('orders').doc(widget.orderId);
                        final topOrderSnap = await topOrderRef.get();
                        if (topOrderSnap.exists) {
                          final topOrderData = topOrderSnap.data() as Map<String, dynamic>;
                          final topOrderItems = List<Map<String, dynamic>>.from(topOrderData['items'] ?? []);
                          for (var i = 0; i < topOrderItems.length; i++) {
                            if (topOrderItems[i]['name'] == widget.name && topOrderItems[i]['status'] == widget.itemStatus) {
                              topOrderItems[i] = {
                                ...topOrderItems[i],
                                'status': 'History',
                              };
                            }
                          }
                          await topOrderRef.update({'items': topOrderItems});
                        }
                        if (mounted) setState(() => loading = false);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Product ID not found for this item.')),
                        );
                      }
                    },
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.cancel, color: Colors.red),
                    label: const Text('Cancel', style: TextStyle(color: Colors.red)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.red),
                    ),
                    onPressed: () async {
                      // Remove from 'Order Completed' tab but keep in order history
                      setState(() => loading = true);
                      final orderRef = FirebaseFirestore.instance
                          .collection('users')
                          .doc(widget.user.uid)
                          .collection('orders')
                          .doc(widget.orderId);
                      final orderSnap = await orderRef.get();
                      if (orderSnap.exists) {
                        final orderData = orderSnap.data() as Map<String, dynamic>;
                        final orderItems = List<Map<String, dynamic>>.from(orderData['items'] ?? []);
                        for (var i = 0; i < orderItems.length; i++) {
                          if (orderItems[i]['name'] == widget.name && orderItems[i]['status'] == widget.itemStatus) {
                            orderItems[i] = {
                              ...orderItems[i],
                              'status': 'History',
                            };
                          }
                        }
                        await orderRef.update({'items': orderItems});
                      }
                      // Update the item's status in the global orders collection (for seller page)
                      final topOrderRef = FirebaseFirestore.instance.collection('orders').doc(widget.orderId);
                      final topOrderSnap = await topOrderRef.get();
                      if (topOrderSnap.exists) {
                        final topOrderData = topOrderSnap.data() as Map<String, dynamic>;
                        final topOrderItems = List<Map<String, dynamic>>.from(topOrderData['items'] ?? []);
                        for (var i = 0; i < topOrderItems.length; i++) {
                          if (topOrderItems[i]['name'] == widget.name && topOrderItems[i]['status'] == widget.itemStatus) {
                            topOrderItems[i] = {
                              ...topOrderItems[i],
                              'status': 'History',
                            };
                          }
                        }
                        await topOrderRef.update({'items': topOrderItems});
                      }
                      if (mounted) setState(() => loading = false);
                    },
                  ),
                ],
              ),
            if (widget.status == 'To Receive')
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  onPressed: loading
                      ? null
                      : () async {
                          setState(() => loading = true);
                          // Update the item's status in the user's subcollection
                          final orderRef = FirebaseFirestore.instance
                              .collection('users')
                              .doc(widget.user.uid)
                              .collection('orders')
                              .doc(widget.orderId);
                          final orderSnap = await orderRef.get();
                          int orderedQty = widget.qty;
                          if (orderSnap.exists) {
                            final orderData = orderSnap.data() as Map<String, dynamic>;
                            final orderItems = List<Map<String, dynamic>>.from(orderData['items'] ?? []);
                            for (var i = 0; i < orderItems.length; i++) {
                              if (orderItems[i]['name'] == widget.name && orderItems[i]['status'] == widget.itemStatus) {
                                orderedQty = orderItems[i]['quantity'] ?? widget.qty;
                                orderItems[i] = {
                                  ...orderItems[i],
                                  'status': 'Order Completed',
                                };
                              }
                            }
                            final allCompleted = orderItems.every((item) => item['status'] == 'Order Completed');
                            await orderRef.update({
                              'items': orderItems,
                              if (allCompleted) 'status': 'Order Completed',
                            });
                          }
                          // Update the item's status in the global orders collection (for seller page)
                          final topOrderRef = FirebaseFirestore.instance.collection('orders').doc(widget.orderId);
                          final topOrderSnap = await topOrderRef.get();
                          if (topOrderSnap.exists) {
                            final topOrderData = topOrderSnap.data() as Map<String, dynamic>;
                            final topOrderItems = List<Map<String, dynamic>>.from(topOrderData['items'] ?? []);
                            for (var i = 0; i < topOrderItems.length; i++) {
                              if (topOrderItems[i]['name'] == widget.name && topOrderItems[i]['status'] == widget.itemStatus) {
                                topOrderItems[i] = {
                                  ...topOrderItems[i],
                                  'status': 'Order Completed',
                                };
                              }
                            }
                            final allCompleted = topOrderItems.every((item) => item['status'] == 'Order Completed');
                            await topOrderRef.update({
                              'items': topOrderItems,
                              if (allCompleted) 'status': 'Order Completed',
                            });
                          }
                          // Record sale in 'sales' collection and increment product sales by quantity
                          final productRef = FirebaseFirestore.instance.collection('products').doc(widget.productId);
                          await FirebaseFirestore.instance.runTransaction((transaction) async {
                            final snapshot = await transaction.get(productRef);
                            final currentSales = (snapshot.data()?['sales'] ?? 0) as int;
                            transaction.update(productRef, {'sales': currentSales + orderedQty});
                          });
                          await FirebaseFirestore.instance.collection('sales').add({
                            'productId': widget.productId,
                            'quantity': orderedQty,
                            'userId': widget.user.uid,
                            'orderId': widget.orderId,
                            'timestamp': FieldValue.serverTimestamp(),
                          });
                          if (mounted) setState(() => loading = false);
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                  ),
                  child: loading
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Confirm Order'),
                ),
              ),
            // Add Cancel button for all statuses except 'Order Completed'
            if (widget.status != 'Order Completed')
              Align(
                alignment: Alignment.centerRight,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.cancel, color: Colors.red),
                  label: const Text('Cancel', style: TextStyle(color: Colors.red)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.red),
                  ),
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Cancel Order'),
                        content: const Text('Are you sure you want to cancel this order item?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            child: const Text('No'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(true),
                            child: const Text('Yes, Cancel'),
                          ),
                        ],
                      ),
                    );
                    if (confirm != true) return;
                    // Update the item's status in the user's subcollection
                    final orderRef = FirebaseFirestore.instance
                        .collection('users')
                        .doc(widget.user.uid)
                        .collection('orders')
                        .doc(widget.orderId);
                    final orderSnap = await orderRef.get();
                    if (orderSnap.exists) {
                      final orderData = orderSnap.data() as Map<String, dynamic>;
                      final orderItems = List<Map<String, dynamic>>.from(orderData['items'] ?? []);
                      for (var i = 0; i < orderItems.length; i++) {
                        if (orderItems[i]['name'] == widget.name && orderItems[i]['status'] == widget.itemStatus) {
                          orderItems[i] = {
                            ...orderItems[i],
                            'status': 'Cancelled',
                          };
                        }
                      }
                      await orderRef.update({'items': orderItems});
                    }
                    // Update the item's status in the global orders collection (for seller page)
                    final topOrderRef = FirebaseFirestore.instance.collection('orders').doc(widget.orderId);
                    final topOrderSnap = await topOrderRef.get();
                    if (topOrderSnap.exists) {
                      final topOrderData = topOrderSnap.data() as Map<String, dynamic>;
                      final topOrderItems = List<Map<String, dynamic>>.from(topOrderData['items'] ?? []);
                      for (var i = 0; i < topOrderItems.length; i++) {
                        if (topOrderItems[i]['name'] == widget.name && topOrderItems[i]['status'] == widget.itemStatus) {
                          topOrderItems[i] = {
                            ...topOrderItems[i],
                            'status': 'Cancelled',
                          };
                        }
                      }
                      await topOrderRef.update({'items': topOrderItems});
                    }
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
} 