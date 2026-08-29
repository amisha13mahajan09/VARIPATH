import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'services/app_language.dart';
import 'widgets/language_selection_dialog.dart';

class ProfileScreen extends StatelessWidget {
  final Map<String, dynamic>? userData;
  final String userType;

  const ProfileScreen({
    super.key,
    required this.userData,
    required this.userType,
  });

  // ================================================================
  // COLORS
  // ================================================================

  static const Color orange = Color(0xFFD8620F);
  static const Color blue = Color(0xFF2D4678);
  static const Color background = Color(0xFFFFFBF7);

  // ================================================================
  // LOGOUT
  // ================================================================

  void _logout(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: background,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          title: const Text(
            'Logout',
            style: TextStyle(
              fontFamily: 'Lexend',
              fontWeight: FontWeight.w700,
              color: blue,
            ),
          ),
          content: const Text(
            'Are you sure you want to log out of VariPath?',
            style: TextStyle(
              fontFamily: 'Lexend',
              fontSize: 14,
              color: blue,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Cancel',
                style: TextStyle(
                  fontFamily: 'Lexend',
                  color: blue,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog

                // Completely clear navigation stack and return to LoginScreen
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const LoginScreen(),
                  ),
                  (route) => false,
                );

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text(
                      'Logged out successfully.',
                      style: TextStyle(fontFamily: 'Lexend'),
                    ),
                    behavior: SnackBarBehavior.floating,
                    backgroundColor: blue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: orange,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Logout',
                style: TextStyle(
                  fontFamily: 'Lexend',
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // ================================================================
  // BUILD
  // ================================================================

  @override
  Widget build(BuildContext context) {
    final username = userData?['username'] ?? (userType == 'VT' ? 'VT101' : 'VK100001');
    final firstName = userData?['first_name'] ?? '';
    final lastName = userData?['last_name'] ?? '';
    final fullName = (firstName.isEmpty && lastName.isEmpty)
        ? (userType == 'VT' ? 'Wari Volunteer' : 'Wari Varkari')
        : '$firstName $lastName'.trim();
    final roleTitle = userType == 'VT' ? 'Volunteer (स्वयंसेवक)' : 'Varkari (वारकरी)';
    final phone = userData?['phone'] ?? 'Not provided';
    final emergencyContact = userData?['emergency_contact'] ?? 'Not provided';
    final bloodGroup = userData?['blood_group'] ?? 'Not provided';
    final age = userData?['age']?.toString() ?? 'N/A';
    final gender = userData?['gender'] ?? 'N/A';
    final healthConditions = userData?['health_conditions'];

    List<String> healthList = [];
    if (healthConditions is List) {
      healthList = healthConditions.map((e) => e.toString()).toList();
    } else if (healthConditions is String && healthConditions.isNotEmpty) {
      healthList = [healthConditions];
    }

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: blue,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: RichText(
          text: const TextSpan(
            children: [
              TextSpan(
                text: 'वारी',
                style: TextStyle(
                  fontFamily: 'YatraOne',
                  color: orange,
                  fontSize: 24,
                ),
              ),
              TextSpan(
                text: ' पथ',
                style: TextStyle(
                  fontFamily: 'Kalam',
                  color: blue,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // ======================================================
              // PROFILE AVATAR & HEADER CARD
              // ======================================================
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: blue.withOpacity(0.08),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: blue.withOpacity(0.05),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Avatar
                    Container(
                      width: 84,
                      height: 84,
                      decoration: BoxDecoration(
                        color: orange.withOpacity(0.12),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: orange,
                          width: 2.5,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          fullName.isNotEmpty ? fullName[0].toUpperCase() : 'V',
                          style: const TextStyle(
                            fontFamily: 'Lexend',
                            fontSize: 34,
                            fontWeight: FontWeight.w700,
                            color: orange,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Full Name
                    Text(
                      fullName,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: 'Lexend',
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: blue,
                      ),
                    ),
                    const SizedBox(height: 6),

                    // User ID Badge (Dynamic from logged in state)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: blue.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.badge_outlined,
                            size: 16,
                            color: blue,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            username,
                            style: const TextStyle(
                              fontFamily: 'Lexend',
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: blue,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Role Tag
                    Text(
                      roleTitle,
                      style: TextStyle(
                        fontFamily: 'Lexend',
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: orange.withOpacity(0.95),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 22),

              // ======================================================
              // ACCOUNT & PERSONAL DETAILS
              // ======================================================
              _buildSectionTitle('Personal Details', Icons.person_outline_rounded),
              const SizedBox(height: 12),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: blue.withOpacity(0.08)),
                  boxShadow: [
                    BoxShadow(
                      color: blue.withOpacity(0.04),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _buildInfoRow(
                      icon: Icons.phone_outlined,
                      label: 'Phone Number',
                      value: phone,
                    ),
                    _buildDivider(),
                    _buildInfoRow(
                      icon: Icons.phone_forwarded_outlined,
                      label: 'Emergency Contact',
                      value: emergencyContact,
                    ),
                    _buildDivider(),
                    _buildInfoRow(
                      icon: Icons.cake_outlined,
                      label: 'Age & Gender',
                      value: '$age yrs • $gender',
                    ),
                    _buildDivider(),
                    _buildInfoRow(
                      icon: Icons.bloodtype_outlined,
                      label: 'Blood Group',
                      value: bloodGroup,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 22),

              // ======================================================
              // HEALTH CONDITIONS
              // ======================================================
              _buildSectionTitle('Health Conditions', Icons.medical_services_outlined),
              const SizedBox(height: 12),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: blue.withOpacity(0.08)),
                  boxShadow: [
                    BoxShadow(
                      color: blue.withOpacity(0.04),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: healthList.isEmpty || healthList.contains('None')
                    ? Row(
                        children: [
                          const Icon(
                            Icons.check_circle_outline_rounded,
                            color: Colors.green,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'No special health conditions reported',
                            style: TextStyle(
                              fontFamily: 'Lexend',
                              fontSize: 13,
                              color: blue.withOpacity(0.70),
                            ),
                          ),
                        ],
                      )
                    : Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: healthList.map((cond) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: orange.withOpacity(0.10),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: orange.withOpacity(0.30),
                              ),
                            ),
                            child: Text(
                              cond,
                              style: const TextStyle(
                                fontFamily: 'Lexend',
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: orange,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
              ),

              const SizedBox(height: 22),

              // ======================================================
              // APP LANGUAGE SETTINGS
              // ======================================================
              _buildSectionTitle(appLanguageNotifier.t('app_language_setting'), Icons.language_rounded),
              const SizedBox(height: 12),

              GestureDetector(
                onTap: () => LanguageSelectionDialog.show(context),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: blue.withOpacity(0.08)),
                    boxShadow: [
                      BoxShadow(
                        color: blue.withOpacity(0.04),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: orange.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.translate_rounded, color: orange, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              appLanguageNotifier.t('app_language_setting'),
                              style: TextStyle(
                                fontFamily: 'Lexend',
                                fontSize: 11.5,
                                color: blue.withOpacity(0.55),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              appLanguageNotifier.currentLanguage == 'en'
                                  ? 'English 🇬🇧'
                                  : (appLanguageNotifier.currentLanguage == 'mr'
                                      ? 'मराठी 🚩'
                                      : 'हिंदी 🇮🇳'),
                              style: const TextStyle(
                                fontFamily: 'Lexend',
                                fontSize: 14.5,
                                fontWeight: FontWeight.w700,
                                color: blue,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios_rounded, color: blue, size: 16),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // ======================================================
              // LOGOUT BUTTON
              // ======================================================
              SizedBox(
                width: double.infinity,
                height: 56,
                child: OutlinedButton.icon(
                  onPressed: () => _logout(context),
                  icon: const Icon(
                    Icons.logout_rounded,
                    color: Colors.redAccent,
                    size: 22,
                  ),
                  label: const Text(
                    'Logout',
                    style: TextStyle(
                      fontFamily: 'Lexend',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.redAccent,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Colors.white,
                    side: const BorderSide(
                      color: Colors.redAccent,
                      width: 1.5,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // ================================================================
  // HELPER WIDGETS
  // ================================================================

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: orange, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontFamily: 'Lexend',
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: blue,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: blue.withOpacity(0.06),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: blue, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Lexend',
                  fontSize: 11.5,
                  color: blue.withOpacity(0.55),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontFamily: 'Lexend',
                  fontSize: 14.5,
                  fontWeight: FontWeight.w600,
                  color: blue,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Divider(
        color: blue.withOpacity(0.08),
        height: 1,
      ),
    );
  }
}
