import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../pages/restaurant/home_page.dart';
import '../pages/owner/owner_screen.dart';
import '../pages/auth/login_page.dart';
import '../pages/owner/add_edit_menu_page.dart';

class AppDrawer extends StatelessWidget {
  final Function(int)? onTabRequested; 
  final String? manualUid; // NEW: Support bypass login

  const AppDrawer({super.key, this.onTabRequested, this.manualUid});

  @override
  Widget build(BuildContext context) {
    final authUser = FirebaseAuth.instance.currentUser;
    final currentUserId = manualUid ?? authUser?.uid;

    return Drawer(
      child: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(currentUserId).snapshots(),
        builder: (context, snapshot) {
          String role = 'User';
          if (snapshot.hasData && snapshot.data!.exists) {
            role = (snapshot.data!.data() as Map<String, dynamic>)['role'] ?? 'User';
          }

          // Auto-upgrade logic
          if (role == 'User' && currentUserId != null) {
            FirebaseFirestore.instance
                .collection('restaurants')
                .where('ownerId', isEqualTo: currentUserId)
                .limit(1)
                .get()
                .then((querySnapshot) {
              if (querySnapshot.docs.isNotEmpty) {
                FirebaseFirestore.instance.collection('users').doc(currentUserId).update({'role': 'Owner'});
              }
            });
          }

          bool hasOwnerAccess = role == 'Owner';

          return Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF064E3B), Color(0xFF065F46), Color(0xFF047857)],
              ),
            ),
            child: Column(
              children: [
                // Header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.only(top: 80, bottom: 40),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), shape: BoxShape.circle),
                        child: const Icon(Icons.mosque_rounded, color: Colors.white, size: 40),
                      ),
                      const SizedBox(height: 16),
                      const Text('HalalEats', style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                    ],
                  ),
                ),
                const Divider(color: Colors.white24, height: 1),
                // Menu Items
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
                    children: [
                      _buildDrawerItem(icon: Icons.home_outlined, label: 'Home Feed', onTap: () {
                          Navigator.pop(context);
                          if (onTabRequested != null) onTabRequested!(0);
                          else Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => HomePage(manualUid: manualUid)), (r) => false);
                      }),
                      _buildDrawerItem(icon: Icons.person_outline_rounded, label: 'My Profile', onTap: () {
                          Navigator.pop(context);
                          if (onTabRequested != null) onTabRequested!(3);
                          else Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => HomePage(manualUid: manualUid)), (r) => false);
                      }),
                      _buildDrawerItem(icon: Icons.favorite_outline_rounded, label: 'Saved Places', onTap: () {
                          Navigator.pop(context);
                          if (onTabRequested != null) onTabRequested!(2);
                          else Navigator.push(context, MaterialPageRoute(builder: (context) => HomePage(manualUid: manualUid)));
                      }),
                      const Divider(color: Colors.white10),
                      if (hasOwnerAccess)
                        _buildDrawerItem(icon: Icons.dashboard_customize_outlined, label: 'Owner Dashboard', activeColor: const Color(0xFFF59E0B), onTap: () {
                            Navigator.pop(context);
                            Navigator.push(context, MaterialPageRoute(builder: (context) => OwnerScreen(manualUid: manualUid)));
                        })
                      else
                        _buildDrawerItem(icon: Icons.add_business_outlined, label: 'Register Restaurant', onTap: () {
                            Navigator.pop(context);
                            Navigator.push(context, MaterialPageRoute(builder: (context) => const AddOrEditMenuPage(isNewRestaurant: true)));
                        }),
                      _buildDrawerItem(icon: Icons.logout_rounded, label: 'Sign Out', isLogout: true, onTap: () async {
                          await FirebaseAuth.instance.signOut();
                          if (!context.mounted) return;
                          Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const LoginPage()), (route) => false);
                      }),
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

  Widget _buildDrawerItem({required IconData icon, required String label, required VoidCallback onTap, Color? activeColor, bool isLogout = false}) {
    final Color textColor = isLogout ? Colors.redAccent.shade100 : Colors.white;
    final Color iconColor = activeColor ?? (isLogout ? Colors.redAccent.shade100 : Colors.white.withOpacity(0.7));
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: Colors.white.withOpacity(0.03)),
      child: ListTile(leading: Icon(icon, color: iconColor, size: 22), title: Text(label, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: textColor)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), onTap: onTap),
    );
  }
}
