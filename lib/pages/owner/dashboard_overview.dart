import 'package:flutter/material.dart';
import '../../widgets/dashboard_sections.dart';

class DashboardOverview extends StatelessWidget {
  final List<Map<String, dynamic>> restaurants;
  final String? manualUid; // NEW

  const DashboardOverview({
    super.key,
    required this.restaurants,
    this.manualUid,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const HeaderSection(),
          const SizedBox(height: 32),
          
          SummarySection(restaurants: restaurants, manualUid: manualUid), // PASS UID
          const SizedBox(height: 32),
          
          TopPerformingRestaurants(restaurants: restaurants),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}
