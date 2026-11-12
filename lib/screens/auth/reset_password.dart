import 'package:flutter/material.dart';
import 'package:hybstockadvisor/screens/auth/auth_scaffold.dart';
import 'package:hybstockadvisor/screens/auth/login.dart';
import 'package:hybstockadvisor/services/api_service.dart';
import 'package:hybstockadvisor/theme/tokens.dart';
import 'package:hybstockadvisor/widgets/ui.dart';

class ResetPassword extends StatefulWidget {
  final String resetToken;
  const ResetPassword({super.key, required this.resetToken});

  @override
  State<ResetPassword> createState() => _ResetPasswordState();
}

class _ResetPasswordState extends State<ResetPassword> {
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  bool _isLoading = false;

  void _toLogin() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const Login()),
      (route) => false,
    );
  }

  Future<void> _handleResetPassword() async {
    FocusScope.of(context).unfocus();
    final newPassword = _newPasswordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (newPassword.isEmpty || confirmPassword.isEmpty) {
      showNotice(context, 'Fill in both fields.');
      return;
    }
    if (newPassword.length < 8) {
      showNotice(context, 'Use at least 8 characters for the password.');
      return;
    }
    if (newPassword != confirmPassword) {
      showNotice(context, "The passwords don't match.");
      return;
    }

    setState(() => _isLoading = true);
    final response = await ApiService.resetPassword(widget.resetToken, newPassword);
    if (!mounted) return;
    setState(() => _isLoading = false);

    if (response['status'] == 'success') {
      showNotice(context, 'Password changed. Log in with the new one.');
      _toLogin();
    } else {
      showNotice(
        context,
        response['detail']?.toString() ?? "Couldn't change the password. Try again.",
      );
    }
  }

  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      title: 'Choose a new password',
      lead: 'Use at least 8 characters.',
      showBack: true,
      children: [
        AutofillGroup(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AuthPasswordField(
                controller: _newPasswordController,
                label: 'New password',
                autofillHints: const [AutofillHints.newPassword],
              ),
              AuthPasswordField(
                controller: _confirmPasswordController,
                label: 'Confirm new password',
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.newPassword],
                onSubmitted: (_) => _handleResetPassword(),
              ),
            ],
          ),
        ),
        const SizedBox(height: Gap.sm),
        PrimaryButton('Change password', onPressed: _handleResetPassword, loading: _isLoading),
        const SizedBox(height: Gap.lg),
        AuthFooterLink(prompt: 'Remembered it?', label: 'Log in', onTap: _toLogin),
      ],
    );
  }
}
