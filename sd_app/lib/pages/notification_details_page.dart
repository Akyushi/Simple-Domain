import 'package:flutter/material.dart';

class NotificationDetailsPage extends StatelessWidget {
  final String title;
  final String body;
  final DateTime? date;

  const NotificationDetailsPage({
    super.key,
    required this.title,
    required this.body,
    this.date,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notification Details'), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22)),
            const SizedBox(height: 16),
            if (date != null)
              Text(
                '${date!.year}-${date!.month.toString().padLeft(2, '0')}-${date!.day.toString().padLeft(2, '0')} ${date!.hour.toString().padLeft(2, '0')}:${date!.minute.toString().padLeft(2, '0')}',
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
            const SizedBox(height: 24),
            Text(body, style: const TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }
} 