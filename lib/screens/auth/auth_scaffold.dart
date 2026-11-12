import 'package:flutter/material.dart';
import 'package:hybstockadvisor/theme/tokens.dart';
import 'package:hybstockadvisor/widgets/ui.dart';

/// The app's name set in the serif, used where the badge logo used to be.
class Wordmark extends StatelessWidget {
  final double size;
  final TextAlign align;
  const Wordmark({super.key, this.size = 30, this.align = TextAlign.left});

  @override
  Widget build(BuildContext context) => Text(
    'HybStockAdvisor',
    textAlign: align,
    style: AppType.serif(size: size, color: context.pal.ink, letterSpacing: -0.4),
  );
}

/// Shared layout for the sign-in, sign-up and password screens: a masthead
/// (wordmark, one-line description, heavy rule), a serif title, a short lead
/// paragraph, then the form.
class AuthScaffold extends StatelessWidget {
  final String title;
  final String? lead;
  final List<Widget> children;
  final bool showBack;

  const AuthScaffold({
    super.key,
    required this.title,
    this.lead,
    required this.children,
    this.showBack = false,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final t = context.text;
    return Scaffold(
      backgroundColor: p.paper,
      body: SafeArea(
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () => FocusScope.of(context).unfocus(),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(Gap.page, Gap.md, Gap.page, Gap.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  height: 44,
                  child: showBack
                      ? Align(
                          alignment: Alignment.centerLeft,
                          child: IconButton(
                            onPressed: () => Navigator.pop(context),
                            tooltip: 'Back',
                            padding: EdgeInsets.zero,
                            alignment: Alignment.centerLeft,
                            icon: Icon(Icons.arrow_back, color: p.ink),
                          ),
                        )
                      : null,
                ),
                const SizedBox(height: Gap.lg),
                const Wordmark(),
                const SizedBox(height: Gap.xs),
                Text(
                  'Research companion for NGX investors',
                  style: t.bodyMedium?.copyWith(color: p.inkMuted),
                ),
                const SizedBox(height: Gap.lg),
                const HeavyRule(),
                const SizedBox(height: Gap.xl),
                Text(title, style: t.headlineSmall),
                if (lead != null) ...[
                  const SizedBox(height: Gap.sm),
                  Text(lead!, style: t.bodyMedium?.copyWith(color: p.inkMuted)),
                ],
                const SizedBox(height: Gap.xl),
                ...children,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A labelled text field using the app's input theme.
class AuthField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData? icon;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;
  final ValueChanged<String>? onSubmitted;
  final Iterable<String>? autofillHints;
  final TextCapitalization capitalization;
  final String? helper;

  const AuthField({
    super.key,
    required this.controller,
    required this.label,
    this.icon,
    this.keyboardType = TextInputType.text,
    this.textInputAction = TextInputAction.next,
    this.onSubmitted,
    this.autofillHints,
    this.capitalization = TextCapitalization.none,
    this.helper,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: Gap.md),
    child: TextField(
      controller: controller,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      onSubmitted: onSubmitted,
      autofillHints: autofillHints,
      textCapitalization: capitalization,
      autocorrect: false,
      style: context.text.bodyLarge,
      decoration: InputDecoration(
        labelText: label,
        helperText: helper,
        helperStyle: context.text.bodySmall,
        prefixIcon: icon == null ? null : Icon(icon, size: 20),
      ),
    ),
  );
}

/// Password field with a show/hide toggle.
class AuthPasswordField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final TextInputAction textInputAction;
  final ValueChanged<String>? onSubmitted;
  final Iterable<String>? autofillHints;
  final String? helper;

  const AuthPasswordField({
    super.key,
    required this.controller,
    required this.label,
    this.textInputAction = TextInputAction.next,
    this.onSubmitted,
    this.autofillHints,
    this.helper,
  });

  @override
  State<AuthPasswordField> createState() => _AuthPasswordFieldState();
}

class _AuthPasswordFieldState extends State<AuthPasswordField> {
  bool _visible = false;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: Gap.md),
    child: TextField(
      controller: widget.controller,
      obscureText: !_visible,
      textInputAction: widget.textInputAction,
      onSubmitted: widget.onSubmitted,
      autofillHints: widget.autofillHints,
      autocorrect: false,
      enableSuggestions: false,
      style: context.text.bodyLarge,
      decoration: InputDecoration(
        labelText: widget.label,
        helperText: widget.helper,
        helperStyle: context.text.bodySmall,
        prefixIcon: const Icon(Icons.lock_outline, size: 20),
        suffixIcon: IconButton(
          tooltip: _visible ? 'Hide password' : 'Show password',
          icon: Icon(
            _visible ? Icons.visibility_off_outlined : Icons.visibility_outlined,
            size: 20,
          ),
          onPressed: () => setState(() => _visible = !_visible),
        ),
      ),
    ),
  );
}

/// "Prompt  Link" line under a form, e.g. "Have an account?  Log in".
class AuthFooterLink extends StatelessWidget {
  final String prompt;
  final String label;
  final VoidCallback onTap;
  const AuthFooterLink({
    super.key,
    required this.prompt,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Wrap(
    alignment: WrapAlignment.center,
    crossAxisAlignment: WrapCrossAlignment.center,
    spacing: Gap.xs,
    children: [
      Text(prompt, style: context.text.bodyMedium?.copyWith(color: context.pal.inkMuted)),
      LinkText(label, arrow: false, onTap: onTap),
    ],
  );
}

/// Small print about the terms, kept on the auth screens.
class AuthTerms extends StatelessWidget {
  const AuthTerms({super.key});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: Gap.lg),
    child: Text(
      'By continuing you agree to the Terms of Service and Privacy Policy. '
      'HybStockAdvisor shows research, not financial advice, and does not place trades.',
      textAlign: TextAlign.center,
      style: context.text.bodySmall,
    ),
  );
}
