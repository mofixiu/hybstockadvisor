// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hybstockadvisor/providers/notification_provider.dart';
import 'package:hybstockadvisor/providers/portfolio_provider.dart';
import 'package:hybstockadvisor/providers/profile_provider.dart';
import 'package:hybstockadvisor/screens/auth/auth_scaffold.dart';
import 'package:hybstockadvisor/screens/auth/forgotPassword.dart';
import 'package:hybstockadvisor/screens/auth/signup.dart';
import 'package:hybstockadvisor/screens/dashboard.dart';
import 'package:hybstockadvisor/screens/firstlogin.dart';
import 'package:hybstockadvisor/services/api_service.dart';
import 'package:hybstockadvisor/theme/tokens.dart';
import 'package:hybstockadvisor/widgets/custom_page_route.dart';
import 'package:hybstockadvisor/widgets/ui.dart';
import 'package:provider/provider.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> handleLogin() async {
    if (_isLoading) return;
    FocusScope.of(context).unfocus();

    if (emailController.text.trim().isEmpty || passwordController.text.isEmpty) {
      showNotice(context, 'Enter your email or username and your password.');
      return;
    }

    setState(() => _isLoading = true);

    final response = await ApiService.login(
      emailController.text.trim(),
      passwordController.text,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (response['status'] != 'success') {
      showNotice(
        context,
        response['detail']?.toString() ?? "Couldn't sign you in. Try again.",
      );
      return;
    }

    final String token = response['token'];
    final String firstName = response['user_data']['first_name'];
    final int userId = response['user_data']['id'];

    // JWT goes to encrypted secure storage; the user id is not sensitive.
    await ApiService.saveToken(token);
    final authBox = await Hive.openBox('auth');
    await authBox.put('user_id', userId);

    final userBox = await Hive.openBox('user');
    await userBox.delete('avatar_path');
    await userBox.delete('has_setup_portfolio');
    await userBox.put('first_name', firstName);
    await userBox.put('last_name', response['user_data']['last_name'] ?? '');

    await context.read<NotificationProvider>().clearAll();
    context.read<ProfileProvider>().resetForSessionChange();
    context.read<PortfolioProvider>().resetForSessionChange();

    // New accounts with no holdings or watchlist go through first-time setup.
    var needsSetup = true;
    if (userBox.get('has_setup_portfolio', defaultValue: false) == true) {
      needsSetup = false;
    } else {
      final assets = await ApiService.getUserAssets();
      if (assets != null) {
        final List portfolio = assets['portfolio'] ?? [];
        final List watchlist = assets['watchlist'] ?? [];
        if (portfolio.isNotEmpty || watchlist.isNotEmpty) {
          needsSetup = false;
          await userBox.put('has_setup_portfolio', true);
        }
      }
    }

    if (!mounted) return;
    // Clear the stack so a previous user's screens are not kept behind.
    context.pushFadeAndRemoveUntil(
      needsSetup ? const FirstLogin() : const Dashboard(),
      (Route<dynamic> route) => false,
    );
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      title: 'Log in',
      lead: 'Daily NGX closes, your holdings, and reviewed research signals.',
      children: [
        AutofillGroup(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AuthField(
                controller: emailController,
                label: 'Email or username',
                icon: Icons.person_outline,
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.username, AutofillHints.email],
              ),
              AuthPasswordField(
                controller: passwordController,
                label: 'Password',
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.password],
                onSubmitted: (_) => handleLogin(),
              ),
            ],
          ),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: LinkText(
            'Forgot password?',
            arrow: false,
            onTap: () => context.pushFade(const ForgotPassword()),
          ),
        ),
        const SizedBox(height: Gap.md),
        PrimaryButton('Log in', onPressed: handleLogin, loading: _isLoading),
        const SizedBox(height: Gap.lg),
        AuthFooterLink(
          prompt: 'No account yet?',
          label: 'Create one',
          onTap: () => context.pushFade(const SignUp()),
        ),
        const AuthTerms(),
      ],
    );
  }
}
