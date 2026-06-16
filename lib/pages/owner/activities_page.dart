import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ActivitiesPage extends StatelessWidget {
  final List<Map<String, dynamic>> restaurants;

  const ActivitiesPage({super.key, required this.restaurants});

  @override
  Widget build(BuildContext context) {
    // 1. Sort and filter
    final List<Map<String, dynamic>> activities = restaurants.where((r) {
      return r['updatedAt'] != null || r['createdAt'] != null;
    }).toList();

    activities.sort((a, b) {
      Timestamp? tA = a['updatedAt'] ?? a['createdAt'];
      Timestamp? tB = b['updatedAt'] ?? b['createdAt'];
      if (tA == null) return 1;
      if (tB == null) return -1;
      return tB.compareTo(tA);
    });

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'All Activities',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: activities.isEmpty 
        ? _buildEmptyState()
        : ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: activities.length,
            itemBuilder: (context, index) {
              final rest = activities[index];
              Timestamp? ts = rest['updatedAt'] ?? rest['createdAt'];
              String time = 'Just now';
              
              if (ts != null) {
                final diff = DateTime.now().difference(ts.toDate());
                if (diff.inMinutes < 1) {
                  time = 'Just now';
                } else if (diff.inMinutes < 60) {
                  time = '${diff.inMinutes}m ago';
                } else if (diff.inHours < 24) {
                  time = '${diff.inHours}h ago';
                } else {
                  time = '${diff.inDays}d ago';
                }
              }
              
              bool isHeader = rest['isHeader'] == true;
              bool hasFood = rest['foodName'] != null && rest['foodName'].toString().isNotEmpty;

              return _ActivityListItem(
                name: rest['name'] ?? 'Restaurant',
                activity: hasFood ? 'Added new dish: ${rest['foodName']}' : (isHeader ? 'Restaurant profile updated' : 'Menu item updated'),
                time: time,
                icon: hasFood ? Icons.add_task_rounded : Icons.update_rounded,
                iconColor: hasFood ? const Color(0xFF2D6A4F) : Colors.blue.shade600,
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
          Icon(Icons.history_rounded, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text('No activities recorded yet', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class _ActivityListItem extends StatelessWidget {
  final String name;
  final String activity;
  final String time;
  final IconData icon;
  final Color iconColor;

  const _ActivityListItem({
    required this.name,
    required this.activity,
    required this.time,
    required this.icon,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 2),
                Text(activity, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
              ],
            ),
          ),
          Text(time, style: TextStyle(color: Colors.grey.shade400, fontSize: 11)),
        ],
      ),
    );
  }
}
