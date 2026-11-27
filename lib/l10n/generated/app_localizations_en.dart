// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get navTable => 'Table';

  @override
  String get navLibrary => 'Library';

  @override
  String get navGuide => 'Guide';

  @override
  String get appTitle => 'Arcana Observatory';

  @override
  String get language => 'Language';

  @override
  String get languageSaveError => 'Could not save the language preference.';

  @override
  String get readingTable => 'Reading table';

  @override
  String get tableHeading => 'The reading table';

  @override
  String get deckLibrary => 'Deck library';

  @override
  String get fieldGuide => 'Field guide';

  @override
  String get uprightReversed => 'Upright & reversed';

  @override
  String get uprightCards => 'Upright cards';

  @override
  String get beginReading => 'Begin reading';

  @override
  String get chooseDeck => 'Choose your deck';

  @override
  String get chooseSpread => 'Choose your spread';

  @override
  String get singleDescription =>
      'One card brings a single question into focus.';

  @override
  String get threeDescription =>
      'Read three positions together to explore how their meanings relate.';

  @override
  String get crossDescription =>
      'Explore a question in depth through ten connected positions.';

  @override
  String get includeReversals => 'Include reversed cards';

  @override
  String get reversalsHelp =>
      'A card can appear upside down with its own interpretation.';

  @override
  String get beginSpread => 'Begin this spread';

  @override
  String cardCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count cards',
      one: '1 card',
    );
    return '$_temp0';
  }

  @override
  String get chooseCard => 'Choose a card';

  @override
  String get turnCard => 'Turn your card';

  @override
  String positionCounter(int number, int total, String position) {
    return 'Position $number of $total · $position';
  }

  @override
  String get previousCards => 'Previous cards';

  @override
  String pageRange(int start, int end, int total) {
    return '$start–$end of $total';
  }

  @override
  String get nextCards => 'Next cards';

  @override
  String get revealCard => 'Reveal card';

  @override
  String get reversed => 'Reversed';

  @override
  String get upright => 'Upright';

  @override
  String get enlargeCard => 'Enlarge card';

  @override
  String get readingComplete => 'Reading complete';

  @override
  String get positionGuide => 'Position guide';

  @override
  String get lookAtImage => 'Look at the image';

  @override
  String get cardMeaning => 'Card meaning';

  @override
  String get readPosition => 'Read the position';

  @override
  String connectDetail(String card, String position) {
    return 'What detail in $card connects its meaning to “$position” in your reading?';
  }

  @override
  String get closingReflection => 'Closing reflection';

  @override
  String get smallAction =>
      'What is one small action this card invites you to try?';

  @override
  String get twoCards =>
      'Which two cards seem to speak to each other? Use their positions to explain the connection, then name one action to take.';

  @override
  String get newReading => 'New reading';

  @override
  String get returnToCard => 'Return to drawn card';

  @override
  String get chooseNext => 'Choose next card';

  @override
  String get drawFromDeck => 'Draw from the deck';

  @override
  String get beforeReveal => 'Before you reveal';

  @override
  String get chooseFaceDown =>
      'Select a face-down card from the shuffled deck for this position.';

  @override
  String get rememberQuestion =>
      'Hold the position’s question in mind, then turn the card to explore its imagery.';

  @override
  String get startAgain => 'Start again';

  @override
  String get spreadLayout => 'Spread layout';

  @override
  String drawCardNumber(int number) {
    return 'Draw card $number';
  }

  @override
  String drawFaceDownNumber(int number) {
    return 'Draw face-down card $number';
  }

  @override
  String get close => 'Close';

  @override
  String get resetZoom => 'Reset zoom';

  @override
  String get zoomIn => 'Zoom in';

  @override
  String get leaveReading => 'Leave this reading?';

  @override
  String get exitingClears => 'Exiting clears the cards on this table.';

  @override
  String get restartClears => 'Starting again clears the cards on this table.';

  @override
  String get keepReading => 'Keep reading';

  @override
  String get exitApp => 'Exit app';

  @override
  String get openingLibrary => 'Opening deck library';

  @override
  String get libraryOpenError => 'The deck library could not be opened.';

  @override
  String get tryAgain => 'Try again';

  @override
  String get symbolism => 'Symbolism';

  @override
  String get useDeck => 'Use this deck';

  @override
  String get cardGallery => 'Card gallery';

  @override
  String get previousPage => 'Previous page';

  @override
  String get nextPage => 'Next page';

  @override
  String get askQuestion => 'Ask a question';

  @override
  String get guideQuestion =>
      'Frame a question that leaves room for reflection. “What could help me approach this decision?” gives each card a role in exploring your choices.';

  @override
  String get noticePicture => 'Notice the picture';

  @override
  String get guidePicture =>
      'Name one visible detail before opening the meaning. Notice where a figure looks, what they carry, or how a repeated suit fills the card. In The Star, vessels pouring water can bring renewal to mind.';

  @override
  String get guidePosition =>
      'A spread gives each card a job. In the Past position, The Star might recall a time when hope returned. In the Present position, the same image can invite you to notice what sustains you today.';

  @override
  String get exploreReversal => 'Explore a reversal';

  @override
  String get guideReversal =>
      'Enable reversed cards to include upside-down draws. Compare the upright idea with the reversed interpretation. Consider whether the image suggests a delay, a private experience, or a different direction.';

  @override
  String get connectCards => 'Connect your cards';

  @override
  String get guideConnect =>
      'Read the cards in spread order. Look for a shared color, suit, gesture, or idea. Describe how that thread changes from one position to the next and name one small action you want to try.';

  @override
  String get softwareLicense => 'Software license';

  @override
  String get artworkCredits => 'Artwork credits';

  @override
  String get licenseOpenError => 'This license file could not be opened.';

  @override
  String get guideIntro =>
      'Learn to connect the imagery, position, and meaning of each card.';

  @override
  String get creditsLicenses => 'Credits & licenses';

  @override
  String get openSourceLibraries => 'Open-source libraries';

  @override
  String get oneCard => 'One card';

  @override
  String get threeCards => 'Past · Present · Future';

  @override
  String get celticCross => 'Celtic Cross';

  @override
  String get focus => 'Focus';

  @override
  String get focusPrompt =>
      'What detail in this card deserves your attention today?';

  @override
  String get past => 'Past';

  @override
  String get pastPrompt =>
      'How might this image describe an influence you bring from the past?';

  @override
  String get present => 'Present';

  @override
  String get presentPrompt =>
      'Where can you recognize this pattern in your situation now?';

  @override
  String get future => 'Future';

  @override
  String get futurePrompt =>
      'If this pattern continues, what possibility might open up?';

  @override
  String get situation => 'Situation';

  @override
  String get situationPrompt =>
      'What does this card suggest is at the heart of the matter?';

  @override
  String get crossing => 'Crossing';

  @override
  String get crossingPrompt =>
      'How could this energy challenge or support the situation?';

  @override
  String get above => 'Above';

  @override
  String get abovePrompt =>
      'What intention or aspiration does this image bring to mind?';

  @override
  String get foundation => 'Foundation';

  @override
  String get foundationPrompt =>
      'What underlying experience could be shaping the situation?';

  @override
  String get behind => 'Behind';

  @override
  String get behindPrompt => 'What influence might be receding into the past?';

  @override
  String get ahead => 'Ahead';

  @override
  String get aheadPrompt => 'What possibility appears to be approaching?';

  @override
  String get stance => 'Your stance';

  @override
  String get stancePrompt => 'Where do you see your own approach in this card?';

  @override
  String get surroundings => 'Surroundings';

  @override
  String get surroundingsPrompt =>
      'How might this pattern appear in the people or conditions around you?';

  @override
  String get hopesFears => 'Hopes and fears';

  @override
  String get hopesFearsPrompt =>
      'What wish or worry does this image bring to the surface?';

  @override
  String get outcome => 'Outcome';

  @override
  String get outcomePrompt =>
      'What direction does the spread suggest if the present pattern continues?';

  @override
  String majorLabel(String number) {
    return 'Major Arcana · $number';
  }

  @override
  String minorLabel(String suit, String rank) {
    return 'Minor Arcana · $suit · $rank';
  }

  @override
  String get unnumbered => 'Unnumbered';

  @override
  String courtLabel(String rank) {
    return '$rank (court)';
  }

  @override
  String get cups => 'Cups';

  @override
  String get swords => 'Swords';

  @override
  String get batons => 'Batons';

  @override
  String get wands => 'Wands';

  @override
  String get coins => 'Coins';

  @override
  String get pentacles => 'Pentacles';

  @override
  String get page => 'Page';

  @override
  String get knight => 'Knight';

  @override
  String get queen => 'Queen';

  @override
  String get king => 'King';

  @override
  String get majorLesson =>
      'Read this image as a turning point and ask what larger change its central figure or event might represent.';

  @override
  String get cupsLesson =>
      'A cup holds, offers or spills its contents, giving you a way to explore how feelings pass between people.';

  @override
  String get swordsLesson =>
      'Read the blade as a tool of judgment and ask what needs to be separated, questioned or decided.';

  @override
  String get wandsLesson =>
      'A staff can support a traveler or direct a movement, so look for where effort is being put to work.';

  @override
  String get coinsLesson =>
      'Read the disc as a resource and ask who holds, shares or cultivates something of practical value.';
}
