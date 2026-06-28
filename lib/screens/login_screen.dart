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
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _name.text.trim();
    final email = _email.text.trim();
    final password = _password.text;

    if (_isSignUp && name.length < 2) {
      setState(() => _error = 'Enter a display name (at least 2 characters).');
      return;
    }
    if (!email.contains('@') || !email.contains('.')) {
      setState(() => _error = 'Enter a valid email address.');
      return;
    }
    if (password.length < 6) {
      setState(() => _error = 'Password must be at least 6 characters.');
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      if (_isSignUp) {
        await _auth.signUp(email: email, password: password, name: name);
      } else {
        await _auth.logIn(email: email, password: password);
      }
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const RoomsListScreen()),
      );
    } catch (e) {
      setState(() => _error = AuthService.friendlyError(e));
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
                    decoration: const InputDecoration(
                      hintText: 'Display name (shown in debates)',
                      prefixIcon: Icon(Icons.person_outline),
                      counterText: '',
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                TextField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  autocorrect: false,
                  decoration: const InputDecoration(
                    hintText: 'Email',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _password,
                  obscureText: true,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _submit(),
                  decoration: const InputDecoration(
                    hintText: 'Password (6+ characters)',
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 10),
                  Text(_error!,
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
                const SizedBox(height: 8),
                TextButton(
                  onPressed: _busy
                      ? null
                      : () => setState(() {
                            _isSignUp = !_isSignUp;
                            _error = null;
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
