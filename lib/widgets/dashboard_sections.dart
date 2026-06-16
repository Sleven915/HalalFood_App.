import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../pages/owner/activities_page.dart';

class HeaderSection extends StatelessWidget {
  const HeaderSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Dashboard Overview',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: Color(0xFF1B4332),
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Welcome back! Here\'s what\'s happening today.',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }
}

class SummarySection extends StatelessWidget {
  final List<Map<String, dynamic>> restaurants;
  final String? manualUid; // NEW

  const SummarySection({super.key, required this.restaurants, this.manualUid});

  @override
  Widget build(BuildContext context) {
    final authUser = FirebaseAuth.instance.currentUser;
    final currentUserId = manualUid ?? authUser?.uid; // USE MANUAL UID

    int totalRestaurants = restaurants.map((r) => r['name']).toSet().length;
    int totalMenus = restaurants.where((r) => r['foodName'] != null && r['foodName'].toString().isNotEmpty).length;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('bookings')
          .where('ownerId', isEqualTo: currentUserId)
          .snapshots(),
      builder: (context, bookingSnapshot) {
        int totalBookings = bookingSnapshot.hasData ? bookingSnapshot.data!.docs.length : 0;

        final ownedRestaurantNames = restaurants.map((r) => r['name'] as String).toSet().toList();

        return StreamBuilder<QuerySnapshot>(
          stream: ownedRestaurantNames.isEmpty 
              ? Stream.empty() 
              : FirebaseFirestore.instance
                  .collection('reviews')
                  .where('restaurantName', whereIn: ownedRestaurantNames.take(10).toList())
                  .snapshots(),
          builder: (context, reviewSnapshot) {
            int totalReviews = reviewSnapshot.hasData ? reviewSnapshot.data!.docs.length : 0;

            return LayoutBuilder(
              builder: (context, constraints) {
                bool isMobile = constraints.maxWidth < 600;
                
                if (isMobile) {
                  return Column(
                    children: [
                      _SummaryCard(title: 'Total Restaurants', value: totalRestaurants.toString(), subtitle: 'Live stores', color: const Color(0xFF2D6A4F), icon: Icons.storefront_rounded, isMobile: true),
                      const SizedBox(height: 16),
                      _SummaryCard(title: 'Total Menus', value: totalMenus.toString(), subtitle: 'Food items', color: Colors.orange.shade700, icon: Icons.restaurant_menu_rounded, isMobile: true),
                      const SizedBox(height: 16),
                      _SummaryCard(title: 'Total Bookings', value: totalBookings.toString(), subtitle: 'Table requests', color: Colors.blue.shade700, icon: Icons.event_available_rounded, isMobile: true),
                      const SizedBox(height: 16),
                      _SummaryCard(title: 'Total Reviews', value: totalReviews.toString(), subtitle: 'Customer feedback', color: Colors.amber.shade800, icon: Icons.chat_bubble_outline_rounded, isMobile: true),
                    ],
                  );
                }

                int crossAxisCount = constraints.maxWidth > 1100 ? 4 : 2;
                return GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 20,
                  mainAxisSpacing: 20,
                  childAspectRatio: 1.6,
                  children: [
                    _SummaryCard(title: 'Total Restaurants', value: totalRestaurants.toString(), subtitle: 'Live stores', color: const Color(0xFF2D6A4F), icon: Icons.storefront_rounded),
                    _SummaryCard(title: 'Total Menus', value: totalMenus.toString(), subtitle: 'Food items', color: Colors.orange.shade700, icon: Icons.restaurant_menu_rounded),
                    _SummaryCard(title: 'Total Bookings', value: totalBookings.toString(), subtitle: 'Table requests', color: Colors.blue.shade700, icon: Icons.event_available_rounded),
                    _SummaryCard(title: 'Total Reviews', value: totalReviews.toString(), subtitle: 'Customer feedback', color: Colors.amber.shade800, icon: Icons.chat_bubble_outline_rounded),
                  ],
                );
              },
            );
          },
        );
      }
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final Color color;
  final IconData icon;
  final bool isMobile;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.color,
    required this.icon,
    this.isMobile = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 20 : 24),
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.withOpacity(0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min, // Allow card to fit content
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
            ],
          ),
          if (!isMobile) const Spacer(),
          if (isMobile) const SizedBox(height: 16),
          Text(
            value,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1B4332),
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              color: color.withOpacity(0.8),
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class RecentActivities extends StatelessWidget {
  final List<Map<String, dynamic>> restaurants;
  const RecentActivities({super.key, required this.restaurants});

  @override
  Widget build(BuildContext context) {
    // 1. Prepare and filter activities
    final List<Map<String, dynamic>> activities = restaurants.where((r) {
      // Show if it has a timestamp
      return r['updatedAt'] != null || r['createdAt'] != null;
    }).toList();

    // 2. Sort by latest first
    activities.sort((a, b) {
      Timestamp? tA = a['updatedAt'] ?? a['createdAt'];
      Timestamp? tB = b['updatedAt'] ?? b['createdAt'];
      if (tA == null) return 1;
      if (tB == null) return -1;
      return tB.compareTo(tA);
    });

    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Recent Activities',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1B4332),
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context, 
                    MaterialPageRoute(builder: (context) => ActivitiesPage(restaurants: restaurants))
                  );
                },
                child: const Text('View All', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (activities.isEmpty)
            _buildEmptyState(Icons.history_rounded, 'No activities yet')
          else
            ...activities.take(5).map((rest) {
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

              return _ActivityItem(
                name: rest['name'] ?? 'Restaurant',
                activity: hasFood ? 'Added new dish: ${rest['foodName']}' : (isHeader ? 'Restaurant profile updated' : 'Menu item updated'),
                time: time,
                icon: hasFood ? Icons.add_task_rounded : Icons.update_rounded,
                iconColor: hasFood ? const Color(0xFF2D6A4F) : Colors.blue.shade600,
                isLast: activities.indexOf(rest) == activities.take(5).length - 1,
              );
            }),
        ],
      ),
    );
  }

  Widget _buildEmptyState(IconData icon, String text) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          children: [
            Icon(icon, size: 50, color: Colors.grey.shade200),
            const SizedBox(height: 16),
            Text(text, style: TextStyle(color: Colors.grey.shade400, fontSize: 15, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}

class _ActivityItem extends StatelessWidget {
  final String name;
  final String activity;
  final String time;
  final IconData icon;
  final Color iconColor;
  final bool isLast;

  const _ActivityItem({
    required this.name,
    required this.activity,
    required this.time,
    required this.icon,
    required this.iconColor,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 18),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    color: Colors.grey.withOpacity(0.1),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Color(0xFF1B4332)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        time,
                        style: TextStyle(color: Colors.grey.shade400, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    activity,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13, height: 1.4),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class TopPerformingRestaurants extends StatelessWidget {
  final List<Map<String, dynamic>> restaurants;
  const TopPerformingRestaurants({super.key, required this.restaurants});

  @override
  Widget build(BuildContext context) {
    var sorted = List<Map<String, dynamic>>.from(restaurants);
    sorted.sort((a, b) => (b['rating'] ?? '0').toString().compareTo((a['rating'] ?? '0').toString()));

    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Top Performing',
            style: TextStyle(
              fontSize: 20, 
              fontWeight: FontWeight.w800, 
              color: Color(0xFF1B4332),
            ),
          ),
          const SizedBox(height: 24),
          if (restaurants.isEmpty)
            Center(child: Padding(padding: const EdgeInsets.symmetric(vertical: 40), child: Text('No performance data', style: TextStyle(color: Colors.grey.shade400))))
          else
            ...sorted.take(3).map((rest) {
              return _TopRestaurantItem(
                name: rest['name'],
                rating: rest['rating'] ?? '5.0',
                imageUrl: rest['imageUrl'] ?? 'https://via.placeholder.com/150',
              );
            }),
        ],
      ),
    );
  }
}

class _TopRestaurantItem extends StatelessWidget {
  final String name;
  final String rating;
  final String imageUrl;

  const _TopRestaurantItem({
    required this.name,
    required this.rating,
    required this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              image: DecorationImage(image: NetworkImage(imageUrl), fit: BoxFit.cover),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Color(0xFF1B4332)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.star_rounded, color: Colors.amber, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      rating,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF2D6A4F)),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Avg Rating',
                      style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Icon(Icons.arrow_forward_ios_rounded, color: Colors.grey.shade200, size: 14),
        ],
      ),
    );
  }
}
