import 'dart:async';

import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../theme.dart';
import 'login_screen.dart';
import 'rooms_list_screen.dart';

/// Shown to an email/password user who hasn't verified their email yet. They
/// cannot enter Arena until they click the link in their inbox — this proves the
/// email is real and belongs to them, which keeps fake/throwaway accounts (and
/// easy ban-evasion) out. Google sign-in users skip this (already verified).
class VerifyEmailScreen extends StatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen>
    with WidgetsBindingObserver {
  final _auth = AuthService();
  bool _checking = false;
  bool _resending = false;
  String? _message;
  Timer? _poll;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Quietly re-check every few seconds so that once they tap the link in their
    // email, the app moves on by itself without them having to press anything.
    _poll = Timer.periodic(
        const Duration(seconds: 4), (_) => _check(silent: true));
  }

  @override
  void dispose() {
    _poll?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // They likely just came back from their email app — re-check immediately.
    if (state == AppLifecycleState.resumed) _check(silent: true);
  }

  /// Reloads the account from the server and, if the email is now verified,
  /// moves on to the rooms list. [silent] hides the "not yet" message so the
  /// background poll doesn't nag.
  Future<void> _check({bool silent = false}) async {
    if (_checking) return;
    if (!silent) setState(() => _checking = true);
    try {
      await _auth.reloadUser();
    } catch (_) {/* offline — ignore */}
    if (!mounted) return;
    if (_auth.isEmailVerified) {
      _poll?.cancel();
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const RoomsListScreen()),
      );
      return;
    }
    if (!silent) {
      setState(() {
        _checking = false;
        _message = "Not verified yet — open the link in your email, then try "
            "again. Check your spam/junk folder too.";
      });
    }
  }

  Future<void> _resend() async {
    setState(() {
      _resending = true;
      _message = null;
    });
    try {
      await _auth.sendEmailVerification();
      _message = 'Verification email sent again — check your inbox and '
          'spam/junk folder.';
    } catch (_) {
      _message = 'Could not send the email right now. Try again in a moment.';
    } finally {
      if (mounted) setState(() => _resending = false);
    }
  }

  Future<void> _useAnotherAccount() async {
    await _auth.signOut();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final email = _auth.email ?? 'your email';
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('📧', style: TextStyle(fontSize: 64)),
                const SizedBox(height: 12),
                const Text(
                  'Verify your email',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 12),
                Text.rich(
                  TextSpan(
                    style: const TextStyle(
                        fontSize: 15, color: AppColors.textGrey, height: 1.4),
                    children: [
                      const TextSpan(
                          text: 'We sent a verification link to\n'),
                      TextSpan(
                        text: email,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark),
                      ),
                      const TextSpan(
                          text:
                              '.\n\nOpen it, tap the link, then come back here. '
                              'This app will continue on its own once you do.'),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
                if (_message != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    _message!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color: AppColors.secondary, fontSize: 13),
                  ),
                ],
                const SizedBox(height: 28),
                ElevatedButton(
                  onPressed: _checking ? null : () => _check(),
                  child: _checking
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Text("I've verified — continue"),
                ),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: _resending ? null : _resend,
                  child: Text(
                      _resending ? 'Sending…' : 'Resend verification email'),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: _useAnotherAccount,
                  child: const Text('Log out / use another account',
                      style: TextStyle(color: AppColors.textGrey)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
