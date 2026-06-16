import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_animate/flutter_animate.dart';

class ReviewRatingPage extends StatefulWidget {
  final String restaurantName;
  final String location;
  final String? manualUid; // NEW: To support bypass login

  const ReviewRatingPage({
    super.key,
    required this.restaurantName,
    required this.location,
    this.manualUid,
  });

  @override
  State<ReviewRatingPage> createState() => _ReviewRatingPageState();
}

class _ReviewRatingPageState extends State<ReviewRatingPage> {
  int _rating = 0;
  bool _isSubmitting = false;
  final TextEditingController _reviewController = TextEditingController();
  final primaryColor = const Color(0xFF1B4332);

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  Future<void> _submitReview() async {
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please provide a star rating'),
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final authUser = FirebaseAuth.instance.currentUser;
      final currentUserId = widget.manualUid ?? authUser?.uid;

      if (currentUserId == null) throw 'Please log in';

      final userDoc = await FirebaseFirestore.instance.collection('users').doc(currentUserId).get();
      final userName = userDoc.data()?['fullName'] ?? 'Anonymous';

      await FirebaseFirestore.instance.collection('reviews').add({
        'restaurantName': widget.restaurantName.trim(),
        'userId': currentUserId,
        'userName': userName,
        'rating': _rating.toDouble(),
        'reviewText': _reviewController.text.trim(),
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Update the restaurant's average rating in the header document
      final reviewsQuery = await FirebaseFirestore.instance
          .collection('reviews')
          .where('restaurantName', isEqualTo: widget.restaurantName.trim())
          .get();
      
      double totalRating = 0;
      for (var doc in reviewsQuery.docs) {
        totalRating += (doc.data()['rating'] ?? 0).toDouble();
      }
      double averageRating = totalRating / reviewsQuery.docs.length;

      final restaurantDocs = await FirebaseFirestore.instance
          .collection('restaurants')
          .where('name', isEqualTo: widget.restaurantName.trim())
          .where('isHeader', isEqualTo: true)
          .get();

      if (restaurantDocs.docs.isNotEmpty) {
        await restaurantDocs.docs.first.reference.update({
          'rating': averageRating.toStringAsFixed(1),
        });
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Your review has been submitted!'),
        backgroundColor: Color(0xFF1B4332),
        behavior: SnackBarBehavior.floating,
      ));
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Write a Review', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white, 
        elevation: 0, 
        iconTheme: const IconThemeData(color: Colors.black)
      ),
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFE8F1ED), Color(0xFFDEEBE6), Color(0xFFD4E5DF)],
              ),
            ),
          ),
          
          SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 10))],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.restaurantName, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: primaryColor)),
                      Text(widget.location, style: TextStyle(color: Colors.grey.shade500, fontSize: 14)),
                      const SizedBox(height: 32),
                      const Text('How was your experience?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(5, (index) {
                          bool isSelected = index < _rating;
                          return GestureDetector(
                            onTap: () => setState(() => _rating = index + 1),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4.0), 
                              child: Icon(
                                isSelected ? Icons.star_rounded : Icons.star_outline_rounded, 
                                color: isSelected ? Colors.amber : Colors.grey.shade300, 
                                size: 48
                              ).animate(target: isSelected ? 1 : 0)
                               .scale(begin: const Offset(1, 1), end: const Offset(1.2, 1.2), duration: 200.ms)
                               .shimmer(delay: 400.ms, duration: 1000.ms, color: Colors.white.withOpacity(0.5)),
                            ),
                          );
                        })
                      ),
                      const SizedBox(height: 32),
                      const Text('Add a Comment', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _reviewController, 
                        maxLines: 5, 
                        decoration: InputDecoration(
                          hintText: 'Share details of your experience...', 
                          hintStyle: TextStyle(color: Colors.grey.shade400),
                          filled: true,
                          fillColor: const Color(0xFFF8F9FA),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: primaryColor.withOpacity(0.3))),
                        )
                      ),
                      const SizedBox(height: 40),
                      SizedBox(
                        width: double.infinity, 
                        height: 56, 
                        child: ElevatedButton(
                          onPressed: _isSubmitting ? null : _submitReview, 
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor, 
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: 0,
                          ), 
                          child: _isSubmitting 
                            ? const CircularProgressIndicator(color: Colors.white) 
                            : const Text('Submit Review', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold))
                        )
                      ),
                    ],
                  ),
                ).animate().fadeIn().slideY(begin: 0.1),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
