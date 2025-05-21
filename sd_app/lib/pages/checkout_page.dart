import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CheckoutPage extends StatelessWidget {
  final List<Map<String, dynamic>> cartItems;

  const CheckoutPage({
    super.key,
    required this.cartItems,
  });

  @override
  Widget build(BuildContext context) {
    return _CheckoutPageBody(cartItems: cartItems);
  }
}

class _CheckoutPageBody extends StatefulWidget {
  final List<Map<String, dynamic>> cartItems;

  const _CheckoutPageBody({Key? key, required this.cartItems}) : super(key: key);
  @override
  State<_CheckoutPageBody> createState() => _CheckoutPageBodyState();
}

class _CheckoutPageBodyState extends State<_CheckoutPageBody> {
  bool loading = false;
  String? _address;
  final TextEditingController _addressController = TextEditingController();
  bool _addressLoading = true;
  String? _gcashRefNumber;
  String _selectedPaymentMethod = 'Cash on Delivery';

  @override
  void initState() {
    super.initState();
    _fetchAddress();
  }

  Future<void> _fetchAddress() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) {
        setState(() {
          _address = null;
          _addressController.text = '';
          _addressLoading = false;
        });
      }
      return;
    }
    final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    final data = doc.data();
    final address = data != null && data['address'] != null && data['address'].toString().isNotEmpty
        ? data['address'] as String
        : '';
    if (mounted) {
      setState(() {
        _address = address;
        _addressController.text = address;
        _addressLoading = false;
      });
    }
  }

  Future<Map<String, dynamic>?> _promptAndValidateGCashNumber(BuildContext context) async {
    final TextEditingController numberController = TextEditingController();
    return await showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text('Enter GCash Number'),
          content: TextField(
            controller: numberController,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'GCash Phone Number',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final number = numberController.text.trim();
                if (number.isEmpty) return;
                // Search for user with this GCash number
                final query = await FirebaseFirestore.instance.collection('users').where('gcashNumber', isEqualTo: number).get();
                if (query.docs.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('GCash number does not exist.')),
                  );
                  return;
                }
                final userDoc = query.docs.first;
                final data = userDoc.data();
                Navigator.of(context).pop({
                  'gcashNumber': data['gcashNumber'],
                  'gcashBalance': (data['gcashBalance'] ?? 0).toDouble(),
                  'userId': userDoc.id,
                });
              },
              child: const Text('Continue'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    double subtotal = 0;
    for (var item in widget.cartItems) {
      final price = (item['product']['price'] ?? 0).toDouble();
      final quantity = (item['quantity'] ?? 1) as int;
      subtotal += price * quantity;
    }
    const shipping = 0.0;
    const estimatedTax = 0.0;
    final total = subtotal + shipping + estimatedTax;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout'),
        centerTitle: true,
      ),
      resizeToAvoidBottomInset: true,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Order Summary', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 12),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: widget.cartItems.length,
              separatorBuilder: (context, index) => const Divider(),
              itemBuilder: (context, index) {
                final item = widget.cartItems[index];
                final product = item['product'];
                final quantity = item['quantity'];
                return ListTile(
                  leading: (product['image'] != null && product['image'].toString().startsWith('http'))
                      ? Image.network(product['image'], width: 50, height: 50, fit: BoxFit.cover)
                      : Image.asset(product['image'] ?? 'assets/images/image.png', width: 50, height: 50, fit: BoxFit.cover),
                  title: Text(product['name'] ?? ''),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('₱${product['price']} x $quantity'),
                      Text('Product ID: ${product['id'] ?? 'N/A'}', style: TextStyle(color: Colors.red, fontSize: 12)),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Subtotal'),
                Text('₱${subtotal.toStringAsFixed(2)}'),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text('Shipping'),
                Text('Free'),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Estimated tax'),
                Text('₱${estimatedTax.toStringAsFixed(2)}'),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total', style: TextStyle(fontWeight: FontWeight.bold)),
                Text('₱${total.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                const Text('Payment Method: ', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButton<String>(
                    value: _selectedPaymentMethod,
                    isExpanded: true,
                    items: const [
                      DropdownMenuItem(
                        value: 'Cash on Delivery',
                        child: Text('Cash on Delivery'),
                      ),
                      DropdownMenuItem(
                        value: 'GCash Online Payment',
                        child: Text('GCash Online Payment'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedPaymentMethod = value;
                        });
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Address Section
            _addressLoading
                ? const Center(child: CircularProgressIndicator())
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Shipping Address', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _addressController,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: 'Enter your shipping address',
                        ),
                        onChanged: (val) {
                          setState(() {});
                        },
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: (loading || _addressController.text.trim().isEmpty) ? null : () async {
                  final user = FirebaseAuth.instance.currentUser;
                  if (user == null) return;
                  final firestore = FirebaseFirestore.instance;
                  if (_selectedPaymentMethod == 'GCash Online Payment') {
                    // Prompt for GCash number and validate
                    final gcashData = await _promptAndValidateGCashNumber(context);
                    if (gcashData == null) return;
                    final gcashNumber = gcashData['gcashNumber'];
                    double balance = gcashData['gcashBalance'];
                    final gcashUserId = gcashData['userId'];
                    // Show transaction page
                    final confirmed = await Navigator.push<bool>(
                      context,
                      MaterialPageRoute(
                        builder: (context) => GCashTransactionPage(
                          balance: balance,
                          amount: total,
                          gcashNumber: gcashNumber,
                          onCancel: () => Navigator.of(context).pop(false),
                          onConfirm: () => Navigator.of(context).pop(true),
                        ),
                      ),
                    );
                    if (confirmed != true) return;
                    // Deduct balance from the correct user
                    await firestore.collection('users').doc(gcashUserId).set({'gcashBalance': balance - total}, SetOptions(merge: true));
                    // Place order as before, then redirect to home
                    setState(() => loading = true);
                    try {
                      // Validate that every product has a sellerId
                      for (var item in widget.cartItems) {
                        final product = item['product'];
                        if (product['sellerId'] == null || product['sellerId'].toString().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('One or more products are missing a seller. Please contact support.')),
                          );
                          return;
                        }
                      }
                      // 1. Prepare order data
                      final orderItems = widget.cartItems.map((item) {
                        final product = item['product'];
                        return {
                          'productId': product['id'],
                          'name': product['name'],
                          'image': product['image'],
                          'price': product['price'],
                          'quantity': item['quantity'],
                          'sellerId': product['sellerId'],
                          'status': 'Order Placed',
                        };
                      }).toList();
                      // Collect all unique sellerIds for Firestore rules
                      final sellerIds = <String>{};
                      for (var item in widget.cartItems) {
                        final product = item['product'];
                        if (product['sellerId'] != null) {
                          sellerIds.add(product['sellerId']);
                        }
                      }
                      // Save address to user profile if changed
                      if (_addressController.text.trim() != (_address ?? '')) {
                        await firestore.collection('users').doc(user.uid).set({'address': _addressController.text.trim()}, SetOptions(merge: true));
                      }
                      final orderData = {
                        'buyerId': user.uid,
                        'items': orderItems,
                        'total': total,
                        'paymentMethod': _selectedPaymentMethod,
                        'status': 'Order Placed',
                        'timestamp': FieldValue.serverTimestamp(),
                        'sellerIds': sellerIds.toList(),
                        'address': _addressController.text.trim(),
                        if (_selectedPaymentMethod == 'GCash Online Payment') 'gcashRefNumber': gcashNumber,
                      };
                      // 2. Create order in top-level 'orders' collection
                      final orderRef = await firestore.collection('orders').add(orderData);
                      // 3. Add order ref to buyer's subcollection
                      await firestore
                          .collection('users')
                          .doc(user.uid)
                          .collection('orders')
                          .doc(orderRef.id)
                          .set(orderData);
                      // 4. Notify the buyer
                      await firestore
                          .collection('users')
                          .doc(user.uid)
                          .collection('notifications')
                          .add({
                        'title': 'Order Placed',
                        'body': 'Your order has been successfully placed!',
                        'timestamp': FieldValue.serverTimestamp(),
                        'read': false,
                      });
                      // 5. Notify each seller (only once per seller)
                      final notifiedSellers = <String>{};
                      for (var item in widget.cartItems) {
                        final product = item['product'];
                        final sellerId = product['sellerId'];
                        if (sellerId != null && sellerId != user.uid && !notifiedSellers.contains(sellerId)) {
                          await firestore
                              .collection('users')
                              .doc(sellerId)
                              .collection('notifications')
                              .add({
                            'title': 'New Order',
                            'body': 'Your product(s) have been ordered.',
                            'timestamp': FieldValue.serverTimestamp(),
                            'read': false,
                          });
                          notifiedSellers.add(sellerId);
                        }
                      }
                      // 6. Clear the cart
                      final cartRef = firestore.collection('users').doc(user.uid).collection('cart');
                      final cartSnapshot = await cartRef.get();
                      for (var doc in cartSnapshot.docs) {
                        await doc.reference.delete();
                      }
                      // 7. Redirect to home
                      if (context.mounted) {
                        Navigator.of(context).popUntil((route) => route.isFirst);
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Order failed: $e')),
                        );
                      }
                    } finally {
                      if (mounted) setState(() => loading = false);
                    }
                    return;
                  }
                  setState(() => loading = true);
                  try {
                    // Validate that every product has a sellerId
                    for (var item in widget.cartItems) {
                      final product = item['product'];
                      if (product['sellerId'] == null || product['sellerId'].toString().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('One or more products are missing a seller. Please contact support.')),
                        );
                        return;
                      }
                    }
                    // 1. Prepare order data
                    final orderItems = widget.cartItems.map((item) {
                      final product = item['product'];
                      return {
                        'productId': product['id'],
                        'name': product['name'],
                        'image': product['image'],
                        'price': product['price'],
                        'quantity': item['quantity'],
                        'sellerId': product['sellerId'],
                        'status': 'Order Placed',
                      };
                    }).toList();
                    // Collect all unique sellerIds for Firestore rules
                    final sellerIds = <String>{};
                    for (var item in widget.cartItems) {
                      final product = item['product'];
                      if (product['sellerId'] != null) {
                        sellerIds.add(product['sellerId']);
                      }
                    }
                    // Save address to user profile if changed
                    if (_addressController.text.trim() != (_address ?? '')) {
                      await firestore.collection('users').doc(user.uid).set({'address': _addressController.text.trim()}, SetOptions(merge: true));
                    }
                    final orderData = {
                      'buyerId': user.uid,
                      'items': orderItems,
                      'total': total,
                      'paymentMethod': _selectedPaymentMethod,
                      'status': 'Order Placed',
                      'timestamp': FieldValue.serverTimestamp(),
                      'sellerIds': sellerIds.toList(),
                      'address': _addressController.text.trim(),
                      if (_selectedPaymentMethod == 'GCash Online Payment') 'gcashRefNumber': _gcashRefNumber,
                    };

                    // 2. Create order in top-level 'orders' collection
                    final orderRef = await firestore.collection('orders').add(orderData);

                    // 3. Add order ref to buyer's subcollection
                    await firestore
                        .collection('users')
                        .doc(user.uid)
                        .collection('orders')
                        .doc(orderRef.id)
                        .set(orderData);

                    // 4. Notify the buyer
                    await firestore
                        .collection('users')
                        .doc(user.uid)
                        .collection('notifications')
                        .add({
                      'title': 'Order Placed',
                      'body': 'Your order has been successfully placed!',
                      'timestamp': FieldValue.serverTimestamp(),
                      'read': false,
                    });

                    // 5. Notify each seller (only once per seller)
                    final notifiedSellers = <String>{};
                    for (var item in widget.cartItems) {
                      final product = item['product'];
                      final sellerId = product['sellerId'];
                      if (sellerId != null && sellerId != user.uid && !notifiedSellers.contains(sellerId)) {
                        await firestore
                            .collection('users')
                            .doc(sellerId)
                            .collection('notifications')
                            .add({
                          'title': 'New Order',
                          'body': 'Your product(s) have been ordered.',
                          'timestamp': FieldValue.serverTimestamp(),
                          'read': false,
                        });
                        notifiedSellers.add(sellerId);
                      }
                    }

                    // 6. Clear the cart
                    final cartRef = firestore.collection('users').doc(user.uid).collection('cart');
                    final cartSnapshot = await cartRef.get();
                    for (var doc in cartSnapshot.docs) {
                      await doc.reference.delete();
                    }

                    // 7. Show success dialog
                    if (context.mounted) {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Order Placed!'),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Your order has been placed using $_selectedPaymentMethod.'),
                              const SizedBox(height: 8),
                              Text('Product IDs:', style: TextStyle(fontWeight: FontWeight.bold)),
                              ...orderItems.map((item) => Text(item['productId'] ?? 'N/A')).toList(),
                            ],
                          ),
                          actions: [
                            TextButton(
                              onPressed: () {
                                Navigator.pop(context); // Close dialog
                                Navigator.pop(context); // Go back to cart
                              },
                              child: const Text('OK'),
                            ),
                          ],
                        ),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Order failed: $e')),
                      );
                    }
                  } finally {
                    if (mounted) setState(() => loading = false);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: loading
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Place Order', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
            SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
          ],
        ),
      ),
    );
  }
}

class GCashTransactionPage extends StatelessWidget {
  final double balance;
  final double amount;
  final String gcashNumber;
  final VoidCallback onCancel;
  final VoidCallback onConfirm;
  const GCashTransactionPage({super.key, required this.balance, required this.amount, required this.gcashNumber, required this.onCancel, required this.onConfirm});

  @override
  Widget build(BuildContext context) {
    final isSufficient = balance >= amount;
    return Scaffold(
      backgroundColor: const Color(0xFFf5f7fa),
      body: Center(
        child: Container(
          width: 320,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 16)],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset('assets/icons/gcash_logo.png', height: 32),
              const SizedBox(height: 8),
              const Text('Dragonpay', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('PAY WITH'),
                  Text('GCash', style: TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(gcashNumber, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  Text('PHP ${balance.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
              const Divider(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('YOU ARE ABOUT TO PAY'),
                  Text('PHP ${amount.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text('PHP ${amount.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 16),
              if (!isSufficient)
                Text('Insufficient balance', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onCancel,
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: isSufficient ? onConfirm : null,
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                      child: Text('PAY PHP ${amount.toStringAsFixed(2)}'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text('Please review to ensure that the details are correct before you proceed.', style: TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
        ),
      ),
    );
  }
}