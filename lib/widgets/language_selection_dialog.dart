import 'package:flutter/material.dart';
import '../services/app_language.dart';

class LanguageSelectionDialog extends StatefulWidget {
  final bool isModal;

  const LanguageSelectionDialog({super.key, this.isModal = true});

  static Future<void> show(BuildContext context) async {
    await showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const LanguageSelectionDialog(),
    );
  }

  @override
  State<LanguageSelectionDialog> createState() => _LanguageSelectionDialogState();
}

class _LanguageSelectionDialogState extends State<LanguageSelectionDialog> {
  static const Color orange = Color(0xFFD8620F);
  static const Color blue = Color(0xFF2D4678);

  late String _selectedCode;

  @override
  void initState() {
    super.initState();
    _selectedCode = appLanguageNotifier.currentLanguage;
  }

  @override
  Widget build(BuildContext context) {
    final lang = appLanguageNotifier;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: blue.withValues(alpha: 0.18),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: orange.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.language_rounded, color: orange, size: 30),
          ),
          const SizedBox(height: 16),
          Text(
            lang.t('select_language_title'),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Lexend',
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: blue,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            lang.t('select_language_sub'),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Lexend',
              fontSize: 13,
              color: blue.withValues(alpha: 0.65),
            ),
          ),
          const SizedBox(height: 22),

          // Option 1: English
          _buildLanguageOption(
            code: 'en',
            title: 'English',
            subtitle: 'English Interface',
            flag: '🇬🇧',
          ),
          const SizedBox(height: 12),

          // Option 2: Marathi
          _buildLanguageOption(
            code: 'mr',
            title: 'मराठी',
            subtitle: 'मराठी इंटरफेस',
            flag: '🚩',
          ),
          const SizedBox(height: 12),

          // Option 3: Hindi
          _buildLanguageOption(
            code: 'hi',
            title: 'हिंदी',
            subtitle: 'हिंदी इंटरफेस',
            flag: '🇮🇳',
          ),
          const SizedBox(height: 26),

          // Continue Button
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: () {
                appLanguageNotifier.setLanguage(_selectedCode);
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: orange,
                foregroundColor: Colors.white,
                elevation: 4,
                shadowColor: orange.withValues(alpha: 0.35),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                lang.t('confirm_language'),
                style: const TextStyle(
                  fontFamily: 'Lexend',
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageOption({
    required String code,
    required String title,
    required String subtitle,
    required String flag,
  }) {
    final isSelected = _selectedCode == code;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedCode = code;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? blue.withValues(alpha: 0.06) : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected ? blue : Colors.grey.shade200,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Text(
              flag,
              style: const TextStyle(fontSize: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontFamily: 'Lexend',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: isSelected ? blue : Colors.black87,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontFamily: 'Lexend',
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              isSelected ? Icons.check_circle_rounded : Icons.radio_button_off_rounded,
              color: isSelected ? blue : Colors.grey.shade400,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}
