import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io';
import 'dart:convert';

class AddProductPage extends StatefulWidget {
  const AddProductPage({super.key});

  @override
  State<AddProductPage> createState() => _AddProductPageState();
}

class _AddProductPageState extends State<AddProductPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _tagsController = TextEditingController();
  String _selectedCategory = 'Food';
  String? _imageUrl;
  XFile? _pickedImage;
  bool _isUploading = false;
  bool _isEdit = false;
  String? _editProductId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null && args['edit'] == true && args['productData'] != null) {
      final data = args['productData'] as Map<String, dynamic>;
      _isEdit = true;
      _editProductId = args['productId'] as String?;
      _nameController.text = data['name'] ?? '';
      _priceController.text = data['price']?.toString() ?? '';
      _descriptionController.text = data['description'] ?? '';
      _selectedCategory = data['category'] ?? 'Food';
      _tagsController.text = (data['tags'] as List<dynamic>?)?.join(', ') ?? '';
      _imageUrl = data['image'];
      setState(() {});
    }
  }

  void _saveProduct() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to add products')),
      );
      return;
    }

    // Validation: Require all fields
    if (_nameController.text.trim().isEmpty ||
        _priceController.text.trim().isEmpty ||
        double.tryParse(_priceController.text.trim()) == null ||
        double.tryParse(_priceController.text.trim())! <= 0 ||
        _descriptionController.text.trim().isEmpty ||
        _selectedCategory.trim().isEmpty ||
        _tagsController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields with valid values.')),
      );
      return;
    }

    final productData = {
      'name': _nameController.text,
      'price': double.tryParse(_priceController.text) ?? 0,
      'description': _descriptionController.text,
      'category': _selectedCategory,
      'tags': _tagsController.text.split(',').map((tag) => tag.trim()).toList(),
      'image': _imageUrl ?? 'assets/images/image.png',
      'hidden': false,
      'sellerId': user.uid,
      'createdAt': FieldValue.serverTimestamp(),
    };

    try {
      if (_isEdit && _editProductId != null) {
        final productDoc = await _firestore.collection('products').doc(_editProductId).get();
        if (productDoc.exists && productDoc.data()?['sellerId'] != user.uid) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('You can only edit your own products')),
          );
          return;
        }
        await _firestore.collection('products').doc(_editProductId).update(productData);
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Product updated!')),
        );
      } else {
        await _firestore.collection('products').add(productData);
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Product added!')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving product: $e')),
      );
    }
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _pickedImage = image;
      });
      await _uploadImage(image);
    }
  }

  Future<void> _uploadImage(XFile image) async {
    setState(() {
      _isUploading = true;
    });
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
          _imageUrl = resJson['secure_url'];
        });
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
      setState(() {
        _isUploading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit Product' : 'Add Product'),
        backgroundColor: const Color.fromARGB(255, 0, 123, 255),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Customize your product:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 150,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: _isUploading
                      ? const Center(child: CircularProgressIndicator())
                      : _pickedImage != null
                          ? Image.file(
                              File(_pickedImage!.path),
                              fit: BoxFit.cover,
                            )
                          : _imageUrl != null
                              ? Image.network(_imageUrl!, fit: BoxFit.cover)
                              : const Center(child: Text('Tap to add an image')),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Product Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _priceController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly], // Restrict to numbers
                decoration: const InputDecoration(
                  labelText: 'Price',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                items: const [
                  DropdownMenuItem(value: 'Food', child: Text('Food')),
                  DropdownMenuItem(value: 'Books', child: Text('Books')),
                  DropdownMenuItem(value: 'Clothing', child: Text('Clothing')),
                  DropdownMenuItem(value: 'Electronics', child: Text('Electronics')),
                  DropdownMenuItem(value: 'Others', child: Text('Others')),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedCategory = value!;
                  });
                },
                decoration: const InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _tagsController,
                decoration: const InputDecoration(
                  labelText: 'Tags (comma-separated)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _saveProduct,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 0, 123, 255),
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: const Text(
                  'Save Product',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
