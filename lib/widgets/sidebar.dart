import 'package:flutter/material.dart';

class Sidebar extends StatelessWidget {
  final String activeItem;
  final Function(String) onItemTap;

  const Sidebar({
    super.key,
    required this.activeItem,
    required this.onItemTap,
  });

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    bool isMobile = screenWidth < 600;
    
    // If it's a drawer (mobile), use standard width, else use responsive width
    double sidebarWidth = isMobile ? 280 : (screenWidth > 900 ? 280 : 220);

    return Container(
      width: sidebarWidth,
      height: double.infinity,
      color: const Color(0xFF0B3D2E), // Dark Green
      child: Column(
        children: [
          const SizedBox(height: 60),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Row(
              children: [
                const Icon(Icons.eco, color: Colors.white, size: 28),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'HalalEats Owner',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 50),
          _SidebarItem(
            icon: Icons.dashboard_outlined,
            label: 'Dashboard',
            isActive: activeItem == 'Dashboard',
            onTap: () => onItemTap('Dashboard'),
          ),
          _SidebarItem(
            icon: Icons.restaurant_outlined,
            label: 'My Restaurants',
            isActive: activeItem == 'My Restaurants',
            onTap: () => onItemTap('My Restaurants'),
          ),
          const Spacer(),
          _SidebarItem(
            icon: Icons.logout,
            label: 'Logout',
            onTap: () => onItemTap('Logout'),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _SidebarItem({
    required this.icon,
    required this.label,
    this.isActive = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isActive ? Colors.white.withOpacity(0.15) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        leading: Icon(
          icon,
          color: isActive ? Colors.white : Colors.white70,
        ),
        title: Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.white : Colors.white70,
            fontSize: 14,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        onTap: onTap,
      ),
    );
  }
}
