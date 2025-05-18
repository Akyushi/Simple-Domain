import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class GCashSimulationPage extends StatefulWidget {
  const GCashSimulationPage({super.key});

  @override
  State<GCashSimulationPage> createState() => _GCashSimulationPageState();
}

class _GCashSimulationPageState extends State<GCashSimulationPage> {
  double? _balance;
  String? _gcashNumber;
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _numberController = TextEditingController();
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchBalance();
  }

  Future<void> _fetchBalance() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    setState(() {
      _balance = (doc.data()?['gcashBalance'] ?? 0).toDouble();
      _gcashNumber = doc.data()?['gcashNumber'] ?? '';
      _numberController.text = _gcashNumber ?? '';
      _loading = false;
    });
  }

  Future<void> _setBalance() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final amount = double.tryParse(_amountController.text.trim());
    final number = _numberController.text.trim();
    if (number.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your GCash phone number.')),
      );
      return;
    }
    if (amount == null || amount < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount.')),
      );
      return;
    }
    await FirebaseFirestore.instance.collection('users').doc(user.uid).set({'gcashBalance': amount, 'gcashNumber': number}, SetOptions(merge: true));
    setState(() {
      _balance = amount;
      _gcashNumber = number;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('GCash balance and number updated!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('GCash Simulation')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 32),
                  const Text('Your GCash Balance', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  Text('₱${_balance?.toStringAsFixed(2) ?? '0.00'}', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.blue)),
                  const SizedBox(height: 32),
                  TextField(
                    controller: _numberController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'GCash Phone Number',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _amountController,
                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Set GCash Balance',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _setBalance,
                      child: const Text('Update Balance'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    _numberController.dispose();
    super.dispose();
  }
} 