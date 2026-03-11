import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hybstockadvisor/screens/auth/reset_password.dart';
import 'package:hybstockadvisor/services/api_service.dart';
import 'package:hybstockadvisor/widgets/customButton.dart';
import 'package:hybstockadvisor/widgets/custom_page_route.dart';

class OtpVerification extends StatefulWidget {
  final String email;
  const OtpVerification({super.key, required this.email});

  @override
  State<OtpVerification> createState() => _OtpVerificationState();
}

class _OtpVerificationState extends State<OtpVerification> {
  final List<TextEditingController> _controllers = List.generate(
    6,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  bool _isLoading = false;
  bool _isResending = false;
  int _resendCooldown = 0;
  Timer? _timer;

  @override
  void dispose() {
    for (final c in _controllers) c.dispose();
    for (final f in _focusNodes) f.dispose();
    _timer?.cancel();
    super.dispose();
  }

  String get _otp => _controllers.map((c) => c.text).join();

  void _startResendTimer() {
    setState(() => _resendCooldown = 30);
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_resendCooldown <= 1) {
        t.cancel();
        setState(() => _resendCooldown = 0);
      } else {
        setState(() => _resendCooldown--);
      }
    });
  }

  Future<void> _handleResend() async {
    if (_resendCooldown > 0 || _isResending) return;
    setState(() => _isResending = true);
    final response = await ApiService.forgotPassword(widget.email);
    setState(() => _isResending = false);
    if (!mounted) return;
    if (response['status'] == 'success') {
      _startResendTimer();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('A new OTP has been sent to your email'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response['detail'] ?? 'Failed to resend OTP'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _handleVerify() async {
    if (_otp.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter the complete 6-digit code'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    final response = await ApiService.verifyResetOtp(widget.email, _otp);
    setState(() => _isLoading = false);

    if (!mounted) return;

    if (response['status'] == 'success') {
      final resetToken = response['reset_token'] ?? '';
      context.pushFade(ResetPassword(resetToken: resetToken));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response['detail'] ?? 'Invalid OTP. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
      // Clear fields on wrong OTP
      for (final c in _controllers) c.clear();
      _focusNodes[0].requestFocus();
    }
  }

  Widget _buildDigitBox(int index) {
    return SizedBox(
      width: 46,
      height: 56,
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
        child: TextField(
          controller: _controllers[index],
          focusNode: _focusNodes[index],
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          maxLength: 1,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A1A2E),
          ),
          decoration: const InputDecoration(
            counterText: '',
            border: InputBorder.none,
          ),
          onChanged: (val) {
            if (val.isNotEmpty && index < 5) {
              _focusNodes[index + 1].requestFocus();
            } else if (val.isEmpty && index > 0) {
              _focusNodes[index - 1].requestFocus();
            }
          },
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
                'Verify Your Email',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, color: Colors.grey),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30),
                child: Text(
                  'Enter the 6-digit code sent to\n${widget.email}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.grey,
                    height: 1.5,
                  ),
                ),
              ),

              SizedBox(height: MediaQuery.of(context).size.height * 0.05),

              // OTP digit boxes
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(6, _buildDigitBox),
                ),
              ),

              SizedBox(height: MediaQuery.of(context).size.height * 0.03),

              // Resend OTP
              Center(
                child: _isResending
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFF0A3D62),
                        ),
                      )
                    : GestureDetector(
                        onTap: _resendCooldown > 0 ? null : _handleResend,
                        child: Text(
                          _resendCooldown > 0
                              ? 'Resend OTP in ${_resendCooldown}s'
                              : 'Resend OTP',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: _resendCooldown > 0
                                ? Colors.grey
                                : const Color(0xFF0A3D62),
                          ),
                        ),
                      ),
              ),

              SizedBox(height: MediaQuery.of(context).size.height * 0.04),

              // Verify Button
              Padding(
                padding: const EdgeInsets.only(left: 20.0, right: 20, top: 10),
                child: CustomButton(
                  ontap: _isLoading ? () {} : _handleVerify,
                  data: 'Verify OTP',
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

              SizedBox(height: MediaQuery.of(context).size.height * 0.01),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
