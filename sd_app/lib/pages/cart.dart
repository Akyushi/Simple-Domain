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
  final Set<String> selectedItems = {};
  bool showCheckboxes = false;
  bool _mounted = true;

  @override
  void dispose() {
    _mounted = false;
    super.dispose();
  }

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

  void _toggleCheckboxes() {
    if (!_mounted) return;
    setState(() {
      showCheckboxes = !showCheckboxes;
      if (!showCheckboxes) {
        selectedItems.clear();
      }
    });
  }

  void _handleCheckboxChange(String itemId, bool? isSelected) {
    if (!_mounted) return;
    setState(() {
      if (isSelected == true) {
        selectedItems.add(itemId);
      } else {
        selectedItems.remove(itemId);
      }
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

    if (_mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Item removed from cart')),
      );
    }
  }

  void _removeSelectedItems() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final batch = FirebaseFirestore.instance.batch();
    for (final itemId in selectedItems) {
      final docRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('cart')
          .doc(itemId);
      batch.delete(docRef);
    }
    await batch.commit();

    if (_mounted) {
      setState(() {
        selectedItems.clear();
        showCheckboxes = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selected items removed from cart')),
      );
    }
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
        actions: [
          if (showCheckboxes) ...[
            TextButton(
              onPressed: selectedItems.isEmpty ? null : _removeSelectedItems,
              child: Text(
                'Delete (${selectedItems.length})',
                style: TextStyle(
                  color: selectedItems.isEmpty ? Colors.grey : Colors.red,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: _toggleCheckboxes,
            ),
          ],
        ],
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
          return RefreshIndicator(
            onRefresh: () async {
              await Future.delayed(const Duration(milliseconds: 700));
              setState(() {});
            },
            child: ListView(
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
                          onPressed: _removeSelectedItems,
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
                    return GestureDetector(
                      onTap: showCheckboxes ? null : () {
                        Navigator.pushNamed(
                          context,
                          '/product_details',
                          arguments: cartItem['product'],
                        );
                      },
                      child: CartItemTile(
                        cartItem: cartItem,
                        showCheckboxes: showCheckboxes,
                        selectedItems: selectedItems,
                        onCheckboxChanged: _handleCheckboxChange,
                        onRemove: () => _removeFromCart(cartItem['id']),
                      ),
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
                  onCheckout: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CheckoutPage(
                          cartItems: cartItems,
                        ),
                      ),
                    );
                  },
                ),
                 const SizedBox(height: 100),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _OrderSummary extends StatelessWidget {
  final List<Map<String, dynamic>> cartItems;
  final Function() onCheckout;
  const _OrderSummary({
    required this.cartItems,
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
  final Function(String, bool?) onCheckboxChanged;
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
              onChanged: (value) => onCheckboxChanged(cartItem['id'], value),
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
                if (!showCheckboxes)
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () async {
                          // Add to wishlist logic
                          final user = FirebaseAuth.instance.currentUser;
                          if (user == null) return;
                          final product = cartItem['product'];
                          await FirebaseFirestore.instance
                              .collection('users')
                              .doc(user.uid)
                              .collection('favorites')
                              .doc(product['id'])
                              .set(product);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Added to wishlist')),
                            );
                          }
                        },
                        child: const Icon(Icons.favorite_border, size: 20, color: Colors.red),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Remove Item'),
                              content: const Text('Are you sure you want to remove this item from the cart?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context, false),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: const Text('Remove'),
                                ),
                              ],
                            ),
                          );
                          if (confirm == true) {
                            onRemove();
                          }
                        },
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
              ],
            ),
          ),
          const SizedBox(width: 16),
          if (!showCheckboxes)
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
