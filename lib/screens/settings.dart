import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hybstockadvisor/providers/theme_provider.dart';
import 'package:hybstockadvisor/screens/auth/otp_verification.dart';
import 'package:hybstockadvisor/services/api_service.dart';
import 'package:hybstockadvisor/widgets/custom_page_route.dart';
import 'package:provider/provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1A1A2E) : const Color(0xFFF2F4F7);
    final cardColor = isDark ? const Color(0xFF2A2D3E) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A2E);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: bgColor,
        centerTitle: true,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            margin: const EdgeInsets.only(left: 16),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4),
              ],
            ),
            child: Icon(Icons.arrow_back_ios_new, size: 16, color: textColor),
          ),
        ),
        title: Text(
          'Settings',
          style: TextStyle(
            color: textColor,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),

              // ── APPEARANCE ──
              _SectionLabel(label: 'APPEARANCE', isDark: isDark),
              const SizedBox(height: 12),
              _buildCard(
                cardColor: cardColor,
                children: [
                  _ToggleRow(
                    icon: Icons.dark_mode_outlined,
                    iconBg: const Color(0xFF2A2D3E),
                    iconColor: const Color(0xFFBBC5E8),
                    label: 'Dark Mode',
                    textColor: textColor,
                    isDark: isDark,
                    value: isDark,
                    onChanged: (val) async {
                      context.read<ThemeProvider>().toggleTheme(val);
                      final box = await Hive.openBox('user');
                      await box.put('theme_dark', val);
                    },
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // ── SECURITY ──
              _SectionLabel(label: 'SECURITY', isDark: isDark),
              const SizedBox(height: 12),
              _buildCard(
                cardColor: cardColor,
                children: [
                  _TapRow(
                    icon: Icons.lock_outline,
                    iconBg: const Color(0xFFDCEAFF),
                    iconColor: const Color(0xFF2979FF),
                    label: 'Change Password',
                    textColor: textColor,
                    isDark: isDark,
                    onTap: () => _showChangePasswordSheet(
                      context,
                      isDark,
                      cardColor,
                      textColor,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // ── DATA ──
              _SectionLabel(label: 'DATA', isDark: isDark),
              const SizedBox(height: 12),
              _buildCard(
                cardColor: cardColor,
                children: [
                  _TapRow(
                    icon: Icons.cleaning_services_outlined,
                    iconBg: const Color(0xFFFFF3E0),
                    iconColor: const Color(0xFFF59E0B),
                    label: 'Clear Cache',
                    textColor: textColor,
                    isDark: isDark,
                    onTap: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          backgroundColor: cardColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          title: Text(
                            'Clear Cache',
                            style: TextStyle(color: textColor),
                          ),
                          content: Text(
                            'This will clear locally cached data. Your account and portfolio data will not be affected.',
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 13,
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: Text(
                                'Cancel',
                                style: TextStyle(color: Colors.grey[500]),
                              ),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              child: const Text(
                                'Clear',
                                style: TextStyle(color: Colors.red),
                              ),
                            ),
                          ],
                        ),
                      );

                      if (confirm == true && mounted) {
                        final box = await Hive.openBox('user');
                        // Preserve account-critical keys
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
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Cache cleared successfully'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      }
                    },
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // ── APP INFO ──
              _SectionLabel(label: 'APP INFO', isDark: isDark),
              const SizedBox(height: 12),
              _buildCard(
                cardColor: cardColor,
                children: [
                  _InfoRow(
                    icon: Icons.info_outline,
                    iconBg: const Color(0xFFDCEAFF),
                    iconColor: const Color(0xFF2979FF),
                    label: 'Version',
                    value: '1.0.0',
                    textColor: textColor,
                  ),
                ],
              ),
              SizedBox(height: 24),
              Text(
                "Please note that this is not financial advice, just a final year project. Always do your own research before making any investment decisions.",
                style: TextStyle(color: Colors.grey[500], fontSize: 12),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCard({
    required Color cardColor,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  void _showChangePasswordSheet(
    BuildContext context,
    bool isDark,
    Color cardColor,
    Color textColor,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ChangePasswordSheet(
        isDark: isDark,
        cardColor: cardColor,
        textColor: textColor,
        onSuccess: (String email) {
          Navigator.pop(context);
          context.pushFade(OtpVerification(email: email));
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Toggle Row (switch)
// ─────────────────────────────────────────────
class _ToggleRow extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String label;
  final Color textColor;
  final bool isDark;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleRow({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.label,
    required this.textColor,
    required this.isDark,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: textColor,
              ),
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xFF0A3D62),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Tap Row (with chevron)
// ─────────────────────────────────────────────
class _TapRow extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String label;
  final Color textColor;
  final bool isDark;
  final VoidCallback onTap;

  const _TapRow({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.label,
    required this.textColor,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: textColor,
                ),
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey[400], size: 20),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Info Row (label + value, no chevron)
// ─────────────────────────────────────────────
class _InfoRow extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String label;
  final String value;
  final Color textColor;

  const _InfoRow({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: textColor,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Section Label
// ─────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String label;
  final bool isDark;

  const _SectionLabel({required this.label, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          letterSpacing: 1.3,
          fontWeight: FontWeight.w600,
          color: Colors.grey[500],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Change Password Bottom Sheet
// ─────────────────────────────────────────────
class _ChangePasswordSheet extends StatefulWidget {
  final bool isDark;
  final Color cardColor;
  final Color textColor;
  final void Function(String email) onSuccess;

  const _ChangePasswordSheet({
    required this.isDark,
    required this.cardColor,
    required this.textColor,
    required this.onSuccess,
  });

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
      setState(() => _error = 'Please enter your email address');
      return;
    }
    if (!email.contains('@') || !email.contains('.')) {
      setState(() => _error = 'Please enter a valid email address');
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
        _error = response['detail'] ?? 'Failed to send OTP. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = widget.isDark
        ? const Color(0xFF1A1A2E)
        : const Color(0xFFF2F4F7);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Title
            Text(
              'Change Password',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: widget.textColor,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Enter your account email to receive a verification code.',
              style: TextStyle(fontSize: 13, color: Colors.grey[500]),
            ),
            const SizedBox(height: 24),

            // Email field
            Container(
              decoration: BoxDecoration(
                color: widget.cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _error != null
                      ? Colors.red.withOpacity(0.6)
                      : Colors.transparent,
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 6,
                  ),
                ],
              ),
              child: TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                autofocus: true,
                style: TextStyle(color: widget.textColor, fontSize: 15),
                decoration: InputDecoration(
                  hintText: 'Email address',
                  hintStyle: TextStyle(color: Colors.grey[400]),
                  prefixIcon: const Icon(
                    Icons.email_outlined,
                    color: Color(0xFF2979FF),
                    size: 20,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onSubmitted: (_) => _sendOtp(),
              ),
            ),

            // Error message
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(
                _error!,
                style: const TextStyle(color: Colors.red, fontSize: 12),
              ),
            ],

            const SizedBox(height: 24),

            // Send OTP button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _sendOtp,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0A3D62),
                  disabledBackgroundColor: Colors.grey,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : const Text(
                        'Send OTP',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
