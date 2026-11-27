class SpreadPosition {
  const SpreadPosition(this.title, this.prompt);
  final String title;
  final String prompt;
}

enum SpreadType {
  one('One card', [
    SpreadPosition(
      'Focus',
      'What detail in this card deserves your attention today?',
    ),
  ]),
  three('Past · Present · Future', [
    SpreadPosition(
      'Past',
      'How might this image describe an influence you bring from the past?',
    ),
    SpreadPosition(
      'Present',
      'Where can you recognize this pattern in your situation now?',
    ),
    SpreadPosition(
      'Future',
      'If this pattern continues, what possibility might open up?',
    ),
  ]),
  celticCross('Celtic Cross', [
    SpreadPosition(
      'Situation',
      'What does this card suggest is at the heart of the matter?',
    ),
    SpreadPosition(
      'Crossing',
      'How could this energy challenge or support the situation?',
    ),
    SpreadPosition(
      'Above',
      'What intention or aspiration does this image bring to mind?',
    ),
    SpreadPosition(
      'Foundation',
      'What underlying experience could be shaping the situation?',
    ),
    SpreadPosition('Behind', 'What influence might be receding into the past?'),
    SpreadPosition('Ahead', 'What possibility appears to be approaching?'),
    SpreadPosition(
      'Your stance',
      'Where do you see your own approach in this card?',
    ),
    SpreadPosition(
      'Surroundings',
      'How might this pattern appear in the people or conditions around you?',
    ),
    SpreadPosition(
      'Hopes and fears',
      'What wish or worry does this image bring to the surface?',
    ),
    SpreadPosition(
      'Outcome',
      'What direction does the spread suggest if the present pattern continues?',
    ),
  ]);

  const SpreadType(this.title, this.positions);
  final String title;
  final List<SpreadPosition> positions;
}
