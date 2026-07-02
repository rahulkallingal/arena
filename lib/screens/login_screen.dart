import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../theme.dart';
import 'legal_screen.dart';
import 'rooms_list_screen.dart';

/// Sign up / log in with email + password. Toggles between the two modes.
class LoginScreen extends StatefulWidget {
  /// Whether to open on the "Create account" view. After logout we pass false so
  /// returning users land on the Log in form.
  final bool startInSignUp;
  const LoginScreen({super.key, this.startInSignUp = true});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _auth = AuthService();

  late bool _isSignUp = widget.startInSignUp;
  bool _submitting = false; // email create/login in progress
  bool _googling = false; // Google sign-in in progress
  bool get _busy => _submitting || _googling; // either action running
  bool _agreed = false; // ticked the Terms & Privacy checkbox
  bool _obscure = true; // hide the password characters (toggle with the eye)

  // DEV-ONLY admin quick-login. These come from --dart-define at build time, so
  // they are NOT in the source code and are EMPTY (button hidden, nothing
  // compiled in) unless a build explicitly passes them. Public/Play Store builds
  // are made WITHOUT these defines, so this never ships. See ADMIN_LOGIN note.
  static const _adminEmail = String.fromEnvironment('ADMIN_EMAIL');
  static const _adminPassword = String.fromEnvironment('ADMIN_PASSWORD');
  bool get _adminEnabled =>
      _adminEmail.isNotEmpty && _adminPassword.isNotEmpty;
  String? _generalError;
  String? _emailError;
  String? _passwordError;
  String? _nameError;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _clearErrors() {
    _generalError = null;
    _emailError = null;
    _passwordError = null;
    _nameError = null;
  }

