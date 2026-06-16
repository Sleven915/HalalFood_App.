import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import 'package:intl/intl.dart';

class AddOrEditMenuPage extends StatefulWidget {
  final bool isNewRestaurant;
  final String? existingRestaurantName;
  final String? restaurantId;
  final String? manualUid; 

  const AddOrEditMenuPage({
    super.key, 
    this.isNewRestaurant = true,
    this.existingRestaurantName,
    this.restaurantId,
    this.manualUid,
  });

  @override
  State<AddOrEditMenuPage> createState() => _AddOrEditMenuPageState();
}

class _AddOrEditMenuPageState extends State<AddOrEditMenuPage> {
  final TextEditingController _restaurantNameController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _imageUrlController = TextEditingController();
  final TextEditingController _halalCertUrlController = TextEditingController(); // NEW
  
  String _selectedCategory = 'halal';
  bool _isSaving = false;

  // Structured Operating Info
  final List<String> _daysOfWeek = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  final List<String> _selectedDays = [];
  TimeOfDay _openTime = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay _closeTime = const TimeOfDay(hour: 22, minute: 0);

  final ImagePicker _picker = ImagePicker();
  
  // Main Restaurant Image
  Uint8List? _pickedImageBytes;
  String? _selectedImageUrl; 

  // Halal Certificate Image
  Uint8List? _halalCertBytes;
  String? _halalCertUrl;

  final List<String> _presetImages = [
    'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?w=800',
    'https://images.unsplash.com/photo-1552566626-52f8b828add9?w=800',
    'https://images.unsplash.com/photo-1514362545857-3bc16c4c7d1b?w=800',
    'https://images.unsplash.com/photo-1555396273-367ea4eb4db5?w=800',
    'https://images.unsplash.com/photo-1414235077428-338989a2e8c0?w=800',
  ];

  String? get currentUserId => widget.manualUid ?? FirebaseAuth.instance.currentUser?.uid;

  @override
  void initState() {
    super.initState();
    if (widget.existingRestaurantName != null) {
      _restaurantNameController.text = widget.existingRestaurantName!;
      _fetchExistingRestaurantData();
    }
    
    _imageUrlController.addListener(() {
      if (_imageUrlController.text.isNotEmpty) {
        setState(() {
          _selectedImageUrl = _imageUrlController.text.trim();
          _pickedImageBytes = null;
        });
      }
    });

    _halalCertUrlController.addListener(() {
      if (_halalCertUrlController.text.isNotEmpty) {
        setState(() {
          _halalCertUrl = _halalCertUrlController.text.trim();
          _halalCertBytes = null;
        });
      }
    });
  }

  Future<void> _fetchExistingRestaurantData() async {
    if (widget.restaurantId != null) {
      final doc = await FirebaseFirestore.instance.collection('restaurants').doc(widget.restaurantId).get();
      if (doc.exists) {
        final data = doc.data()!;
        setState(() {
          _locationController.text = data['location'] ?? '';
          _phoneController.text = data['phone'] ?? '';
          _descriptionController.text = data['description'] ?? '';
          _selectedCategory = data['category'] ?? 'halal';
          _selectedImageUrl = data['imageUrl'];
          _imageUrlController.text = data['imageUrl'] ?? '';
          _halalCertUrl = data['halalCertUrl'];
          _halalCertUrlController.text = data['halalCertUrl'] ?? '';
          
          // Parse Days
          String daysStr = data['operatingDays'] ?? 'Mon - Fri';
          _selectedDays.clear();
          if (daysStr.toLowerCase().contains('daily') || daysStr.toLowerCase().contains('everyday')) {
            _selectedDays.addAll(_daysOfWeek);
          } else {
            for (var day in _daysOfWeek) {
              if (daysStr.contains(day)) _selectedDays.add(day);
            }
          }

          // Parse Hours
          String hoursStr = data['openingHours'] ?? '8:00 AM - 10:00 PM';
          final parts = hoursStr.split('-');
          if (parts.length == 2) {
            _openTime = _parseTime(parts[0]);
            _closeTime = _parseTime(parts[1]);
          }
        });
      }
    }
  }

  TimeOfDay _parseTime(String timeStr) {
    try {
      final format = DateFormat.jm();
      final date = format.parse(timeStr.trim());
      return TimeOfDay.fromDateTime(date);
    } catch (e) {
      return const TimeOfDay(hour: 8, minute: 0);
    }
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final now = DateTime.now();
    final dt = DateTime(now.year, now.month, now.day, time.hour, time.minute);
    return DateFormat.jm().format(dt);
  }

