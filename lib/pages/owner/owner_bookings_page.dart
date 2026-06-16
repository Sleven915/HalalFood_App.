import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_animate/flutter_animate.dart';

class OwnerBookingsPage extends StatelessWidget {
  final String? manualUid;
  const OwnerBookingsPage({super.key, this.manualUid});

  @override
  Widget build(BuildContext context) {
    final authUser = FirebaseAuth.instance.currentUser;
    final currentUserId = manualUid ?? authUser?.uid;
    final primaryColor = const Color(0xFF1B4332);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text('Live Bookings', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1B4332))),
        actions: [
          IconButton(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => BookingHistoryPage(ownerId: currentUserId))),
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(color: primaryColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
              child: Icon(Icons.history_rounded, color: primaryColor, size: 20),
            ),
            tooltip: 'View History',
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('bookings')
            .where('ownerId', isEqualTo: currentUserId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          
          // TALLY LOGIC: Live Bookings ONLY show 'Confirmed'
          final bookings = snapshot.data?.docs.where((doc) {
            final status = (doc.data() as Map)['status'] ?? 'Confirmed';
            return status == 'Confirmed';
          }).toList() ?? [];
          
          if (bookings.isEmpty) return _buildEmptyState();

          bookings.sort((a, b) {
            final aTime = (a.data() as Map)['timestamp'] as Timestamp?;
            final bTime = (b.data() as Map)['timestamp'] as Timestamp?;
            if (aTime == null) return 1;
            if (bTime == null) return -1;
            return bTime.compareTo(aTime);
          });

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: bookings.length,
            itemBuilder: (context, index) {
              final data = bookings[index].data() as Map<String, dynamic>;
              final docId = bookings[index].id;
              return _buildBookingCard(context, docId, data, primaryColor);
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.event_note_rounded, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text('No new bookings today.', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildBookingCard(BuildContext context, String docId, Map<String, dynamic> data, Color primaryColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: primaryColor.withOpacity(0.1), shape: BoxShape.circle),
                  child: Icon(Icons.person_pin_rounded, color: primaryColor, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(data['userName'] ?? 'Customer', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text(data['restaurantName'] ?? 'Restaurant', style: TextStyle(color: primaryColor, fontSize: 13, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
                _buildStatusBadge('CONFIRMED', Colors.blue),
              ],
            ),
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildInfoCol(Icons.calendar_today_rounded, 'Date', data['date'] ?? '-'),
                _buildInfoCol(Icons.access_time_rounded, 'Time', data['time'] ?? '-'),
                Row(
                  children: [
                    IconButton(onPressed: () => _markAsCompleted(context, docId), icon: const Icon(Icons.check_box_outlined, color: Colors.green), tooltip: 'Mark as Present'),
                    IconButton(onPressed: () => _showCancelDialog(context, docId), icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent), tooltip: 'Cancel Booking'),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    ).animate().fadeIn();
  }

  Widget _buildInfoCol(IconData icon, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [Icon(icon, size: 14, color: Colors.grey), const SizedBox(width: 4), Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold))]),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildStatusBadge(String status, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
      child: Text(status, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  Future<void> _markAsCompleted(BuildContext context, String docId) async {
    try {
      await FirebaseFirestore.instance.collection('bookings').doc(docId).update({'status': 'Completed'});
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Customer marked as present!'), backgroundColor: Colors.green));
    } catch (e) { debugPrint(e.toString()); }
  }

  void _showCancelDialog(BuildContext context, String docId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Cancel Booking'),
        content: const Text('Move this booking to history?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('No')),
          TextButton(
            onPressed: () async {
              await FirebaseFirestore.instance.collection('bookings').doc(docId).update({'status': 'Cancelled'});
              Navigator.pop(context);
            }, 
            child: const Text('Yes, Cancel', style: TextStyle(color: Colors.redAccent))
          ),
        ],
      ),
    );
  }
}

class BookingHistoryPage extends StatelessWidget {
  final String? ownerId;
  const BookingHistoryPage({super.key, this.ownerId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white, elevation: 0, centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text('Booking History', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18)),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('bookings').where('ownerId', isEqualTo: ownerId).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          
          // TALLY LOGIC: History ONLY shows 'Completed' and 'Cancelled'
          final history = snapshot.data?.docs.where((doc) {
            final status = (doc.data() as Map)['status']?.toString().toLowerCase() ?? '';
            return status == 'completed' || status == 'cancelled';
          }).toList() ?? [];

          if (history.isEmpty) return const Center(child: Text('No history found.'));

          history.sort((a, b) {
            final aTime = (a.data() as Map)['timestamp'] as Timestamp?;
            final bTime = (b.data() as Map)['timestamp'] as Timestamp?;
            if (aTime == null) return 1;
            if (bTime == null) return -1;
            return bTime.compareTo(aTime);
          });

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: history.length,
            itemBuilder: (context, index) {
              final data = history[index].data() as Map<String, dynamic>;
              bool isCancelled = (data['status'] ?? '').toString().toLowerCase() == 'cancelled';

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade100)),
                child: Row(
                  children: [
                    Icon(isCancelled ? Icons.cancel_rounded : Icons.check_circle_rounded, color: isCancelled ? Colors.redAccent : Colors.green, size: 24),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(data['userName'] ?? 'Customer', style: const TextStyle(fontWeight: FontWeight.bold)),
                          Text('${data['restaurantName']} | ${data['date']}', style: const TextStyle(color: Colors.grey, fontSize: 11)),
                        ],
                      ),
                    ),
                    Text(isCancelled ? 'CANCELLED' : 'COMPLETED', style: TextStyle(color: isCancelled ? Colors.redAccent : Colors.green, fontSize: 10, fontWeight: FontWeight.bold)),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
