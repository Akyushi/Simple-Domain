import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Import FirebaseAuth
import 'package:google_sign_in/google_sign_in.dart'; // Import GoogleSignIn
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore
import 'password_reset.dart'; // Import PasswordResetPage
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'gcash_simulation_page.dart';

class AccountSettingsPage extends StatefulWidget {
  const AccountSettingsPage({super.key});

  @override
  State<AccountSettingsPage> createState() => _AccountSettingsPageState();
}

class _AccountSettingsPageState extends State<AccountSettingsPage> {
  late final User? user;
  late final String email;
  final googleSignIn = GoogleSignIn(); // Initialize GoogleSignIn
  final ImagePicker _picker = ImagePicker();
  bool _isUploadingAvatar = false;

  @override
  void initState() {
    super.initState();
    user = FirebaseAuth.instance.currentUser; // Get the current user
    email = user?.email ?? 'no account connected'; // Check if email is bound
  }

  // Cloudinary upload function
  Future<String?> uploadImageToCloudinary(File imageFile) async {
    final cloudName = 'dstlwxkdr'; // TODO: Replace with your Cloudinary cloud name
    final uploadPreset = 'Unsigned'; // TODO: Replace with your unsigned upload preset

    final url = Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload');
    final request = http.MultipartRequest('POST', url)
      ..fields['upload_preset'] = uploadPreset
      ..files.add(await http.MultipartFile.fromPath('file', imageFile.path));

    final response = await request.send();

    if (response.statusCode == 200) {
      final resStr = await response.stream.bytesToString();
      final resJson = json.decode(resStr);
      return resJson['secure_url']; // This is the image URL
    } else {
      return null;
    }
  }

  Future<void> _changeAvatar() async {
    if (user == null) return;
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (pickedFile == null) return;
    setState(() => _isUploadingAvatar = true);
    try {
      final url = await uploadImageToCloudinary(File(pickedFile.path));
      if (url != null) {
        await FirebaseFirestore.instance.collection('users').doc(user!.uid).set({'avatarUrl': url}, SetOptions(merge: true));
        setState(() {}); // Refresh UI
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Avatar updated!')));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to upload image.')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => _isUploadingAvatar = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Account Settings'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.account_balance_wallet),
                label: const Text('GCash Simulation'),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const GCashSimulationPage()),
                  );
                },
              ),
            ),
          ),
          ListTile(
            leading: _isUploadingAvatar
                ? const CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.grey,
                    child: CircularProgressIndicator(),
                  )
                : user == null
                    ? CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.grey[200],
                        child: SvgPicture.asset(
                          'assets/icons/avatar.svg',
                          width: 40,
                          height: 40,
                        ),
                      )
                    : FutureBuilder<DocumentSnapshot>(
                        future: FirebaseFirestore.instance
                            .collection('users')
                            .doc(user!.uid)
                            .get(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const CircleAvatar(
                              radius: 30,
                              backgroundColor: Colors.grey,
                              child: CircularProgressIndicator(),
                            );
                          }
                          if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.exists) {
                            return CircleAvatar(
                              radius: 30,
                              backgroundColor: Colors.grey[200],
                              child: SvgPicture.asset(
                                'assets/icons/avatar.svg',
                                width: 40,
                                height: 40,
                              ),
                            );
                          }
                          final data = snapshot.data!.data() as Map<String, dynamic>?;
                          final avatarUrl = data != null && data['avatarUrl'] != null && data['avatarUrl'].toString().isNotEmpty
                              ? data['avatarUrl'] as String
                              : null;
                          if (avatarUrl != null) {
                            return CircleAvatar(
                              radius: 30,
                              backgroundImage: NetworkImage(avatarUrl),
                            );
                          } else {
                            return CircleAvatar(
                              radius: 30,
                              backgroundColor: Colors.grey[200],
                              child: SvgPicture.asset(
                                'assets/icons/avatar.svg',
                                width: 40,
                                height: 40,
                              ),
                            );
                          }
                        },
                      ),
            title: const Text('Avatar'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: _changeAvatar,
          ),
          const Divider(),
          ListTile(
            title: const Text('Nickname'),
            subtitle: user == null
                ? const Text('no account connected')
                : FutureBuilder<DocumentSnapshot>(
                    future: FirebaseFirestore.instance.collection('users').doc(user!.uid).get(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Text('Loading...');
                      }
                      if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.exists) {
                        return const Text('no account connected');
                      }
                      final data = snapshot.data!.data() as Map<String, dynamic>?;
                      final name = data != null && data['name'] != null && data['name'].toString().isNotEmpty
                          ? data['name'] as String
                          : null;
                      final nickname = data != null && data['nickname'] != null && data['nickname'].toString().isNotEmpty
                          ? data['nickname'] as String
                          : null;
                      return Text(name ?? nickname ?? email);
                    },
                  ),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () async {
              if (user == null) return;
              final controller = TextEditingController();
              final result = await showDialog<String>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Change Nickname'),
                  content: TextField(
                    controller: controller,
                    decoration: const InputDecoration(hintText: 'Enter new nickname'),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, controller.text.trim()),
                      child: const Text('Save'),
                    ),
                  ],
                ),
              );
              if (result != null && result.isNotEmpty) {
                await FirebaseFirestore.instance.collection('users').doc(user!.uid).set({'nickname': result}, SetOptions(merge: true));
                setState(() {}); // Refresh UI
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nickname updated!')));
              }
            },
          ),
          const Divider(),
          ListTile(
            title: const Text('Email'),
            subtitle: Text(email), // Display email or "no account connected"
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              if (user != null) {
                // Handle email change logic
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Email change functionality not implemented.'),
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('No account connected to bind email.'),
                  ),
                );
              }
            },
          ),
          const Divider(),
          // Address ListTile
          ListTile(
            title: const Text('Address'),
            subtitle: user == null
                ? const Text('no account connected')
                : FutureBuilder<DocumentSnapshot>(
                    future: FirebaseFirestore.instance.collection('users').doc(user!.uid).get(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Text('Loading...');
                      }
                      if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.exists) {
                        return const Text('no account connected');
                      }
                      final data = snapshot.data!.data() as Map<String, dynamic>?;
                      final address = data != null && data['address'] != null && data['address'].toString().isNotEmpty
                          ? data['address'] as String
                          : 'No address set';
                      return Text(address);
                    },
                  ),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () async {
              if (user == null) return;
              final controller = TextEditingController();
              final result = await showDialog<String>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Change Address'),
                  content: TextField(
                    controller: controller,
                    decoration: const InputDecoration(hintText: 'Enter new address'),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, controller.text.trim()),
                      child: const Text('Save'),
                    ),
                  ],
                ),
              );
              if (result != null && result.isNotEmpty) {
                await FirebaseFirestore.instance.collection('users').doc(user!.uid).set({'address': result}, SetOptions(merge: true));
                setState(() {}); // Refresh UI
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Address updated!')));
              }
            },
          ),
          const Divider(),
          ListTile(
            title: const Text('Password'),
            subtitle: const Text('Go to set up'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PasswordResetPage(),
                ),
              );
            },
          ),
          const Divider(),
        ],
      ),
    );
  }
}
