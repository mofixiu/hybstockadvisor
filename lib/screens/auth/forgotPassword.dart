import 'package:flutter/material.dart';
import 'package:hybstockadvisor/screens/auth/otp_verification.dart';
import 'package:hybstockadvisor/services/api_service.dart';
import 'package:hybstockadvisor/themes/theme.dart';
import 'package:hybstockadvisor/widgets/customButton.dart';
import 'package:hybstockadvisor/widgets/custom_page_route.dart';

class ForgotPassword extends StatefulWidget {
  const ForgotPassword({super.key});

  @override
  State<ForgotPassword> createState() => _ForgotPasswordState();
}

class _ForgotPasswordState extends State<ForgotPassword> {
  final TextEditingController _emailController = TextEditingController();
  bool _isLoading = false;

  Future<void> _handleSendOtp() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your email address'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    final response = await ApiService.forgotPassword(email);
    setState(() => _isLoading = false);

    if (!mounted) return;

    if (response['status'] == 'success') {
      context.pushFade(OtpVerification(email: email));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response['detail'] ?? 'Something went wrong'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
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

              // Back button
              Padding(
                padding: const EdgeInsets.only(left: 12.0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color.fromRGBO(252, 242, 212, 1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey[300]!, width: 1),
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios_new,
                        size: 18,
                        color: Color(0xFF0A3D62),
                      ),
                    ),
                  ),
                ),
              ),

              SizedBox(height: MediaQuery.of(context).size.height * 0.02),

              // Logo
              Center(
                child: Image.asset(
                  'assets/images/logo.png',
                  height: 180,
                  width: 180,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 16),

              // Title
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
              const Text(
                'Reset Your Password',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, color: Colors.grey),
              ),
              const SizedBox(height: 8),
              const Text(
                'Enter your email and we\'ll send you\na one-time code to reset your password.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Colors.grey, height: 1.5),
              ),
              SizedBox(height: MediaQuery.of(context).size.height * 0.04),

              // Email Field
              Padding(
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 4.0,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.email_outlined,
                          color: Colors.grey[600],
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(
                              hintText: 'Enter Email Address',
                              hintStyle: TextStyle(
                                color: HybStockAdvisor.darkBorderColor,
                                fontSize: 16,
                                fontWeight: FontWeight.w400,
                              ),
                              border: InputBorder.none,
                              errorStyle: TextStyle(fontSize: 0),
                            ),
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              SizedBox(height: MediaQuery.of(context).size.height * 0.04),

              // Send OTP Button
              Padding(
                padding: const EdgeInsets.only(left: 20.0, right: 20, top: 10),
                child: CustomButton(
                  ontap: _handleSendOtp,
                  data: 'Send OTP',
                  textcolor: Colors.white,
                  backgroundcolor: const Color(0xFF0A3D62),
                  width: MediaQuery.of(context).size.width,
                  height: 50,
                  isLoading: _isLoading,
                ),
              ),

              SizedBox(height: MediaQuery.of(context).size.height * 0.03),

              // Back to login
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Remember your password?    ',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Text(
                        'Login now!',
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
}
