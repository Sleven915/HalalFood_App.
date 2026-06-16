import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PersonalInfoPage extends StatefulWidget {
  final String? manualUid; // Terima ID manual untuk bypass login
  const PersonalInfoPage({super.key, this.manualUid});

  @override
  State<PersonalInfoPage> createState() => _PersonalInfoPageState();
}

class _PersonalInfoPageState extends State<PersonalInfoPage> {
  final authUser = FirebaseAuth.instance.currentUser;
  bool _isLoading = true;
  bool _isSaving = false;
  String _selectedAvatar = 'https://api.dicebear.com/7.x/adventurer/png?seed=Felix';
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _keywordController = TextEditingController();

  final List<String> _avatars = [
    'https://api.dicebear.com/7.x/adventurer/png?seed=Felix',
    'https://api.dicebear.com/7.x/adventurer/png?seed=Aneka',
    'https://api.dicebear.com/7.x/adventurer/png?seed=Max',
    'https://api.dicebear.com/7.x/adventurer/png?seed=Boots',
    'https://api.dicebear.com/7.x/adventurer/png?seed=Bear',
    'https://api.dicebear.com/7.x/adventurer/png?seed=Lion',
  ];

  String get currentUid => widget.manualUid ?? authUser?.uid ?? "";

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    if (currentUid.isEmpty) {
      setState(() => _isLoading = false);
      return;
    }
    
    final doc = await FirebaseFirestore.instance.collection('users').doc(currentUid).get();
    if (doc.exists) {
      final data = doc.data()!;
      String? keyword = data['recoveryKeyword'];
      
      if (keyword == null || keyword == 'Not set') {
        final List<String> keywordPool = ['Tiger', 'Elephant', 'Durian', 'Satay', 'Pizza', 'Panda'];
        keyword = keywordPool[DateTime.now().millisecond % keywordPool.length].toLowerCase();
        await FirebaseFirestore.instance.collection('users').doc(currentUid).update({'recoveryKeyword': keyword});
      }

      setState(() {
        _nameController.text = data['fullName'] ?? '';
        _emailController.text = data['email'] ?? '';
        _phoneController.text = data['phone'] ?? '';
        _addressController.text = data['address'] ?? '';
        _keywordController.text = keyword![0].toUpperCase() + keyword.substring(1);
        _selectedAvatar = data['avatarUrl'] ?? _avatars[0];
      });
    }
    setState(() => _isLoading = false);
  }

  Future<void> _saveData() async {
    if (currentUid.isEmpty) return;
    setState(() => _isSaving = true);
    try {
      await FirebaseFirestore.instance.collection('users').doc(currentUid).update({
        'fullName': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'address': _addressController.text.trim(),
        'avatarUrl': _selectedAvatar,
      });
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _keywordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = const Color(0xFF1B4332);
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Edit Profile', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white, elevation: 0, iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: _isLoading ? const Center(child: CircularProgressIndicator()) : SingleChildScrollView(padding: const EdgeInsets.all(24.0), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Choose an Avatar', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            SizedBox(height: 80, child: ListView.builder(scrollDirection: Axis.horizontal, itemCount: _avatars.length, itemBuilder: (context, index) {
                  bool isSelected = _selectedAvatar == _avatars[index];
                  return GestureDetector(onTap: () => setState(() => _selectedAvatar = _avatars[index]), child: Container(margin: const EdgeInsets.only(right: 12), decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: isSelected ? primaryColor : Colors.transparent, width: 3)), child: CircleAvatar(radius: 35, backgroundImage: NetworkImage(_avatars[index]))));
                })),
            const SizedBox(height: 32),
            _buildLabel('Full Name'), _buildTextField(_nameController, 'Enter your full name'),
            const SizedBox(height: 20),
            _buildLabel('Phone Number'), _buildTextField(_phoneController, 'e.g. 0123456789', type: TextInputType.phone),
            const SizedBox(height: 20),
            _buildLabel('Address'), _buildTextField(_addressController, 'Enter your address', maxLines: 3),
            const SizedBox(height: 20),
            _buildLabel('Recovery Keyword'), _buildTextField(_keywordController, '', enabled: false, prefixIcon: Icons.lock_outline_rounded),
            const Text('This keyword is used for account recovery and cannot be changed.', style: TextStyle(color: Colors.grey, fontSize: 11)),
            const SizedBox(height: 48),
            SizedBox(width: double.infinity, height: 56, child: ElevatedButton(onPressed: _isSaving ? null : _saveData, style: ElevatedButton.styleFrom(backgroundColor: primaryColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: _isSaving ? const CircularProgressIndicator(color: Colors.white) : const Text('Save Changes', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)))),
          ])),
    );
  }

  Widget _buildLabel(String text) => Padding(padding: const EdgeInsets.only(bottom: 8.0), child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)));
  Widget _buildTextField(TextEditingController controller, String hint, {TextInputType? type, int maxLines = 1, bool enabled = true, IconData? prefixIcon}) {
    return TextField(controller: controller, keyboardType: type, maxLines: maxLines, enabled: enabled, style: TextStyle(color: enabled ? Colors.black : Colors.grey.shade600), decoration: InputDecoration(hintText: hint, prefixIcon: prefixIcon != null ? Icon(prefixIcon, size: 20) : null, filled: !enabled, fillColor: enabled ? Colors.white : Colors.grey.shade50, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), disabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200))));
  }
}
