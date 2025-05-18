import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String? _selectedUserId;
  String? _selectedUserNickname;
  String _userSortOption = 'A-Z';

  Future<void> _deleteProduct(String productId) async {
    await _firestore.collection('products').doc(productId).delete();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Product deleted!')));
  }

  Future<void> _toggleHideProduct(String productId, bool currentHiddenStatus) async {
    await _firestore.collection('products').doc(productId).update({'hidden': !currentHiddenStatus});
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(currentHiddenStatus ? 'Product unhidden!' : 'Product hidden!')),
    );
  }

  Future<void> _banUnbanUser(String userId, bool isBanned) async {
    await _firestore.collection('users').doc(userId).set({'banned': !isBanned}, SetOptions(merge: true));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(isBanned ? 'User unbanned!' : 'User banned!')),
    );
  }

  Future<void> _deleteAllComments(String productId) async {
    final commentsRef = _firestore.collection('products').doc(productId).collection('comments');
    final snapshot = await commentsRef.get();
    for (var doc in snapshot.docs) {
      await doc.reference.delete();
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('All comments and ratings deleted!')));
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Admin Page'),
          centerTitle: true,
          bottom: const TabBar(
            tabs: [
              Tab(text: 'All Products'),
              Tab(text: 'User Management'),
              Tab(text: 'User Data'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // --- All Products Tab ---
            ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                // User filter dropdown
                StreamBuilder<QuerySnapshot>(
                  stream: _firestore.collection('users').snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const SizedBox();
                    final users = snapshot.data!.docs;
                    return Row(
                      children: [
                        const Text('Filter by user: ', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: DropdownButton<String>(
                            value: _selectedUserId,
                            hint: const Text('Select user'),
                            isExpanded: true,
                            items: users.map((userDoc) {
                              final data = userDoc.data() as Map<String, dynamic>;
                              final nickname = data['nickname'] ?? userDoc.id;
                              return DropdownMenuItem<String>(
                                value: userDoc.id,
                                child: Text(nickname),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedUserId = value;
                                final userDoc = users.firstWhere((u) => u.id == value);
                                final userData = userDoc.data() as Map<String, dynamic>?;
                                _selectedUserNickname = userData != null && userData['nickname'] != null ? userData['nickname'] as String : value;
                              });
                            },
                          ),
                        ),
                        if (_selectedUserId != null)
                          IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () => setState(() {
                              _selectedUserId = null;
                              _selectedUserNickname = null;
                            }),
                          ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 16),
                if (_selectedUserId != null)
                  Text('Products by: ${_selectedUserNickname ?? _selectedUserId}', style: const TextStyle(fontWeight: FontWeight.bold)),
                if (_selectedUserId != null)
                  StreamBuilder<QuerySnapshot>(
                    stream: _firestore.collection('products').where('sellerId', isEqualTo: _selectedUserId).snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final products = snapshot.data!.docs;
                      if (products.isEmpty) {
                        return const Text('No products found for this user.');
                      }
                      return ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: products.length,
                        separatorBuilder: (context, index) => const Divider(),
                        itemBuilder: (context, index) {
                          final product = products[index];
                          final data = product.data() as Map<String, dynamic>;
                          final productId = product.id;
                          final productName = data['name'] ?? 'No Name';
                          final productHidden = data['hidden'] ?? false;
                          return ListTile(
                            leading: (data['image'] != null && data['image'].toString().startsWith('http'))
                                ? Image.network(data['image'], width: 50, height: 50, fit: BoxFit.cover)
                                : Image.asset(data['image'] ?? 'assets/images/image.png', width: 50, height: 50, fit: BoxFit.cover),
                            title: Text(productName),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(productHidden ? 'Hidden' : 'Visible'),
                                Text('Product ID: $productId', style: TextStyle(color: Colors.red, fontSize: 12)),
                              ],
                            ),
                            trailing: PopupMenuButton<String>(
                              onSelected: (value) {
                                if (value == 'edit') {
                                  Navigator.pushNamed(context, '/add_product', arguments: {
                                    'edit': true,
                                    'productId': productId,
                                    'productData': data,
                                  });
                                } else if (value == 'delete') {
                                  _deleteProduct(productId);
                                } else if (value == 'toggle') {
                                  _toggleHideProduct(productId, productHidden);
                                } else if (value == 'delete_comments') {
                                  _deleteAllComments(productId);
                                }
                              },
                              itemBuilder: (context) => [
                                const PopupMenuItem(value: 'edit', child: Text('Edit')),
                                const PopupMenuItem(value: 'delete', child: Text('Delete')),
                                PopupMenuItem(value: 'toggle', child: Text(productHidden ? 'Unhide' : 'Hide')),
                                const PopupMenuItem(value: 'delete_comments', child: Text('Delete All Comments')),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
                if (_selectedUserId == null) ...[
                  const Text('All Products', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  const SizedBox(height: 12),
                  StreamBuilder<QuerySnapshot>(
                    stream: _firestore.collection('products').snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final products = snapshot.data!.docs;
                      if (products.isEmpty) {
                        return const Text('No products found.');
                      }
                      return ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: products.length,
                        separatorBuilder: (context, index) => const Divider(),
                        itemBuilder: (context, index) {
                          final product = products[index];
                          final data = product.data() as Map<String, dynamic>;
                          final productId = product.id;
                          final productName = data['name'] ?? 'No Name';
                          final productHidden = data['hidden'] ?? false;
                          return ListTile(
                            leading: (data['image'] != null && data['image'].toString().startsWith('http'))
                                ? Image.network(data['image'], width: 50, height: 50, fit: BoxFit.cover)
                                : Image.asset(data['image'] ?? 'assets/images/image.png', width: 50, height: 50, fit: BoxFit.cover),
                            title: Text(productName),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(productHidden ? 'Hidden' : 'Visible'),
                                Text('Product ID: $productId', style: TextStyle(color: Colors.red, fontSize: 12)),
                              ],
                            ),
                            trailing: PopupMenuButton<String>(
                              onSelected: (value) {
                                if (value == 'edit') {
                                  Navigator.pushNamed(context, '/add_product', arguments: {
                                    'edit': true,
                                    'productId': productId,
                                    'productData': data,
                                  });
                                } else if (value == 'delete') {
                                  _deleteProduct(productId);
                                } else if (value == 'toggle') {
                                  _toggleHideProduct(productId, productHidden);
                                } else if (value == 'delete_comments') {
                                  _deleteAllComments(productId);
                                }
                              },
                              itemBuilder: (context) => [
                                const PopupMenuItem(value: 'edit', child: Text('Edit')),
                                const PopupMenuItem(value: 'delete', child: Text('Delete')),
                                PopupMenuItem(value: 'toggle', child: Text(productHidden ? 'Unhide' : 'Hide')),
                                const PopupMenuItem(value: 'delete_comments', child: Text('Delete All Comments')),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
                ],
              ],
            ),
            // --- User Management Tab ---
            ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                Row(
                  children: [
                    const Text('Sort by: ', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(width: 8),
                    DropdownButton<String>(
                      value: _userSortOption,
                      items: const [
                        DropdownMenuItem(value: 'A-Z', child: Text('Nickname (A-Z)')),
                        DropdownMenuItem(value: 'Z-A', child: Text('Nickname (Z-A)')),
                        DropdownMenuItem(value: 'Banned', child: Text('Banned First')),
                        DropdownMenuItem(value: 'Unbanned', child: Text('Unbanned First')),
                      ],
                      onChanged: (value) {
                        if (value != null) setState(() => _userSortOption = value);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                StreamBuilder<QuerySnapshot>(
                  stream: _firestore.collection('users').snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    List<QueryDocumentSnapshot> users = snapshot.data!.docs;
                    // Sort users based on selected option
                    if (_userSortOption == 'A-Z') {
                      users.sort((a, b) {
                        final an = (a.data() as Map<String, dynamic>)['nickname'] ?? '';
                        final bn = (b.data() as Map<String, dynamic>)['nickname'] ?? '';
                        return an.toString().toLowerCase().compareTo(bn.toString().toLowerCase());
                      });
                    } else if (_userSortOption == 'Z-A') {
                      users.sort((a, b) {
                        final an = (a.data() as Map<String, dynamic>)['nickname'] ?? '';
                        final bn = (b.data() as Map<String, dynamic>)['nickname'] ?? '';
                        return bn.toString().toLowerCase().compareTo(an.toString().toLowerCase());
                      });
                    } else if (_userSortOption == 'Banned') {
                      users.sort((a, b) {
                        final ab = (a.data() as Map<String, dynamic>)['banned'] ?? false;
                        final bb = (b.data() as Map<String, dynamic>)['banned'] ?? false;
                        return (bb ? 1 : 0) - (ab ? 1 : 0);
                      });
                    } else if (_userSortOption == 'Unbanned') {
                      users.sort((a, b) {
                        final ab = (a.data() as Map<String, dynamic>)['banned'] ?? false;
                        final bb = (b.data() as Map<String, dynamic>)['banned'] ?? false;
                        return (ab ? 1 : 0) - (bb ? 1 : 0);
                      });
                    }
                    if (users.isEmpty) {
                      return const Text('No users found.');
                    }
                    return ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: users.length,
                      separatorBuilder: (context, index) => const Divider(),
                      itemBuilder: (context, index) {
                        final user = users[index];
                        final data = user.data() as Map<String, dynamic>;
                        final userId = user.id;
                        final nickname = data['nickname'] ?? 'No nickname';
                        final isBanned = data['banned'] ?? false;
                        return ListTile(
                          leading: Icon(isBanned ? Icons.block : Icons.person, color: isBanned ? Colors.red : Colors.blue),
                          title: Text(nickname),
                          subtitle: Text(userId),
                          trailing: TextButton(
                            onPressed: () => _banUnbanUser(userId, isBanned),
                            child: Text(isBanned ? 'Unban' : 'Ban', style: TextStyle(color: isBanned ? Colors.green : Colors.red)),
                          ),
                        );
                      },
                    );
                  },
                ),
              ],
            ),
            // --- User Data Tab ---
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: _UserDataManagementTab(firestore: _firestore),
            ),
          ],
        ),
      ),
    );
  }
}

class _UserDataManagementTab extends StatefulWidget {
  final FirebaseFirestore firestore;
  const _UserDataManagementTab({required this.firestore});

  @override
  State<_UserDataManagementTab> createState() => _UserDataManagementTabState();
}

class _UserDataManagementTabState extends State<_UserDataManagementTab> {
  String? _selectedUserId;
  String? _selectedUserNickname;

  Future<void> _deleteAll(String collection) async {
    if (!mounted) return;
    if (_selectedUserId == null) return;
    final ref = widget.firestore.collection('users').doc(_selectedUserId).collection(collection);
    final snapshot = await ref.get();
    for (var doc in snapshot.docs) {
      await doc.reference.delete();
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('All $collection deleted for user.')));
    setState(() {}); // Refresh
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        StreamBuilder<QuerySnapshot>(
          stream: widget.firestore.collection('users').snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const SizedBox();
            final users = snapshot.data!.docs;
            return Row(
              children: [
                const Text('Select user: ', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButton<String>(
                    value: _selectedUserId,
                    hint: const Text('Select user'),
                    isExpanded: true,
                    items: users.map((userDoc) {
                      final data = userDoc.data() as Map<String, dynamic>;
                      final nickname = data['nickname'] ?? userDoc.id;
                      return DropdownMenuItem<String>(
                        value: userDoc.id,
                        child: Text(nickname),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedUserId = value;
                        final userDoc = users.firstWhere((u) => u.id == value);
                        final userData = userDoc.data() as Map<String, dynamic>?;
                        _selectedUserNickname = userData != null && userData['nickname'] != null ? userData['nickname'] as String : value;
                      });
                    },
                  ),
                ),
                if (_selectedUserId != null)
                  IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () => setState(() {
                      _selectedUserId = null;
                      _selectedUserNickname = null;
                    }),
                  ),
              ],
            );
          },
        ),
        const SizedBox(height: 16),
        if (_selectedUserId != null) ...[
          Text('User: ${_selectedUserNickname ?? _selectedUserId}', style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          // Cart
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Cart', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ElevatedButton(
                onPressed: () => _deleteAll('cart'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Delete All'),
              ),
            ],
          ),
          StreamBuilder<QuerySnapshot>(
            stream: widget.firestore.collection('users').doc(_selectedUserId).collection('cart').snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const SizedBox();
              final docs = snapshot.data!.docs;
              if (docs.isEmpty) return const Text('No cart items.');
              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: docs.length,
                separatorBuilder: (context, i) => const Divider(),
                itemBuilder: (context, i) {
                  final data = docs[i].data() as Map<String, dynamic>;
                  final product = data['product'] ?? {};
                  return ListTile(
                    leading: (product['image'] != null && product['image'].toString().startsWith('http'))
                        ? Image.network(product['image'], width: 40, height: 40, fit: BoxFit.cover)
                        : Image.asset(product['image'] ?? 'assets/images/image.png', width: 40, height: 40, fit: BoxFit.cover),
                    title: Text(product['name'] ?? 'No Name'),
                    subtitle: Text('Qty: ${data['quantity'] ?? 1}'),
                  );
                },
              );
            },
          ),
          const SizedBox(height: 24),
          // Wishlist
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Wishlist', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ElevatedButton(
                onPressed: () => _deleteAll('wishlist'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Delete All'),
              ),
            ],
          ),
          StreamBuilder<QuerySnapshot>(
            stream: widget.firestore.collection('users').doc(_selectedUserId).collection('wishlist').snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const SizedBox();
              final docs = snapshot.data!.docs;
              if (docs.isEmpty) return const Text('No wishlist items.');
              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: docs.length,
                separatorBuilder: (context, i) => const Divider(),
                itemBuilder: (context, i) {
                  final data = docs[i].data() as Map<String, dynamic>;
                  final product = data['product'] ?? {};
                  return ListTile(
                    leading: (product['image'] != null && product['image'].toString().startsWith('http'))
                        ? Image.network(product['image'], width: 40, height: 40, fit: BoxFit.cover)
                        : Image.asset(product['image'] ?? 'assets/images/image.png', width: 40, height: 40, fit: BoxFit.cover),
                    title: Text(product['name'] ?? 'No Name'),
                  );
                },
              );
            },
          ),
          const SizedBox(height: 24),
          // Orders
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Orders', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ElevatedButton(
                onPressed: () => _deleteAll('orders'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Delete All'),
              ),
            ],
          ),
          StreamBuilder<QuerySnapshot>(
            stream: widget.firestore.collection('users').doc(_selectedUserId).collection('orders').snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const SizedBox();
              final docs = snapshot.data!.docs;
              if (docs.isEmpty) return const Text('No orders.');
              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: docs.length,
                separatorBuilder: (context, i) => const Divider(),
                itemBuilder: (context, i) {
                  final data = docs[i].data() as Map<String, dynamic>;
                  final items = data['items'] as List<dynamic>? ?? [];
                  final total = data['total'] ?? 0;
                  final status = data['status'] ?? 'Unknown';
                  return ListTile(
                    title: Text('Order: ₱$total'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Status: $status'),
                        ...items.map((item) {
                          final name = item['name'] ?? 'Item';
                          final qty = item['quantity'] ?? 1;
                          return Text('- $name x$qty');
                        }).toList(),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ],
      ],
    );
  }
} 