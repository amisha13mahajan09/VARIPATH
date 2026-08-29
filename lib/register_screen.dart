import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() =>
      _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {

  static const Color orange = Color(0xFFD8620F);
  static const Color blue = Color(0xFF2D4678);
  static const Color background = Color(0xFFFFFBF7);

  static const String backendUrl =
      'http://10.0.2.2:5001';

  final TextEditingController _firstNameController =
  TextEditingController();

  final TextEditingController _lastNameController =
  TextEditingController();

  final TextEditingController _dobController =
  TextEditingController();

  final TextEditingController _ageController =
  TextEditingController();

  final TextEditingController _phoneController =
  TextEditingController();

  final TextEditingController _emergencyController =
  TextEditingController();

  final TextEditingController _passwordController =
  TextEditingController();

  String? _selectedType;
  String? _selectedGender;
  String? _selectedBloodGroup;

  bool _obscurePassword = true;
  bool _isLoading = false;

  final List<String> _healthConditions = [
    'Diabetes',
    'Asthma',
    'Hypertension',
    'Heart Disease',
    'Kidney Disease',
    'Liver Disease',
    'Epilepsy',
    'Thyroid Disorder',
    'Arthritis',
    'Allergies',
    'Chronic Respiratory Disease',
    'Other',
    'None',
  ];

  final List<String> _selectedHealthConditions = [];

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _dobController.dispose();
    _ageController.dispose();
    _phoneController.dispose();
    _emergencyController.dispose();
    _passwordController.dispose();

    super.dispose();
  }

  Future<void> _selectDateOfBirth() async {

    final DateTime? pickedDate =
    await showDatePicker(
      context: context,
      initialDate: DateTime(2005),
      firstDate: DateTime(1940),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: orange,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: blue,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate == null) return;

    final today = DateTime.now();

    int age = today.year - pickedDate.year;

    if (today.month < pickedDate.month ||
        (today.month == pickedDate.month &&
            today.day < pickedDate.day)) {
      age--;
    }

    setState(() {
      _dobController.text =
      '${pickedDate.year}-'
          '${pickedDate.month.toString().padLeft(2, '0')}-'
          '${pickedDate.day.toString().padLeft(2, '0')}';

      _ageController.text = age.toString();
    });
  }

  void _toggleHealthCondition(
      String condition) {

    setState(() {

      if (condition == 'None') {

        _selectedHealthConditions.clear();
        _selectedHealthConditions.add('None');

        return;
      }

      _selectedHealthConditions.remove('None');

      if (_selectedHealthConditions
          .contains(condition)) {

        _selectedHealthConditions
            .remove(condition);

      } else {

        _selectedHealthConditions
            .add(condition);
      }
    });
  }

  bool _validateFields() {

    if (_selectedType == null) {
      _showMessage(
        'Please select account type.',
        isError: true,
      );
      return false;
    }

    if (_firstNameController.text.trim().isEmpty ||
        _lastNameController.text.trim().isEmpty ||
        _dobController.text.trim().isEmpty ||
        _ageController.text.trim().isEmpty ||
        _phoneController.text.trim().isEmpty ||
        _emergencyController.text.trim().isEmpty ||
        _passwordController.text.trim().isEmpty ||
        _selectedGender == null ||
        _selectedBloodGroup == null) {

      _showMessage(
        'Please fill in all fields.',
        isError: true,
      );

      return false;
    }

    if (_passwordController.text.length != 4) {

      _showMessage(
        'Password must contain exactly 4 characters.',
        isError: true,
      );

      return false;
    }

    if (_phoneController.text.length != 10) {

      _showMessage(
        'Phone number must contain 10 digits.',
        isError: true,
      );

      return false;
    }

    if (_emergencyController.text.length != 10) {

      _showMessage(
        'Emergency contact must contain 10 digits.',
        isError: true,
      );

      return false;
    }

    if (_selectedHealthConditions.isEmpty) {

      _showMessage(
        'Please select at least one health condition.',
        isError: true,
      );

      return false;
    }

    return true;
  }

  Future<void> _register() async {

    if (!_validateFields()) return;

    setState(() {
      _isLoading = true;
    });

    try {

      final response = await http.post(
        Uri.parse('$backendUrl/register'),

        headers: {
          'Content-Type': 'application/json',
        },

        body: jsonEncode({

          'user_type': _selectedType,

          'password':
          _passwordController.text.trim(),

          'first_name':
          _firstNameController.text.trim(),

          'last_name':
          _lastNameController.text.trim(),

          'date_of_birth':
          _dobController.text.trim(),

          'age':
          int.parse(
            _ageController.text.trim(),
          ),

          'gender':
          _selectedGender,

          'phone':
          _phoneController.text.trim(),

          'emergency_contact':
          _emergencyController.text.trim(),

          'blood_group':
          _selectedBloodGroup,

          'health_conditions':
          _selectedHealthConditions,
        }),
      );

      final data = jsonDecode(response.body);

      if (!mounted) return;

      if (response.statusCode == 201 &&
          data['success'] == true) {

        final username = data['username'];

        _showCredentialsDialog(
          username,
          data['password'],
        );

      } else {

        _showMessage(
          data['message'] ??
              'Registration failed.',
          isError: true,
        );
      }

    } catch (e) {

      if (!mounted) return;

      _showMessage(
        'Could not connect to the server.',
        isError: true,
      );

    } finally {

      if (mounted) {

        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showCredentialsDialog(
      String username,
      String password) {

    showDialog(
      context: context,
      barrierDismissible: false,

      builder: (context) {

        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),

          title: const Text(
            'Registration Successful!',
            style: TextStyle(
              fontFamily: 'Lexend',
              fontWeight: FontWeight.w700,
              color: blue,
            ),
          ),

          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment:
            CrossAxisAlignment.start,

            children: [

              const Text(
                'Your VariPath login credentials:',
                style: TextStyle(
                  fontFamily: 'Lexend',
                ),
              ),

              const SizedBox(height: 20),

              Text(
                'Username: $username',
                style: const TextStyle(
                  fontFamily: 'Lexend',
                  fontWeight: FontWeight.w700,
                  color: blue,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                'Password: $password',
                style: const TextStyle(
                  fontFamily: 'Lexend',
                  fontWeight: FontWeight.w700,
                  color: blue,
                ),
              ),

              const SizedBox(height: 15),

              const Text(
                'Please remember these credentials.',
                style: TextStyle(
                  fontFamily: 'Lexend',
                  fontSize: 12,
                ),
              ),
            ],
          ),

          actions: [

            ElevatedButton(
              onPressed: () {

                Navigator.pop(context);

                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                    const LoginScreen(),
                  ),
                );
              },

              style: ElevatedButton.styleFrom(
                backgroundColor: orange,
                foregroundColor: Colors.white,
              ),

              child: const Text(
                'Go to Login',
                style: TextStyle(
                  fontFamily: 'Lexend',
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showMessage(
      String message, {
        bool isError = false,
      }) {

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            fontFamily: 'Lexend',
          ),
        ),

        backgroundColor:
        isError
            ? Colors.red.shade700
            : orange,

        behavior:
        SnackBarBehavior.floating,

        shape: RoundedRectangleBorder(
          borderRadius:
          BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required String hint,
    required TextEditingController controller,
    TextInputType keyboardType =
        TextInputType.text,
    List<TextInputFormatter>?
    inputFormatters,
    Widget? suffixIcon,
    VoidCallback? onTap,
    bool readOnly = false,
  }) {

    return Column(
      crossAxisAlignment:
      CrossAxisAlignment.start,

      children: [

        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Lexend',
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: blue,
          ),
        ),

        const SizedBox(height: 8),

        Container(
          height: 58,

          decoration: BoxDecoration(
            color: Colors.white,

            borderRadius:
            BorderRadius.circular(15),

            border: Border.all(
              color: blue.withOpacity(0.70),
              width: 1.4,
            ),
          ),

          child: TextField(
            controller: controller,

            keyboardType:
            keyboardType,

            inputFormatters:
            inputFormatters,

            readOnly:
            readOnly,

            onTap:
            onTap,

            style: const TextStyle(
              fontFamily: 'Lexend',
              fontSize: 15,
              color: blue,
            ),

            decoration:
            InputDecoration(

              border:
              InputBorder.none,

              hintText:
              hint,

              hintStyle:
              TextStyle(
                fontFamily:
                'Lexend',
                fontSize: 14,
                color:
                Colors.grey.shade400,
              ),

              suffixIcon:
              suffixIcon,

              contentPadding:
              const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 17,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown({
    required String label,
    required String hint,
    required String? value,
    required List<String> items,
    required ValueChanged<String?>
    onChanged,
  }) {

    return Column(
      crossAxisAlignment:
      CrossAxisAlignment.start,

      children: [

        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Lexend',
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: blue,
          ),
        ),

        const SizedBox(height: 8),

        Container(
          height: 58,

          padding:
          const EdgeInsets.symmetric(
            horizontal: 15,
          ),

          decoration: BoxDecoration(
            color: Colors.white,

            borderRadius:
            BorderRadius.circular(15),

            border: Border.all(
              color: blue.withOpacity(0.70),
              width: 1.4,
            ),
          ),

          child:
          DropdownButtonHideUnderline(

            child:
            DropdownButton<String>(

              value: value,

              isExpanded: true,

              hint: Text(
                hint,
                style: TextStyle(
                  fontFamily:
                  'Lexend',
                  fontSize: 14,
                  color:
                  Colors.grey.shade400,
                ),
              ),

              icon:
              const Icon(
                Icons
                    .keyboard_arrow_down_rounded,
                color: blue,
              ),

              items:
              items.map(
                    (item) {

                  return
                    DropdownMenuItem<
                        String>(
                      value: item,

                      child: Text(
                        item,
                        style:
                        const TextStyle(
                          fontFamily:
                          'Lexend',
                          fontSize: 15,
                          color: blue,
                        ),
                      ),
                    );
                },
              ).toList(),

              onChanged:
              onChanged,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(
      BuildContext context) {

    final size =
        MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor:
      background,

      body: SafeArea(
        child: Stack(
          children: [

            Positioned(
              top: -100,
              right: -80,
              child: Container(
                width: 220,
                height: 220,
                decoration:
                BoxDecoration(
                  color:
                  orange.withOpacity(
                      0.09),
                  shape:
                  BoxShape.circle,
                ),
              ),
            ),

            Positioned(
              top: -60,
              left: -100,
              child: Container(
                width: 180,
                height: 180,
                decoration:
                BoxDecoration(
                  color:
                  blue.withOpacity(
                      0.055),
                  shape:
                  BoxShape.circle,
                ),
              ),
            ),

            SingleChildScrollView(
              physics:
              const BouncingScrollPhysics(),

              child: Padding(
                padding:
                EdgeInsets.symmetric(
                  horizontal:
                  size.width * 0.075,
                  vertical: 25,
                ),

                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.center,

                  children: [

                    Text(
                      'Welcome To',
                      style: TextStyle(
                        fontFamily:
                        'Lexend',
                        fontSize:
                        size.width *
                            0.065,
                        color: blue,
                      ),
                    ),

                    const SizedBox(
                      height: 2,
                    ),

                    RichText(
                      text:
                      TextSpan(
                        children: [

                          TextSpan(
                            text: 'वारी',
                            style:
                            TextStyle(
                              fontFamily:
                              'YatraOne',
                              fontSize:
                              size.width *
                                  0.145,
                              color:
                              orange,
                            ),
                          ),

                          TextSpan(
                            text: 'पथ',
                            style:
                            TextStyle(
                              fontFamily:
                              'Kalam',
                              fontSize:
                              size.width *
                                  0.145,
                              fontWeight:
                              FontWeight
                                  .w700,
                              color:
                              blue,
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(
                      height:
                      size.height *
                          0.035,
                    ),

                    Text(
                      'Register',
                      style: TextStyle(
                        fontFamily:
                        'Lexend',
                        fontSize:
                        size.width *
                            0.095,
                        fontWeight:
                        FontWeight.w700,
                        color: blue,
                      ),
                    ),

                    const SizedBox(
                      height: 30,
                    ),

                    _buildDropdown(
                      label:
                      'Account Type',
                      hint:
                      'Select account type',
                      value:
                      _selectedType,
                      items: const [
                        'VT',
                        'VK',
                      ],
                      onChanged:
                          (value) {
                        setState(() {
                          _selectedType =
                              value;
                        });
                      },
                    ),

                    const SizedBox(
                      height: 20,
                    ),

                    _buildTextField(
                      label:
                      'First Name',
                      hint:
                      'Enter your first name',
                      controller:
                      _firstNameController,
                    ),

                    const SizedBox(
                      height: 20,
                    ),

                    _buildTextField(
                      label:
                      'Last Name',
                      hint:
                      'Enter your last name',
                      controller:
                      _lastNameController,
                    ),

                    const SizedBox(
                      height: 20,
                    ),

                    _buildTextField(
                      label:
                      'Date of Birth',
                      hint:
                      'Select your date of birth',
                      controller:
                      _dobController,
                      readOnly:
                      true,
                      onTap:
                      _selectDateOfBirth,
                      suffixIcon:
                      const Icon(
                        Icons
                            .calendar_month_outlined,
                        color: blue,
                      ),
                    ),

                    const SizedBox(
                      height: 20,
                    ),

                    _buildTextField(
                      label:
                      'Age',
                      hint:
                      'Age',
                      controller:
                      _ageController,
                      keyboardType:
                      TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter
                            .digitsOnly,
                        LengthLimitingTextInputFormatter(
                            3),
                      ],
                    ),

                    const SizedBox(
                      height: 20,
                    ),

                    _buildDropdown(
                      label:
                      'Gender',
                      hint:
                      'Select gender',
                      value:
                      _selectedGender,
                      items: const [
                        'Male',
                        'Female',
                        'Other',
                      ],
                      onChanged:
                          (value) {
                        setState(() {
                          _selectedGender =
                              value;
                        });
                      },
                    ),

                    const SizedBox(
                      height: 20,
                    ),

                    _buildTextField(
                      label:
                      'Phone Number',
                      hint:
                      'Enter 10-digit phone number',
                      controller:
                      _phoneController,
                      keyboardType:
                      TextInputType.phone,
                      inputFormatters: [
                        FilteringTextInputFormatter
                            .digitsOnly,
                        LengthLimitingTextInputFormatter(
                            10),
                      ],
                    ),

                    const SizedBox(
                      height: 20,
                    ),

                    _buildTextField(
                      label:
                      'Emergency Contact Number',
                      hint:
                      'Enter emergency contact number',
                      controller:
                      _emergencyController,
                      keyboardType:
                      TextInputType.phone,
                      inputFormatters: [
                        FilteringTextInputFormatter
                            .digitsOnly,
                        LengthLimitingTextInputFormatter(
                            10),
                      ],
                    ),

                    const SizedBox(
                      height: 20,
                    ),

                    _buildDropdown(
                      label:
                      'Blood Group',
                      hint:
                      'Select blood group',
                      value:
                      _selectedBloodGroup,
                      items: const [
                        'A+',
                        'A-',
                        'B+',
                        'B-',
                        'AB+',
                        'AB-',
                        'O+',
                        'O-',
                      ],
                      onChanged:
                          (value) {
                        setState(() {
                          _selectedBloodGroup =
                              value;
                        });
                      },
                    ),

                    const SizedBox(
                      height: 20,
                    ),

                    // PASSWORD

                    _buildTextField(
                      label:
                      'Password',
                      hint:
                      'Create 4-character password',
                      controller:
                      _passwordController,
                      inputFormatters: [
                        LengthLimitingTextInputFormatter(
                            4),
                        FilteringTextInputFormatter
                            .allow(
                          RegExp(
                              r'[A-Za-z0-9]'),
                        ),
                      ],
                      suffixIcon:
                      IconButton(
                        onPressed: () {
                          setState(() {
                            _obscurePassword =
                            !_obscurePassword;
                          });
                        },
                        icon: Icon(
                          _obscurePassword
                              ? Icons
                              .visibility_outlined
                              : Icons
                              .visibility_off_outlined,
                          color: blue,
                        ),
                      ),
                    ),

                    const SizedBox(
                      height: 25,
                    ),

                    const Align(
                      alignment:
                      Alignment.centerLeft,
                      child: Text(
                        'Health Conditions',
                        style: TextStyle(
                          fontFamily:
                          'Lexend',
                          fontSize: 15,
                          fontWeight:
                          FontWeight.w600,
                          color: blue,
                        ),
                      ),
                    ),

                    const SizedBox(
                      height: 5,
                    ),

                    const Align(
                      alignment:
                      Alignment.centerLeft,
                      child: Text(
                        'Select all that apply',
                        style: TextStyle(
                          fontFamily:
                          'Lexend',
                          fontSize: 12,
                          color: blue,
                        ),
                      ),
                    ),

                    const SizedBox(
                      height: 12,
                    ),

                    Container(
                      width:
                      double.infinity,

                      padding:
                      const EdgeInsets.all(
                          12),

                      decoration:
                      BoxDecoration(
                        color:
                        Colors.white,
                        borderRadius:
                        BorderRadius
                            .circular(15),
                        border:
                        Border.all(
                          color: blue
                              .withOpacity(
                              0.70),
                          width: 1.4,
                        ),
                      ),

                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,

                        children:
                        _healthConditions
                            .map(
                              (condition) {

                            final selected =
                            _selectedHealthConditions
                                .contains(
                                condition);

                            return GestureDetector(
                              onTap: () =>
                                  _toggleHealthCondition(
                                      condition),

                              child:
                              AnimatedContainer(
                                duration:
                                const Duration(
                                  milliseconds:
                                  180,
                                ),

                                padding:
                                const EdgeInsets
                                    .symmetric(
                                  horizontal:
                                  13,
                                  vertical:
                                  9,
                                ),

                                decoration:
                                BoxDecoration(
                                  color:
                                  selected
                                      ? orange
                                      : blue.withOpacity(
                                      0.055),
                                  borderRadius:
                                  BorderRadius
                                      .circular(
                                      20),
                                ),

                                child:
                                Row(
                                  mainAxisSize:
                                  MainAxisSize
                                      .min,
                                  children: [

                                    if (selected)
                                      const Icon(
                                        Icons
                                            .check_rounded,
                                        size:
                                        15,
                                        color:
                                        Colors.white,
                                      ),

                                    if (selected)
                                      const SizedBox(
                                        width:
                                        5,
                                      ),

                                    Text(
                                      condition,
                                      style:
                                      TextStyle(
                                        fontFamily:
                                        'Lexend',
                                        fontSize:
                                        12,
                                        color:
                                        selected
                                            ? Colors.white
                                            : blue,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ).toList(),
                      ),
                    ),

                    const SizedBox(
                      height: 35,
                    ),

                    SizedBox(
                      width:
                      double.infinity,
                      height: 60,

                      child:
                      ElevatedButton(
                        onPressed:
                        _isLoading
                            ? null
                            : _register,

                        style:
                        ElevatedButton
                            .styleFrom(
                          backgroundColor:
                          orange,
                          foregroundColor:
                          Colors.white,
                          shape:
                          RoundedRectangleBorder(
                            borderRadius:
                            BorderRadius
                                .circular(
                                17),
                          ),
                        ),

                        child: _isLoading
                            ? const SizedBox(
                          width: 25,
                          height: 25,
                          child:
                          CircularProgressIndicator(
                            color:
                            Colors.white,
                            strokeWidth:
                            2.5,
                          ),
                        )
                            : const Row(
                          mainAxisAlignment:
                          MainAxisAlignment
                              .center,
                          children: [
                            Text(
                              'Register',
                              style:
                              TextStyle(
                                fontFamily:
                                'Lexend',
                                fontSize:
                                18,
                                fontWeight:
                                FontWeight
                                    .w600,
                              ),
                            ),
                            SizedBox(
                                width: 12),
                            Icon(
                              Icons
                                  .arrow_forward_rounded,
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(
                      height: 25,
                    ),

                    GestureDetector(
                      onTap: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                            const LoginScreen(),
                          ),
                        );
                      },

                      child: const Text(
                        'Already have an account? Login here',
                        style: TextStyle(
                          fontFamily:
                          'Lexend',
                          fontSize: 13.5,
                          color: orange,
                          fontWeight:
                          FontWeight.w700,
                          decoration:
                          TextDecoration
                              .underline,
                        ),
                      ),
                    ),

                    const SizedBox(
                      height: 30,
                    ),
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