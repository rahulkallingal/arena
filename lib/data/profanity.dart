/// A basic list of vulgar / abusive words used to warn a user before they send
/// a message that could get them into trouble. This is intentionally a simple
/// client-side check — a warning, not censorship. It is not exhaustive.
const Set<String> _kProfanity = {
  'fuck', 'fucking', 'fucker', 'motherfucker', 'shit', 'bullshit', 'bitch',
  'bastard', 'asshole', 'arsehole', 'dick', 'dickhead', 'prick', 'cock',
  'pussy', 'cunt', 'slut', 'whore', 'wanker', 'twat', 'bollocks',
  'nigger', 'nigga', 'faggot', 'retard', 'rape', 'raping', 'rapist',
  'kill you', 'kill yourself', 'kys',
};

/// Returns the offending words/phrases found in [text] (empty if clean).
/// Matching is case-insensitive and whole-word for single words; multi-word
/// phrases (e.g. "kill you") are matched as substrings.
List<String> profanityIn(String text) {
  final lower = text.toLowerCase();
  // Split into word tokens for whole-word matching.
  final tokens = lower.split(RegExp(r"[^a-z']+")).where((w) => w.isNotEmpty).toSet();
  final hits = <String>{};
  for (final bad in _kProfanity) {
    if (bad.contains(' ')) {
      // Phrase — substring match.
      if (lower.contains(bad)) hits.add(bad);
    } else if (tokens.contains(bad)) {
      hits.add(bad);
    }
  }
  return hits.toList();
}

/// Whether [text] contains any flagged word.
bool hasProfanity(String text) => profanityIn(text).isNotEmpty;
