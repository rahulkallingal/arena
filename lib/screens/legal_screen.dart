import 'package:flutter/material.dart';

import '../theme.dart';

/// Which legal document to show.
enum LegalDoc { terms, privacy }

/// A simple scrollable page that displays the Terms of Service or Privacy
/// Policy. These are general starter documents, not legal advice.
class LegalScreen extends StatelessWidget {
  final LegalDoc doc;
  const LegalScreen({super.key, required this.doc});

  @override
  Widget build(BuildContext context) {
    final isTerms = doc == LegalDoc.terms;
    return Scaffold(
      appBar: AppBar(
        title: Text(isTerms ? 'Terms of Service' : 'Privacy Policy'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Text(
          isTerms ? _termsText : _privacyText,
          style: const TextStyle(
              fontSize: 14, height: 1.5, color: AppColors.textDark),
        ),
      ),
    );
  }
}

const String _termsText = '''
ARENA — TERMS OF SERVICE
Last updated: June 2026

Welcome to Arena, a community app for friendly debate. By creating an account
or using Arena, you agree to these Terms. If you do not agree, please do not
use the app.

1. WHO CAN USE ARENA
You must be at least 13 years old (or the minimum age required in your country)
to use Arena. By using it you confirm you meet this requirement.

2. YOUR ACCOUNT
You are responsible for keeping your login details safe and for all activity on
your account. Provide accurate information when you sign up.

3. WHAT ARENA IS
Arena lets you create and join debate rooms and post messages ("arguments").
Messages you post are visible to other users in that room.

4. ACCEPTABLE USE
You agree NOT to post or do anything that:
  • is hateful, harassing, threatening, or bullying;
  • is illegal, defamatory, or infringes someone else's rights;
  • is sexually explicit, violent, or otherwise harmful;
  • impersonates another person or misrepresents who you are;
  • is spam, advertising, or a scam;
  • attempts to hack, disrupt, or misuse the service.
Debate the idea, not the person. Be respectful.

5. YOUR CONTENT
You keep ownership of what you post. By posting, you grant Arena a licence to
store and display your content so the app can work. You are responsible for
what you post and confirm you have the right to post it.

6. MODERATION
We (and other users, via reporting/blocking) may review content. We may remove
content or suspend or remove accounts that break these Terms, at our discretion,
to keep the community safe.

7. NO WARRANTY
Arena is provided "as is", without warranties of any kind. We do not guarantee
the app will always be available, error-free, or that content posted by others
is accurate or appropriate.

8. LIMITATION OF LIABILITY
To the maximum extent allowed by law, Arena and its creator are not liable for
any indirect or consequential loss arising from your use of the app, or from
content posted by other users.

9. CHANGES
We may update these Terms. Continued use after changes means you accept the
updated Terms.

10. CONTACT
Questions? Contact us at cryptork97@gmail.com.
''';

const String _privacyText = '''
ARENA — PRIVACY POLICY
Last updated: June 2026

This policy explains what information Arena collects and how we use it.

1. WHAT WE COLLECT
  • Account info: your email address and the display name you choose.
  • Content you create: debate rooms and messages you post.
  • Basic technical data needed to run the app (e.g. sign-in tokens).

2. HOW WE USE IT
  • To create and secure your account.
  • To show your debates and messages to you and other users.
  • To keep your data available when you sign in on another device.
  • To keep the community safe (e.g. handling reports).

3. WHAT OTHER USERS SEE
Your display name and the messages you post in a room are visible to other
users of that room. Please don't share private information in messages.

4. WHERE YOUR DATA IS STORED
Arena uses Google Firebase (Authentication and Firestore) to store your account
and content. Your data is held on Google's secure cloud infrastructure.

5. SHARING
We do NOT sell your personal data. We share data only with the service
providers that run the app (Google/Firebase), or if required by law.

6. DATA RETENTION & DELETION
Your data is kept while your account is active. You can ask us to delete your
account and associated data by emailing cryptork97@gmail.com.

7. CHILDREN
Arena is not intended for children under 13. We do not knowingly collect data
from children under 13.

8. SECURITY
We rely on Google Firebase's security to protect your data. No system is 100%
secure, but we take reasonable steps to keep your information safe.

9. CHANGES
We may update this policy. We'll update the "last updated" date above when we do.

10. CONTACT
Questions about your privacy? Contact us at cryptork97@gmail.com.
''';
