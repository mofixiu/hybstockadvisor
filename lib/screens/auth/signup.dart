// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:hybstockadvisor/screens/auth/auth_scaffold.dart';
import 'package:hybstockadvisor/services/api_service.dart';
import 'package:hybstockadvisor/theme/tokens.dart';
import 'package:hybstockadvisor/widgets/ui.dart';

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
  final TextEditingController confirmPasswordController = TextEditingController();
  final TextEditingController inviteController = TextEditingController();
  bool _isLoading = false;

  Future<void> handleSignUp() async {
    if (_isLoading) return;
    FocusScope.of(context).unfocus();

    if (firstNameController.text.trim().isEmpty ||
        lastNameController.text.trim().isEmpty ||
        userNameController.text.trim().isEmpty ||
        emailController.text.trim().isEmpty ||
        passwordController.text.isEmpty ||
        confirmPasswordController.text.isEmpty) {
      showNotice(context, 'Fill in every field.');
      return;
    }

    if (!RegExp(r'^[\w\-\.]+@([\w\-]+\.)+[\w\-]{2,4}$')
        .hasMatch(emailController.text.trim())) {
      showNotice(context, 'Enter a valid email address.');
      return;
    }

    if (passwordController.text.length < 8) {
      showNotice(context, 'Use at least 8 characters for the password.');
      return;
    }

    if (passwordController.text != confirmPasswordController.text) {
      showNotice(context, "The passwords don't match.");
      return;
    }

    final invite = inviteController.text.trim();
    setState(() => _isLoading = true);

    final userData = <String, dynamic>{
      'first_name': firstNameController.text.trim(),
      'last_name': lastNameController.text.trim(),
      'username': userNameController.text.trim(),
      'email': emailController.text.trim(),
      'password': passwordController.text,
      if (invite.isNotEmpty) 'invite_code': invite,
    };

    final response = await ApiService.register(userData);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (response['status'] == 'success') {
      showNotice(context, 'Account created. Log in to continue.');
      Navigator.pop(context);
    } else {
      showNotice(
        context,
        response['detail']?.toString() ?? "Couldn't create the account. Try again.",
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
    inviteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      title: 'Create an account',
      lead: 'Accounts are by invitation. Use the email you were invited with, or enter your invitation code.',
      showBack: true,
      children: [
        AutofillGroup(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: AuthField(
                      controller: firstNameController,
                      label: 'First name',
                      keyboardType: TextInputType.name,
                      capitalization: TextCapitalization.words,
                      autofillHints: const [AutofillHints.givenName],
                    ),
                  ),
                  const SizedBox(width: Gap.md),
                  Expanded(
                    child: AuthField(
                      controller: lastNameController,
                      label: 'Last name',
                      keyboardType: TextInputType.name,
                      capitalization: TextCapitalization.words,
                      autofillHints: const [AutofillHints.familyName],
                    ),
                  ),
                ],
              ),
              AuthField(
                controller: userNameController,
                label: 'Username',
                icon: Icons.person_outline,
                autofillHints: const [AutofillHints.newUsername],
              ),
              AuthField(
                controller: emailController,
                label: 'Email',
                icon: Icons.mail_outline,
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.email],
              ),
              AuthPasswordField(
                controller: passwordController,
                label: 'Password',
                helper: 'At least 8 characters',
                autofillHints: const [AutofillHints.newPassword],
              ),
              AuthPasswordField(
                controller: confirmPasswordController,
                label: 'Confirm password',
                autofillHints: const [AutofillHints.newPassword],
              ),
              AuthField(
                controller: inviteController,
                label: 'Invitation code (optional)',
                icon: Icons.key_outlined,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => handleSignUp(),
              ),
            ],
          ),
        ),
        const SizedBox(height: Gap.sm),
        PrimaryButton('Create account', onPressed: handleSignUp, loading: _isLoading),
        const SizedBox(height: Gap.lg),
        AuthFooterLink(
          prompt: 'Already have an account?',
          label: 'Log in',
          onTap: () => Navigator.pop(context),
        ),
        const AuthTerms(),
      ],
    );
  }
}
