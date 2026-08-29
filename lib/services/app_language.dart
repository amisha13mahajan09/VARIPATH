import 'package:flutter/material.dart';

/// App-wide language manager providing English ('en'), Marathi ('mr'), and Hindi ('hi')
class AppLanguage extends ChangeNotifier {
  static final AppLanguage instance = AppLanguage._internal();
  factory AppLanguage() => instance;
  AppLanguage._internal();

  String _currentLanguage = 'mr'; // Default Marathi
  bool _hasSelectedLanguage = false;

  String get currentLanguage => _currentLanguage;
  bool get hasSelectedLanguage => _hasSelectedLanguage;

  void setLanguage(String code) {
    if (_currentLanguage != code || !_hasSelectedLanguage) {
      _currentLanguage = code;
      _hasSelectedLanguage = true;
      notifyListeners();
    }
  }

  String t(String key) {
    final Map<String, String>? dict = _translations[key];
    if (dict == null) return key;
    return dict[_currentLanguage] ?? dict['en'] ?? key;
  }

  static const Map<String, Map<String, String>> _translations = {
    // --- LANGUAGE NAMES ---
    'lang_name_en': {
      'en': 'English',
      'mr': 'इंग्रजी (English)',
      'hi': 'अंग्रेज़ी (English)',
    },
    'lang_name_mr': {
      'en': 'Marathi (मराठी)',
      'mr': 'मराठी',
      'hi': 'मराठी',
    },
    'lang_name_hi': {
      'en': 'Hindi (हिंदी)',
      'mr': 'हिंदी',
      'hi': 'हिंदी',
    },
    'select_language_title': {
      'en': 'Choose App Language',
      'mr': 'ॲपची भाषा निवडा',
      'hi': 'ऐप की भाषा चुनें',
    },
    'select_language_sub': {
      'en': 'Select your preferred language for the entire app experience.',
      'mr': 'पूर्ण ॲप वापरण्यासाठी तुमची आवडती भाषा निवडा.',
      'hi': 'पूरे ऐप के लिए अपनी पसंदीदा भाषा चुनें।',
    },
    'confirm_language': {
      'en': 'Continue with Selected Language',
      'mr': 'निवडलेल्या भाषेत पुढे जा',
      'hi': 'चुनी हुई भाषा में आगे बढ़ें',
    },

    // --- NAVIGATION BAR ---
    'nav_home': {
      'en': 'Home',
      'mr': 'मुख्य',
      'hi': 'मुख्य',
    },
    'nav_missing': {
      'en': 'Missing Persons',
      'mr': 'हरवलेले व्यक्ती',
      'hi': 'लापता व्यक्ति',
    },
    'nav_map': {
      'en': 'Route Map',
      'mr': 'मार्ग नकाशा',
      'hi': 'मार्ग मानचित्र',
    },

    // --- HOME SCREEN ---
    'varkari_welcome': {
      'en': 'Jai Hari Vitthal',
      'mr': 'जय हरी विठ्ठल',
      'hi': 'जय हरि विट्ठल',
    },
    'volunteer_welcome': {
      'en': 'Namaskar',
      'mr': 'नमस्कार',
      'hi': 'नमस्कार',
    },
    'varkari_sub': {
      'en': 'Stay safe and enjoy your holy Vaari journey.',
      'mr': 'सुरक्षित राहा आणि तुमची पवित्र वारी यात्रा सुखकर होवो.',
      'hi': 'सुरक्षित रहें और अपनी पवित्र वारी यात्रा का आनंद लें।',
    },
    'volunteer_sub': {
      'en': 'Thank you for helping and guiding the Varkaris.',
      'mr': 'वारकऱ्यांना मदत आणि मार्गदर्शन केल्याबद्दल धन्यवाद.',
      'hi': 'वारकरियों की सहायता और मार्गदर्शन करने के लिए धन्यवाद।',
    },
    'sos_button': {
      'en': 'SOS',
      'mr': 'SOS',
      'hi': 'SOS',
    },
    'need_help': {
      'en': 'Need Help?',
      'mr': 'मदत हवी आहे?',
      'hi': 'मदद चाहिए?',
    },
    'alert_sent': {
      'en': 'ALERT SENT',
      'mr': 'अलर्ट पाठवला',
      'hi': 'अलर्ट भेजा गया',
    },
    'tap_for_help': {
      'en': 'Tap for emergency assistance',
      'mr': 'आणीबाणी मदतीसाठी टॅप करा',
      'hi': 'आपातकालीन सहायता के लिए टैप करें',
    },
    'todays_vaari': {
      'en': 'Today\'s Vaari Route',
      'mr': 'आजची वारी',
      'hi': 'आज की वारी',
    },
    'live_gps_loc': {
      'en': 'Current Location (Live GPS)',
      'mr': 'सध्याचे स्थान (थेट जीपीएस)',
      'hi': 'वर्तमान स्थिति (लाइव जीपीएस)',
    },
    'next_checkpoint': {
      'en': 'Next Checkpoint (Route Target)',
      'mr': 'पुढील चेकपॉइंट (मार्ग लक्ष्य)',
      'hi': 'अगला चेकपॉइंट (मार्ग लक्ष्य)',
    },
    'active_alerts': {
      'en': 'Active Alerts',
      'mr': 'सक्रिय अलर्ट',
      'hi': 'सक्रिय अलर्ट',
    },
    'nearby_requests': {
      'en': 'Nearby Assistance Requests',
      'mr': 'जवळपासच्या मदत विनंत्या',
      'hi': 'निकटतम सहायता अनुरोध',
    },
    'view_assigned_sos': {
      'en': 'View SOS requests assigned to you',
      'mr': 'तुम्हाला नेमलेल्या एसओएस विनंत्या पहा',
      'hi': 'आपको सौंपे गए एसओएस अनुरोध देखें',
    },
    'volunteer_status_title': {
      'en': 'Volunteer Status & Location',
      'mr': 'स्वयंसेवक स्थिती आणि स्थान',
      'hi': 'स्वयंसेवक स्थिति और स्थान',
    },
    'active_on_duty': {
      'en': 'You are currently active on duty',
      'mr': 'तुम्ही सध्या कर्तव्यावर सक्रिय आहात',
      'hi': 'आप वर्तमान में ड्यूटी पर सक्रिय हैं',
    },
    'online': {
      'en': 'ONLINE',
      'mr': 'ऑनलाइन (सक्रिय)',
      'hi': 'ऑनलाइन (सक्रिय)',
    },
    'track_volunteer_btn': {
      'en': 'TRACK VOLUNTEER & SOS MAP',
      'mr': 'स्वयंसेवक ट्रॅक करा आणि एसओएस नकाशा',
      'hi': 'स्वयंसेवक ट्रैक करें और एसओएस मानचित्र',
    },
    'volunteer_reached_btn': {
      'en': 'VOLUNTEER REACHED',
      'mr': 'स्वयंसेवक पोहोचला',
      'hi': 'स्वयंसेवक पहुंच गया',
    },
    'searching_volunteer': {
      'en': 'Looking for the nearest volunteer...',
      'mr': 'जवळच्या स्वयंसेवकाचा शोध घेत आहे...',
      'hi': 'निकटतम स्वयंसेवक की खोज की जा रही है...',
    },
    'volunteer_assigned': {
      'en': 'Volunteer Assigned! ✅',
      'mr': 'स्वयंसेवक नियुक्त झाला! ✅',
      'hi': 'स्वयंसेवक नियुक्त हो गया! ✅',
    },
    'search_user_hint': {
      'en': 'Search Anyone by Name or ID',
      'mr': 'नाव किंवा आयडीने कोणालाही शोधा',
      'hi': 'नाम या आईडी द्वारा किसी को भी खोजें',
    },

    // --- MAP SCREEN ---
    'live_tracking': {
      'en': 'LIVE TRACKING',
      'mr': 'थेट ट्रॅकिंग चालू',
      'hi': 'लाइव ट्रैकिंग जारी',
    },
    'tracking_paused': {
      'en': 'TRACKING PAUSED',
      'mr': 'ट्रॅकिंग थांबवले',
      'hi': 'ट्रैकिंग रुकी हुई',
    },
    'pandharpur_dist': {
      'en': 'Pandharpur Distance',
      'mr': 'पंढरपूर अंतर',
      'hi': 'पंढरपुर दूरी',
    },
    'filter_all': {
      'en': 'All Spot Markers',
      'mr': 'सर्व स्थान चिन्हे',
      'hi': 'सभी स्थान चिन्ह',
    },
    'filter_volunteers': {
      'en': 'Volunteers',
      'mr': 'स्वयंसेवक',
      'hi': 'स्वयंसेवक',
    },
    'filter_medical': {
      'en': 'Medical Live Stocks',
      'mr': 'वैद्यकीय थेट साठा',
      'hi': 'चिकित्सा लाइव स्टॉक',
    },
    'filter_weather': {
      'en': 'Weather Suggestions',
      'mr': 'हवामान सल्ला',
      'hi': 'मौसम सलाह',
    },
    'my_spot': {
      'en': 'My Spot',
      'mr': 'माझे स्थान',
      'hi': 'मेरा स्थान',
    },
    'weather_advisory_btn': {
      'en': 'Weather Advisory',
      'mr': 'हवामान माहिती',
      'hi': 'मौसम सलाह',
    },

    // --- MISSING PERSON SCREEN ---
    'missing_title': {
      'en': 'Missing Persons Portal',
      'mr': 'हरवलेल्या व्यक्तींचा कक्ष',
      'hi': 'लापता व्यक्ति पोर्टल',
    },
    'tab_reported': {
      'en': 'Reported Missing',
      'mr': 'हरवलेल्यांच्या नोंदी',
      'hi': 'लापता दर्ज',
    },
    'tab_sightings': {
      'en': 'Sightings Reported',
      'mr': 'पाहिल्याच्या नोंदी',
      'hi': 'देखने की रिपोर्ट',
    },
    'report_missing_btn': {
      'en': '+ Report Missing Person',
      'mr': '+ हरवलेल्या व्यक्तीची नोंद करा',
      'hi': '+ नए लापता व्यक्ति की रिपोर्ट करें',
    },

    // --- ACTIVE REQUESTS SCREEN ---
    'active_sos_title': {
      'en': 'Active Emergency SOS Requests',
      'mr': 'सक्रिय आणीबाणी एसओएस विनंत्या',
      'hi': 'सक्रिय आपातकालीन एसओएस अनुरोध',
    },
    'accept_request': {
      'en': 'ACCEPT EMERGENCY REQUEST',
      'mr': 'आणीबाणी विनंती स्वीकारा',
      'hi': 'आपातकालीन अनुरोध स्वीकारें',
    },

    // --- PROFILE SCREEN ---
    'profile_title': {
      'en': 'Profile & Settings',
      'mr': 'प्रोफाइल आणि सेटिंग्ज',
      'hi': 'प्रोफ़ाइल और सेटिंग्स',
    },
    'app_language_setting': {
      'en': 'App Language',
      'mr': 'ॲप भाषा',
      'hi': 'ऐप भाषा',
    },
    'logout': {
      'en': 'Logout',
      'mr': 'लॉग आउट करा',
      'hi': 'लॉग आउट करें',
    },
  };
}

final appLanguageNotifier = AppLanguage.instance;
