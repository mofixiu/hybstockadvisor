// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:hybstockadvisor/screens/auth/login.dart';
// import 'package:hybstockadvisor/screens/dashboard.dart';
import 'package:hybstockadvisor/services/api_service.dart';
import 'package:hybstockadvisor/themes/theme.dart';
import 'package:hybstockadvisor/widgets/customButton.dart';
import 'package:hybstockadvisor/widgets/custom_page_route.dart';

class SignUp extends StatefulWidget {
  const SignUp({super.key});

  @override
  State<SignUp> createState() => _SignUpState();
}

class _SignUpState extends State<SignUp> {
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController userNameController = TextEditingController();

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isLoading = false;
  Future<void> handleSignUp() async {
    if (_isLoading) return;

    if (firstNameController.text.trim().isEmpty ||
        lastNameController.text.trim().isEmpty ||
        userNameController.text.trim().isEmpty ||
        emailController.text.trim().isEmpty ||
        passwordController.text.isEmpty ||
        confirmPasswordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all fields'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (!RegExp(
      r'^[\w\-\.]+@([\w\-]+\.)+[\w\-]{2,4}$',
    ).hasMatch(emailController.text.trim())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid email address'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (passwordController.text.length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password must be at least 8 characters'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (passwordController.text != confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Passwords do not match!",
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    Map<String, dynamic> userData = {
      "first_name": firstNameController.text.trim(),
      "last_name": lastNameController.text.trim(),
      "username": userNameController.text.trim(),
      "email": emailController.text.trim(),
      "password": passwordController.text,
    };

    final response = await ApiService.register(userData);

    setState(() => _isLoading = false);

    if (response['status'] == 'success') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Account created! Please log in."),
          backgroundColor: Colors.green,
        ),
      );
      // Navigate back to Login Screen
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response['detail']),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    firstNameController.dispose();
    lastNameController.dispose();
    userNameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 5.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: MediaQuery.of(context).size.height * 0.02),

              // Logo Image
              Center(
                child: Image.asset(
                  'assets/images/logo.png',
                  height: 150,
                  width: 150,
                  fit: BoxFit.contain,
                ),
              ),

              const SizedBox(height: 16),

              // App Name
              const Text(
                'HYBSTOCKADVISOR',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A2E),
                ),
              ),

              const SizedBox(height: 8),

              // Subtitle
              const Text(
                'Create Your Account Today',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, color: Colors.grey),
              ),

              const SizedBox(height: 15),

              // ── User Name ──
              _buildInputField(
                controller: userNameController,
                hint: 'Enter User Name',
                icon: Icons.person_outline,
                keyboardType: TextInputType.name,
              ),

              SizedBox(height: MediaQuery.of(context).size.height * 0.02),

              // ── First Name ──
              _buildInputField(
                controller: firstNameController,
                hint: 'Enter First Name',
                icon: Icons.person_outline,
                keyboardType: TextInputType.name,
              ),

              SizedBox(height: MediaQuery.of(context).size.height * 0.02),

              // ── Last Name ──
              _buildInputField(
                controller: lastNameController,
                hint: 'Enter Last Name',
                icon: Icons.person_outline,
                keyboardType: TextInputType.name,
              ),

              SizedBox(height: MediaQuery.of(context).size.height * 0.02),

              // ── Email ──
              _buildInputField(
                controller: emailController,
                hint: 'Enter Email Address',
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
              ),

              SizedBox(height: MediaQuery.of(context).size.height * 0.02),

              // ── Password ──
              _buildPasswordField(
                controller: passwordController,
                hint: 'Enter Password',
                isVisible: _isPasswordVisible,
                onToggle: () =>
                    setState(() => _isPasswordVisible = !_isPasswordVisible),
              ),

              SizedBox(height: MediaQuery.of(context).size.height * 0.02),

              // ── Confirm Password ──
              _buildPasswordField(
                controller: confirmPasswordController,
                hint: 'Confirm Password',
                isVisible: _isConfirmPasswordVisible,
                onToggle: () => setState(
                  () => _isConfirmPasswordVisible = !_isConfirmPasswordVisible,
                ),
              ),

              SizedBox(height: MediaQuery.of(context).size.height * 0.02),

              // ── Sign Up Button ──
              Padding(
                padding: const EdgeInsets.only(left: 20.0, right: 20, top: 10),
                child: CustomButton(
                  ontap: () {
                    // context.pushFade(const Dashboard());
                    handleSignUp();
                  },
                  data: 'Sign Up',
                  textcolor: Colors.white,
                  backgroundcolor: _isLoading
                      ? Colors.grey
                      : const Color(0xFF0A3D62),
                  width: MediaQuery.of(context).size.width,
                  height: 50,
                ),
              ),

              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.only(bottom: 10),
                  child: CircularProgressIndicator(color: Color(0xFF0A3D62)),
                ),

              SizedBox(height: MediaQuery.of(context).size.height * 0.005),

              // ── Already have account ──
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Already have an account?    ',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        context.pushFade(const Login());
                      },
                      child: const Text(
                        'Login now!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF0A3D62),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: MediaQuery.of(context).size.height * 0.01),

              // ── Terms ──
              const Center(
                child: Text(
                  'By Continuing, you agree to our',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SizedBox(height: MediaQuery.of(context).size.height * 0.005),
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Terms of Service',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF0A3D62),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    ' and ',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Privacy Policy',
                    style: TextStyle(
                      fontSize: 14,
                      decoration: TextDecoration.underline,
                      decorationColor: Colors.black,
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // Reusable plain input field (matches login style)
  // ─────────────────────────────────────────────
  Widget _buildInputField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Container(
        decoration: BoxDecoration(
          color: const Color.fromRGBO(252, 242, 212, 1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 3,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
          child: Row(
            children: [
              Icon(icon, color: Colors.grey[600], size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: controller,
                  keyboardType: keyboardType,
                  decoration: InputDecoration(
                    hintText: hint,
                    hintStyle: const TextStyle(
                      color: HybStockAdvisor.darkBorderColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                    ),
                    border: InputBorder.none,
                    errorStyle: const TextStyle(fontSize: 0),
                  ),
                  style: const TextStyle(fontSize: 16, color: Colors.black87),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // Reusable password field (matches login style)
  // ─────────────────────────────────────────────
  Widget _buildPasswordField({
    required TextEditingController controller,
    required String hint,
    required bool isVisible,
    required VoidCallback onToggle,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Container(
        decoration: BoxDecoration(
          color: const Color.fromRGBO(252, 242, 212, 1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 3,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
          child: Row(
            children: [
              Icon(Icons.lock, color: Colors.grey[600], size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: controller,
                  obscureText: !isVisible,
                  decoration: InputDecoration(
                    hintText: hint,
                    hintStyle: const TextStyle(
                      color: HybStockAdvisor.darkBorderColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                    ),
                    border: InputBorder.none,
                    errorStyle: const TextStyle(fontSize: 0),
                    suffixIcon: IconButton(
                      icon: Icon(
                        isVisible ? Icons.visibility : Icons.visibility_off,
                        color: Colors.grey[600],
                        size: 20,
                      ),
                      onPressed: onToggle,
                    ),
                  ),
                  style: const TextStyle(fontSize: 16, color: Colors.black87),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
