import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Import for MaxLengthEnforcement
import 'package:provider/provider.dart';
import '../models/user_model.dart';
import '../providers/user_provider.dart';
import '../widgets/glass_card.dart';
import 'main_navigation.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({Key? key}) : super(key: key);

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _mobileController = TextEditingController();
  final _usernameController = TextEditingController();

  static const Color _primaryColor = Color(0xFF5bd43d);
  static const Color _darkOverlay = Colors.black;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Assuming these assets exist in the project
    precacheImage(const AssetImage('assets/img/bg/bg1.jpg'), context);
    precacheImage(const AssetImage('assets/img/logo/logo2.png'), context);
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // Background - Static, no animation
          Positioned.fill(
            child: RepaintBoundary(
              child: Image.asset(
                'assets/img/bg/bg1.jpg',
                fit: BoxFit.cover,
                // These hints help Flutter optimize asset decoding
                cacheWidth: 1080,
                cacheHeight: 1920,
                errorBuilder: (context, error, stackTrace) {
                  return Container(color: _darkOverlay);
                },
              ),
            ),
          ),

          // Content - Scrollable to prevent overflow
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                // Outer Padding: Fixed 20.0 padding from screen edges
                padding: const EdgeInsets.symmetric(
                  horizontal: 20.0,
                  vertical: 40,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Logo
                      RepaintBoundary(
                        child: Image.asset(
                          'assets/img/logo/logo2.png',
                          width: 90,
                          height: 90,
                          cacheWidth: 200,
                          cacheHeight: 200,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(
                              Icons.account_balance_wallet,
                              size: 70,
                              color: _primaryColor,
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Title with premium styling
                      ShaderMask(
                        shaderCallback: (bounds) => LinearGradient(
                          colors: [
                            Colors.white,
                            _primaryColor.withOpacity(0.9),
                          ],
                        ).createShader(bounds),
                        child: const Text(
                          'SpendX',
                          style: TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 2.0,
                            height: 1.2,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Subtitle
                      const Text(
                        'Track your expenses effortlessly',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white70,
                          fontWeight: FontWeight.w300,
                          letterSpacing: 0.5,
                        ),
                      ),
                      SizedBox(height: screenHeight * 0.04),

                      // Premium Glass Card Form
                      RepaintBoundary(
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                // Changed to transparent to remove the green shadow/filling
                                color: Colors.transparent, 
                                blurRadius: 0,
                                spreadRadius: 0,
                                offset: const Offset(0, 0),
                              ),
                            ],
                          ),
                          child: GlassCard(
                            borderRadius: BorderRadius.circular(24),
                            // Inner Padding: Uniform 20.0 padding inside the card
                            child: Padding(
                              padding: const EdgeInsets.all(20.0),
                              child: Column(
                                children: [
                                  _buildTextField(
                                    controller: _nameController,
                                    label: 'Full Name',
                                    icon: Icons.person_outline_rounded,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please enter your name';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 20),
                                  _buildTextField(
                                    controller: _mobileController,
                                    label: 'Mobile Number',
                                    icon: Icons.phone_android_rounded,
                                    keyboardType: TextInputType.phone,
                                    maxLength: 10,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please enter your mobile number';
                                      }
                                      // The max length is also enforced by maxLength property, but validator confirms the length before moving on
                                      if (value.length != 10) {
                                        return 'Mobile number must be 10 digits';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 20),
                                  _buildTextField(
                                    controller: _usernameController,
                                    label: 'Username',
                                    icon: Icons.alternate_email_rounded,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please enter a username';
                                      }
                                      return null;
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Premium Continue Button
                      Container(
                        width: double.infinity,
                        height: 56,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          gradient: LinearGradient(
                            colors: [
                              _primaryColor,
                              _primaryColor.withOpacity(0.85),
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: _primaryColor.withOpacity(0.4),
                              blurRadius: 20,
                              spreadRadius: 0,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: _continue,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Text(
                            'Continue',
                            style: TextStyle(
                              color: _darkOverlay,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Updated to accept an optional maxLength parameter
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    int? maxLength, // <--- New optional parameter for length limit
  }) {
    const Color inputTextColor = Colors.white;
    const Color inputHintColor = Colors.white60;
    const Color inputBorderColor = Colors.white12;
    const Color focusedBorderColor = _primaryColor;

    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLength: maxLength, // <--- Applied the max length
      // Enforce the maximum length and hide the counter text
      maxLengthEnforcement:
          maxLength != null ? MaxLengthEnforcement.enforced : null,
      style: const TextStyle(
        color: inputTextColor,
        fontSize: 16,
        fontWeight: FontWeight.w400,
      ),
      validator: validator,
      cursorColor: focusedBorderColor,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
          color: inputHintColor,
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
        prefixIcon: Container(
          margin: const EdgeInsets.only(right: 12),
          child: Icon(
            icon,
            color: focusedBorderColor,
            size: 22,
          ),
        ),
        // Hide the counter text when a maxLength is applied
        counterText: maxLength != null ? "" : null, // <--- Hides the length counter
        filled: true,
        fillColor: Colors.white.withOpacity(0.05),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: inputBorderColor,
            width: 1.5,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: focusedBorderColor,
            width: 2.0,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: Colors.redAccent,
            width: 1.5,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: Colors.redAccent,
            width: 2.0,
          ),
        ),
        errorStyle: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w400,
        ),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 18,
          horizontal: 16,
        ),
      ),
    );
  }

  void _continue() async {
    if (_formKey.currentState!.validate()) {
      final user = User(
        name: _nameController.text,
        mobile: _mobileController.text,
        username: _usernameController.text,
      );

      // Save user data (assuming UserProvider and User model are correctly defined)
      await context.read<UserProvider>().saveUser(user);

      if (mounted) {
        // Navigate to MainNavigation with a smooth fade transition
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                const MainNavigation(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(
                opacity: animation,
                child: child,
              );
            },
            transitionDuration: const Duration(milliseconds: 400),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _mobileController.dispose();
    _usernameController.dispose();
    super.dispose();
  }
}