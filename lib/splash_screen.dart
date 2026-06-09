import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
import 'login_screen.dart';
import 'tailor_icon.dart';

// --- Design System Constants ---
const Color kPrimaryColor = Color(0xFF1E3A5F); // Deep Navy
const Color kAccentColor = Color(0xFF10B981); // Emerald Green
const Color kTextWhite = Color(0xFFFFFFFF); // White Text

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  
  late Animation<double> _logoDrawAnimation;
  late Animation<double> _logoFadeAnimation;
  late Animation<double> _titleFadeAnimation;
  late Animation<double> _taglineFadeAnimation;
  late Animation<Offset> _contentSlideAnimation;

  @override
  void initState() {
    super.initState();

    // Hide status bar and navigation bar for full screen effect
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000), // Slightly longer for drawing effect
    );

    // 1. Logo fades in quickly (0.0 - 0.2) and draws progressively (0.0 - 0.5)
    _logoFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.2, curve: Curves.easeIn),
      ),
    );

    _logoDrawAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeInOut),
      ),
    );

    // 2. Entire content slightly slides up while fading in (0.3 - 0.7)
    _contentSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.3, 0.7, curve: Curves.easeOutCubic),
    ));

    // 3. Title fades in (0.4 - 0.7)
    _titleFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.4, 0.7, curve: Curves.easeIn),
      ),
    );

    // 4. Tagline fades in (0.6 - 0.9)
    _taglineFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.6, 0.9, curve: Curves.easeIn),
      ),
    );

    _animationController.forward();

    // Navigate to LoginScreen after 3.5 seconds
    Future.delayed(const Duration(milliseconds: 3500), () {
      if (mounted) {
        // Restore system UI overlays before navigating
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
        
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            transitionDuration: const Duration(milliseconds: 800),
            pageBuilder: (context, animation, secondaryAnimation) => const LoginScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(
                opacity: animation,
                child: child,
              );
            },
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kPrimaryColor, // Deep Navy background
      body: Center(
        child: SlideTransition(
          position: _contentSlideAnimation,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 1. App logo/icon (Progressive Line Art Draw)
              FadeTransition(
                opacity: _logoFadeAnimation,
                child: AnimatedBuilder(
                  animation: _logoDrawAnimation,
                  builder: (context, child) {
                    return CustomPaint(
                      size: const Size(120, 120),
                      painter: TailorLineArtPainter(
                        primaryColor: kTextWhite,
                        accentColor: kAccentColor,
                        progress: _logoDrawAnimation.value,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 40),
              
              // 2. App Name
              FadeTransition(
                opacity: _titleFadeAnimation,
                child: Text(
                  'Irfan Tailors',
                  style: GoogleFonts.inter(
                    color: kTextWhite,
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              
              // 3. Tagline
              FadeTransition(
                opacity: _taglineFadeAnimation,
                child: Text(
                  'Smart Tailoring Management',
                  style: GoogleFonts.inter(
                    color: kAccentColor, // Emerald Green
                    fontSize: 16,
                    fontWeight: FontWeight.w300,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
