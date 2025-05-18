import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';

class CommentsPage extends StatefulWidget {
  final String productId;
  const CommentsPage({super.key, required this.productId});

  @override
  State<CommentsPage> createState() => _CommentsPageState();
}

class _CommentsPageState extends State<CommentsPage> {
  int _rating = 0;
  final TextEditingController _commentController = TextEditingController();
  List<File> _imageFiles = [];
  bool _isSubmitting = false;

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final pickedFiles = await picker.pickMultiImage();
    if (pickedFiles.isNotEmpty) {
      setState(() {
        _imageFiles = pickedFiles.map((f) => File(f.path)).toList();
      });
    }
  }

  Future<String?> _uploadImage(File image) async {
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
        return resJson['secure_url'];
      } else {
        debugPrint('Cloudinary upload failed: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('Cloudinary upload error: $e');
      return null;
    }
  }

  Future<List<String?>> _uploadImages(List<File> images) async {
    List<String?> urls = [];
    for (final image in images) {
      urls.add(await _uploadImage(image));
    }
    return urls;
  }

  Future<void> _submitComment() async {
    if (_rating == 0 || _commentController.text.trim().isEmpty) return;
    setState(() => _isSubmitting = true);
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    List<String?> imageUrls = [];
    if (_imageFiles.isNotEmpty) {
      imageUrls = await _uploadImages(_imageFiles);
    }
    // Fetch user info from Firestore
    String userName = user.displayName ?? user.email ?? 'User';
    String? userPhotoUrl = user.photoURL;
    try {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        final data = userDoc.data();
        if (data != null) {
          if (data['nickname'] != null && data['nickname'].toString().isNotEmpty) {
            userName = data['nickname'];
          } else if (data['name'] != null && data['name'].toString().isNotEmpty) {
            userName = data['name'];
          }
          if (data['avatarUrl'] != null && data['avatarUrl'].toString().isNotEmpty) {
            userPhotoUrl = data['avatarUrl'];
          }
        }
      }
    } catch (_) {}
    await FirebaseFirestore.instance
        .collection('products')
        .doc(widget.productId)
        .collection('comments')
        .add({
      'userId': user.uid,
      'userName': userName,
      'userPhotoUrl': userPhotoUrl,
      'rating': _rating,
      'comment': _commentController.text.trim(),
      'photoUrls': imageUrls,
      'timestamp': FieldValue.serverTimestamp(),
    });
    setState(() => _isSubmitting = false);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Rate & Comment'), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Your Rating:', style: TextStyle(fontWeight: FontWeight.bold)),
            Row(
              children: List.generate(5, (index) => IconButton(
                icon: Icon(
                  index < _rating ? Icons.star : Icons.star_border,
                  color: Colors.amber,
                  size: 32,
                ),
                onPressed: () {
                  setState(() {
                    _rating = index + 1;
                  });
                },
              )),
            ),
            const SizedBox(height: 16),
            const Text('Your Comment:', style: TextStyle(fontWeight: FontWeight.bold)),
            TextField(
              controller: _commentController,
              maxLines: 3,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Write your comment here...',
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: _pickImages,
                  icon: const Icon(Icons.photo_library),
                  label: const Text('Upload Photos'),
                ),
                const SizedBox(width: 12),
                if (_imageFiles.isNotEmpty)
                  Expanded(
                    child: SizedBox(
                      height: 60,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _imageFiles.length,
                        separatorBuilder: (context, i) => const SizedBox(width: 8),
                        itemBuilder: (context, i) => Stack(
                          children: [
                            Image.file(_imageFiles[i], width: 60, height: 60, fit: BoxFit.cover),
                            Positioned(
                              right: 0,
                              top: 0,
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _imageFiles.removeAt(i);
                                  });
                                },
                                child: Container(
                                  color: Colors.black54,
                                  child: const Icon(Icons.close, color: Colors.white, size: 18),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitComment,
                child: _isSubmitting
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Submit'),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 