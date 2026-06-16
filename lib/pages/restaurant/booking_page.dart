import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';

class BookingPage extends StatefulWidget {
  final String restaurantName;
  final String location;
  final String openingHours;
  final String operatingDays;
  final String? ownerId;
  final String? manualUid; 

  const BookingPage({
    super.key,
    required this.restaurantName,
    required this.location,
    required this.openingHours,
    required this.operatingDays,
    this.ownerId,
    this.manualUid,
  });

  @override
  State<BookingPage> createState() => _BookingPageState();
}

class _BookingPageState extends State<BookingPage> {
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _sessionController = TextEditingController();
  
  bool _isBooking = false;
  final primaryColor = const Color(0xFF1B4332);

  @override
  void dispose() {
    _dateController.dispose();
    _sessionController.dispose();
    super.dispose();
  }

  // Helper: Susun hari untuk paparan rujukan supaya tally dan kemas
  String _sortAndFormatDays(String daysStr) {
    if (daysStr == 'Daily' || daysStr.contains(' - ')) return daysStr;
    final List<String> order = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    final List<String> shortOrder = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    List<String> currentDays = daysStr.split(',').map((e) => e.trim()).toList();
    List<String> sortedFull = [];
    for (int i = 0; i < order.length; i++) {
      bool found = false;
      for (var d in currentDays) {
        if (d.toLowerCase() == order[i].toLowerCase() || d.toLowerCase() == shortOrder[i].toLowerCase()) {
          found = true; break;
        }
      }
      if (found) sortedFull.add(order[i]);
    }
    if (sortedFull.isEmpty) return daysStr;
    if (sortedFull.length == 7) return 'Daily';
    return sortedFull.join(', ');
  }

