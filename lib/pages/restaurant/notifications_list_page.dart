import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../profile/personal_info_page.dart';

class NotificationsListPage extends StatefulWidget {
  const NotificationsListPage({super.key});

  @override
  State<NotificationsListPage> createState() => _NotificationsListPageState();
}

class _NotificationsListPageState extends State<NotificationsListPage> {
  bool _isCleared = false;

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text('Notifications', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        actions: [
          if (!_isCleared)
            TextButton(
              onPressed: () => setState(() => _isCleared = true),
              child: const Text('Clear All', style: TextStyle(color: Colors.redAccent)),
            ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(user?.uid).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

          List<Map<String, String>> currentNotifications = [];

          bool isProfileIncomplete = false;
          if (snapshot.hasData && snapshot.data!.exists) {
            var data = snapshot.data!.data() as Map<String, dynamic>;
            if (data['address'] == null || data['address'].toString().isEmpty) {
              isProfileIncomplete = true;
            }
          }

          if (isProfileIncomplete) {
            currentNotifications.add({
              'title': 'Incomplete Profile',
              'desc': 'Please update your address to facilitate restaurant discovery and delivery.',
              'time': 'Just now',
              'type': 'alert'
            });
          }

          if (!_isCleared) {
            currentNotifications.add({
              'title': 'Welcome',
              'desc': 'Thank you for joining HalalEats! Start exploring halal gems around you.',
              'time': '1 day ago',
              'type': 'info'
            });
          }

          if (currentNotifications.isEmpty) {
            return _buildEmptyState();
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: currentNotifications.length,
            itemBuilder: (context, index) {
              final item = currentNotifications[index];
              return _buildNotificationItem(item, onTap: item['type'] == 'alert' 
                  ? () => Navigator.push(context, MaterialPageRoute(builder: (context) => const PersonalInfoPage()))
                  : null);
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_off_outlined, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text('No notifications at the moment', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildNotificationItem(Map<String, String> item, {VoidCallback? onTap}) {
    IconData icon = item['type'] == 'alert' ? Icons.error_outline_rounded : Icons.info_outline_rounded;
    Color color = item['type'] == 'alert' ? Colors.redAccent : Colors.blue;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))]),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle), child: Icon(icon, color: color, size: 24)),
            const SizedBox(width: 16),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(item['title']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)), Text(item['time']!, style: const TextStyle(color: Colors.grey, fontSize: 12))]),
              const SizedBox(height: 4),
              Text(item['desc']!, style: TextStyle(color: Colors.grey.shade700, fontSize: 14, height: 1.4)),
            ])),
          ],
        ),
      ),
    );
  }
}