  Future<void> _pickImage({bool forCert = false}) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        imageQuality: 70,
      );
      
      if (image != null) {
        final Uint8List bytes = await image.readAsBytes();
        setState(() {
          if (forCert) {
            _halalCertBytes = bytes;
            _halalCertUrl = null;
            _halalCertUrlController.clear();
          } else {
            _pickedImageBytes = bytes;
            _selectedImageUrl = null;
            _imageUrlController.clear();
          }
        });
      }
    } catch (e) {
      debugPrint("Error picking image: $e");
    }
  }

  Future<String?> _uploadToStorage(Uint8List bytes, String prefix) async {
    if (currentUserId == null) return null;
    try {
      final fileName = '${prefix}_${currentUserId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final storageRef = FirebaseStorage.instance.ref().child('restaurant_assets/$fileName');
      final uploadTask = storageRef.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
      final snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      debugPrint("Error uploading to storage: $e");
      return null;
    }
  }

  @override
  void dispose() {
    _restaurantNameController.dispose();
    _locationController.dispose();
    _phoneController.dispose();
    _descriptionController.dispose();
    _imageUrlController.dispose();
    _halalCertUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(widget.isNewRestaurant ? 'Register Restaurant' : 'Restaurant Details', 
            style: const TextStyle(color: Color(0xFF1B4332), fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Color(0xFF1B4332)),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 800),
            margin: const EdgeInsets.all(24),
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white, 
              borderRadius: BorderRadius.circular(24),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 10))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildForm(),
                const SizedBox(height: 32),
                _buildImageSelection(),
                const SizedBox(height: 32),
                _buildHalalCertUpload(),
                const SizedBox(height: 40),
                _buildPreview(),
                const SizedBox(height: 40),
                _buildActionButtons(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Helper to generate 30-minute intervals for the dropdown
  List<String> _generateTimeSlotsList() {
    List<String> slots = [];
    for (int hour = 0; hour < 24; hour++) {
      for (int min in [0, 30]) {
        final time = TimeOfDay(hour: hour, minute: min);
        final now = DateTime.now();
        final dt = DateTime(now.year, now.month, now.day, time.hour, time.minute);
        slots.add(DateFormat.jm().format(dt));
      }
    }
    return slots;
  }

  Widget _buildForm() {
    final timeSlots = _generateTimeSlotsList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldLabel('Restaurant Name'),
        TextField(
          controller: _restaurantNameController, 
          enabled: widget.isNewRestaurant,
          decoration: _inputDecoration('Enter restaurant name...'),
        ),
        const SizedBox(height: 20),
        _buildFieldLabel('Category'),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _buildCategoryChip('halal', 'Halal', const Color(0xFF2D6A4F)),
            _buildCategoryChip('non-halal', 'Non-Halal', Colors.red.shade800),
            _buildCategoryChip('vege', 'Vege', Colors.orange.shade800),
          ],
        ),
        const SizedBox(height: 24),
        
        _buildFieldLabel('Operating Days'),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _daysOfWeek.map((day) {
            bool isSelected = _selectedDays.contains(day);
            return ChoiceChip(
              label: Text(day, style: TextStyle(color: isSelected ? Colors.white : Colors.black, fontSize: 12)),
              selected: isSelected,
              onSelected: (v) {
                setState(() {
                  if (v) _selectedDays.add(day);
                  else _selectedDays.remove(day);
                });
              },
              selectedColor: const Color(0xFF1B4332),
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: isSelected ? Colors.transparent : Colors.grey.shade200)),
            );
          }).toList(),
        ),
        
        const SizedBox(height: 24),
        
        _buildFieldLabel('Opening Hours'),
        Row(
          children: [
            Expanded(
              child: _buildTimeDropdown('Open Time', _formatTimeOfDay(_openTime), timeSlots, (val) {
                if (val != null) setState(() => _openTime = _parseTime(val));
              }),
            ),
            const Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Text('-', style: TextStyle(fontWeight: FontWeight.bold))),
            Expanded(
              child: _buildTimeDropdown('Close Time', _formatTimeOfDay(_closeTime), timeSlots, (val) {
                if (val != null) setState(() => _closeTime = _parseTime(val));
              }),
            ),
          ],
        ),

        const SizedBox(height: 20),
        _buildFieldLabel('Location'), 
        TextField(controller: _locationController, decoration: _inputDecoration('e.g. Setapak, KL')),
        const SizedBox(height: 20),
        _buildFieldLabel('Phone Number'), 
        TextField(controller: _phoneController, keyboardType: TextInputType.phone, decoration: _inputDecoration('e.g. 03-4142 1234')),
        const SizedBox(height: 20),
        _buildFieldLabel('About / Description'), 
        TextField(controller: _descriptionController, maxLines: 4, decoration: _inputDecoration('Describe your restaurant...')),
      ],
    );
  }

  Widget _buildTimeDropdown(String label, String value, List<String> items, ValueChanged<String?> onChanged) {
    List<String> uniqueItems = List.from(items);
    if (!uniqueItems.contains(value)) uniqueItems.insert(0, value);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(color: const Color(0xFFF8F9FA), borderRadius: BorderRadius.circular(12)),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value, isExpanded: true, icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 20),
              items: uniqueItems.toSet().toList().map((String time) => DropdownMenuItem<String>(value: time, child: Text(time, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)))).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryChip(String value, String label, Color color) {
    bool isSelected = _selectedCategory == value;
    IconData icon = value == 'halal' ? Icons.verified_user_rounded : (value == 'non-halal' ? Icons.block_flipped : Icons.eco_rounded);
    return GestureDetector(
      onTap: () => setState(() => _selectedCategory = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(color: isSelected ? color : Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: isSelected ? color : Colors.grey.shade200, width: 1.5)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 18, color: isSelected ? Colors.white : color), const SizedBox(width: 8), Text(label, style: TextStyle(color: isSelected ? Colors.white : Colors.black87, fontWeight: FontWeight.bold, fontSize: 14))]),
      ),
    );
  }

  Widget _buildImageSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldLabel('Restaurant Image'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 12, runSpacing: 12, crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            ElevatedButton.icon(
              onPressed: () => _pickImage(forCert: false),
              icon: const Icon(Icons.add_a_photo_outlined, size: 18),
              label: const Text('Pick from Gallery'),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1B4332), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            ),
            const Text('OR paste a direct URL:', style: TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.w500)),
          ],
        ),
        const SizedBox(height: 16),
        TextField(controller: _imageUrlController, decoration: _inputDecoration('Paste image address (e.g. https://...)').copyWith(prefixIcon: const Icon(Icons.link_rounded, color: Color(0xFF1B4332)))),
        const SizedBox(height: 20),
        const Text('OR choose from gallery:', style: TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.w500)),
        const SizedBox(height: 12),
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal, itemCount: _presetImages.length,
            itemBuilder: (context, index) {
              bool isSelected = _selectedImageUrl == _presetImages[index];
              return GestureDetector(
                onTap: () => setState(() { _selectedImageUrl = _presetImages[index]; _imageUrlController.text = _presetImages[index]; _pickedImageBytes = null; }),
                child: Container(margin: const EdgeInsets.only(right: 12), width: 120, decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), border: Border.all(color: isSelected ? const Color(0xFF1B4332) : Colors.transparent, width: 3), image: DecorationImage(image: NetworkImage(_presetImages[index]), fit: BoxFit.cover)), child: isSelected ? const Center(child: Icon(Icons.check_circle, color: Colors.white, shadows: [Shadow(blurRadius: 10, color: Colors.black45)])) : null),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildHalalCertUpload() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldLabel('Halal Certificate / Menu Proof'),
        const Text('Optional: For verification badge', style: TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12, runSpacing: 12, crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            ElevatedButton.icon(
              onPressed: () => _pickImage(forCert: true),
              icon: const Icon(Icons.verified_rounded, size: 18),
              label: const Text('Upload Certificate'),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1B4332).withOpacity(0.1), foregroundColor: const Color(0xFF1B4332), padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            ),
            const Text('OR paste a direct URL:', style: TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.w500)),
          ],
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _halalCertUrlController, 
          decoration: _inputDecoration('Paste certificate URL (e.g. https://...)').copyWith(
            prefixIcon: const Icon(Icons.link_rounded, color: Color(0xFF1B4332)),
          )
        ),
        if (_halalCertBytes != null || (_halalCertUrl != null && _halalCertUrl!.isNotEmpty))
          Padding(
            padding: const EdgeInsets.only(top: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Certificate Preview:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: _halalCertBytes != null 
                    ? Image.memory(_halalCertBytes!, height: 120, width: 120, fit: BoxFit.cover)
                    : Image.network(
                        _halalCertUrl!, height: 120, width: 120, fit: BoxFit.cover,
                        errorBuilder: (c,e,s) => const Icon(Icons.broken_image, color: Colors.red),
                      ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(hintText: hint, filled: true, fillColor: const Color(0xFFF8F9FA), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none), contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16));
  }

  Widget _buildPreview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Preview', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1B4332))),
        const SizedBox(height: 16),
        Container(
          height: 200, width: double.infinity, decoration: BoxDecoration(color: const Color(0xFF1B4332).withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: _pickedImageBytes != null 
              ? Image.memory(_pickedImageBytes!, fit: BoxFit.cover)
              : (_selectedImageUrl != null && _selectedImageUrl!.isNotEmpty)
                ? Image.network(_selectedImageUrl!, fit: BoxFit.cover, errorBuilder: (context, error, stackTrace) => const Center(child: Icon(Icons.storefront_rounded, color: Color(0xFF1B4332), size: 50)))
                : const Center(child: Icon(Icons.storefront_rounded, color: Color(0xFF1B4332), size: 50)),
          ),
        ),
        const SizedBox(height: 16),
        Text(_restaurantNameController.text.isEmpty ? 'Restaurant Name' : _restaurantNameController.text, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(_locationController.text.isEmpty ? 'Location' : _locationController.text, style: const TextStyle(color: Colors.grey)),
      ],
    );
  }

  Widget _buildActionButtons() {
    return SizedBox(width: double.infinity, height: 55, child: ElevatedButton(
      onPressed: _isSaving ? null : _saveRestaurant,
      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1B4332), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), elevation: 0),
      child: _isSaving ? const CircularProgressIndicator(color: Colors.white) : Text(widget.isNewRestaurant ? 'Register Restaurant' : 'Update Details', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
    ));
  }

  Future<void> _saveRestaurant() async {
    if (_restaurantNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter restaurant name')));
      return;
    }
    if (_selectedImageUrl == null && _pickedImageBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select or upload an image')));
      return;
    }
    if (_selectedDays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select at least one operating day')));
      return;
    }

    setState(() => _isSaving = true);
    try {
      if (currentUserId == null) throw 'Login required';
      
      final restaurantName = _restaurantNameController.text.trim();
      
      // Upload images
      String? imageUrl = _selectedImageUrl;
      if (_pickedImageBytes != null) {
        imageUrl = await _uploadToStorage(_pickedImageBytes!, 'restaurant');
      }

      String? certUrl = _halalCertUrl;
      if (_halalCertBytes != null) {
        certUrl = await _uploadToStorage(_halalCertBytes!, 'cert');
      }

      // Format operating days string
      final List<String> sortedDays = [];
      for (var day in _daysOfWeek) { if (_selectedDays.contains(day)) sortedDays.add(day); }

      String opDaysStr;
      if (sortedDays.length == 7) opDaysStr = 'Daily';
      else if (sortedDays.length == 5 && sortedDays[0] == 'Mon' && sortedDays[4] == 'Fri') opDaysStr = 'Monday - Friday';
      else if (sortedDays.length == 6 && sortedDays[0] == 'Mon' && sortedDays[5] == 'Sat') opDaysStr = 'Monday - Saturday';
      else {
        final Map<String, String> fullNames = {'Mon': 'Monday', 'Tue': 'Tuesday', 'Wed': 'Wednesday', 'Thu': 'Thursday', 'Fri': 'Friday', 'Sat': 'Saturday', 'Sun': 'Sunday'};
        opDaysStr = sortedDays.map((d) => fullNames[d]).join(', ');
      }

      final data = {
        'ownerId': currentUserId, 'name': restaurantName, 'category': _selectedCategory,
        'operatingDays': opDaysStr, 'openingHours': '${_formatTimeOfDay(_openTime)} - ${_formatTimeOfDay(_closeTime)}',
        'location': _locationController.text.trim().isEmpty ? 'Setapak, KL' : _locationController.text.trim(),
        'phone': _phoneController.text.trim().isEmpty ? '03-4142 1234' : _phoneController.text.trim(), 
        'description': _descriptionController.text.trim(), 'status': 'Active',
        'imageUrl': imageUrl, 'halalCertUrl': certUrl, // NEW
        'updatedAt': FieldValue.serverTimestamp(), 'isHeader': true,
      };

      if (widget.restaurantId != null) {
        await FirebaseFirestore.instance.collection('restaurants').doc(widget.restaurantId).update(data);
        final relatedDocs = await FirebaseFirestore.instance.collection('restaurants').where('ownerId', isEqualTo: currentUserId).where('name', isEqualTo: widget.existingRestaurantName ?? restaurantName).get();
        for (var doc in relatedDocs.docs) {
          if (doc.id != widget.restaurantId) {
             await doc.reference.update({'name': restaurantName, 'location': data['location'], 'phone': data['phone'], 'category': data['category'], 'openingHours': data['openingHours'], 'operatingDays': data['operatingDays'], 'halalCertUrl': certUrl});
          }
        }
      } else {
        data['rating'] = '5.0'; data['distance'] = '0.5 km'; data['createdAt'] = FieldValue.serverTimestamp(); data['foodName'] = ''; data['price'] = '';
        await FirebaseFirestore.instance.collection('restaurants').add(data);
        await FirebaseFirestore.instance.collection('users').doc(currentUserId!).update({'role': 'Owner'});
      }
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) { setState(() => _isSaving = false); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'))); }
    }
  }

  Widget _buildFieldLabel(String label) => Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1B4332))));
}
