import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';



class SellerPage extends StatefulWidget {
  final List<String>? productIds;
  const SellerPage({super.key, this.productIds});

  @override
  State<SellerPage> createState() => _SellerPageState();
}

class _SellerPageState extends State<SellerPage> {
  int _selectedTabIndex = 0;
  final List<String> _tabs = ['Products', 'Orders'];
  String? _profileImageUrl;
  String? _coverImageUrl;
  bool _isEditing = false;
  bool _isUploadingProfile = false;
  bool _isUploadingCover = false;
  final TextEditingController _nameController = TextEditingController();
  String _selectedSortOption = 'Featured';
  String _orderFilter = 'All';
  String _sellerName = 'Seller';
  String? _errorMessage; // Add this line

  @override
  void initState() {
    super.initState();
    _loadSellerProfile();
    _fetchSellerName();
  }

  Future<void> _fetchSellerName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get()
          .timeout(const Duration(seconds: 10));
      if (userDoc.exists) {
        final userData = userDoc.data()!;
        setState(() {
          _sellerName = (userData['nickname'] != null && userData['nickname'].toString().isNotEmpty)
              ? userData['nickname']
              : 'Seller';
          if (!_isEditing) {
            _nameController.text = _sellerName;
          }
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Unable to connect to Firestore. Please check your internet connection.';
      });
    }
  }

  Future<void> _loadSellerProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('seller_profile')
          .doc(user.uid)
          .get()
          .timeout(const Duration(seconds: 10));
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get()
          .timeout(const Duration(seconds: 10));
      if (doc.exists) {
        final data = doc.data()!;
        setState(() {
          if (data['coverImageUrl'] != null) _coverImageUrl = data['coverImageUrl'];
        });
      }
      if (userDoc.exists) {
        final userData = userDoc.data()!;
        setState(() {
          if (userData['avatarUrl'] != null) _profileImageUrl = userData['avatarUrl'];
          if (userData['nickname'] != null) _nameController.text = userData['nickname'];
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Unable to connect to Firestore. Please check your internet connection.';
      });
    }
  }

  Future<void> _uploadImage(XFile image, {required bool isProfile}) async {
    if (isProfile) setState(() => _isUploadingProfile = true);
    if (!isProfile) setState(() => _isUploadingCover = true);
    try {
      final cloudName = 'dstlwxkdr'; // TODO: Replace with your Cloudinary cloud name
      final uploadPreset = 'Unsigned'; // TODO: Replace with your unsigned upload preset
      final url = Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload');
      final request = http.MultipartRequest('POST', url)
        ..fields['upload_preset'] = uploadPreset
        ..files.add(await http.MultipartFile.fromPath('file', image.path));
      final response = await request.send();
      if (response.statusCode == 200) {
        final resStr = await response.stream.bytesToString();
        final resJson = json.decode(resStr);
        setState(() {
          if (isProfile) {
            _profileImageUrl = resJson['secure_url'];
          } else {
            _coverImageUrl = resJson['secure_url'];
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(isProfile ? 'Profile image uploaded!' : 'Background image uploaded!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Image upload failed: ${response.statusCode}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Image upload failed: $e')),
      );
    } finally {
      if (isProfile) setState(() => _isUploadingProfile = false);
      if (!isProfile) setState(() => _isUploadingCover = false);
    }
  }

  Future<void> _pickAndUploadImage({required bool isProfile}) async {
    if (!_isEditing) return;
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      await _uploadImage(pickedFile, isProfile: isProfile);
    }
  }

  Future<void> _saveProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && _nameController.text.trim().isNotEmpty && !_isUploadingProfile && !_isUploadingCover) {
      await user.updateDisplayName(_nameController.text.trim());
      if (_profileImageUrl != null) {
        await user.updatePhotoURL(_profileImageUrl);
      }
      await user.reload();
      // Save seller profile to Firestore
      final sellerProfile = {
        'name': _nameController.text.trim(),
        'profileImageUrl': _profileImageUrl ?? user.photoURL,
        'coverImageUrl': _coverImageUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      await FirebaseFirestore.instance
          .collection('seller_profile')
          .doc(user.uid)
          .set(sellerProfile, SetOptions(merge: true));
      // Also update users collection for avatar and nickname
      final userUpdate = <String, dynamic>{
        'avatarUrl': _profileImageUrl ?? user.photoURL,
        'nickname': _nameController.text.trim(),
      };
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set(userUpdate, SetOptions(merge: true));
      setState(() {
        _isEditing = false;
        _profileImageUrl = null;
        _coverImageUrl = null;
      });
      await _loadSellerProfile();
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Please log in to view your seller page.')),
      );
    }
    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Seller Page'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.cloud_off, size: 60, color: Colors.red),
              const SizedBox(height: 16),
              Text(_errorMessage!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _errorMessage = null;
                  });
                  _loadSellerProfile();
                  _fetchSellerName();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }
    // Use the cached _sellerName instead of a FutureBuilder
    Widget sellerNameWidget = Text(
      _sellerName,
      style: const TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 24,
      ),
    );

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(56),
        child: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: const Text(
            'Seller Page',
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 22,
            ),
          ),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.menu, color: Colors.black),
              onPressed: () {
                showMenu(
                  context: context,
                  position: const RelativeRect.fromLTRB(1000, 80, 0, 0),
                  items: [
                    PopupMenuItem(child: Text('Add Products')),
                    PopupMenuItem(child: Text('Orders')),
                  ],
                );
              },
            ),
          ],
        ),
      ),
      body: ListView(
        children: [
          // Cover photo section
          Stack(
            clipBehavior: Clip.none,
            children: [
              // Cover photo (background)
              GestureDetector(
                onTap: _isEditing ? () => _pickAndUploadImage(isProfile: false) : null,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      height: 180,
                      width: double.infinity,
                      color: Colors.grey[300],
                      child: _coverImageUrl != null
                          ? Image.network(_coverImageUrl!, fit: BoxFit.cover)
                          : Container(color: Colors.white),
                    ),
                    if (_isUploadingCover)
                      const CircularProgressIndicator(),
                  ],
                ),
              ),
              // Cover camera icon
              Positioned(
                right: 16,
                bottom: 16,
                child: CircleAvatar(
                  backgroundColor: Colors.black.withOpacity(0.5),
                  child: IconButton(
                    icon: const Icon(Icons.camera_alt, color: Colors.white),
                    onPressed: _isEditing ? () => _pickAndUploadImage(isProfile: false) : null,
                  ),
                ),
              ),
              // Profile image (centered, frontmost)
              Positioned(
                left: 0,
                right: 0,
                bottom: -56,
                child: Center(
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 4),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: GestureDetector(
                      onTap: _isEditing ? () => _pickAndUploadImage(isProfile: true) : null,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          CircleAvatar(
                            radius: 48,
                            backgroundColor: Colors.white,
                            child: CircleAvatar(
                              radius: 44,
                              backgroundImage: _isEditing
                                  ? (_profileImageUrl != null && _profileImageUrl!.isNotEmpty
                                      ? NetworkImage(_profileImageUrl!)
                                      : const AssetImage('assets/images/default_profile.png') as ImageProvider)
                                  : (_profileImageUrl != null && _profileImageUrl!.isNotEmpty
                                      ? NetworkImage(_profileImageUrl!)
                                      : const AssetImage('assets/images/default_profile.png') as ImageProvider),
                            ),
                          ),
                          if (_isUploadingProfile)
                            const CircularProgressIndicator(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 72),
          // Seller name and subtitle
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _isEditing
                    ? TextField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: 'Name',
                        ),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 24,
                        ),
                      )
                    : sellerNameWidget,
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (!_isEditing)
                      ElevatedButton(
                        onPressed: () => Navigator.pushNamed(context, '/add_product'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('Add Product', style: TextStyle(color: Colors.white)),
                      ),
                    if (!_isEditing)
                      const SizedBox(width: 8),
                    if (!_isEditing)
                      OutlinedButton(
                        onPressed: () {
                          setState(() {
                            _isEditing = true;
                          });
                        },
                        child: const Text('Edit Profile'),
                      ),
                    if (_isEditing)
                      Padding(
                        padding: const EdgeInsets.only(left: 8.0),
                        child: Row(
                          children: [
                            ElevatedButton(
                              onPressed: (!_isUploadingProfile && !_isUploadingCover) ? _saveProfile : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: const Text('Save', style: TextStyle(color: Colors.white)),
                            ),
                            const SizedBox(width: 8),
                            OutlinedButton(
                              onPressed: () {
                                setState(() {
                                  _isEditing = false;
                                });
                              },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.red,
                                side: const BorderSide(color: Colors.red),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: const Text('Cancel'),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Facebook-style tabs
          Container(
            height: 48,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(_tabs.length, (index) {
                final selected = _selectedTabIndex == index;
                return GestureDetector(
                  onTap: () {
                    if (!_isEditing) {
                      setState(() {
                        _selectedTabIndex = index;
                      });
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    decoration: BoxDecoration(
                      border: selected
                          ? Border(
                              bottom: BorderSide(
                                color: _isEditing ? Colors.grey[400]! : Colors.blue,
                                width: 3,
                              ),
                            )
                          : null,
                    ),
                    child: Text(
                      _tabs[index],
                      style: TextStyle(
                        color: _isEditing
                            ? Colors.grey[400]
                            : (selected ? Colors.blue : Colors.black87),
                        fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                        fontSize: 16,
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
          const Divider(height: 1),
          // Tab content placeholder
          if (_selectedTabIndex == 0)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: _buildProductsTab(),
            )
          else if (_selectedTabIndex == 1)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: _buildOrdersTab(),
            ),
        ],
      ),
    );
  }

  Widget _buildProductsTab() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Center(child: Text('Please log in to view your products.'));
    }
    final sortOptions = [
      'Featured',
      'Release date',
      'Title (A-Z)',
      'Title (Z-A)',
      'Price (high to low)',
      'Price (low to high)',
    ];
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
          child: Row(
            children: [
              const Text('Sort by:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(width: 8),
              DropdownButton<String>(
                value: _selectedSortOption,
                items: sortOptions.map((option) {
                  return DropdownMenuItem(
                    value: option,
                    child: Text(option),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedSortOption = value;
                    });
                  }
                },
              ),
            ],
          ),
        ),
        SizedBox(
          height: 400, // Set a fixed height or calculate dynamically as needed
          child: RefreshIndicator(
            onRefresh: () async {
              await Future.delayed(const Duration(milliseconds: 700));
              setState(() {});
            },
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('products')
                  .where('sellerId', isEqualTo: user.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No products posted yet.'));
                }
                var products = snapshot.data!.docs;
                // Convert to list of maps for sorting
                var productList = products.map((product) {
                  final data = product.data() as Map<String, dynamic>;
                  return {
                    'id': product.id,
                    'name': data['name'] ?? 'No Name',
                    'image': data['image'] ?? 'assets/images/image.png',
                    'price': data['price'] ?? 0,
                    'category': data['category'] ?? '',
                    'createdAt': data['createdAt'] ?? data['timestamp'], // support both field names
                    'data': data,
                    'doc': product,
                  };
                }).toList();
                // Sort
                switch (_selectedSortOption) {
                  case 'Price (low to high)':
                    productList.sort((a, b) => (a['price'] as num).compareTo(b['price'] as num));
                    break;
                  case 'Price (high to low)':
                    productList.sort((a, b) => (b['price'] as num).compareTo(a['price'] as num));
                    break;
                  case 'Title (A-Z)':
                    productList.sort((a, b) => (a['name'] as String).toLowerCase().compareTo((b['name'] as String).toLowerCase()));
                    break;
                  case 'Title (Z-A)':
                    productList.sort((a, b) => (b['name'] as String).toLowerCase().compareTo((a['name'] as String).toLowerCase()));
                    break;
                  case 'Release date':
                    productList.sort((a, b) {
                      final aTime = a['createdAt'];
                      final bTime = b['createdAt'];
                      if (aTime == null && bTime == null) return 0;
                      if (aTime == null) return 1;
                      if (bTime == null) return -1;
                      // Firestore Timestamp or DateTime
                      final aMillis = aTime is Timestamp ? aTime.millisecondsSinceEpoch : (aTime is DateTime ? aTime.millisecondsSinceEpoch : 0);
                      final bMillis = bTime is Timestamp ? bTime.millisecondsSinceEpoch : (bTime is DateTime ? bTime.millisecondsSinceEpoch : 0);
                      return bMillis.compareTo(aMillis); // Newest first
                    });
                    break;
                  case 'Featured':
                  default:
                    break;
                }
                return ListView.separated(
                  shrinkWrap: true,
                  physics: const AlwaysScrollableScrollPhysics(),
                  itemCount: productList.length,
                  separatorBuilder: (context, index) => const Divider(),
                  itemBuilder: (context, index) {
                    final product = productList[index];
                    final data = product['data'] as Map<String, dynamic>;
                    final productName = product['name'];
                    final productImage = product['image'];
                    final productPrice = product['price'];
                    final productCategory = product['category'];
                    final doc = product['doc'];
                    return ListTile(
                      leading: (productImage.toString().startsWith('http'))
                          ? Image.network(productImage, width: 50, height: 50, fit: BoxFit.cover)
                          : Image.asset(productImage, width: 50, height: 50, fit: BoxFit.cover),
                      title: Text(productName),
                      subtitle: Text('₱$productPrice • $productCategory'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Delete Product'),
                                  content: const Text('Are you sure you want to delete this product? This action cannot be undone.'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context, false),
                                      child: const Text('Cancel'),
                                    ),
                                    ElevatedButton(
                                      onPressed: () => Navigator.pop(context, true),
                                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                      child: const Text('Delete'),
                                    ),
                                  ],
                                ),
                              );
                              if (confirm == true) {
                                final firestore = FirebaseFirestore.instance;
                                final productId = doc.id;
                                // 1. Delete product from products collection
                                await firestore.collection('products').doc(productId).delete();
                                // 2. Remove product from all users' cart
                                final usersSnapshot = await firestore.collection('users').get();
                                for (var userDoc in usersSnapshot.docs) {
                                  final cartRef = userDoc.reference.collection('cart');
                                  final cartItems = await cartRef.where('productId', isEqualTo: productId).get();
                                  for (var cartItem in cartItems.docs) {
                                    await cartItem.reference.delete();
                                  }
                                  // 3. Remove product from all users' favorites (wishlist)
                                  final favRef = userDoc.reference.collection('favorites');
                                  final favItems = await favRef.where(FieldPath.documentId, isEqualTo: productId).get();
                                  for (var favItem in favItems.docs) {
                                    await favItem.reference.delete();
                                  }
                                }
                                // 4. Mark product as 'Deleted' in all orders (global and user subcollections)
                                final ordersSnapshot = await firestore.collection('orders').get();
                                for (var orderDoc in ordersSnapshot.docs) {
                                  final orderData = orderDoc.data();
                                  final items = (orderData['items'] as List<dynamic>? ?? [])
                                      .map((e) => Map<String, dynamic>.from(e as Map))
                                      .toList();
                                  bool updated = false;
                                  for (var item in items) {
                                    if (item['productId'] == productId) {
                                      item['status'] = 'Deleted';
                                      updated = true;
                                    }
                                  }
                                  if (updated) {
                                    await orderDoc.reference.update({'items': items});
                                  }
                                  // Also update in user's subcollection
                                  final buyerId = orderData['buyerId'];
                                  if (buyerId != null) {
                                    final userOrderRef = firestore.collection('users').doc(buyerId).collection('orders').doc(orderDoc.id);
                                    final userOrderSnap = await userOrderRef.get();
                                    if (userOrderSnap.exists) {
                                      final userOrderData = userOrderSnap.data() as Map<String, dynamic>;
                                      final userItems = (userOrderData['items'] as List<dynamic>? ?? [])
                                          .map((e) => Map<String, dynamic>.from(e as Map))
                                          .toList();
                                      bool userUpdated = false;
                                      for (var item in userItems) {
                                        if (item['productId'] == productId) {
                                          item['status'] = 'Deleted';
                                          userUpdated = true;
                                        }
                                      }
                                      if (userUpdated) {
                                        await userOrderRef.update({'items': userItems});
                                      }
                                    }
                                  }
                                }
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Product deleted.')));
                                }
                              }
                            },
                          ),
                          const Icon(Icons.chevron_right),
                        ],
                      ),
                      onTap: () {
                        Navigator.pushNamed(
                          context,
                          '/edit_product',
                          arguments: {
                            'edit': true,
                            'productId': doc.id,
                            'productData': data,
                          },
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOrdersTab() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Center(child: Text('Please log in to view your orders.'));
    }
    final List<String> statuses = [
      'Order Placed',
      'To Deliver',
      'To Receive',
    ];
    return DefaultTabController(
      length: statuses.length,
      child: Column(
        children: [
          TabBar(
            isScrollable: true,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.black87,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            indicator: BoxDecoration(
              color: Colors.blue,
              borderRadius: BorderRadius.circular(10),
            ),
            tabs: statuses.map((s) => Tab(text: s)).toList(),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              children: [
                const Text('Filter:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(width: 8),
                DropdownButton<String>(
                  value: _orderFilter,
                  items: const [
                    DropdownMenuItem(value: 'All', child: Text('All')),
                    DropdownMenuItem(value: 'Today', child: Text('Today')),
                  ],
                  onChanged: (val) {
                    if (val != null) setState(() => _orderFilter = val);
                  },
                ),
              ],
            ),
          ),
          SizedBox(
            height: 400, // Adjust as needed
            child: TabBarView(
              children: statuses.map((status) {
                return StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('orders').snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Center(child: Text('No orders in this status.'));
                    }
                    // Show all items in all orders, as long as the item was posted by the current seller
                    final List<Map<String, dynamic>> sellerItems = [];
                    for (var orderDoc in snapshot.data!.docs) {
                      final data = orderDoc.data() as Map<String, dynamic>;
                      final orderId = orderDoc.id;
                      final items = (data['items'] as List<dynamic>? ?? []);
                      for (var item in items) {
                        if (item['sellerId'] == user.uid && item['status'] == status && item['status'] != 'Cancelled') {
                          // Filter by date if needed
                          if (_orderFilter == 'Today') {
                            final timestamp = item['timestamp'] ?? data['timestamp'];
                            if (timestamp != null) {
                              DateTime dt;
                              if (timestamp is Timestamp) {
                                dt = timestamp.toDate();
                              } else if (timestamp is DateTime) {
                                dt = timestamp;
                              } else {
                                dt = DateTime.tryParse(timestamp.toString()) ?? DateTime.now();
                              }
                              final now = DateTime.now();
                              if (!(dt.year == now.year && dt.month == now.month && dt.day == now.day)) {
                                continue;
                              }
                            }
                          }
                          sellerItems.add({
                            'orderId': orderId,
                            'orderData': data,
                            'item': item,
                          });
                        }
                      }
                    }
                    if (sellerItems.isEmpty) {
                      return const Center(child: Text('No orders in this status.'));
                    }
                    // Group by orderId for display
                    final Map<String, List<Map<String, dynamic>>> grouped = {};
                    for (var entry in sellerItems) {
                      final orderId = entry['orderId'];
                      grouped.putIfAbsent(orderId, () => []).add(entry);
                    }
                    final orderIds = grouped.keys.toList();
                    return ListView.separated(
                      itemCount: orderIds.length,
                      separatorBuilder: (context, idx) => const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8.0),
                        child: Divider(thickness: 2),
                      ),
                      itemBuilder: (context, idx) {
                        final orderId = orderIds[idx];
                        final entries = grouped[orderId]!;
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            FutureBuilder<DocumentSnapshot>(
                              future: FirebaseFirestore.instance.collection('users').doc(entries.first['orderData']['buyerId']).get(),
                              builder: (context, snapshot) {
                                if (!snapshot.hasData || !snapshot.data!.exists) {
                                  return const ListTile(
                                    leading: CircleAvatar(child: Icon(Icons.person)),
                                    title: Text('Unknown User'),
                                  );
                                }
                                final userData = snapshot.data!.data() as Map<String, dynamic>;
                                final avatarUrl = userData['avatarUrl'] ?? '';
                                final nickname = userData['nickname'] ?? 'User';
                                return ListTile(
                                  leading: avatarUrl.isNotEmpty
                                      ? CircleAvatar(backgroundImage: NetworkImage(avatarUrl))
                                      : const CircleAvatar(child: Icon(Icons.person)),
                                  title: Text(nickname, style: const TextStyle(fontWeight: FontWeight.bold)),
                                );
                              },
                            ),
                            ...entries.map((entry) {
                              final item = entry['item'] as Map<String, dynamic>;
                              final name = item['name'] ?? 'Item';
                              final qty = item['quantity'] ?? 1;
                              final productId = item['productId'] ?? 'N/A';
                              final image = item['image'];
                              final price = item['price'];
                              final timestamp = item['timestamp'] ?? entry['orderData']['timestamp'];
                              String dateText = '';
                              if (timestamp != null) {
                                DateTime dt;
                                if (timestamp is Timestamp) {
                                  dt = timestamp.toDate();
                                } else if (timestamp is DateTime) {
                                  dt = timestamp;
                                } else {
                                  dt = DateTime.tryParse(timestamp.toString()) ?? DateTime.now();
                                }
                                final now = DateTime.now();
                                if (dt.year == now.year && dt.month == now.month && dt.day == now.day) {
                                  dateText = 'Today';
                                } else {
                                  dateText = '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
                                }
                              }
                              // Filter by productIds if provided
                              if (widget.productIds != null && widget.productIds!.isNotEmpty && !widget.productIds!.contains(productId)) {
                                return const SizedBox.shrink();
                              }
                              return Card(
                                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                                child: Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      if (dateText.isNotEmpty)
                                        Text('Date: $dateText', style: const TextStyle(color: Colors.blueGrey, fontSize: 12)),
                                      Text('Product ID: $productId', style: const TextStyle(color: Colors.red, fontSize: 12)),
                                      ListTile(
                                        contentPadding: EdgeInsets.zero,
                                        leading: image != null && image.toString().startsWith('http')
                                            ? Image.network(image, width: 40, height: 40, fit: BoxFit.cover)
                                            : Image.asset(image ?? 'assets/images/image.png', width: 40, height: 40, fit: BoxFit.cover),
                                        title: Text(name, style: const TextStyle(fontWeight: FontWeight.w500)),
                                        subtitle: Text('₱$price x $qty'),
                                        dense: true,
                                      ),
                                      if (status == 'Order Placed')
                                        Row(
                                          children: [
                                            ElevatedButton(
                                              onPressed: () async {
                                                // Update only this item's status in global orders collection
                                                final orderRef = FirebaseFirestore.instance.collection('orders').doc(orderId);
                                                final orderSnap = await orderRef.get();
                                                if (orderSnap.exists) {
                                                  final orderData = orderSnap.data() as Map<String, dynamic>;
                                                  final allItems = List<Map<String, dynamic>>.from(orderData['items'] ?? []);
                                                  for (var i = 0; i < allItems.length; i++) {
                                                    if (allItems[i]['sellerId'] == user.uid && allItems[i]['productId'] == productId) {
                                                      allItems[i] = {
                                                        ...allItems[i],
                                                        'status': 'To Deliver',
                                                      };
                                                    }
                                                  }
                                                  await orderRef.update({'items': allItems});
                                                  // Also update in user's subcollection
                                                  final buyerId = orderData['buyerId'];
                                                  if (buyerId != null) {
                                                    final userOrderRef = FirebaseFirestore.instance.collection('users').doc(buyerId).collection('orders').doc(orderId);
                                                    final userOrderSnap = await userOrderRef.get();
                                                    if (userOrderSnap.exists) {
                                                      final userOrderData = userOrderSnap.data() as Map<String, dynamic>;
                                                      final userItems = List<Map<String, dynamic>>.from(userOrderData['items'] ?? []);
                                                      for (var i = 0; i < userItems.length; i++) {
                                                        if (userItems[i]['sellerId'] == user.uid && userItems[i]['productId'] == productId) {
                                                          userItems[i] = {
                                                            ...userItems[i],
                                                            'status': 'To Deliver',
                                                          };
                                                        }
                                                      }
                                                      await userOrderRef.update({'items': userItems});
                                                    }
                                                  }
                                                }
                                              },
                                              child: const Text('Mark as To Deliver'),
                                            ),
                                            const SizedBox(width: 8),
                                            OutlinedButton(
                                              onPressed: () async {
                                                // Update only this item's status in global orders collection
                                                final orderRef = FirebaseFirestore.instance.collection('orders').doc(orderId);
                                                final orderSnap = await orderRef.get();
                                                if (orderSnap.exists) {
                                                  final orderData = orderSnap.data() as Map<String, dynamic>;
                                                  final allItems = List<Map<String, dynamic>>.from(orderData['items'] ?? []);
                                                  for (var i = 0; i < allItems.length; i++) {
                                                    if (allItems[i]['sellerId'] == user.uid && allItems[i]['productId'] == productId) {
                                                      allItems[i] = {
                                                        ...allItems[i],
                                                        'status': 'Cancelled',
                                                      };
                                                    }
                                                  }
                                                  await orderRef.update({'items': allItems});
                                                  // Also update in user's subcollection
                                                  final buyerId = orderData['buyerId'];
                                                  if (buyerId != null) {
                                                    final userOrderRef = FirebaseFirestore.instance.collection('users').doc(buyerId).collection('orders').doc(orderId);
                                                    final userOrderSnap = await userOrderRef.get();
                                                    if (userOrderSnap.exists) {
                                                      final userOrderData = userOrderSnap.data() as Map<String, dynamic>;
                                                      final userItems = List<Map<String, dynamic>>.from(userOrderData['items'] ?? []);
                                                      for (var i = 0; i < userItems.length; i++) {
                                                        if (userItems[i]['sellerId'] == user.uid && userItems[i]['productId'] == productId) {
                                                          userItems[i] = {
                                                            ...userItems[i],
                                                            'status': 'Cancelled',
                                                          };
                                                        }
                                                      }
                                                      await userOrderRef.update({'items': userItems});
                                                    }
                                                  }
                                                }
                                              },
                                              child: const Text('Cancel'),
                                            ),
                                          ],
                                        ),
                                      if (status == 'To Deliver')
                                        Row(
                                          children: [
                                            ElevatedButton(
                                              onPressed: () async {
                                                // Update only this item's status in global orders collection
                                                final orderRef = FirebaseFirestore.instance.collection('orders').doc(orderId);
                                                final orderSnap = await orderRef.get();
                                                if (orderSnap.exists) {
                                                  final orderData = orderSnap.data() as Map<String, dynamic>;
                                                  final allItems = List<Map<String, dynamic>>.from(orderData['items'] ?? []);
                                                  for (var i = 0; i < allItems.length; i++) {
                                                    if (allItems[i]['sellerId'] == user.uid && allItems[i]['productId'] == productId) {
                                                      allItems[i] = {
                                                        ...allItems[i],
                                                        'status': 'To Receive',
                                                      };
                                                    }
                                                  }
                                                  await orderRef.update({'items': allItems});
                                                  // Also update in user's subcollection
                                                  final buyerId = orderData['buyerId'];
                                                  if (buyerId != null) {
                                                    final userOrderRef = FirebaseFirestore.instance.collection('users').doc(buyerId).collection('orders').doc(orderId);
                                                    final userOrderSnap = await userOrderRef.get();
                                                    if (userOrderSnap.exists) {
                                                      final userOrderData = userOrderSnap.data() as Map<String, dynamic>;
                                                      final userItems = List<Map<String, dynamic>>.from(userOrderData['items'] ?? []);
                                                      for (var i = 0; i < userItems.length; i++) {
                                                        if (userItems[i]['sellerId'] == user.uid && userItems[i]['productId'] == productId) {
                                                          userItems[i] = {
                                                            ...userItems[i],
                                                            'status': 'To Receive',
                                                          };
                                                        }
                                                      }
                                                      await userOrderRef.update({'items': userItems});
                                                    }
                                                  }
                                                }
                                              },
                                              child: const Text('Mark as To Receive'),
                                            ),
                                            const SizedBox(width: 8),
                                            OutlinedButton(
                                              onPressed: () async {
                                                // Update only this item's status in global orders collection
                                                final orderRef = FirebaseFirestore.instance.collection('orders').doc(orderId);
                                                final orderSnap = await orderRef.get();
                                                if (orderSnap.exists) {
                                                  final orderData = orderSnap.data() as Map<String, dynamic>;
                                                  final allItems = List<Map<String, dynamic>>.from(orderData['items'] ?? []);
                                                  for (var i = 0; i < allItems.length; i++) {
                                                    if (allItems[i]['sellerId'] == user.uid && allItems[i]['productId'] == productId) {
                                                      allItems[i] = {
                                                        ...allItems[i],
                                                        'status': 'Cancelled',
                                                      };
                                                    }
                                                  }
                                                  await orderRef.update({'items': allItems});
                                                  // Also update in user's subcollection
                                                  final buyerId = orderData['buyerId'];
                                                  if (buyerId != null) {
                                                    final userOrderRef = FirebaseFirestore.instance.collection('users').doc(buyerId).collection('orders').doc(orderId);
                                                    final userOrderSnap = await userOrderRef.get();
                                                    if (userOrderSnap.exists) {
                                                      final userOrderData = userOrderSnap.data() as Map<String, dynamic>;
                                                      final userItems = List<Map<String, dynamic>>.from(userOrderData['items'] ?? []);
                                                      for (var i = 0; i < userItems.length; i++) {
                                                        if (userItems[i]['sellerId'] == user.uid && userItems[i]['productId'] == productId) {
                                                          userItems[i] = {
                                                            ...userItems[i],
                                                            'status': 'Cancelled',
                                                          };
                                                        }
                                                      }
                                                      await userOrderRef.update({'items': userItems});
                                                    }
                                                  }
                                                }
                                              },
                                              child: const Text('Cancel'),
                                            ),
                                          ],
                                        ),
                                      if (status == 'To Receive')
                                        Row(
                                          children: [
                                            OutlinedButton(
                                              onPressed: () async {
                                                // Update only this item's status in global orders collection
                                                final orderRef = FirebaseFirestore.instance.collection('orders').doc(orderId);
                                                final orderSnap = await orderRef.get();
                                                if (orderSnap.exists) {
                                                  final orderData = orderSnap.data() as Map<String, dynamic>;
                                                  final allItems = List<Map<String, dynamic>>.from(orderData['items'] ?? []);
                                                  for (var i = 0; i < allItems.length; i++) {
                                                    if (allItems[i]['sellerId'] == user.uid && allItems[i]['productId'] == productId) {
                                                      allItems[i] = {
                                                        ...allItems[i],
                                                        'status': 'Cancelled',
                                                      };
                                                    }
                                                  }
                                                  await orderRef.update({'items': allItems});
                                                  // Also update in user's subcollection
                                                  final buyerId = orderData['buyerId'];
                                                  if (buyerId != null) {
                                                    final userOrderRef = FirebaseFirestore.instance.collection('users').doc(buyerId).collection('orders').doc(orderId);
                                                    final userOrderSnap = await userOrderRef.get();
                                                    if (userOrderSnap.exists) {
                                                      final userOrderData = userOrderSnap.data() as Map<String, dynamic>;
                                                      final userItems = List<Map<String, dynamic>>.from(userOrderData['items'] ?? []);
                                                      for (var i = 0; i < userItems.length; i++) {
                                                        if (userItems[i]['sellerId'] == user.uid && userItems[i]['productId'] == productId) {
                                                          userItems[i] = {
                                                            ...userItems[i],
                                                            'status': 'Cancelled',
                                                          };
                                                        }
                                                      }
                                                      await userOrderRef.update({'items': userItems});
                                                    }
                                                  }
                                                }
                                              },
                                              child: const Text('Cancel'),
                                            ),
                                          ],
                                        ),
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
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
