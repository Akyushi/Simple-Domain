import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'notification_details_page.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  final Set<String> selectedNotifications = {};
  bool showCheckboxes = false;

  void _toggleCheckboxes() {
    setState(() {
      showCheckboxes = !showCheckboxes;
      if (!showCheckboxes) selectedNotifications.clear();
    });
  }

  void _deleteSelected(String userId) async {
    if (selectedNotifications.isEmpty) return;
    final notificationsRef = FirebaseFirestore.instance.collection('users').doc(userId).collection('notifications');
    for (var id in selectedNotifications) {
      await notificationsRef.doc(id).delete();
    }
    setState(() {
      selectedNotifications.clear();
      showCheckboxes = false;
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selected notifications deleted')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        centerTitle: true,
        actions: user == null
            ? null
            : [
                if (showCheckboxes)
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    tooltip: 'Delete Selected',
                    onPressed: () => _deleteSelected(user.uid),
                  ),
                IconButton(
                  icon: Icon(showCheckboxes ? Icons.close : Icons.check_box),
                  tooltip: showCheckboxes ? 'Cancel' : 'Select Multiple',
                  onPressed: _toggleCheckboxes,
                ),
              ],
      ),
      body: user == null
          ? const Center(child: Text('Please log in to see notifications.'))
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(user.uid)
                  .collection('notifications')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No notifications yet.'));
                }
                final notifications = snapshot.data!.docs;
                return ListView.separated(
                  itemCount: notifications.length,
                  separatorBuilder: (context, index) => const Divider(),
                  itemBuilder: (context, index) {
                    final doc = notifications[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final title = data['title'] ?? '';
                    final body = data['body'] ?? '';
                    final timestamp = data['timestamp'] as Timestamp?;
                    final date = timestamp?.toDate();
                    final isSelected = selectedNotifications.contains(doc.id);
                    return Dismissible(
                      key: Key(doc.id),
                      direction: showCheckboxes ? DismissDirection.none : DismissDirection.endToStart,
                      background: Container(
                        color: Colors.red,
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      onDismissed: showCheckboxes
                          ? null
                          : (direction) async {
                              await FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(user.uid)
                                  .collection('notifications')
                                  .doc(doc.id)
                                  .delete();
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Notification deleted')),
                                );
                              }
                            },
                      child: ListTile(
                        leading: showCheckboxes
                            ? Checkbox(
                                value: isSelected,
                                onChanged: (checked) {
                                  setState(() {
                                    if (checked == true) {
                                      selectedNotifications.add(doc.id);
                                    } else {
                                      selectedNotifications.remove(doc.id);
                                    }
                                  });
                                },
                              )
                            : const Icon(Icons.notifications),
                        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(body),
                            if (date != null)
                              Text(
                                '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}',
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                          ],
                        ),
                        trailing: showCheckboxes
                            ? null
                            : Builder(
                                builder: (context) => IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  tooltip: 'Delete',
                                  onPressed: () async {
                                    await FirebaseFirestore.instance
                                        .collection('users')
                                        .doc(user.uid)
                                        .collection('notifications')
                                        .doc(doc.id)
                                        .delete();
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Notification deleted')),
                                      );
                                    }
                                  },
                                ),
                              ),
                        onTap: showCheckboxes
                            ? () {
                                setState(() {
                                  if (isSelected) {
                                    selectedNotifications.remove(doc.id);
                                  } else {
                                    selectedNotifications.add(doc.id);
                                  }
                                });
                              }
                            : () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => NotificationDetailsPage(
                                      title: title,
                                      body: body,
                                      date: date,
                                    ),
                                  ),
                                );
                              },
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
} 