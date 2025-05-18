import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'checkout_page.dart';

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  final Set<String> selectedItems = {}; // Track selected cart item IDs for deletion
  bool showCheckboxes = false; // Control visibility of checkboxes
  String _selectedPaymentMethod = 'Cash on Delivery'; // Default payment method

  Stream<List<Map<String, dynamic>>> get cartStream {
    final user = FirebaseAuth.instance.currentUser; // Get the current user
    if (user == null) {
      return const Stream.empty(); // Return an empty stream if no user is logged in
    }

    return FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('cart')
        .snapshots()
        .asyncMap((snapshot) async {
          List<Map<String, dynamic>> items = [];
          for (var doc in snapshot.docs) {
            final data = doc.data();
            final productId = data['productId'];
            final productDoc = await FirebaseFirestore.instance
                .collection('products')
                .doc(productId)
                .get();
            if (productDoc.exists) {
              final productData = productDoc.data();
              if (productData != null) {
                productData['id'] = productDoc.id; // Always set the product's real ID
                // Ensure sellerId is included from cart doc if not present in productData
                if (data['sellerId'] != null) {
                  productData['sellerId'] = data['sellerId'];
                }
                items.add({
                  'id': doc.id,
                  'product': productData,
                  'quantity': data['quantity'],
                });
              }
            }
          }
          return items;
        });
  }

  void _removeFromCart(String cartItemId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('cart')
        .doc(cartItemId)
        .delete();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Item removed from cart')),
      );
    }
  }

  void _toggleCheckboxes() {
    setState(() {
      showCheckboxes = !showCheckboxes; // Toggle checkbox visibility
      if (!showCheckboxes) {
        selectedItems.clear(); // Clear selections when hiding checkboxes
      }
    });
  }

  void _confirmDeletion() {
    if (selectedItems.isEmpty) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Deletion'),
        content: const Text('Are you sure you want to remove the selected items from the cart?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), // Cancel
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final user = FirebaseAuth.instance.currentUser;
              if (user == null) return;

              final cartRef = FirebaseFirestore.instance
                  .collection('users')
                  .doc(user.uid)
                  .collection('cart');

              for (var cartItemId in selectedItems) {
                await cartRef.doc(cartItemId).delete(); // Remove from Firestore
              }

              setState(() {
                selectedItems.clear();
                showCheckboxes = false; // Hide checkboxes after deletion
              });

              Navigator.pop(context); // Close dialog
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Selected items removed from cart')),
                );
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser; // Get the current user

    if (user == null) {
      return const Scaffold(
        body: SizedBox.shrink(), // Return an empty container
      );
    }

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text(
          'Cart',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        centerTitle: true,
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: cartStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
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
                ],
              ),
            );
          }

          final cartItems = snapshot.data!;
          return ListView(
            padding: const EdgeInsets.all(8.0),
            children: [
              if (cartItems.isNotEmpty)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: showCheckboxes ? _toggleCheckboxes : () => setState(() => showCheckboxes = true),
                      child: Text(
                        showCheckboxes ? 'Cancel' : 'Delete',
                        style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                      ),
                    ),
                    if (showCheckboxes)
                      ElevatedButton(
                        onPressed: _confirmDeletion,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        ),
                        child: const Text(
                          'Confirm',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
              const SizedBox(height: 8),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16.0),
                itemCount: cartItems.length,
                itemBuilder: (context, index) {
                  final cartItem = cartItems[index];
                  return CartItemTile(
                    cartItem: cartItem,
                    showCheckboxes: showCheckboxes,
                    selectedItems: selectedItems,
                    onCheckboxChanged: (isSelected) {
                      setState(() {
                        if (isSelected == true) {
                          selectedItems.add(cartItem['id']);
                        } else {
                          selectedItems.remove(cartItem['id']);
                        }
                      });
                    },
                    onRemove: () => _removeFromCart(cartItem['id']),
                  );
                },
                separatorBuilder: (context, index) => const Divider(
                  thickness: 1,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 16),
              _OrderSummary(
                cartItems: cartItems,
                selectedPaymentMethod: _selectedPaymentMethod,
                onPaymentMethodChanged: (String? value) {
                  if (value != null) {
                    setState(() {
                      _selectedPaymentMethod = value;
                    });
                  }
                },
                onCheckout: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CheckoutPage(
                        cartItems: cartItems,
                        paymentMethod: _selectedPaymentMethod,
                      ),
                    ),
                  );
                },
              ),
               const SizedBox(height: 100),
            ],
          );
        },
      ),
    );
  }
}