  /// DEV-ONLY: signs in instantly with the admin account baked in at build time.
  Future<void> _adminLogin() async {
    setState(() {
      _submitting = true;
      _clearErrors();
    });
    try {
      await _auth.logIn(email: _adminEmail, password: _adminPassword);
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const RoomsListScreen()),
      );
    } catch (e) {
      setState(() => _generalError = AuthService.friendlyError(e));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  /// Emails a password-reset link to whatever is typed in the email field.
  Future<void> _forgotPassword() async {
    final email = _email.text.trim();
    setState(_clearErrors);
    if (!email.contains('@') || !email.contains('.')) {
      setState(() => _emailError =
          'Enter your email above first, then tap "Forgot password".');
      return;
    }
    setState(() => _submitting = true);
    try {
      await _auth.sendPasswordReset(email);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password reset email sent — check your inbox and '
              'spam/junk folder.'),
          duration: Duration(seconds: 6),
        ),
      );
    } catch (e) {
      setState(() => _generalError = AuthService.friendlyError(e));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _google() async {
    // Terms only need to be accepted when creating a new account, not on login.
    if (_isSignUp && !_agreed) {
      setState(() => _generalError =
          'Please accept the Terms of Service and Privacy Policy first.');
      return;
    }
    setState(() {
      _googling = true;
      _clearErrors();
    });
    try {
      final ok = await _auth.signInWithGoogle();
      if (!ok) {
        if (mounted) setState(() => _googling = false);
        return; // user cancelled
      }
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const RoomsListScreen()),
      );
    } catch (e) {
      setState(() => _generalError = AuthService.friendlyError(e));
    } finally {
      if (mounted) setState(() => _googling = false);
    }
  }

  Future<void> _submit() async {
    final name = _name.text.trim();
    final email = _email.text.trim();
    final password = _password.text;

    setState(_clearErrors);

    if (_isSignUp && !_agreed) {
      setState(() => _generalError =
          'Please accept the Terms of Service and Privacy Policy first.');
      return;
    }

    // Client-side validation, highlighting the specific field.
    if (_isSignUp && name.length < 2) {
      setState(() => _nameError = 'Enter a display name (2+ characters).');
      return;
    }
    if (!email.contains('@') || !email.contains('.')) {
      setState(() => _emailError = 'Incorrect email address.');
      return;
    }
    if (password.length < 6) {
      setState(() => _passwordError = 'Password must be at least 6 characters.');
      return;
    }

    setState(() => _submitting = true);
    try {
      if (_isSignUp) {
        await _auth.signUp(email: email, password: password, name: name);
      } else {
        await _auth.logIn(email: email, password: password);
      }
      if (!mounted) return;
      if (_isSignUp) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Verification email sent to $email — check your '
                'inbox AND your spam/junk folder.'),
            duration: const Duration(seconds: 6),
          ),
        );
      }
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const RoomsListScreen()),
      );
    } catch (e) {
      // Highlight the field the error belongs to (email vs password).
      final err = AuthService.classifyError(e);
      setState(() {
        switch (err.field) {
          case AuthField.email:
            _emailError = err.message;
            break;
          case AuthField.password:
            _passwordError = err.message;
            break;
          case AuthField.general:
            _generalError = err.message;
            break;
        }
      });
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('🔥', style: TextStyle(fontSize: 64)),
                const SizedBox(height: 12),
                const Text(
                  'Welcome to Arena',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _isSignUp
                      ? 'Create an account to start debating.'
                      : 'Log back in to your account.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 15, color: AppColors.textGrey),
                ),
                const SizedBox(height: 28),
                if (_isSignUp) ...[
                  TextField(
                    controller: _name,
                    textInputAction: TextInputAction.next,
                    textCapitalization: TextCapitalization.words,
                    maxLength: 20,
                    onChanged: (_) {
                      if (_nameError != null) setState(() => _nameError = null);
                    },
                    decoration: InputDecoration(
                      hintText: 'Display name (shown in debates)',
                      prefixIcon: const Icon(Icons.person_outline),
                      counterText: '',
                      errorText: _nameError,
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                TextField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  autocorrect: false,
                  onChanged: (_) {
                    if (_emailError != null) setState(() => _emailError = null);
                  },
                  decoration: InputDecoration(
                    hintText: 'Email',
                    prefixIcon: const Icon(Icons.email_outlined),
                    errorText: _emailError,
                    // Let long messages (e.g. "account already exists…") show in
                    // full instead of being cut off with an ellipsis.
                    errorMaxLines: 3,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _password,
                  obscureText: _obscure,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _submit(),
                  onChanged: (_) {
                    if (_passwordError != null) {
                      setState(() => _passwordError = null);
                    }
                  },
                  decoration: InputDecoration(
                    hintText: 'Password (6+ characters)',
                    prefixIcon: const Icon(Icons.lock_outline),
                    errorText: _passwordError,
                    errorMaxLines: 3,
                    // Tap the eye to show/hide the password so you can check for
                    // typos.
                    suffixIcon: IconButton(
                      icon: Icon(_obscure
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined),
                      tooltip: _obscure ? 'Show password' : 'Hide password',
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                ),
                // "Forgot password?" only makes sense when logging in.
                if (!_isSignUp)
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _busy ? null : _forgotPassword,
                      child: const Text('Forgot password?',
                          style: TextStyle(color: AppColors.secondary)),
                    ),
                  ),
                if (_generalError != null) ...[
                  const SizedBox(height: 10),
                  Text(_generalError!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.primary)),
                ],
                // The Terms & Privacy agreement is only shown (and required)
                // when creating a new account — not when logging back in.
                if (_isSignUp) ...[
                  const SizedBox(height: 14),
                  _AgreementCheckbox(
                    value: _agreed,
                    onChanged: (v) => setState(() => _agreed = v ?? false),
                  ),
                ],
                const SizedBox(height: 14),
                // Both sign-in options sit BELOW the Terms checkbox (which gates
                // them) and ABOVE nothing else — Google is not left after the
                // Create-account button.
                OutlinedButton.icon(
                  onPressed:
                      _busy || (_isSignUp && !_agreed) ? null : _google,
                  icon: _googling
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('G',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF4285F4))),
                  label:
                      Text(_googling ? 'Please wait…' : 'Continue with Google'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textDark,
                    minimumSize: const Size.fromHeight(48),
                    side: const BorderSide(color: AppColors.border),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: const [
                    Expanded(child: Divider()),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Text('or', style: TextStyle(color: AppColors.textGrey)),
                    ),
                    Expanded(child: Divider()),
                  ],
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _busy || (_isSignUp && !_agreed) ? null : _submit,
                  child: _submitting
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : Text(_isSignUp ? 'Create account' : 'Log in'),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: _busy
                      ? null
                      : () => setState(() {
                            _isSignUp = !_isSignUp;
                            _clearErrors();
                          }),
                  child: Text(
                    _isSignUp
                        ? 'Already have an account? Log in'
                        : 'New here? Create an account',
                    style: const TextStyle(color: AppColors.secondary),
                  ),
                ),
                // DEV-ONLY: appears only when this build was made with the admin
                // credentials (--dart-define). Never present in public builds.
                if (_adminEnabled) ...[
                  const SizedBox(height: 4),
                  TextButton.icon(
                    onPressed: _busy ? null : _adminLogin,
                    icon: const Icon(Icons.bolt, size: 18),
                    label: const Text('Admin quick login (dev)'),
                    style: TextButton.styleFrom(
                        foregroundColor: AppColors.textGrey),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Checkbox + tappable Terms / Privacy links shown above the auth buttons.
class _AgreementCheckbox extends StatelessWidget {
  final bool value;
  final ValueChanged<bool?> onChanged;
  const _AgreementCheckbox({required this.value, required this.onChanged});

  void _open(BuildContext context, LegalDoc doc) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => LegalScreen(doc: doc)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 28,
          height: 28,
          child: Checkbox(
            value: value,
            onChanged: onChanged,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text.rich(
              TextSpan(
                style: const TextStyle(
                    fontSize: 13, color: AppColors.textGrey, height: 1.4),
                children: [
                  const TextSpan(text: 'I agree to the '),
                  WidgetSpan(
                    alignment: PlaceholderAlignment.middle,
                    child: GestureDetector(
                      onTap: () => _open(context, LegalDoc.terms),
                      child: const Text('Terms of Service',
                          style: TextStyle(
                              fontSize: 13,
                              color: AppColors.secondary,
                              fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const TextSpan(text: ' and '),
                  WidgetSpan(
                    alignment: PlaceholderAlignment.middle,
                    child: GestureDetector(
                      onTap: () => _open(context, LegalDoc.privacy),
                      child: const Text('Privacy Policy',
                          style: TextStyle(
                              fontSize: 13,
                              color: AppColors.secondary,
                              fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const TextSpan(text: '.'),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
