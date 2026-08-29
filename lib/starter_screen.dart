import 'dart:async';
import 'package:flutter/material.dart';
import 'login_screen.dart';

class StarterScreen extends StatefulWidget {
  const StarterScreen({super.key});

  @override
  State<StarterScreen> createState() => _StarterScreenState();
}

class _StarterScreenState extends State<StarterScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late Animation<double> _logoAnimation;

  late AnimationController _subtitleController;
  late Animation<double> _subtitleAnimation;

  final String firstWord = 'वारी';
  final String secondWord = 'पथ';

  late List<String> _firstLetters;
  late List<String> _secondLetters;

  final List<bool> _firstVisible = [];
  final List<bool> _secondVisible = [];

  @override
  void initState() {
    super.initState();

    // --------------------------------------------------
    // MARATHI LETTERS
    // --------------------------------------------------

    _firstLetters = firstWord.characters.toList();
    _secondLetters = secondWord.characters.toList();

    _firstVisible.addAll(
      List.generate(
        _firstLetters.length,
            (_) => false,
      ),
    );

    _secondVisible.addAll(
      List.generate(
        _secondLetters.length,
            (_) => false,
      ),
    );

    // --------------------------------------------------
    // LOGO ANIMATION
    // --------------------------------------------------

    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    _logoAnimation = CurvedAnimation(
      parent: _logoController,
      curve: Curves.easeOutCubic,
    );

    // --------------------------------------------------
    // SUBTITLE ANIMATION
    // --------------------------------------------------

    _subtitleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _subtitleAnimation = CurvedAnimation(
      parent: _subtitleController,
      curve: Curves.easeOut,
    );

    // Start complete animation sequence
    _startAnimationSequence();
  }

  // ==================================================
  // COMPLETE ANIMATION SEQUENCE
  // ==================================================

  Future<void> _startAnimationSequence() async {
    // --------------------------------------------------
    // STEP 1 — LOGO
    // --------------------------------------------------

    await _logoController.forward();

    if (!mounted) return;

    await Future.delayed(
      const Duration(milliseconds: 250),
    );

    if (!mounted) return;

    // --------------------------------------------------
    // STEP 2 — वारी
    // --------------------------------------------------

    for (int i = 0; i < _firstLetters.length; i++) {
      if (!mounted) return;

      setState(() {
        _firstVisible[i] = true;
      });

      await Future.delayed(
        const Duration(milliseconds: 500),
      );
    }

    // --------------------------------------------------
    // STEP 3 — -पथ
    // --------------------------------------------------

    for (int i = 0; i < _secondLetters.length; i++) {
      if (!mounted) return;

      setState(() {
        _secondVisible[i] = true;
      });

      await Future.delayed(
        const Duration(milliseconds: 500),
      );
    }

    // --------------------------------------------------
    // STEP 4 — SUBTITLE
    // --------------------------------------------------

    if (!mounted) return;

    await Future.delayed(
      const Duration(milliseconds: 150),
    );

    if (!mounted) return;

    await _subtitleController.forward();

    // --------------------------------------------------
    // STEP 5 — WAIT BEFORE LOGIN
    // --------------------------------------------------

    await Future.delayed(
      const Duration(milliseconds: 1800),
    );

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
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

  // ==================================================
  // ANIMATED LETTERS
  // ==================================================

  Widget _buildAnimatedLetters(
      List<String> letters,
      List<bool> visibility,
      String fontFamily,
      Color color,
      double fontSize,
      ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        letters.length,
            (index) {
          return AnimatedOpacity(
            opacity: visibility[index] ? 1.0 : 0.0,

            duration: const Duration(
              milliseconds: 700,
            ),

            curve: Curves.easeOutCubic,

            child: AnimatedSlide(
              offset: visibility[index]
                  ? Offset.zero
                  : const Offset(0, 0.10),

              duration: const Duration(
                milliseconds: 700,
              ),

              curve: Curves.easeOutCubic,

              child: Text(
                letters[index],
                style: TextStyle(
                  fontFamily: fontFamily,
                  fontSize: fontSize,
                  fontWeight: FontWeight.w400,
                  color: color,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ==================================================
  // SUBTITLE
  // ==================================================

  Widget _buildSubtitle() {
    const blue = Color(0xFF2D4678);
    const orange = Color(0xFFD8620F);

    return FadeTransition(
      opacity: _subtitleAnimation,

      child: RichText(
        textAlign: TextAlign.center,

        text: const TextSpan(
          style: TextStyle(
            fontFamily: 'Lexend',
            fontSize: 14,
            color: blue,
            height: 1.35,
          ),

          children: [

            // -- Because
            TextSpan(
              text: 'Because ',
            ),

            // Every — BOLD
            TextSpan(
              text: 'Every',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),

            // Varkari
            TextSpan(
              text: ' Varkari',
            ),

            // NEW LINE
            TextSpan(
              text: '\n',
            ),

            // Deserves — UNDERLINED
            TextSpan(
              text: 'Deserves',
              style: TextStyle(
                decoration: TextDecoration.underline,
                decorationColor: blue,
                decorationThickness: 1.5,
              ),
            ),

            // to Walk
            TextSpan(
              text: ' to Walk ',
            ),

            // Safely — ORANGE
            TextSpan(
              text: 'Safely',
              style: TextStyle(
                color: orange,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================================================
  // DISPOSE
  // ==================================================

  @override
  void dispose() {
    _logoController.dispose();
    _subtitleController.dispose();
    super.dispose();
  }

  // ==================================================
  // BUILD
  // ==================================================

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    final fontSize = screenWidth < 360
        ? 52.0
        : screenWidth < 600
        ? 62.0
        : 76.0;

    return Scaffold(
      backgroundColor: Colors.white,

      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,

            children: [

              // ==================================================
              // LOGO
              // ==================================================

              FadeTransition(
                opacity: _logoAnimation,

                child: ScaleTransition(
                  scale: Tween<double>(
                    begin: 0.94,
                    end: 1.0,
                  ).animate(
                    _logoAnimation,
                  ),

                  child: Image.asset(
                    'assets/images/logo.png',
                    width: screenWidth < 600
                        ? 105
                        : 130,
                    height: screenWidth < 600
                        ? 105
                        : 130,
                    fit: BoxFit.contain,
                  ),
                ),
              ),

              const SizedBox(height: 28),

              // ==================================================
              // APP NAME — वारी-पथ
              // ==================================================

              Row(
                mainAxisSize: MainAxisSize.min,

                children: [

                  // वारी
                  _buildAnimatedLetters(
                    _firstLetters,
                    _firstVisible,
                    'YatraOne',
                    const Color(0xFFD8620F),
                    fontSize,
                  ),

                  // -पथ
                  _buildAnimatedLetters(
                    _secondLetters,
                    _secondVisible,
                    'Kalam',
                    const Color(0xFF2D4678),
                    fontSize,
                  ),
                ],
              ),

              // Reduced space between title & subtitle
              const SizedBox(height: 5),

              // ==================================================
              // SUBTITLE
              // ==================================================

              _buildSubtitle(),
            ],
          ),
        ),
      ),
    );
  }
}