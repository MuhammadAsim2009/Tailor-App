import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'tailor_icon.dart';
import 'dashboard_screen.dart';
import 'controllers/profile_controller.dart';
// --- Design System Constants ---
const Color kPrimaryColor = Color(0xFF1E3A5F); // Deep Navy
const Color kAccentColor = Color(0xFF10B981); // Emerald Green
const Color kBackgroundColor = Color(0xFFF8FAFC); // Background
const Color kCardColor = Color(0xFFFFFFFF); // Card Color
const Color kTextPrimary = Color(0xFF0F172A); // Text Primary
const Color kTextSecondary = Color(0xFF64748B); // Text Secondary
const double kBorderRadius = 16.0;

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  
  bool _obscurePassword = true;
  final FocusNode _usernameFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    // Setup animation controller
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.2), // Start slightly below
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    // Start animation
    _animationController.forward();
    
    // Auto-focus after a short delay to ensure transition is complete
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          _usernameFocusNode.requestFocus();
        }
      });
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _usernameFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Determine the text style with Google Fonts fallback
    final TextStyle primaryTextStyle = GoogleFonts.inter(
      color: kTextPrimary,
    );
    final TextStyle secondaryTextStyle = GoogleFonts.inter(
      color: kTextSecondary,
    );

    return Scaffold(
      backgroundColor: kBackgroundColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 1. Simple tailor line-art illustration
                    Center(
                      child: CustomPaint(
                        size: const Size(120, 120),
                        painter: TailorLineArtPainter(
                          primaryColor: kPrimaryColor,
                          accentColor: kAccentColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    
                    // 2. Title
                    Text(
                      'Welcome Back',
                      style: primaryTextStyle.copyWith(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    
                    // 3. Subtitle
                    Text(
                      ProfileController().profile?.shopName == null || ProfileController().profile!.shopName.isEmpty ? 'Tailor App Management' : '${ProfileController().profile!.shopName} Management',
                      style: secondaryTextStyle.copyWith(
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 48),

                    // 4. Username / Phone input field
                    _buildInputField(
                      hintText: 'Username or Phone',
                      icon: Icons.person_outline,
                      focusNode: _usernameFocusNode,
                      textStyle: primaryTextStyle,
                    ),
                    const SizedBox(height: 16),

                    // 5. Password input field
                    _buildInputField(
                      hintText: 'Password',
                      icon: Icons.lock_outline,
                      isPassword: true,
                      textStyle: primaryTextStyle,
                    ),
                    const SizedBox(height: 32),

                    // 6. Login button
                    _buildLoginButton(textStyle: primaryTextStyle),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required String hintText,
    required IconData icon,
    bool isPassword = false,
    FocusNode? focusNode,
    required TextStyle textStyle,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: kCardColor,
        borderRadius: BorderRadius.circular(kBorderRadius),
        boxShadow: [
          BoxShadow(
            color: kTextPrimary.withValues(alpha: 0.06),
            offset: const Offset(0, 4),
            blurRadius: 12,
          ),
        ],
      ),
      child: TextField(
        focusNode: focusNode,
        obscureText: isPassword && _obscurePassword,
        style: textStyle.copyWith(fontSize: 16),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: textStyle.copyWith(color: kTextSecondary.withValues(alpha: 0.6)),
          prefixIcon: Icon(icon, color: kTextSecondary),
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    color: kTextSecondary,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(kBorderRadius),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(kBorderRadius),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(kBorderRadius),
            borderSide: const BorderSide(color: kPrimaryColor, width: 1.5),
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16), // Min 48px height
        ),
      ),
    );
  }

  Widget _buildLoginButton({required TextStyle textStyle}) {
    return Container(
      height: 56, // >= 48px requirement
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(kBorderRadius),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF22C55E), // Slightly lighter green for subtle highlight
            kAccentColor, // Emerald Green
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: kAccentColor.withValues(alpha: 0.3),
            offset: const Offset(0, 6),
            blurRadius: 16,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(kBorderRadius),
          onTap: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const DashboardScreen()),
            );
          },
          child: Center(
            child: Text(
              'Login',
              style: textStyle.copyWith(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}


