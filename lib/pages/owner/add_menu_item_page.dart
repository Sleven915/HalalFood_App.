import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';

class AddMenuItemPage extends StatefulWidget {
  final String restaurantName;
  final String? restaurantId; 
  final String? manualUid; // NEW

  const AddMenuItemPage({
    super.key,
    required this.restaurantName,
    this.restaurantId,
    this.manualUid,
  });

  @override
  State<AddMenuItemPage> createState() => _AddMenuItemPageState();
}

class _AddMenuItemPageState extends State<AddMenuItemPage> {
  final TextEditingController _foodNameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _imageUrlController = TextEditingController();
  
  String _selectedCategory = 'Main Course';
  String _selectedDietary = 'Halal';
  bool _isSaving = false;

  final ImagePicker _picker = ImagePicker();
  Uint8List? _pickedImageBytes;
  String? _selectedImageUrl;

  final List<String> _categories = ['Main Course', 'Appetizer', 'Dessert', 'Beverage', 'Snacks', 'Drinks'];
  final List<String> _dietaryOptions = ['Halal', 'Non Halal', 'Vege'];

  final List<String> _presetFoodImages = [
    'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=800', // Salad
    'https://images.unsplash.com/photo-1567620905732-2d1ec7bb7445?w=800', // Pancakes
    'https://images.unsplash.com/photo-1565299624946-b28f40a0ae38?w=800', // Pizza
    'https://images.unsplash.com/photo-1482049016688-2d3e1b311543?w=800', // Sandwich
    'https://images.unsplash.com/photo-1484723088339-fe2a7a8f1d45?w=800', // Toast
    'https://images.unsplash.com/photo-1540189549336-e6e99c3679fe?w=800', // General food
    'https://images.unsplash.com/photo-1555939594-58d7cb561ad1?w=800', // Grilled meat
    'https://images.unsplash.com/photo-1565958011703-44f9829ba187?w=800', // Cake
  ];

  String? get currentUserId => widget.manualUid ?? FirebaseAuth.instance.currentUser?.uid;

  @override
  void initState() {
    super.initState();
    if (widget.restaurantId != null) {
      _fetchItemData();
    }
    
    _imageUrlController.addListener(() {
      if (_imageUrlController.text.isNotEmpty) {
        setState(() {
          _selectedImageUrl = _imageUrlController.text.trim();
          _pickedImageBytes = null;
        });
      }
    });
  }

