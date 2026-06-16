import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'add_menu_item_page.dart';

class RestaurantMenuListPage extends StatelessWidget {
  final String restaurantName;
  final String? manualUid; // NEW

  const RestaurantMenuListPage({super.key, required this.restaurantName, this.manualUid});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text('Menu: $restaurantName', style: const TextStyle(color: Color(0xFF1B4332), fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Color(0xFF1B4332)),
        actions: [
          IconButton(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => AddMenuItemPage(restaurantName: restaurantName, manualUid: manualUid))),
            icon: const Icon(Icons.add_circle_outline),
            tooltip: 'Add New Item',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('restaurants')
            .where('name', isEqualTo: restaurantName)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          
          final allDocs = snapshot.data?.docs ?? [];
          final items = allDocs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return data['isHeader'] != true;
          }).toList();

          if (items.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.restaurant_menu_rounded, size: 64, color: Colors.grey.shade200),
                  const SizedBox(height: 16),
                  Text('No menu items yet.', style: TextStyle(color: Colors.grey.shade400, fontSize: 16)),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => AddMenuItemPage(restaurantName: restaurantName, manualUid: manualUid))),
                    icon: const Icon(Icons.add, color: Colors.white),
                    label: const Text('Add First Item', style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1B4332)),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(24),
            itemCount: items.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final doc = items[index];
              final data = doc.data() as Map<String, dynamic>;
              return _buildMenuListItem(context, doc.id, data);
            },
          );
        },
      ),
    );
  }

  Widget _buildMenuListItem(BuildContext context, String docId, Map<String, dynamic> data) {
    String name = data['foodName'] ?? 'No Name';
    String price = data['price'] ?? '0.00';
    
    IconData foodIcon = Icons.restaurant_rounded;
    Color iconColor = const Color(0xFF2D6A4F);
    String lowerName = name.toLowerCase();
    
    if (lowerName.contains('nasi') || lowerName.contains('rice')) {
      foodIcon = Icons.rice_bowl_rounded;
      iconColor = Colors.orange.shade700;
    } else if (lowerName.contains('ayam') || lowerName.contains('chicken')) {
      foodIcon = Icons.kebab_dining_rounded;
      iconColor = Colors.brown.shade400;
    } else if (lowerName.contains('drink') || lowerName.contains('air')) {
      foodIcon = Icons.local_drink_rounded;
      iconColor = Colors.blue.shade400;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
      ),
      child: Row(
        children: [
          Container(
            width: 50, height: 50,
            decoration: BoxDecoration(color: iconColor.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: Icon(foodIcon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                Text('RM $price', style: const TextStyle(color: Color(0xFF2D6A4F), fontWeight: FontWeight.bold, fontSize: 13)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: Colors.blue, size: 20),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => AddMenuItemPage(restaurantName: restaurantName, restaurantId: docId, manualUid: manualUid))),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
            onPressed: () => _deleteItem(context, docId, name),
          ),
        ],
      ),
    );
  }

  void _deleteItem(BuildContext context, String docId, String name) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Item'),
        content: Text('Are you sure you want to delete "$name"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              FirebaseFirestore.instance.collection('restaurants').doc(docId).delete();
              Navigator.pop(context);
            }, 
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
