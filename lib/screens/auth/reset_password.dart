import 'package:flutter/material.dart';
import 'package:hybstockadvisor/screens/auth/login.dart';
import 'package:hybstockadvisor/services/api_service.dart';
import 'package:hybstockadvisor/themes/theme.dart';
import 'package:hybstockadvisor/widgets/customButton.dart';

class ResetPassword extends StatefulWidget {
  final String resetToken;
  const ResetPassword({super.key, required this.resetToken});

  @override
  State<ResetPassword> createState() => _ResetPasswordState();
}

class _ResetPasswordState extends State<ResetPassword> {
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  bool _isNewPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isLoading = false;

  Future<void> _handleResetPassword() async {
    final newPassword = _newPasswordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (newPassword.isEmpty || confirmPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all fields'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (newPassword.length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password must be at least 8 characters'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (newPassword != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Passwords do not match'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    final response = await ApiService.resetPassword(
      widget.resetToken,
      newPassword,
    );
    setState(() => _isLoading = false);

    if (!mounted) return;

    if (response['status'] == 'success') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password reset successfully! Please log in.'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const Login()),
        (route) => false,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response['detail'] ?? 'Failed to reset password'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

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
                  height: 150,
                  width: 150,
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
                'Create a New Password',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, color: Colors.grey),
              ),
              const SizedBox(height: 8),
              const Text(
                'Your new password must be\nat least 8 characters long.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Colors.grey, height: 1.5),
              ),

              SizedBox(height: MediaQuery.of(context).size.height * 0.04),

              // New Password
              _buildPasswordField(
                controller: _newPasswordController,
                hint: 'Enter New Password',
                isVisible: _isNewPasswordVisible,
                onToggle: () => setState(
                  () => _isNewPasswordVisible = !_isNewPasswordVisible,
                ),
              ),

              SizedBox(height: MediaQuery.of(context).size.height * 0.02),

              // Confirm Password
              _buildPasswordField(
                controller: _confirmPasswordController,
                hint: 'Confirm New Password',
                isVisible: _isConfirmPasswordVisible,
                onToggle: () => setState(
                  () => _isConfirmPasswordVisible = !_isConfirmPasswordVisible,
                ),
              ),

              SizedBox(height: MediaQuery.of(context).size.height * 0.04),

              // Reset Button
              Padding(
                padding: const EdgeInsets.only(left: 20.0, right: 20, top: 10),
                child: CustomButton(
                  ontap: _isLoading ? () {} : _handleResetPassword,
                  data: 'Reset Password',
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
                  padding: EdgeInsets.only(top: 16),
                  child: Center(
                    child: CircularProgressIndicator(color: Color(0xFF0A3D62)),
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
                      onTap: () => Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (_) => const Login()),
                        (route) => false,
                      ),
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