  // Feature: Buka kalendar bantuan tanpa menyekat sebarang tarikh (Manual approach)
  Future<void> _pickFromCalendar() async {
    final DateTime now = DateTime.now();
    // Normalisasi tarikh kepada tengah malam untuk elak ralat teknikal
    final DateTime today = DateTime(now.year, now.month, now.day);

    try {
      final DateTime? picked = await showDatePicker(
        context: context,
        initialDate: today,
        firstDate: today,
        lastDate: today.add(const Duration(days: 365)), // Boleh pilih sampai setahun
        builder: (context, child) => Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: primaryColor, 
              onPrimary: Colors.white, 
              onSurface: Colors.black
            )
          ),
          child: child!,
        ),
      );
      if (picked != null) {
        setState(() { 
          _dateController.text = DateFormat('dd MMM yyyy').format(picked); 
        });
      }
    } catch (e) {
      debugPrint("Calendar Error: $e");
    }
  }

  Future<void> _handleBooking() async {
    final authUser = FirebaseAuth.instance.currentUser;
    final currentUserId = widget.manualUid ?? authUser?.uid;
    if (currentUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error: User not identified.')));
      return;
    }
    
    final dateInput = _dateController.text.trim();
    final sessionInput = _sessionController.text.trim();
    if (dateInput.isEmpty || sessionInput.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill in both Date and Session')));
      return;
    }

    setState(() => _isBooking = true);
    try {
      final bookingId = '${widget.restaurantName.replaceAll(' ', '_')}_${dateInput.replaceAll(' ', '_')}_${sessionInput.replaceAll(' ', '_')}';
      final docRef = FirebaseFirestore.instance.collection('bookings').doc(bookingId);
      final doc = await docRef.get();
      if (doc.exists) throw 'This slot is already booked. Try another date/time.';
      
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(currentUserId).get();
      await docRef.set({
        'restaurantName': widget.restaurantName, 
        'location': widget.location,
        'userId': currentUserId, 
        'ownerId': widget.ownerId,
        'userName': userDoc.data()?['fullName'] ?? 'Customer',
        'date': dateInput, 
        'time': sessionInput, 
        'timestamp': FieldValue.serverTimestamp(), 
        'status': 'Confirmed',
      });
      if (!mounted) return;
      _showSuccessDialog(dateInput, sessionInput);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.redAccent));
    } finally {
      if (mounted) setState(() => _isBooking = false);
    }
  }

  void _showSuccessDialog(String date, String session) {
    showDialog(context: context, builder: (context) => AlertDialog(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)), content: Column(mainAxisSize: MainAxisSize.min, children: [const SizedBox(height: 16), Icon(Icons.check_circle_rounded, size: 60, color: primaryColor), const SizedBox(height: 24), const Text('Booking Successful!', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)), const SizedBox(height: 12), Text('Your booking for "$session" on "$date" is confirmed.', textAlign: TextAlign.center), const SizedBox(height: 32), SizedBox(width: double.infinity, child: ElevatedButton(onPressed: () { Navigator.pop(context); Navigator.pop(context); }, style: ElevatedButton.styleFrom(backgroundColor: primaryColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: const Text('Back to Home', style: TextStyle(color: Colors.white))))])));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text('Book a Table', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)), backgroundColor: Colors.white, elevation: 0, iconTheme: const IconThemeData(color: Colors.black)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildRestaurantHeader(),
            const SizedBox(height: 40),
            
            // 1. DATE SECTION
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                const Text('Booking Date', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                TextButton.icon(
                  onPressed: _pickFromCalendar,
                  icon: const Icon(Icons.calendar_month_rounded, size: 18),
                  label: const Text('Check Calendar', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  style: TextButton.styleFrom(foregroundColor: primaryColor),
                ),
            ]),
            _buildManualInput(controller: _dateController, hint: 'Type date (e.g. 25 Dec)...', icon: Icons.edit_calendar_rounded),
            
            const SizedBox(height: 32),
            
            // 2. SESSION SECTION
            const Text('Session / Time', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _buildManualInput(controller: _sessionController, hint: 'Type session (e.g. Lunch)...', icon: Icons.access_time_rounded),
            const SizedBox(height: 16),
            
            // Helpful View (Reference only)
            Container(
              width: double.infinity, padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(16)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Restaurant Operations Ref:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.blue)),
                  const SizedBox(height: 8),
                  Row(children: [const Icon(Icons.calendar_today_rounded, size: 14, color: Colors.blue), const SizedBox(width: 8), Expanded(child: Text(_sortAndFormatDays(widget.operatingDays), style: const TextStyle(fontSize: 13, color: Colors.blue)))]),
                  const SizedBox(height: 4),
                  Row(children: [const Icon(Icons.access_time_rounded, size: 14, color: Colors.blue), const SizedBox(width: 8), Text(widget.openingHours, style: const TextStyle(fontSize: 13, color: Colors.blue))]),
                  const SizedBox(height: 12),
                  const Divider(color: Colors.blue, thickness: 0.2),
                  const SizedBox(height: 8),
                  const Row(children: [Icon(Icons.warning_amber_rounded, size: 16, color: Colors.orange), SizedBox(width: 8), Expanded(child: Text('Note: Bookings will be automatically cancelled if you are more than 30 minutes late.', style: TextStyle(fontSize: 12, color: Colors.blue, fontWeight: FontWeight.bold, fontStyle: FontStyle.italic)))]),
                ],
              ),
            ),
            const SizedBox(height: 48),
            _buildConfirmButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildRestaurantHeader() {
    return Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: primaryColor.withOpacity(0.05), borderRadius: BorderRadius.circular(20)), child: Row(children: [Icon(Icons.restaurant_rounded, color: primaryColor, size: 24), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(widget.restaurantName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)), Text(widget.location, style: TextStyle(color: Colors.grey.shade600, fontSize: 11))]))])).animate().fadeIn();
  }

  Widget _buildManualInput({required TextEditingController controller, required String hint, required IconData icon}) {
    return TextField(controller: controller, decoration: InputDecoration(hintText: hint, hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14), prefixIcon: Icon(icon, color: primaryColor.withOpacity(0.5)), filled: true, fillColor: const Color(0xFFF8F9FA), border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none), contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16)));
  }

  Widget _buildConfirmButton() {
    return SizedBox(width: double.infinity, height: 58, child: ElevatedButton(onPressed: _isBooking ? null : _handleBooking, style: ElevatedButton.styleFrom(backgroundColor: primaryColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), elevation: 0), child: _isBooking ? const CircularProgressIndicator(color: Colors.white) : const Text('Confirm Booking', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold))));
  }
}
