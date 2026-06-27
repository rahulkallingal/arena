/// A curated pool of debate "topics of the day".
///
/// Each is phrased as an open QUESTION ("debate this"), never as a stated fact,
/// so Arena never looks like it's pushing a claim as true — just inviting an
/// argument. The app picks one per calendar day (see DailyTopicService).
class DailyTopic {
  final String topic;
  final String category;
  const DailyTopic(this.topic, this.category);
}

const List<DailyTopic> kDailyTopics = [
  // Science
  DailyTopic('Are we alone in the universe?', 'Science'),
  DailyTopic('Could we be living inside a computer simulation?', 'Science'),
  DailyTopic('Should humans try to colonise Mars?', 'Science'),
  DailyTopic('Does free will actually exist, or is everything predetermined?',
      'Science'),
  DailyTopic('Is nuclear power the cleanest energy we have?', 'Science'),
  DailyTopic('Should we bring extinct species back to life?', 'Science'),
  DailyTopic('Could time travel ever really work?', 'Science'),
  DailyTopic('Has space exploration been worth the money?', 'Science'),

  // Religion & Philosophy
  DailyTopic('Can morality exist without religion?', 'Religion'),
  DailyTopic('Are science and faith fundamentally incompatible?', 'Religion'),
  DailyTopic('Is there a purpose to the universe?', 'Religion'),
  DailyTopic('Should religion be taught in public schools?', 'Religion'),
  DailyTopic('Do humans have something like a soul?', 'Religion'),

  // Movies & Pop culture
  DailyTopic('Is the MCU actually better than the DCEU?', 'Movies'),
  DailyTopic('Was the top still spinning at the end of Inception?', 'Movies'),
  DailyTopic('Are endless remakes ruining cinema?', 'Movies'),
  DailyTopic('Is the book always better than the movie?', 'Movies'),
  DailyTopic('Should AI be allowed to write movie scripts?', 'Movies'),
  DailyTopic('Is Christopher Nolan overrated?', 'Movies'),

  // Politics & Society
  DailyTopic('Should voting be made mandatory?', 'Politics'),
  DailyTopic('Is a four-day work week the future?', 'Politics'),
  DailyTopic('Should the voting age be lowered to 16?', 'Politics'),
  DailyTopic('Should there be a maximum wage as well as a minimum one?',
      'Politics'),
  DailyTopic('Does money buy happiness?', 'Politics'),

  // Technology
  DailyTopic('Will AI do more good than harm?', 'Technology'),
  DailyTopic('Should under-16s be banned from social media?', 'Technology'),
  DailyTopic('Is online privacy already dead?', 'Technology'),
  DailyTopic('Will self-driving cars actually make roads safer?', 'Technology'),
  DailyTopic('Is social media doing more harm than good?', 'Technology'),
  DailyTopic('Should there be a tax on companies that replace workers with AI?',
      'Technology'),

  // Sports
  DailyTopic('Messi or Ronaldo — who is the real GOAT?', 'Sports'),
  DailyTopic('Is VAR ruining football?', 'Sports'),
  DailyTopic('Should esports count as a real sport?', 'Sports'),
  DailyTopic('Is natural talent or hard work more important in sport?',
      'Sports'),

  // History
  DailyTopic('Was the Industrial Revolution good for humanity?', 'History'),
  DailyTopic('Do great individuals shape history, or does history shape them?',
      'History'),
  DailyTopic('Could the Great Pyramids have been built without modern tools?',
      'History'),
  DailyTopic('Was the printing press the most important invention ever?',
      'History'),

  // Just for fun
  DailyTopic('Is a hot dog a sandwich?', 'Other'),
  DailyTopic('Should pineapple be allowed on pizza?', 'Other'),
  DailyTopic('Is cereal a soup?', 'Other'),
  DailyTopic('Is water actually wet?', 'Other'),
  DailyTopic(
      'One horse-sized duck or a hundred duck-sized horses — which do you fight?',
      'Other'),
  DailyTopic('Does the pour go milk-first or cereal-first?', 'Other'),
];
