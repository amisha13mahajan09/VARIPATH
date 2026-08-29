import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

import 'home_screen.dart';
import 'register_screen.dart';
import 'missing_screen.dart';
import 'map_screen.dart';
import 'widgets/language_selection_dialog.dart';
import 'services/app_language.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // ================================================================
  // COLORS
  // ================================================================

  static const Color orange = Color(0xFFD8620F);
  static const Color blue = Color(0xFF2D4678);
  static const Color background = Color(0xFFFFFBF7);

  // ================================================================
  // BACKEND URL (Android emulator maps localhost to 10.0.2.2)
  // ================================================================

  static const String backendUrl = 'http://10.0.2.2:5001';

  // ================================================================
  // CONTROLLERS
  // ================================================================

  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // ================================================================
  // VARIABLES
  // ================================================================

  String _selectedType = 'VT';
  bool _obscurePassword = true;
  bool _isLoading = false;

  // VT = 3 digits (e.g. VT101)
  // VK = 6 digits (e.g. VK100001)
  int get _maxDigits => _selectedType == 'VT' ? 3 : 6;

  // ================================================================
  // DISPOSE
  // ================================================================

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ================================================================
  // CHANGE USER TYPE
  // ================================================================

  void _changeUserType(String? value) {
    if (value == null) return;

    setState(() {
      _selectedType = value;
      _usernameController.clear();
    });
  }

  // ================================================================
  // LOGIN (Real PostgreSQL authentication via Flask Backend)
  // ================================================================

  Future<void> _login() async {
    final digits = _usernameController.text.trim();
    final password = _passwordController.text.trim();

    // ------------------------------------------------------------
    // EMPTY USERNAME
    // ------------------------------------------------------------

    if (digits.isEmpty) {
      _showError('Please enter your User ID.');
      return;
    }

    // ------------------------------------------------------------
    // USERNAME LENGTH
    // ------------------------------------------------------------

    if (digits.length != _maxDigits) {
      _showError(
        _selectedType == 'VT'
            ? 'Volunteer ID must contain 3 digits (e.g., VT101).'
            : 'Varkari ID must contain 6 digits (e.g., VK100001).',
      );
      return;
    }

    // ------------------------------------------------------------
    // EMPTY PASSWORD
    // ------------------------------------------------------------

    if (password.isEmpty) {
      _showError('Please enter your password.');
      return;
    }

    final fullUsername = '$_selectedType$digits';

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse('$backendUrl/login'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'username': fullUsername,
          'password': password,
          'user_type': _selectedType,
        }),
      );

      final data = jsonDecode(response.body);

      if (!mounted) return;

      if (response.statusCode == 200 && data['success'] == true) {
        final userData = data['user'] as Map<String, dynamic>?;

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => MainNavigation(
              userType: _selectedType,
              userData: userData,
            ),
          ),
        );
      } else {
        _showError(data['message'] ?? 'Incorrect username or password.');
      }
    } catch (e) {
      if (!mounted) return;
      _showError('Could not connect to the backend server ($backendUrl).');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // ================================================================
  // ERROR MESSAGE
  // ================================================================

  void _showError(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: const TextStyle(
              fontFamily: 'Lexend',
            ),
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: blue,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
  }

  // ================================================================
  // REGISTER
  // ================================================================

  void _openRegisterScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const RegisterScreen(),
      ),
    );
  }

  // ================================================================
  // BUILD
  // ================================================================

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: Stack(
          children: [
            // ======================================================
            // TOP ORANGE DECORATION
            // ======================================================

            Positioned(
              top: -100,
              right: -80,
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  color: orange.withOpacity(0.09),
                  shape: BoxShape.circle,
                ),
              ),
            ),

            // ======================================================
            // TOP BLUE DECORATION
            // ======================================================

            Positioned(
              top: -60,
              left: -100,
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  color: blue.withOpacity(0.055),
                  shape: BoxShape.circle,
                ),
              ),
            ),

            // ======================================================
            // BOTTOM BLUE DECORATION
            // ======================================================

            Positioned(
              bottom: -120,
              left: -90,
              child: Container(
                width: 270,
                height: 270,
                decoration: BoxDecoration(
                  color: blue.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
              ),
            ),

            // ======================================================
            // BOTTOM ORANGE DECORATION
            // ======================================================

            Positioned(
              bottom: -100,
              right: -80,
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  color: orange.withOpacity(0.07),
                  shape: BoxShape.circle,
                ),
              ),
            ),

            // ======================================================
            // MAIN CONTENT
            // ======================================================

            SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: size.width * 0.075,
                  vertical: 30,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // ==================================================
                    // WELCOME TO
                    // ==================================================

                    Text(
                      'Welcome To',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Lexend',
                        fontSize: size.width * 0.065,
                        fontWeight: FontWeight.w500,
                        color: blue,
                        letterSpacing: 0.2,
                      ),
                    ),

                    const SizedBox(height: 2),

                    // ==================================================
                    // VARIPATH LOGO
                    // ==================================================

                    RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: 'वारी',
                            style: TextStyle(
                              fontFamily: 'YatraOne',
                              fontSize: size.width * 0.145,
                              fontWeight: FontWeight.w400,
                              color: orange,
                            ),
                          ),
                          TextSpan(
                            text: 'पथ',
                            style: TextStyle(
                              fontFamily: 'Kalam',
                              fontSize: size.width * 0.145,
                              fontWeight: FontWeight.w700,
                              color: blue,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 38),

                    // ==================================================
                    // LOGIN TITLE
                    // ==================================================

                    Text(
                      'Login',
                      style: TextStyle(
                        fontFamily: 'Lexend',
                        fontSize: size.width * 0.105,
                        fontWeight: FontWeight.w700,
                        color: blue,
                        letterSpacing: -1,
                      ),
                    ),

                    const SizedBox(height: 35),

                    // ==================================================
                    // USERNAME LABEL
                    // ==================================================

                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Username',
                        style: TextStyle(
                          fontFamily: 'Lexend',
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: blue,
                        ),
                      ),
                    ),

                    const SizedBox(height: 9),

                    // ==================================================
                    // USERNAME BOX
                    // ==================================================

                    Container(
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: blue.withOpacity(0.75),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: blue.withOpacity(0.06),
                            blurRadius: 12,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          // ============================================
                          // VT / VK DROPDOWN
                          // ============================================

                          Container(
                            width: 90,
                            height: double.infinity,
                            decoration: BoxDecoration(
                              color: blue.withOpacity(0.055),
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(15),
                                bottomLeft: Radius.circular(15),
                              ),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _selectedType,
                                isExpanded: true,
                                icon: const Icon(
                                  Icons.keyboard_arrow_down_rounded,
                                  color: blue,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                ),
                                dropdownColor: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                items: const [
                                  DropdownMenuItem(
                                    value: 'VT',
                                    child: Text(
                                      'VT',
                                      style: TextStyle(
                                        fontFamily: 'Lexend',
                                        fontSize: 17,
                                        fontWeight: FontWeight.w600,
                                        color: blue,
                                      ),
                                    ),
                                  ),
                                  DropdownMenuItem(
                                    value: 'VK',
                                    child: Text(
                                      'VK',
                                      style: TextStyle(
                                        fontFamily: 'Lexend',
                                        fontSize: 17,
                                        fontWeight: FontWeight.w600,
                                        color: blue,
                                      ),
                                    ),
                                  ),
                                ],
                                onChanged: _changeUserType,
                              ),
                            ),
                          ),

                          // ============================================
                          // DIVIDER
                          // ============================================

                          Container(
                            width: 1,
                            height: 38,
                            color: blue.withOpacity(0.18),
                          ),

                          // ============================================
                          // NUMBER INPUT
                          // ============================================

                          Expanded(
                            child: TextField(
                              controller: _usernameController,
                              keyboardType: TextInputType.number,
                              maxLength: _maxDigits,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(
                                  _maxDigits,
                                ),
                              ],
                              style: const TextStyle(
                                fontFamily: 'Lexend',
                                fontSize: 17,
                                fontWeight: FontWeight.w500,
                                color: blue,
                                letterSpacing: 2,
                              ),
                              decoration: InputDecoration(
                                counterText: '',
                                border: InputBorder.none,
                                hintText: _selectedType == 'VT'
                                    ? 'Enter 3 digits'
                                    : 'Enter 6 digits',
                                hintStyle: TextStyle(
                                  fontFamily: 'Lexend',
                                  fontSize: 15,
                                  color: Colors.grey.shade400,
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 15,
                                  vertical: 18,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 9),

                    // ==================================================
                    // USERNAME HELP
                    // ==================================================

                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        _selectedType == 'VT'
                            ? 'Volunteer ID: VT + 3 digits'
                            : 'Varkari ID: VK + 6 digits',
                        style: TextStyle(
                          fontFamily: 'Lexend',
                          fontSize: 11,
                          color: blue.withOpacity(0.55),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ==================================================
                    // PASSWORD LABEL
                    // ==================================================

                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Password',
                        style: TextStyle(
                          fontFamily: 'Lexend',
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: blue,
                        ),
                      ),
                    ),

                    const SizedBox(height: 9),

                    // ==================================================
                    // PASSWORD BOX
                    // ==================================================

                    Container(
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: blue.withOpacity(0.75),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: blue.withOpacity(0.06),
                            blurRadius: 12,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        style: const TextStyle(
                          fontFamily: 'Lexend',
                          fontSize: 16,
                          color: blue,
                        ),
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: 'Enter your password',
                          hintStyle: TextStyle(
                            fontFamily: 'Lexend',
                            fontSize: 15,
                            color: Colors.grey.shade400,
                          ),
                          prefixIcon: const Icon(
                            Icons.lock_outline_rounded,
                            color: blue,
                            size: 22,
                          ),
                          suffixIcon: IconButton(
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              color: blue,
                              size: 22,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 18,
                          ),
                        ),
                      ),
                    ),

                    // ==================================================
                    // LOGIN BUTTON SPACE
                    // ==================================================

                    SizedBox(
                      height: size.height * 0.045,
                    ),

                    // ==================================================
                    // LOGIN BUTTON
                    // ==================================================

                    SizedBox(
                      width: double.infinity,
                      height: 60,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _login,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: orange,
                          foregroundColor: Colors.white,
                          elevation: 6,
                          shadowColor: orange.withOpacity(0.30),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(17),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.white,
                                ),
                              )
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Login',
                                    style: TextStyle(
                                      fontFamily: 'Lexend',
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  SizedBox(width: 12),
                                  Icon(
                                    Icons.arrow_forward_rounded,
                                    size: 23,
                                  ),
                                ],
                              ),
                      ),
                    ),

                    // ==================================================
                    // REGISTER
                    // ==================================================

                    const SizedBox(height: 28),

                    RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        children: [
                          const TextSpan(
                            text: "Don't have an account yet? ",
                            style: TextStyle(
                              fontFamily: 'Lexend',
                              fontSize: 13.5,
                              fontWeight: FontWeight.w400,
                              color: blue,
                            ),
                          ),
                          WidgetSpan(
                            alignment: PlaceholderAlignment.middle,
                            child: GestureDetector(
                              onTap: _openRegisterScreen,
                              child: const Text(
                                'Register here',
                                style: TextStyle(
                                  fontFamily: 'Lexend',
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                  color: orange,
                                  decoration: TextDecoration.underline,
                                  decorationColor: orange,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 25),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ====================================================================
// MAIN NAVIGATION
// ====================================================================

class MainNavigation extends StatefulWidget {
  final String userType;
  final Map<String, dynamic>? userData;

  const MainNavigation({
    super.key,
    required this.userType,
    this.userData,
  });

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 1;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      LanguageSelectionDialog.show(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      MissingScreen(
        userType: widget.userType,
        userData: widget.userData,
      ),
      HomeScreen(
        userType: widget.userType,
        userData: widget.userData,
      ),
      const MapScreen(),
    ];

    return Scaffold(
      body: screens[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        backgroundColor: Colors.white,
        indicatorColor: const Color(0xFF2D4678).withOpacity(0.12),
        destinations: const [
          // ==========================================================
          // MISSING PERSON / HELP
          // ==========================================================
          NavigationDestination(
            icon: Icon(
              Icons.question_mark,
            ),
            selectedIcon: Icon(
              Icons.question_mark,
              color: Color(0xFF2D4678),
            ),
            label: '',
          ),

          // ==========================================================
          // HOME
          // ==========================================================
          NavigationDestination(
            icon: Icon(
              Icons.home_outlined,
            ),
            selectedIcon: Icon(
              Icons.home,
              color: Color(0xFF2D4678),
            ),
            label: '',
          ),

          // ==========================================================
          // MAP
          // ==========================================================
          NavigationDestination(
            icon: Icon(
              Icons.map_outlined,
            ),
            selectedIcon: Icon(
              Icons.map,
              color: Color(0xFF2D4678),
            ),
            label: '',
          ),
        ],
      ),
    );
  }
}