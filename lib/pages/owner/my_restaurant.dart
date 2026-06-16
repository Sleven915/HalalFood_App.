import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'add_edit_menu_page.dart';
import 'add_menu_item_page.dart';
import 'restaurant_menu_list_page.dart';

class MyRestaurantsPage extends StatefulWidget {
  final List<Map<String, dynamic>> restaurants;
  final String? manualUid; // NEW

  const MyRestaurantsPage({super.key, required this.restaurants, this.manualUid});

  @override
  State<MyRestaurantsPage> createState() => _MyRestaurantsPageState();
}

class _MyRestaurantsPageState extends State<MyRestaurantsPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _confirmDelete(BuildContext context, String docId, String name) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Restaurant', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('Are you sure you want to delete "$name"? This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await FirebaseFirestore.instance.collection('restaurants').doc(docId).delete();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('"$name" has been deleted'), behavior: SnackBarBehavior.floating),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, elevation: 0),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    bool isMobile = screenWidth < 600;

    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? 20 : 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'My Restaurants',
                      style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: Color(0xFF1B4332), letterSpacing: -0.5),
                    ),
                    Text('Manage your business listings', style: TextStyle(color: Colors.grey, fontSize: 14)),
                  ],
                ),
                if (!isMobile) _buildAddButton(),
              ],
            ),
            const SizedBox(height: 24),
            if (isMobile) ...[
              _buildAddButton(),
              const SizedBox(height: 24),
            ],

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white, 
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.withOpacity(0.1)),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (value) => setState(() => _searchQuery = value.toLowerCase()),
                decoration: InputDecoration(
                  hintText: 'Search your restaurants...', 
                  hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                  prefixIcon: const Icon(Icons.search, size: 20), 
                  border: InputBorder.none, 
                  contentPadding: const EdgeInsets.symmetric(vertical: 18)
                ),
              ),
            ),
            const SizedBox(height: 32),

            Builder(
              builder: (context) {
                final filtered = widget.restaurants.where((rest) {
                  final name = rest['name']?.toString().toLowerCase() ?? '';
                  final location = rest['location']?.toString().toLowerCase() ?? '';
                  return name.contains(_searchQuery) || location.contains(_searchQuery);
                }).toList();

                if (filtered.isEmpty) {
                  return _buildEmptyState();
                }

                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: filtered.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final rest = filtered[index];
                    return _buildRestaurantCard(rest, isMobile);
                  },
                );
              }
            ),
            const SizedBox(height: 40),
          ],
        ),
      );
  }

  Widget _buildAddButton() {
    return ElevatedButton.icon(
      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => AddOrEditMenuPage(isNewRestaurant: true, manualUid: widget.manualUid))),
      icon: const Icon(Icons.add_rounded, color: Colors.white, size: 20),
      label: const Text('Add Restaurant', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF1B4332), 
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16), 
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        elevation: 2,
        shadowColor: const Color(0xFF1B4332).withOpacity(0.4),
      ),
    );
  }

  Widget _buildRestaurantCard(Map<String, dynamic> rest, bool isMobile) {
    bool isActive = (rest['status'] ?? 'Active') == 'Active';
    Color themeColor = const Color(0xFF1B4332);

    return InkWell(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => AddOrEditMenuPage(isNewRestaurant: false, existingRestaurantName: rest['name'], restaurantId: rest['id'], manualUid: widget.manualUid))),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.withOpacity(0.08)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: themeColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(Icons.storefront_rounded, color: themeColor, size: 30),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(rest['name'] ?? 'No Name', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Color(0xFF1B4332)), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on_rounded, size: 12, color: Colors.grey),
                      const SizedBox(width: 4),
                      Expanded(child: Text(rest['location'] ?? 'Setapak, KL', style: TextStyle(color: Colors.grey.shade500, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isActive ? const Color(0xFF2D6A4F).withOpacity(0.1) : Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      isActive ? 'ACTIVE' : 'INACTIVE', 
                      style: TextStyle(color: isActive ? const Color(0xFF2D6A4F) : Colors.red, fontWeight: FontWeight.w800, fontSize: 10),
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => RestaurantMenuListPage(restaurantName: rest['name'], manualUid: widget.manualUid))),
                  icon: const Icon(Icons.list_alt_rounded, color: Colors.orange, size: 18),
                  label: const Text('List Menu', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 12)),
                  style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8), minimumSize: const Size(0, 30)),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: 'Edit Details',
                      icon: const Icon(Icons.edit_outlined, color: Colors.blue, size: 22), 
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => AddOrEditMenuPage(isNewRestaurant: false, existingRestaurantName: rest['name'], restaurantId: rest['id'], manualUid: widget.manualUid))),
                    ),
                    IconButton(
                      tooltip: 'Delete Restaurant',
                      icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 22), 
                      onPressed: () => _confirmDelete(context, rest['id'], rest['name']),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          children: [
            Icon(Icons.restaurant_rounded, size: 64, color: Colors.grey.shade200),
            const SizedBox(height: 16),
            Text(_searchQuery.isEmpty ? 'No restaurants listed yet.' : 'No results for "$_searchQuery"', style: TextStyle(color: Colors.grey.shade400, fontSize: 16, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}
