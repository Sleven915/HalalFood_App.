import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/restaurant.dart';
import 'restaurant_details_page.dart';

class FavouriteRestaurantPage extends StatefulWidget {
  final bool showBackButton;
  final VoidCallback? onBack;
  final String? manualUid; // NEW: Support bypass login

  const FavouriteRestaurantPage({super.key, this.showBackButton = true, this.onBack, this.manualUid});

  @override
  State<FavouriteRestaurantPage> createState() => _FavouriteRestaurantPageState();
}

class _FavouriteRestaurantPageState extends State<FavouriteRestaurantPage> {
  final authUser = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    final currentUserId = widget.manualUid ?? authUser?.uid;

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: widget.showBackButton 
          ? IconButton(icon: const Icon(Icons.arrow_back, color: Colors.black), onPressed: widget.onBack ?? () => Navigator.pop(context))
          : null,
        title: const Text('My Favourites', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(currentUserId)
            .collection('favorites')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return _buildEmptyState();
          final favDocs = snapshot.data!.docs;
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: favDocs.length,
            itemBuilder: (context, index) {
              final data = favDocs[index].data() as Map<String, dynamic>;
              return _buildFavouriteItem(data, currentUserId);
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.favorite_outline_rounded, size: 60, color: Colors.grey.shade300), const SizedBox(height: 24), const Text('No favorites yet', style: TextStyle(color: Colors.black87, fontSize: 18, fontWeight: FontWeight.bold)), const SizedBox(height: 8), Text('Explore restaurants and save the ones you love!', style: TextStyle(color: Colors.grey.shade500, fontSize: 14))]));
  }

  Widget _buildFavouriteItem(Map<String, dynamic> data, String? userId) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => RestaurantDetailsPage(name: data['name'] ?? '', rating: data['rating'] ?? '5.0', distance: data['distance'] ?? '', imageUrl: data['imageUrl'] ?? ''))),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 4))]),
        child: Row(
          children: [
            ClipRRect(borderRadius: BorderRadius.circular(16), child: Image.network(data['imageUrl'] ?? '', width: 90, height: 90, fit: BoxFit.cover, errorBuilder: (context, error, stackTrace) => Container(width: 90, height: 90, color: Colors.grey.shade100, child: const Icon(Icons.restaurant, color: Colors.grey)))),
            const SizedBox(width: 16),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(data['name'] ?? 'Restaurant', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: Color(0xFF2D3436))), const SizedBox(height: 4), Text(data['location'] ?? 'Location', style: TextStyle(color: Colors.grey.shade500, fontSize: 13)), const SizedBox(height: 12), Row(children: [const Icon(Icons.star_rounded, color: Colors.amber, size: 20), const SizedBox(width: 4), Text(data['rating'] ?? '5.0', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14))])])),
            IconButton(icon: const Icon(Icons.favorite_rounded, color: Colors.redAccent, size: 28), onPressed: () async {
                await FirebaseFirestore.instance.collection('users').doc(userId).collection('favorites').doc(data['name']).delete();
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${data['name']} removed')));
            }),
          ],
        ),
      ),
    );
  }
}