  Future<void> _fetchItemData() async {
    final doc = await FirebaseFirestore.instance.collection('restaurants').doc(widget.restaurantId).get();
    if (doc.exists) {
      final data = doc.data()!;
      setState(() {
        _foodNameController.text = data['foodName'] ?? '';
        _priceController.text = data['price'] ?? '';
        _descriptionController.text = data['description'] ?? '';
        _selectedImageUrl = data['imageUrl'];
        _imageUrlController.text = data['imageUrl'] ?? '';
        
        // Load Food Category (Main Course, etc.)
        if (data['foodCategory'] != null && _categories.contains(data['foodCategory'])) {
          _selectedCategory = data['foodCategory'];
        }

        // Load Dietary (Halal, etc.)
        String storedDietary = data['category'] ?? 'halal';
        _selectedDietary = storedDietary == 'non-halal' ? 'Non Halal' : (storedDietary == 'vege' ? 'Vege' : 'Halal');
      });
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        imageQuality: 70,
      );
      
      if (image != null) {
        final Uint8List bytes = await image.readAsBytes();
        setState(() {
          _pickedImageBytes = bytes;
          _selectedImageUrl = null;
          _imageUrlController.clear();
        });
      }
    } catch (e) {
      debugPrint("Error picking image: $e");
    }
  }

  Future<String?> _uploadImage() async {
    if (_pickedImageBytes == null) return _selectedImageUrl;
    if (currentUserId == null) return _selectedImageUrl;

    try {
      final fileName = 'food_${currentUserId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final storageRef = FirebaseStorage.instance.ref().child('food_photos/$fileName');
      
      final uploadTask = storageRef.putData(
        _pickedImageBytes!, 
        SettableMetadata(contentType: 'image/jpeg')
      );
      
      final snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      debugPrint("Error uploading image: $e");
      return _selectedImageUrl;
    }
  }

  @override
  void dispose() {
    _foodNameController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(widget.restaurantId == null ? 'Add Menu Item' : 'Edit Menu Item', 
            style: const TextStyle(color: Color(0xFF1B4332), fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Color(0xFF1B4332)),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 700),
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 10))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Restaurant: ${widget.restaurantName}', style: const TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.w500)),
                const SizedBox(height: 24),
                
                _buildForm(),
                const SizedBox(height: 32),
                _buildImageSelection(),
                const SizedBox(height: 40),
                _buildPreview(),
                const SizedBox(height: 40),
                _buildSaveButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldLabel('Food Name'),
        _buildTextField(_foodNameController, 'e.g. Nasi Ayam Penyet'),
        const SizedBox(height: 20),
        _buildFieldLabel('Price (RM)'),
        _buildTextField(_priceController, 'e.g. 15.00', keyboardType: TextInputType.number),
        const SizedBox(height: 20),
        _buildFieldLabel('Category'),
        DropdownButtonFormField<String>(
          value: _selectedCategory,
          decoration: _inputDecoration('Select category'),
          items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
          onChanged: (v) => setState(() => _selectedCategory = v!),
        ),
        const SizedBox(height: 20),
        _buildFieldLabel('Dietary'),
        DropdownButtonFormField<String>(
          value: _selectedDietary,
          decoration: _inputDecoration('Select dietary'),
          items: _dietaryOptions.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
          onChanged: (v) => setState(() => _selectedDietary = v!),
        ),
        const SizedBox(height: 20),
        _buildFieldLabel('Description'),
        _buildTextField(_descriptionController, 'Describe this dish...', maxLines: 3),
      ],
    );
  }

  Widget _buildImageSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldLabel('Food Photo'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            ElevatedButton.icon(
              onPressed: _pickImage,
              icon: const Icon(Icons.add_a_photo_outlined, size: 18),
              label: const Text('Pick from Gallery'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1B4332),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const Text('OR paste a direct URL:', style: TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.w500)),
          ],
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _imageUrlController,
          decoration: _inputDecoration('Paste image address (e.g. https://...)').copyWith(
            prefixIcon: const Icon(Icons.link_rounded, color: Color(0xFF1B4332)),
          ),
        ),
        const SizedBox(height: 20),
        const Text('OR choose a preset:', style: TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.w500)),
        const SizedBox(height: 12),
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _presetFoodImages.length,
            itemBuilder: (context, index) {
              bool isSelected = _selectedImageUrl == _presetFoodImages[index];
              return GestureDetector(
                onTap: () => setState(() {
                  _selectedImageUrl = _presetFoodImages[index];
                  _imageUrlController.text = _presetFoodImages[index];
                  _pickedImageBytes = null;
                }),
                child: Container(
                  margin: const EdgeInsets.only(right: 12),
                  width: 120,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? const Color(0xFF1B4332) : Colors.transparent, 
                      width: 3
                    ),
                    image: DecorationImage(
                      image: NetworkImage(_presetFoodImages[index]),
                      fit: BoxFit.cover,
                    ),
                  ),
                  child: isSelected 
                    ? const Center(child: Icon(Icons.check_circle, color: Colors.white, shadows: [Shadow(blurRadius: 10, color: Colors.black45)]))
                    : null,
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPreview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Preview', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1B4332))),
        const SizedBox(height: 16),
        Container(
          height: 200, 
          width: double.infinity, 
          decoration: BoxDecoration(
            color: const Color(0xFF1B4332).withOpacity(0.1), 
            borderRadius: BorderRadius.circular(16),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: _pickedImageBytes != null 
              ? Image.memory(_pickedImageBytes!, fit: BoxFit.cover)
              : (_selectedImageUrl != null && _selectedImageUrl!.isNotEmpty)
                ? Image.network(
                    _selectedImageUrl!, 
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.broken_image_outlined, color: Colors.red, size: 40),
                          SizedBox(height: 8),
                          Text('Invalid Image URL', style: TextStyle(color: Colors.red, fontSize: 12)),
                        ],
                      )
                    ),
                  )
                : const Center(child: Icon(Icons.restaurant_menu_rounded, color: Color(0xFF1B4332), size: 50)),
          ),
        ),
        const SizedBox(height: 16),
        Text(_foodNameController.text.isEmpty ? 'Food Name' : _foodNameController.text, 
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(_priceController.text.isEmpty ? 'RM 0.00' : 'RM ${_priceController.text}', 
            style: const TextStyle(color: Color(0xFF2D6A4F), fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildFieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1B4332))),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: const Color(0xFFF8F9FA),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, {TextInputType? keyboardType, int maxLines = 1}) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      onChanged: (_) => setState(() {}),
      decoration: _inputDecoration(hint),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        onPressed: _isSaving ? null : _saveMenuItem,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1B4332),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
        ),
        child: _isSaving 
          ? const CircularProgressIndicator(color: Colors.white)
          : const Text('Save Menu Item', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
      ),
    );
  }

  Future<void> _saveMenuItem() async {
    if (_foodNameController.text.isEmpty || _priceController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill in food name and price')));
      return;
    }

    setState(() => _isSaving = true);

    try {
      if (currentUserId == null) throw 'User not logged in';

      final imageUrl = await _uploadImage();

      final headerSnapshot = await FirebaseFirestore.instance
          .collection('restaurants')
          .where('name', isEqualTo: widget.restaurantName)
          .where('isHeader', isEqualTo: true)
          .limit(1)
          .get();

      if (headerSnapshot.docs.isEmpty) throw 'Restaurant profile not found';
      final headerData = headerSnapshot.docs.first.data();

      final dietary = _selectedDietary.toLowerCase().replaceAll(' ', '-');
      
      final data = {
        'ownerId': currentUserId,
        'name': widget.restaurantName,
        'location': headerData['location'] ?? 'Setapak, KL',
        'phone': headerData['phone'] ?? '',
        'status': headerData['status'] ?? 'Active',
        'imageUrl': imageUrl ?? 'https://images.unsplash.com/photo-1563379091339-03b21bc4a4f8?w=800',
        'foodName': _foodNameController.text.trim(),
        'price': _priceController.text.trim(),
        'foodCategory': _selectedCategory, // SAVE FOOD CATEGORY
        'category': dietary, // This is 'halal', 'non-halal', or 'vege'
        'description': _descriptionController.text.trim(),
        'isHeader': false,
        'updatedAt': FieldValue.serverTimestamp(),
        'rating': headerData['rating'] ?? '5.0',
        'distance': headerData['distance'] ?? '0.5 km',
      };

      if (widget.restaurantId != null) {
        await FirebaseFirestore.instance.collection('restaurants').doc(widget.restaurantId).update(data);
      } else {
        data['createdAt'] = FieldValue.serverTimestamp();
        await FirebaseFirestore.instance.collection('restaurants').add(data);
      }

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }
}
