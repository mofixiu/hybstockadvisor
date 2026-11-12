// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hybstockadvisor/providers/notification_provider.dart';
import 'package:hybstockadvisor/providers/theme_provider.dart';
import 'package:hybstockadvisor/screens/auth/otp_verification.dart';
import 'package:hybstockadvisor/services/api_service.dart';
import 'package:hybstockadvisor/theme/tokens.dart';
import 'package:hybstockadvisor/widgets/custom_page_route.dart';
import 'package:hybstockadvisor/widgets/ui.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _appVersion = '';

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (mounted) setState(() => _appVersion = '${info.version} (${info.buildNumber})');
    } catch (_) {}
  }

  Future<void> _setDark(bool value) async {
    context.read<ThemeProvider>().toggleTheme(value);
    final box = await Hive.openBox('user');
    await box.put('theme_dark', value);
  }

  Future<void> _clearCache() async {
    final confirm = await confirmAction(
      context,
      title: 'Clear cached data?',
      message: 'This clears notifications and saved preferences on this phone. '
          'Your account, holdings and watchlist are not affected.',
      confirmLabel: 'Clear',
      destructive: true,
    );
    if (!confirm || !mounted) return;

    await context.read<NotificationProvider>().clearAll();
    final box = await Hive.openBox('user');
    // Keep the keys the account and theme depend on.
    final keep = {
      'first_name': box.get('first_name'),
      'last_name': box.get('last_name'),
      'has_setup_portfolio': box.get('has_setup_portfolio'),
      'avatar_path': box.get('avatar_path'),
      'theme_dark': box.get('theme_dark'),
    };
    await box.clear();
    for (final e in keep.entries) {
      if (e.value != null) await box.put(e.key, e.value);
    }
    if (mounted) showNotice(context, 'Cached data cleared.');
  }

  void _changePassword() {
    showAppSheet<void>(
      context,
      (_) => _ChangePasswordSheet(
        onSuccess: (email) {
          Navigator.pop(context);
          context.pushFade(OtpVerification(email: email));
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final t = context.text;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: p.paper,
      appBar: AppBar(title: const Text('Settings')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(bottom: Gap.xxl),
          children: [
            const _Group('Appearance'),
            _Row(
              icon: Icons.dark_mode_outlined,
              label: 'Dark mode',
              trailing: Switch(value: isDark, onChanged: _setDark),
              onTap: () => _setDark(!isDark),
              last: true,
            ),
            const _Group('Security'),
            _Row(
              icon: Icons.lock_outline,
              label: 'Change password',
              onTap: _changePassword,
              last: true,
            ),
            const _Group('Data'),
            _Row(
              icon: Icons.delete_sweep_outlined,
              label: 'Clear cached data',
              onTap: _clearCache,
              last: true,
            ),
            const _Group('About'),
            _Row(
              icon: Icons.info_outline,
              label: 'Version',
              trailing: Text(_appVersion.isEmpty ? '—' : _appVersion, style: t.bodyMedium?.copyWith(color: p.inkMuted)),
              last: true,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(Gap.page, Gap.xl, Gap.page, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const HeavyRule(),
                  const SizedBox(height: Gap.md),
                  Text(
                    'HybStockAdvisor shows verified daily closes and reviewed research signals for NGX stocks. '
                    'It is not financial advice and it does not place trades. Signals are uncertain; '
                    'check the figures and do your own research before you invest.',
                    style: t.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Group label with a hairline under it.
class _Group extends StatelessWidget {
  final String label;
  const _Group(this.label);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(Gap.page, Gap.xl, Gap.page, 0),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Kicker(label),
        const SizedBox(height: Gap.sm),
        const Hairline(),
      ],
    ),
  );
}

/// Plain settings row: ink icon, label, trailing control or chevron.
class _Row extends StatelessWidget {
  final IconData icon;
  final String label;
  final Widget? trailing;
  final VoidCallback? onTap;
  /// The last row of a group gets a full-width rule; others are indented.
  final bool last;
  const _Row({
    required this.icon,
    required this.label,
    this.trailing,
    this.onTap,
    this.last = false,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: Gap.page,
              vertical: trailing is Switch ? 6 : 14,
            ),
            child: Row(
              children: [
                Icon(icon, size: 20, color: p.ink),
                const SizedBox(width: Gap.lg),
                Expanded(child: Text(label, style: context.text.bodyLarge)),
                trailing ??
                    (onTap != null
                        ? Icon(Icons.chevron_right, size: 20, color: p.inkFaint)
                        : const SizedBox.shrink()),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Gap.page),
            child: last ? const Hairline() : const Hairline(indent: 36),
          ),
        ],
      ),
    );
  }
}

/// Sends a reset code to the account email, then continues to code entry.
class _ChangePasswordSheet extends StatefulWidget {
  final void Function(String email) onSuccess;
  const _ChangePasswordSheet({required this.onSuccess});

  @override
  State<_ChangePasswordSheet> createState() => _ChangePasswordSheetState();
}

class _ChangePasswordSheetState extends State<_ChangePasswordSheet> {
  final TextEditingController _emailController = TextEditingController();
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      setState(() => _error = 'Enter the email on your account.');
      return;
    }
    if (!email.contains('@') || !email.contains('.')) {
      setState(() => _error = 'Enter a valid email address.');
      return;
    }
    setState(() {
      _isLoading = true;
      _error = null;
    });
    final response = await ApiService.forgotPassword(email);
    if (!mounted) return;
    setState(() => _isLoading = false);
    if (response['status'] == 'success') {
      widget.onSuccess(email);
    } else {
      setState(() {
        _error = response['detail']?.toString() ?? "Couldn't send the code. Try again.";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.text;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SheetFrame(
        title: 'Change password',
        subtitle: Text("We'll email a 6-digit code to confirm it's you.", style: t.bodySmall),
        child: Padding(
          padding: const EdgeInsets.only(top: Gap.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                autofocus: true,
                autocorrect: false,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendOtp(),
                decoration: InputDecoration(
                  labelText: 'Email',
                  prefixIcon: const Icon(Icons.mail_outline, size: 20),
                  errorText: _error,
                  errorMaxLines: 3,
                ),
              ),
              const SizedBox(height: Gap.lg),
              PrimaryButton('Send code', onPressed: _sendOtp, loading: _isLoading),
            ],
          ),
        ),
      ),
    );
  }
}
