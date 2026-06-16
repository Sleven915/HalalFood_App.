import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/restaurant.dart';
import 'review_rating_page.dart';
import 'booking_page.dart';
import '../owner/add_edit_menu_page.dart';
import '../owner/add_menu_item_page.dart';

class RestaurantDetailsPage extends StatefulWidget {
  final String? restaurantId; 
  final String name;
  final String rating;
  final String distance;
  final String imageUrl;
  final String? manualUid; 

  const RestaurantDetailsPage({
    super.key,
    this.restaurantId,
    required this.name,
    required this.rating,
    required this.distance,
    required this.imageUrl,
    this.manualUid,
  });

  @override
  State<RestaurantDetailsPage> createState() => _RestaurantDetailsPageState();
}

class _RestaurantDetailsPageState extends State<RestaurantDetailsPage> {
  String _activeTab = 'Overview';
  final authUser = FirebaseAuth.instance.currentUser;

  String? get currentUserId => widget.manualUid ?? authUser?.uid;
  final primaryColor = const Color(0xFF1B4332);

  Stream<DocumentSnapshot> _favoriteStream() {
    return FirebaseFirestore.instance.collection('users').doc(currentUserId).collection('favorites').doc(widget.name).snapshots();
  }

  Future<void> toggleFavorite(bool isCurrentlyFavorite) async {
    if (currentUserId == null) return;
    final favRef = FirebaseFirestore.instance.collection('users').doc(currentUserId!).collection('favorites').doc(widget.name);
    if (isCurrentlyFavorite) {
      await favRef.delete();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${widget.name} removed from Favourites')));
    } else {
      await favRef.set({'name': widget.name, 'location': 'Setapak, KL', 'rating': widget.rating, 'distance': widget.distance, 'imageUrl': widget.imageUrl, 'category': 'halal', 'timestamp': FieldValue.serverTimestamp()});
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${widget.name} added to Favourites')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('restaurants').where('name', isEqualTo: widget.name).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Center(child: CircularProgressIndicator());
          final docs = snapshot.data!.docs;
          DocumentSnapshot? headerDoc;
          for (var doc in docs) { if ((doc.data() as Map)['isHeader'] == true) { headerDoc = doc; break; } }
          headerDoc ??= docs.first;
          final data = headerDoc.data() as Map<String, dynamic>;
          final ownerId = data['ownerId'];
          final name = data['name'] ?? widget.name;
          final location = data['location'] ?? 'Setapak, Kuala Lumpur';
          final phone = data['phone'] ?? '03-4142 1234';
          final about = data['description'] ?? '$name serves authentic dishes with high-quality ingredients.';
          final openingHours = data['openingHours'] ?? '8:00 AM - 10:00 PM';
          final operatingDays = data['operatingDays'] ?? 'Monday - Friday';
          final imageUrl = data['imageUrl'] ?? widget.imageUrl;
          final category = data['category'] ?? 'halal';

          return SingleChildScrollView(
            child: Column(
              children: [
                _buildHeader(imageUrl, category),
                Container(
                  color: Colors.white, width: double.infinity, padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      _buildRatingRow(),
                      const SizedBox(height: 8),
                      Text('Malay • $location', style: TextStyle(color: Colors.orange.shade700, fontWeight: FontWeight.w500)),
                      const SizedBox(height: 20),
                      _buildTabs(),
                      const Divider(),
                      const SizedBox(height: 16),
                      _buildTabContent(data, name, about, openingHours, operatingDays, phone, location, ownerId),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(String imageUrl, String category) {
    return Stack(
      children: [
        Image.network(imageUrl, height: 300, width: double.infinity, fit: BoxFit.cover, errorBuilder: (context, error, stackTrace) => Container(height: 300, color: Colors.grey.shade200, child: const Icon(Icons.restaurant, color: Colors.grey, size: 50))),
        Container(height: 300, decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.black.withOpacity(0.4), Colors.transparent]))),
        Positioned(top: 40, left: 20, child: _buildCircleButton(Icons.arrow_back, () => Navigator.pop(context))),
        _buildHalalBadge(category),
      ],
    );
  }

  Widget _buildCircleButton(IconData icon, VoidCallback onTap) => CircleAvatar(backgroundColor: Colors.white, child: IconButton(icon: Icon(icon, color: Colors.black), onPressed: onTap));

  Widget _buildHalalBadge(String category) {
    Color badgeColor = const Color(0xFF1B4332);
    String arabicText = 'حلال';
    String englishText = 'HALAL';
    
    if (category == 'non-halal') {
      badgeColor = Colors.red.shade800;
      arabicText = 'غير حلال';
      englishText = 'NON-HALAL';
    } else if (category == 'vege') {
      badgeColor = Colors.orange.shade800;
      arabicText = 'نباتي';
      englishText = 'VEGETARIAN';
    }

    return Positioned(
      bottom: -1, 
      left: 20, 
      child: Container(
        padding: const EdgeInsets.all(8), 
        decoration: const BoxDecoration(
          color: Colors.white, 
          borderRadius: BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12))
        ), 
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), 
          decoration: BoxDecoration(color: badgeColor, borderRadius: BorderRadius.circular(8)), 
          child: Column(
            mainAxisSize: MainAxisSize.min, 
            children: [
              Text(arabicText, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
              Text(englishText, style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
            ]
          )
        )
      )
    );
  }

  Widget _buildRatingRow() => Row(children: [const Icon(Icons.star, color: Colors.amber, size: 18), const SizedBox(width: 4), Text(widget.rating, style: const TextStyle(fontWeight: FontWeight.bold)), Text(' (512)', style: TextStyle(color: Colors.grey.shade600)), const SizedBox(width: 12), Icon(Icons.access_time, color: Colors.grey.shade400, size: 18), const SizedBox(width: 4), Text(widget.distance, style: TextStyle(color: Colors.grey.shade600)), const SizedBox(width: 12), Text('•  \$\$', style: TextStyle(color: Colors.grey.shade600))]);

  Widget _buildTabs() => SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: ['Overview', 'Menu', 'Reviews', 'Photos'].map((tab) => GestureDetector(onTap: () => setState(() => _activeTab = tab), child: _TabItem(title: tab, isActive: _activeTab == tab))).toList()));

  String _sortAndFormatDays(String daysStr) {
    if (daysStr == 'Daily' || daysStr == 'Monday - Friday' || daysStr == 'Monday - Saturday' || daysStr == 'Weekend') return daysStr;
    final List<String> order = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    final List<String> shortOrder = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    List<String> currentDays = daysStr.split(',').map((e) => e.trim()).toList();
    List<String> sortedFull = [];
    for (int i = 0; i < order.length; i++) {
      bool found = false;
      for (var d in currentDays) { if (d.toLowerCase() == order[i].toLowerCase() || d.toLowerCase() == shortOrder[i].toLowerCase()) { found = true; break; } }
      if (found) sortedFull.add(order[i]);
    }
    if (sortedFull.isEmpty) return daysStr;
    if (sortedFull.length == 7) return 'Daily';
    if (sortedFull.length == 5 && sortedFull[0] == 'Monday' && sortedFull[sortedFull.length-1] == 'Friday') return 'Monday - Friday';
    return sortedFull.join(', ');
  }

  void _showFullCertificate(BuildContext context, String url) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Align(alignment: Alignment.centerRight, child: IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: () => Navigator.pop(context))),
            ClipRRect(borderRadius: BorderRadius.circular(16), child: Image.network(url, fit: BoxFit.contain)),
          ],
        ),
      ),
    );
  }

  Widget _buildTabContent(Map<String, dynamic> data, String name, String about, String openingHours, String operatingDays, String phone, String location, String? ownerId) {
    if (_activeTab == 'Menu') return _buildMenuTab(name, ownerId);
    if (_activeTab == 'Reviews') return _buildReviewsTab(location, ownerId);
    if (_activeTab == 'Photos') return _buildPhotosTab(data['imageUrl'] ?? widget.imageUrl);

    String formattedDays = _sortAndFormatDays(operatingDays);
    String? certUrl = data['halalCertUrl'];

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('About', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text(about, style: TextStyle(color: Colors.grey.shade700, height: 1.5)),
        const SizedBox(height: 24),
        Row(children: [_buildInfoItem(Icons.calendar_today_outlined, formattedDays), _buildInfoItem(Icons.access_time, openingHours)]),
        const SizedBox(height: 16),
        Row(children: [_buildInfoItem(Icons.phone, phone), _buildInfoItem(Icons.location_on, location)]),
        const SizedBox(height: 32),
        
        // HALAL CERTIFICATE SECTION
        if (certUrl != null && certUrl.isNotEmpty) ...[
          const Text('Verification & Certificates', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () => _showFullCertificate(context, certUrl),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1B4332).withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF1B4332).withOpacity(0.1)),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(certUrl, width: 60, height: 60, fit: BoxFit.cover, errorBuilder: (c,e,s) => const Icon(Icons.description, color: Colors.grey)),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Official Halal Certificate', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        Text('Tap to view full document', style: TextStyle(color: Colors.grey, fontSize: 12)),
                      ],
                    ),
                  ),
                  const Icon(Icons.verified_user_rounded, color: Color(0xFF2D6A4F)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],

        SizedBox(width: double.infinity, height: 56, child: ElevatedButton.icon(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => BookingPage(restaurantName: widget.name, location: location, openingHours: openingHours, operatingDays: operatingDays, ownerId: ownerId, manualUid: widget.manualUid))), icon: const Icon(Icons.calendar_month_rounded, color: Colors.white), label: const Text('Book a Table Now', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)), style: ElevatedButton.styleFrom(backgroundColor: primaryColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), elevation: 0))),
        const SizedBox(height: 16),
        StreamBuilder<DocumentSnapshot>(
          stream: _favoriteStream(),
          builder: (context, favSnapshot) {
            bool isFav = favSnapshot.hasData && favSnapshot.data!.exists;
            return SizedBox(
              width: double.infinity, height: 56,
              child: OutlinedButton.icon(
                onPressed: () => toggleFavorite(isFav), 
                icon: Icon(isFav ? Icons.favorite : Icons.favorite_border_rounded, color: isFav ? Colors.red : primaryColor),
                label: Text(isFav ? 'Remove from Favourites' : 'Save to Favourites', style: TextStyle(color: isFav ? Colors.red.shade800 : primaryColor, fontWeight: FontWeight.bold)),
                style: OutlinedButton.styleFrom(side: BorderSide(color: isFav ? Colors.red.shade200 : primaryColor.withOpacity(0.2)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), backgroundColor: isFav ? Colors.red.withOpacity(0.05) : Colors.white),
              ),
            );
          }
        ),
        const SizedBox(height: 32),
        const Text('Menu Highlights', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        _buildMenuTab(name, ownerId, isHighlight: true),
      ]);
  }

  Widget _buildMenuTab(String restaurantName, String? ownerId, {bool isHighlight = false}) {
    bool isTheOwnerOfThis = currentUserId != null && ownerId != null && currentUserId!.trim() == ownerId.toString().trim();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!isHighlight && isTheOwnerOfThis) ...[
          SizedBox(
            width: double.infinity, 
            height: 50, 
            child: ElevatedButton.icon(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => AddMenuItemPage(
                restaurantName: restaurantName, // Corrected from 'name' to 'restaurantName'
                manualUid: currentUserId
              ))), 
              icon: const Icon(Icons.add, color: Colors.white), 
              label: const Text('Add New Item', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)), 
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange.shade800, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)))
            )
          ),
          const SizedBox(height: 20),
        ],
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('restaurants').where('name', isEqualTo: restaurantName).snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Text('No menu available.');
            final allDocs = snapshot.data!.docs.where((doc) => (doc.data() as Map)['isHeader'] != true).toList();
            if (allDocs.isEmpty) return const Text('No menu available.');
            final items = isHighlight ? allDocs.take(3) : allDocs;
            return Column(children: items.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                return _buildMenuItem(doc.id, data['foodName'] ?? 'Signature Dish', 'RM ${data['price'] ?? '0.00'}', isTheOwnerOfThis, restaurantName, data['imageUrl'] ?? 'https://images.unsplash.com/photo-1563379091339-03b21bc4a4f8?w=800');
              }).toList());
          }
        ),
      ],
    );
  }

  Widget _buildReviewsTab(String location, String? restaurantOwnerId) {
    if (currentUserId == null) return const Center(child: Padding(padding: EdgeInsets.all(24.0), child: Text('Login required.')));

    // LOGIC: Sesiapa boleh tulis ulasan ASALKAN bukan pemilik restoran INI.
    bool isNotThisOwner = currentUserId!.trim() != restaurantOwnerId.toString().trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isNotThisOwner) ...[
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => ReviewRatingPage(restaurantName: widget.name, location: location, manualUid: currentUserId))),
              icon: const Icon(Icons.rate_review_outlined, color: Colors.white),
              label: const Text('Write a Review', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange.shade800, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 2),
            ),
          ),
          const SizedBox(height: 24),
        ] else ...[
          Container(
            width: double.infinity, padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12)),
            child: const Row(children: [Icon(Icons.info_outline, size: 18, color: Colors.grey), SizedBox(width: 10), Expanded(child: Text('You cannot review your own restaurant.', style: TextStyle(color: Colors.grey, fontSize: 12, fontStyle: FontStyle.italic)))]),
          ),
          const SizedBox(height: 24),
        ],
        const Text('Customer Reviews', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('reviews').where('restaurantName', isEqualTo: widget.name.trim()).snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
            if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Center(child: Padding(padding: EdgeInsets.symmetric(vertical: 40), child: Text('No reviews yet.')));
            return Column(children: snapshot.data!.docs.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final timestamp = data['timestamp'] as Timestamp?;
                final dateStr = timestamp != null ? "${timestamp.toDate().day}/${timestamp.toDate().month}/${timestamp.toDate().year}" : "Just now";
                return _buildReviewItem(data['userName'] ?? 'HalalEats User', (data['rating'] ?? 0.0).toString(), data['reviewText'] ?? '', dateStr);
              }).toList());
          },
        ),
      ],
    );
  }

  Widget _buildPhotosTab(String mainImage) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Restaurant Photo', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)), const SizedBox(height: 16), Container(decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 15, offset: const Offset(0, 8))]), child: ClipRRect(borderRadius: BorderRadius.circular(20), child: AspectRatio(aspectRatio: 16 / 9, child: Image.network(mainImage, width: double.infinity, fit: BoxFit.cover, errorBuilder: (context, error, stackTrace) => Container(color: Colors.grey.shade100, child: const Icon(Icons.restaurant, color: Colors.grey, size: 48)))))), const SizedBox(height: 20)]);

  Widget _buildReviewItem(String user, String rating, String comment, String time) => Padding(padding: const EdgeInsets.only(bottom: 20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [const CircleAvatar(child: Icon(Icons.person)), const SizedBox(width: 12), Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(user, style: const TextStyle(fontWeight: FontWeight.bold)), Text(time, style: const TextStyle(color: Colors.grey, fontSize: 12))]), const Spacer(), const Icon(Icons.star, color: Colors.amber, size: 16), Text(rating, style: const TextStyle(fontWeight: FontWeight.bold))]), const SizedBox(height: 8), Text(comment, style: TextStyle(color: Colors.grey.shade700))]));

  Widget _buildMenuItem(String docId, String name, String price, bool isOwner, String restaurantName, String imageUrl) => Container(margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.white, border: Border.all(color: Colors.grey.shade100), borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))]), child: Row(children: [ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.network(imageUrl, width: 60, height: 60, fit: BoxFit.cover, errorBuilder: (context, error, stackTrace) => Container(width: 60, height: 60, color: Colors.grey.shade100, child: const Icon(Icons.restaurant_menu_rounded, color: Colors.grey)))), const SizedBox(width: 16), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)), const SizedBox(height: 4), Text(price, style: const TextStyle(color: Color(0xFF2D6A4F), fontWeight: FontWeight.bold, fontSize: 15))])), if (isOwner) IconButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => AddMenuItemPage(restaurantName: restaurantName, restaurantId: docId, manualUid: currentUserId))), icon: const Icon(Icons.edit_note_rounded, color: Colors.blue)) else const Icon(Icons.add_circle_outline, color: Color(0xFF1B4332), size: 20)]));

  Widget _buildInfoItem(IconData icon, String text) => Expanded(child: Column(children: [Icon(icon, color: const Color(0xFF1B4332), size: 24), const SizedBox(height: 8), Text(text, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold))]));
}

class _TabItem extends StatelessWidget {
  final String title;
  final bool isActive;
  const _TabItem({required this.title, this.isActive = false});
  @override
  Widget build(BuildContext context) {
    return Container(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10), decoration: BoxDecoration(border: Border(bottom: BorderSide(color: isActive ? const Color(0xFF1B4332) : Colors.transparent, width: 2))), child: Text(title, style: TextStyle(fontWeight: isActive ? FontWeight.bold : FontWeight.normal, color: isActive ? const Color(0xFF1B4332) : Colors.grey)));
  }
}