class _OrderSummary extends StatelessWidget {
  final List<Map<String, dynamic>> cartItems;
  final String selectedPaymentMethod;
  final Function(String?) onPaymentMethodChanged;
  final Function() onCheckout;
  const _OrderSummary({
    required this.cartItems,
    required this.selectedPaymentMethod,
    required this.onPaymentMethodChanged,
    required this.onCheckout,
  });

  @override
  Widget build(BuildContext context) {
    double subtotal = 0;
    for (var item in cartItems) {
      final price = (item['product']['price'] ?? 0).toDouble();
      final quantity = (item['quantity'] ?? 1) as int;
      subtotal += price * quantity;
    }
    const shipping = 0.0;
    const estimatedTax = 0.0;
    final total = subtotal + shipping + estimatedTax;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Order summary', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Item(s) subtotal'),
              Text('₱${subtotal.toStringAsFixed(2)}'),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text('Shipping'),
              Text('Free'),
            ],
          ),
          const SizedBox(height: 8),
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
              const Text('Estimated total', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('₱${total.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Text('Payment Method: ', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButton<String>(
                  value: selectedPaymentMethod,
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
                  onChanged: onPaymentMethodChanged,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onCheckout,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Checkout', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
            ),
          ),
         
        ],
      ),
    );
  }
  
}

class CartItemTile extends StatelessWidget {
  final Map<String, dynamic> cartItem;
  final bool showCheckboxes;
  final Set<String> selectedItems;
  final ValueChanged<bool?> onCheckboxChanged;
  final VoidCallback onRemove;

  const CartItemTile({
    super.key,
    required this.cartItem,
    required this.showCheckboxes,
    required this.selectedItems,
    required this.onCheckboxChanged,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final product = cartItem['product'];
    final quantity = cartItem['quantity'];
    return InkWell(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showCheckboxes)
            Checkbox(
              value: selectedItems.contains(cartItem['id']),
              onChanged: onCheckboxChanged,
            ),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: (product['image'] != null && product['image'].toString().startsWith('http'))
                ? Image.network(
                    product['image'],
                    width: 100,
                    height: 100,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(Icons.broken_image, size: 100, color: Colors.grey);
                    },
                  )
                : Image.asset(
                    product['image'] ?? 'assets/images/image.png',
                    width: 100,
                    height: 100,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(Icons.broken_image, size: 100, color: Colors.grey);
                    },
                  ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product['name'],
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Text(
                  '₱${product['price']}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: onRemove,
                  child: const Text(
                    'Remove',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.red,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Column(
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () {
                      if (quantity > 1) {
                        FirebaseFirestore.instance
                            .collection('users')
                            .doc(FirebaseAuth.instance.currentUser!.uid)
                            .collection('cart')
                            .doc(cartItem['id'])
                            .update({'quantity': quantity - 1});
                      }
                    },
                    icon: const Icon(Icons.remove, color: Colors.black),
                  ),
                  Text(
                    '$quantity',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    onPressed: () {
                      FirebaseFirestore.instance
                          .collection('users')
                          .doc(FirebaseAuth.instance.currentUser!.uid)
                          .collection('cart')
                          .doc(cartItem['id'])
                          .update({'quantity': quantity + 1});
                    },
                    icon: const Icon(Icons.add, color: Colors.black),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
