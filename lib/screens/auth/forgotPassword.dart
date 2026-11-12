import 'package:flutter/material.dart';
import 'package:hybstockadvisor/screens/auth/auth_scaffold.dart';
import 'package:hybstockadvisor/screens/auth/otp_verification.dart';
import 'package:hybstockadvisor/services/api_service.dart';
import 'package:hybstockadvisor/theme/tokens.dart';
import 'package:hybstockadvisor/widgets/custom_page_route.dart';
import 'package:hybstockadvisor/widgets/ui.dart';

class ForgotPassword extends StatefulWidget {
  const ForgotPassword({super.key});

  @override
  State<ForgotPassword> createState() => _ForgotPasswordState();
}

class _ForgotPasswordState extends State<ForgotPassword> {
  final TextEditingController _emailController = TextEditingController();
  bool _isLoading = false;

  Future<void> _handleSendOtp() async {
    FocusScope.of(context).unfocus();
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      showNotice(context, 'Enter the email on your account.');
      return;
    }

    setState(() => _isLoading = true);
    final response = await ApiService.forgotPassword(email);
    if (!mounted) return;
    setState(() => _isLoading = false);

    if (response['status'] == 'success') {
      context.pushFade(OtpVerification(email: email));
    } else {
      showNotice(
        context,
        response['detail']?.toString() ?? "Couldn't send the code. Try again.",
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
    return AuthScaffold(
      title: 'Reset your password',
      lead: "Enter your account email and we'll send a 6-digit code. It expires after 15 minutes.",
      showBack: true,
      children: [
        AuthField(
          controller: _emailController,
          label: 'Email',
          icon: Icons.mail_outline,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.send,
          autofillHints: const [AutofillHints.email],
          onSubmitted: (_) => _handleSendOtp(),
        ),
        const SizedBox(height: Gap.sm),
        PrimaryButton('Send code', onPressed: _handleSendOtp, loading: _isLoading),
        const SizedBox(height: Gap.lg),
        AuthFooterLink(
          prompt: 'Remembered it?',
          label: 'Log in',
          onTap: () => Navigator.pop(context),
        ),
      ],
    );
  }
}
