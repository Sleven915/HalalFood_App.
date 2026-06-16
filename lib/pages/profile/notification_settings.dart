import 'package:flutter/material.dart';

class NotificationSettingsPage extends StatefulWidget {
  const NotificationSettingsPage({super.key});
  @override
  State<NotificationSettingsPage> createState() => _NotificationSettingsPageState();
}

class _NotificationSettingsPageState extends State<NotificationSettingsPage> {
  bool _orderUpdates = true;
  bool _promotions = true;
  bool _nearbyDeals = false;
  bool _newRestaurants = true;
  bool _emailNewsletter = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Notification Settings', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        children: [
          _buildSectionHeader('Push Notifications'),
          _buildSwitchTile(
            'Order Updates',
            'Get notified about your food order status.',
            _orderUpdates,
            (v) => setState(() => _orderUpdates = v),
          ),
          _buildSwitchTile(
            'Promotions & Offers',
            'Receive alerts for discounts and special deals.',
            _promotions,
            (v) => setState(() => _promotions = v),
          ),
          _buildSwitchTile(
            'Nearby Deals',
            'Get notified about offers from restaurants near you.',
            _nearbyDeals,
            (v) => setState(() => _nearbyDeals = v),
          ),
          _buildSwitchTile(
            'New Restaurants',
            'Be the first to know when a new Halal gem opens.',
            _newRestaurants,
            (v) => setState(() => _newRestaurants = v),
          ),
          const SizedBox(height: 24),
          _buildSectionHeader('Email Notifications'),
          _buildSwitchTile(
            'Weekly Newsletter',
            'Summary of top restaurants and news of the week.',
            _emailNewsletter,
            (v) => setState(() => _emailNewsletter = v),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 12, top: 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: Colors.grey.shade600,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildSwitchTile(String title, String subtitle, bool value, ValueChanged<bool> onChanged) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: SwitchListTile(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        subtitle: Text(subtitle, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
        value: value,
        onChanged: onChanged,
        activeColor: const Color(0xFF1B4332),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
    );
  }
}
