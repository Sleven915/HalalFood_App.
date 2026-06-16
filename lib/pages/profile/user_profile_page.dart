import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../auth/login_page.dart';
import '../owner/add_edit_menu_page.dart';
import '../owner/owner_screen.dart';
import 'personal_info_page.dart';
import 'change_password_page.dart';
import 'help_support_page.dart';

class UserProfilePage extends StatefulWidget {
  final VoidCallback? onBack;
  final String? manualUid; // NEW: To support bypass login data

  const UserProfilePage({super.key, this.onBack, this.manualUid});

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  final authUser = FirebaseAuth.instance.currentUser;
  final primaryColor = const Color(0xFF1B4332);

  @override
  Widget build(BuildContext context) {
    // Gunakan manualUid jika ada (kerana login bypass), jika tidak guna authUser!.uid
    final currentUserId = widget.manualUid ?? authUser?.uid;

    return Scaffold(
      body: Stack(
        children: [
          Container(decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFFE8F1ED), Color(0xFFDEEBE6), Color(0xFFD4E5DF)]))),
          Positioned(top: 100, right: -50, child: Icon(Icons.eco_rounded, size: 250, color: primaryColor.withOpacity(0.05))),
          Positioned(bottom: 50, left: -40, child: Icon(Icons.restaurant_rounded, size: 200, color: primaryColor.withOpacity(0.05))),
          
          SafeArea(
            child: StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance.collection('users').doc(currentUserId).snapshots(),
              builder: (context, snapshot) {
                String name = "Loading...";
                String email = authUser?.email ?? "";
                String role = "User";
                String avatarUrl = 'https://api.dicebear.com/7.x/adventurer/png?seed=default'; 

                if (snapshot.hasData && snapshot.data!.exists) {
                  var data = snapshot.data!.data() as Map<String, dynamic>;
                  name = data['fullName'] ?? "User Name";
                  email = data['email'] ?? email;
                  role = data['role'] ?? "User";
                  avatarUrl = data['avatarUrl'] ?? 'https://api.dicebear.com/7.x/adventurer/png?seed=$email';
                }

                bool isOwner = role == 'Owner';

                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Row(
                        children: [
                          if (widget.onBack != null) IconButton(icon: Icon(Icons.arrow_back, color: primaryColor), onPressed: widget.onBack),
                          const Spacer(),
                          Text('Profile', style: TextStyle(color: primaryColor, fontSize: 20, fontWeight: FontWeight.bold)),
                          const Spacer(),
                          const SizedBox(width: 48),
                        ],
                      ),
                    ),
                    
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                        child: Column(
                          children: [
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(32),
                              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(28), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 25, offset: const Offset(0, 10))]),
                              child: Column(
                                children: [
                                  Container(padding: const EdgeInsets.all(4), decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: primaryColor.withOpacity(0.1), width: 4)), child: CircleAvatar(radius: 50, backgroundImage: NetworkImage(avatarUrl))),
                                  const SizedBox(height: 16),
                                  Text(name, textAlign: TextAlign.center, style: TextStyle(color: primaryColor, fontSize: 22, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 4),
                                  Text(email, textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade500, fontSize: 14)),
                                  const SizedBox(height: 24),
                                  SizedBox(
                                    width: double.infinity,
                                    height: 50,
                                    child: ElevatedButton(
                                      onPressed: () {
                                        if (isOwner) { Navigator.push(context, MaterialPageRoute(builder: (context) => OwnerScreen(manualUid: currentUserId))); }
                                        else { Navigator.push(context, MaterialPageRoute(builder: (context) => AddOrEditMenuPage(isNewRestaurant: true, manualUid: currentUserId))).then((result) async {
                                            if (result == true) { await FirebaseFirestore.instance.collection('users').doc(currentUserId).update({'role': 'Owner'}); }
                                          });
                                        }
                                      },
                                      style: ElevatedButton.styleFrom(backgroundColor: isOwner ? const Color(0xFFF59E0B) : primaryColor, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), elevation: 0),
                                      child: Text(isOwner ? 'Manage My Restaurant' : 'Register My Restaurant', style: const TextStyle(fontWeight: FontWeight.bold)),
                                    ),
                                  ),
                                ],
                              ),
                            ).animate().fadeIn().slideY(begin: 0.1),
                            
                            const SizedBox(height: 24),
                            
                            Container(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(28), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 25, offset: const Offset(0, 10))]),
                              child: Column(
                                children: [
                                  _buildProfileOption(Icons.person_outline_rounded, 'Personal Information', () => Navigator.push(context, MaterialPageRoute(builder: (context) => PersonalInfoPage(manualUid: currentUserId)))),
                                  _buildDivider(),
                                  _buildProfileOption(Icons.lock_outline_rounded, 'Change Password', () => Navigator.push(context, MaterialPageRoute(builder: (context) => ChangePasswordPage(manualUid: currentUserId)))),
                                  _buildDivider(),
                                  _buildProfileOption(Icons.help_outline_rounded, 'Help & Support', () => Navigator.push(context, MaterialPageRoute(builder: (context) => const HelpSupportPage()))),
                                  _buildDivider(),
                                  _buildProfileOption(Icons.logout_rounded, 'Logout', () => _showLogoutDialog(context), isLogout: true),
                                ],
                              ),
                            ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1),
                            const SizedBox(height: 40),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() { return Divider(height: 1, indent: 60, endIndent: 20, color: Colors.grey.shade100); }

  Widget _buildProfileOption(IconData icon, String title, VoidCallback onTap, {bool isLogout = false}) {
    final color = isLogout ? Colors.redAccent : primaryColor;
    return ListTile(
      leading: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(14)), child: Icon(icon, color: color, size: 22)),
      title: Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: isLogout ? Colors.redAccent : Colors.black87)),
      trailing: Icon(Icons.chevron_right_rounded, color: Colors.grey.shade300, size: 22),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context, 
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Logout', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel', style: TextStyle(color: Colors.grey.shade600))),
          ElevatedButton(onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (!mounted) return;
              Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const LoginPage()), (route) => false);
            }, 
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), elevation: 0),
            child: const Text('Logout', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }
}
