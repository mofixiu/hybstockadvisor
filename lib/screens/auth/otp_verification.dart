import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hybstockadvisor/screens/auth/auth_scaffold.dart';
import 'package:hybstockadvisor/screens/auth/reset_password.dart';
import 'package:hybstockadvisor/services/api_service.dart';
import 'package:hybstockadvisor/theme/tokens.dart';
import 'package:hybstockadvisor/widgets/custom_page_route.dart';
import 'package:hybstockadvisor/widgets/ui.dart';

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
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    _timer?.cancel();
    super.dispose();
  }

  String get _otp => _controllers.map((c) => c.text).join();

  void _startResendTimer() {
    setState(() => _resendCooldown = 30);
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
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
    if (!mounted) return;
    setState(() => _isResending = false);
    if (response['status'] == 'success') {
      _startResendTimer();
      showNotice(context, 'A new code is on its way to ${widget.email}.');
    } else {
      showNotice(
        context,
        response['detail']?.toString() ?? "Couldn't send a new code. Try again.",
      );
    }
  }

  Future<void> _handleVerify() async {
    if (_otp.length < 6) {
      showNotice(context, 'Enter all 6 digits of the code.');
      return;
    }

    setState(() => _isLoading = true);
    final response = await ApiService.verifyResetOtp(widget.email, _otp);
    if (!mounted) return;
    setState(() => _isLoading = false);

    if (response['status'] == 'success') {
      final resetToken = response['reset_token'] ?? '';
      context.pushFade(ResetPassword(resetToken: resetToken));
    } else {
      final detail = (response['detail'] as String?) ?? '';
      final isExpired = detail.toLowerCase().contains('expir');
      final message = isExpired
          ? 'That code has expired or is wrong. Send a new code and try again.'
          : detail.isNotEmpty
          ? detail
          : "That code didn't work. Try again.";
      showNotice(context, message);
      for (final c in _controllers) {
        c.clear();
      }
      _focusNodes[0].requestFocus();
    }
  }

  Widget _digitBox(int index) {
    return SizedBox(
      width: 46,
      child: TextField(
        controller: _controllers[index],
        focusNode: _focusNodes[index],
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        maxLength: 1,
        autofillHints: index == 0 ? const [AutofillHints.oneTimeCode] : null,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        style: AppType.figure(size: 22, color: context.pal.ink),
        decoration: const InputDecoration(
          counterText: '',
          contentPadding: EdgeInsets.symmetric(vertical: 14),
        ),
        onChanged: (val) {
          if (val.isNotEmpty && index < 5) {
            _focusNodes[index + 1].requestFocus();
          } else if (val.isEmpty && index > 0) {
            _focusNodes[index - 1].requestFocus();
          } else if (val.isNotEmpty && index == 5) {
            FocusScope.of(context).unfocus();
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final canResend = _resendCooldown == 0 && !_isResending;
    return AuthScaffold(
      title: 'Enter the code',
      lead: 'We sent a 6-digit code to ${widget.email}.',
      showBack: true,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(6, _digitBox),
        ),
        const SizedBox(height: Gap.md),
        Align(
          alignment: Alignment.centerLeft,
          child: _isResending
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text('Sending…', style: context.text.bodyMedium?.copyWith(color: p.inkFaint)),
                )
              : canResend
              ? LinkText('Send a new code', arrow: false, onTap: _handleResend)
              : Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'You can send a new code in ${_resendCooldown}s',
                    style: context.text.bodyMedium?.copyWith(color: p.inkFaint),
                  ),
                ),
        ),
        const SizedBox(height: Gap.lg),
        PrimaryButton('Verify code', onPressed: _handleVerify, loading: _isLoading),
      ],
    );
  }
}
