import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'login_page.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  final List<Map<String, String>> _slides = [
    {
      'title': 'Welcome to HalalEats',
      'desc': 'Discover the best Halal-certified restaurants around you with ease and confidence.',
      'image': 'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?w=800',
    },
    {
      'title': 'Authentic & Verified',
      'desc': 'We ensure all listings are verified, so you can enjoy your meal without any worries.',
      'image': 'https://images.unsplash.com/photo-1504674900247-0877df9cc836?w=800',
    },
    {
      'title': 'Save Your Favourites',
      'desc': 'Keep track of the places you love and access them anytime, anywhere.',
      'image': 'https://images.unsplash.com/photo-1493770348161-369560ae357d?w=800',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final primaryColor = const Color(0xFF1B4332);
    final secondaryColor = const Color(0xFF2D6A4F);

    return Scaffold(
      body: Stack(
        children: [
          // Global Background Gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFE8F1ED), Color(0xFFF9FAFB)],
              ),
            ),
          ),
          
          // Subtle Decorative Background Icons
          Positioned(
            top: 40,
            right: -30,
            child: Icon(Icons.eco_rounded, size: 200, color: primaryColor.withOpacity(0.04)),
          ),
          Positioned(
            bottom: 100,
            left: -40,
            child: Icon(Icons.restaurant_rounded, size: 250, color: primaryColor.withOpacity(0.04)),
          ),

          PageView.builder(
            controller: _pageController,
            onPageChanged: (index) => setState(() => _currentIndex = index),
            itemCount: _slides.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Neater Image Frame
                    Container(
                      height: MediaQuery.of(context).size.height * 0.4,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(40),
                        boxShadow: [
                          BoxShadow(
                            color: primaryColor.withOpacity(0.1),
                            blurRadius: 30,
                            offset: const Offset(0, 15),
                          )
                        ],
                        image: DecorationImage(
                          image: NetworkImage(_slides[index]['image']!),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ).animate().scale(duration: 600.ms, curve: Curves.easeOutBack).fadeIn(),
                    
                    const SizedBox(height: 60),
                    
                    // Text Content
                    Text(
                      _slides[index]['title']!,
                      style: TextStyle(
                        fontSize: 28, 
                        fontWeight: FontWeight.w900, 
                        color: primaryColor,
                        letterSpacing: -0.5
                      ),
                      textAlign: TextAlign.center,
                    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2),
                    
                    const SizedBox(height: 20),
                    
                    Text(
                      _slides[index]['desc']!,
                      style: TextStyle(
                        fontSize: 16, 
                        color: Colors.grey.shade600, 
                        height: 1.6,
                        fontWeight: FontWeight.w400
                      ),
                      textAlign: TextAlign.center,
                    ).animate().fadeIn(delay: 400.ms),
                  ],
                ),
              );
            },
          ),
          
          // Navigation UI (Bottom Bar)
          Positioned(
            bottom: 50,
            left: 40,
            right: 40,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Modern Dots
                Row(
                  children: List.generate(_slides.length, (index) {
                    bool isActive = _currentIndex == index;
                    return AnimatedContainer(
                      duration: 300.ms,
                      margin: const EdgeInsets.only(right: 8),
                      height: 8,
                      width: isActive ? 30 : 8,
                      decoration: BoxDecoration(
                        color: isActive ? secondaryColor : Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    );
                  }),
                ),
                
                // Circular Progress-like Button
                GestureDetector(
                  onTap: () {
                    if (_currentIndex == _slides.length - 1) {
                      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginPage()));
                    } else {
                      _pageController.nextPage(duration: 400.ms, curve: Curves.easeInOut);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: primaryColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: primaryColor.withOpacity(0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        )
                      ],
                    ),
                    child: Icon(
                      _currentIndex == _slides.length - 1 
                        ? Icons.check_rounded 
                        : Icons.arrow_forward_ios_rounded, 
                      color: Colors.white, 
                      size: 24
                    ),
                  ),
                ).animate().scale(duration: 400.ms, curve: Curves.elasticOut),
              ],
            ),
          ),
          
          // Elegant Skip Button
          if (_currentIndex != _slides.length - 1)
            Positioned(
              top: 60,
              right: 20,
              child: TextButton(
                onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginPage())),
                child: Text(
                  'Skip', 
                  style: TextStyle(
                    color: primaryColor.withOpacity(0.6), 
                    fontWeight: FontWeight.bold,
                    fontSize: 15
                  )
                ),
              ),
            ),
        ],
      ),
    );
  }
}
