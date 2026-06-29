import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../theme.dart';
import 'rooms_list_screen.dart';

/// Sign up / log in with email + password. Toggles between the two modes.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _auth = AuthService();

  bool _isSignUp = true; // start on "create account"
  bool _busy = false;
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

  Future<void> _google() async {
    setState(() {
      _busy = true;
      _clearErrors();
    });
    try {
      final ok = await _auth.signInWithGoogle();
      if (!ok) {
        if (mounted) setState(() => _busy = false);
        return; // user cancelled
      }
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const RoomsListScreen()),
      );
    } catch (e) {
      setState(() => _generalError = AuthService.friendlyError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _submit() async {
    final name = _name.text.trim();
    final email = _email.text.trim();
    final password = _password.text;

    setState(_clearErrors);

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

    setState(() => _busy = true);
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
            content: Text('Verification email sent to $email — '
                'please check your inbox.'),
            duration: const Duration(seconds: 4),
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
      if (mounted) setState(() => _busy = false);
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
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _password,
                  obscureText: true,
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
                  ),
                ),
                if (_generalError != null) ...[
                  const SizedBox(height: 10),
                  Text(_generalError!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.primary)),
                ],
                const SizedBox(height: 18),
                ElevatedButton(
                  onPressed: _busy ? null : _submit,
                  child: _busy
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : Text(_isSignUp ? 'Create account' : 'Log in'),
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
                OutlinedButton.icon(
                  onPressed: _busy ? null : _google,
                  icon: const Text('G',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF4285F4))),
                  label: const Text('Continue with Google'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textDark,
                    minimumSize: const Size.fromHeight(48),
                    side: const BorderSide(color: AppColors.border),
                  ),
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
