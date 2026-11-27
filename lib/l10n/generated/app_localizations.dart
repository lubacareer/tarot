import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_he.dart';
import 'app_localizations_ru.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('he'),
    Locale('ru'),
  ];

  /// No description provided for @navTable.
  ///
  /// In en, this message translates to:
  /// **'Table'**
  String get navTable;

  /// No description provided for @navLibrary.
  ///
  /// In en, this message translates to:
  /// **'Library'**
  String get navLibrary;

  /// No description provided for @navGuide.
  ///
  /// In en, this message translates to:
  /// **'Guide'**
  String get navGuide;

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Arcana Observatory'**
  String get appTitle;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @languageSaveError.
  ///
  /// In en, this message translates to:
  /// **'Could not save the language preference.'**
  String get languageSaveError;

  /// No description provided for @readingTable.
  ///
  /// In en, this message translates to:
  /// **'Reading table'**
  String get readingTable;

  /// No description provided for @tableHeading.
  ///
  /// In en, this message translates to:
  /// **'The reading table'**
  String get tableHeading;

  /// No description provided for @deckLibrary.
  ///
  /// In en, this message translates to:
  /// **'Deck library'**
  String get deckLibrary;

  /// No description provided for @fieldGuide.
  ///
  /// In en, this message translates to:
  /// **'Field guide'**
  String get fieldGuide;

  /// No description provided for @uprightReversed.
  ///
  /// In en, this message translates to:
  /// **'Upright & reversed'**
  String get uprightReversed;

  /// No description provided for @uprightCards.
  ///
  /// In en, this message translates to:
  /// **'Upright cards'**
  String get uprightCards;

  /// No description provided for @beginReading.
  ///
  /// In en, this message translates to:
  /// **'Begin reading'**
  String get beginReading;

  /// No description provided for @chooseDeck.
  ///
  /// In en, this message translates to:
  /// **'Choose your deck'**
  String get chooseDeck;

  /// No description provided for @chooseSpread.
  ///
  /// In en, this message translates to:
  /// **'Choose your spread'**
  String get chooseSpread;

  /// No description provided for @singleDescription.
  ///
  /// In en, this message translates to:
  /// **'One card brings a single question into focus.'**
  String get singleDescription;

  /// No description provided for @threeDescription.
  ///
  /// In en, this message translates to:
  /// **'Read three positions together to explore how their meanings relate.'**
  String get threeDescription;

  /// No description provided for @crossDescription.
  ///
  /// In en, this message translates to:
  /// **'Explore a question in depth through ten connected positions.'**
  String get crossDescription;

  /// No description provided for @includeReversals.
  ///
  /// In en, this message translates to:
  /// **'Include reversed cards'**
  String get includeReversals;

  /// No description provided for @reversalsHelp.
  ///
  /// In en, this message translates to:
  /// **'A card can appear upside down with its own interpretation.'**
  String get reversalsHelp;

  /// No description provided for @beginSpread.
  ///
  /// In en, this message translates to:
  /// **'Begin this spread'**
  String get beginSpread;

  /// No description provided for @cardCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{1 card} other{{count} cards}}'**
  String cardCount(int count);

  /// No description provided for @chooseCard.
  ///
  /// In en, this message translates to:
  /// **'Choose a card'**
  String get chooseCard;

  /// No description provided for @turnCard.
  ///
  /// In en, this message translates to:
  /// **'Turn your card'**
  String get turnCard;

  /// No description provided for @positionCounter.
  ///
  /// In en, this message translates to:
  /// **'Position {number} of {total} · {position}'**
  String positionCounter(int number, int total, String position);

  /// No description provided for @previousCards.
  ///
  /// In en, this message translates to:
  /// **'Previous cards'**
  String get previousCards;

  /// No description provided for @pageRange.
  ///
  /// In en, this message translates to:
  /// **'{start}–{end} of {total}'**
  String pageRange(int start, int end, int total);

  /// No description provided for @nextCards.
  ///
  /// In en, this message translates to:
  /// **'Next cards'**
  String get nextCards;

  /// No description provided for @revealCard.
  ///
  /// In en, this message translates to:
  /// **'Reveal card'**
  String get revealCard;

  /// No description provided for @reversed.
  ///
  /// In en, this message translates to:
  /// **'Reversed'**
  String get reversed;

  /// No description provided for @upright.
  ///
  /// In en, this message translates to:
  /// **'Upright'**
  String get upright;

  /// No description provided for @enlargeCard.
  ///
  /// In en, this message translates to:
  /// **'Enlarge card'**
  String get enlargeCard;

  /// No description provided for @readingComplete.
  ///
  /// In en, this message translates to:
  /// **'Reading complete'**
  String get readingComplete;

  /// No description provided for @positionGuide.
  ///
  /// In en, this message translates to:
  /// **'Position guide'**
  String get positionGuide;

  /// No description provided for @lookAtImage.
  ///
  /// In en, this message translates to:
  /// **'Look at the image'**
  String get lookAtImage;

  /// No description provided for @cardMeaning.
  ///
  /// In en, this message translates to:
  /// **'Card meaning'**
  String get cardMeaning;

  /// No description provided for @readPosition.
  ///
  /// In en, this message translates to:
  /// **'Read the position'**
  String get readPosition;

  /// No description provided for @connectDetail.
  ///
  /// In en, this message translates to:
  /// **'What detail in {card} connects its meaning to “{position}” in your reading?'**
  String connectDetail(String card, String position);

  /// No description provided for @closingReflection.
  ///
  /// In en, this message translates to:
  /// **'Closing reflection'**
  String get closingReflection;

  /// No description provided for @smallAction.
  ///
  /// In en, this message translates to:
  /// **'What is one small action this card invites you to try?'**
  String get smallAction;

  /// No description provided for @twoCards.
  ///
  /// In en, this message translates to:
  /// **'Which two cards seem to speak to each other? Use their positions to explain the connection, then name one action to take.'**
  String get twoCards;

  /// No description provided for @newReading.
  ///
  /// In en, this message translates to:
  /// **'New reading'**
  String get newReading;

  /// No description provided for @returnToCard.
  ///
  /// In en, this message translates to:
  /// **'Return to drawn card'**
  String get returnToCard;

  /// No description provided for @chooseNext.
  ///
  /// In en, this message translates to:
  /// **'Choose next card'**
  String get chooseNext;

  /// No description provided for @drawFromDeck.
  ///
  /// In en, this message translates to:
  /// **'Draw from the deck'**
  String get drawFromDeck;

  /// No description provided for @beforeReveal.
  ///
  /// In en, this message translates to:
  /// **'Before you reveal'**
  String get beforeReveal;

  /// No description provided for @chooseFaceDown.
  ///
  /// In en, this message translates to:
  /// **'Select a face-down card from the shuffled deck for this position.'**
  String get chooseFaceDown;

  /// No description provided for @rememberQuestion.
  ///
  /// In en, this message translates to:
  /// **'Hold the position’s question in mind, then turn the card to explore its imagery.'**
  String get rememberQuestion;

  /// No description provided for @startAgain.
  ///
  /// In en, this message translates to:
  /// **'Start again'**
  String get startAgain;

  /// No description provided for @spreadLayout.
  ///
  /// In en, this message translates to:
  /// **'Spread layout'**
  String get spreadLayout;

  /// No description provided for @drawCardNumber.
  ///
  /// In en, this message translates to:
  /// **'Draw card {number}'**
  String drawCardNumber(int number);

  /// No description provided for @drawFaceDownNumber.
  ///
  /// In en, this message translates to:
  /// **'Draw face-down card {number}'**
  String drawFaceDownNumber(int number);

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @resetZoom.
  ///
  /// In en, this message translates to:
  /// **'Reset zoom'**
  String get resetZoom;

  /// No description provided for @zoomIn.
  ///
  /// In en, this message translates to:
  /// **'Zoom in'**
  String get zoomIn;

  /// No description provided for @leaveReading.
  ///
  /// In en, this message translates to:
  /// **'Leave this reading?'**
  String get leaveReading;

  /// No description provided for @exitingClears.
  ///
  /// In en, this message translates to:
  /// **'Exiting clears the cards on this table.'**
  String get exitingClears;

  /// No description provided for @restartClears.
  ///
  /// In en, this message translates to:
  /// **'Starting again clears the cards on this table.'**
  String get restartClears;

  /// No description provided for @keepReading.
  ///
  /// In en, this message translates to:
  /// **'Keep reading'**
  String get keepReading;

  /// No description provided for @exitApp.
  ///
  /// In en, this message translates to:
  /// **'Exit app'**
  String get exitApp;

  /// No description provided for @openingLibrary.
  ///
  /// In en, this message translates to:
  /// **'Opening deck library'**
  String get openingLibrary;

  /// No description provided for @libraryOpenError.
  ///
  /// In en, this message translates to:
  /// **'The deck library could not be opened.'**
  String get libraryOpenError;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get tryAgain;

  /// No description provided for @symbolism.
  ///
  /// In en, this message translates to:
  /// **'Symbolism'**
  String get symbolism;

  /// No description provided for @useDeck.
  ///
  /// In en, this message translates to:
  /// **'Use this deck'**
  String get useDeck;

  /// No description provided for @cardGallery.
  ///
  /// In en, this message translates to:
  /// **'Card gallery'**
  String get cardGallery;

  /// No description provided for @previousPage.
  ///
  /// In en, this message translates to:
  /// **'Previous page'**
  String get previousPage;

  /// No description provided for @nextPage.
  ///
  /// In en, this message translates to:
  /// **'Next page'**
  String get nextPage;

  /// No description provided for @askQuestion.
  ///
  /// In en, this message translates to:
  /// **'Ask a question'**
  String get askQuestion;

  /// No description provided for @guideQuestion.
  ///
  /// In en, this message translates to:
  /// **'Frame a question that leaves room for reflection. “What could help me approach this decision?” gives each card a role in exploring your choices.'**
  String get guideQuestion;

  /// No description provided for @noticePicture.
  ///
  /// In en, this message translates to:
  /// **'Notice the picture'**
  String get noticePicture;

  /// No description provided for @guidePicture.
  ///
  /// In en, this message translates to:
  /// **'Name one visible detail before opening the meaning. Notice where a figure looks, what they carry, or how a repeated suit fills the card. In The Star, vessels pouring water can bring renewal to mind.'**
  String get guidePicture;

  /// No description provided for @guidePosition.
  ///
  /// In en, this message translates to:
  /// **'A spread gives each card a job. In the Past position, The Star might recall a time when hope returned. In the Present position, the same image can invite you to notice what sustains you today.'**
  String get guidePosition;

  /// No description provided for @exploreReversal.
  ///
  /// In en, this message translates to:
  /// **'Explore a reversal'**
  String get exploreReversal;

  /// No description provided for @guideReversal.
  ///
  /// In en, this message translates to:
  /// **'Enable reversed cards to include upside-down draws. Compare the upright idea with the reversed interpretation. Consider whether the image suggests a delay, a private experience, or a different direction.'**
  String get guideReversal;

  /// No description provided for @connectCards.
  ///
  /// In en, this message translates to:
  /// **'Connect your cards'**
  String get connectCards;

  /// No description provided for @guideConnect.
  ///
  /// In en, this message translates to:
  /// **'Read the cards in spread order. Look for a shared color, suit, gesture, or idea. Describe how that thread changes from one position to the next and name one small action you want to try.'**
  String get guideConnect;

  /// No description provided for @softwareLicense.
  ///
  /// In en, this message translates to:
  /// **'Software license'**
  String get softwareLicense;

  /// No description provided for @artworkCredits.
  ///
  /// In en, this message translates to:
  /// **'Artwork credits'**
  String get artworkCredits;

  /// No description provided for @licenseOpenError.
  ///
  /// In en, this message translates to:
  /// **'This license file could not be opened.'**
  String get licenseOpenError;

  /// No description provided for @guideIntro.
  ///
  /// In en, this message translates to:
  /// **'Learn to connect the imagery, position, and meaning of each card.'**
  String get guideIntro;

  /// No description provided for @creditsLicenses.
  ///
  /// In en, this message translates to:
  /// **'Credits & licenses'**
  String get creditsLicenses;

  /// No description provided for @openSourceLibraries.
  ///
  /// In en, this message translates to:
  /// **'Open-source libraries'**
  String get openSourceLibraries;

  /// No description provided for @oneCard.
  ///
  /// In en, this message translates to:
  /// **'One card'**
  String get oneCard;

  /// No description provided for @threeCards.
  ///
  /// In en, this message translates to:
  /// **'Past · Present · Future'**
  String get threeCards;

  /// No description provided for @celticCross.
  ///
  /// In en, this message translates to:
  /// **'Celtic Cross'**
  String get celticCross;

  /// No description provided for @focus.
  ///
  /// In en, this message translates to:
  /// **'Focus'**
  String get focus;

  /// No description provided for @focusPrompt.
  ///
  /// In en, this message translates to:
  /// **'What detail in this card deserves your attention today?'**
  String get focusPrompt;

  /// No description provided for @past.
  ///
  /// In en, this message translates to:
  /// **'Past'**
  String get past;

  /// No description provided for @pastPrompt.
  ///
  /// In en, this message translates to:
  /// **'How might this image describe an influence you bring from the past?'**
  String get pastPrompt;

  /// No description provided for @present.
  ///
  /// In en, this message translates to:
  /// **'Present'**
  String get present;

  /// No description provided for @presentPrompt.
  ///
  /// In en, this message translates to:
  /// **'Where can you recognize this pattern in your situation now?'**
  String get presentPrompt;

  /// No description provided for @future.
  ///
  /// In en, this message translates to:
  /// **'Future'**
  String get future;

  /// No description provided for @futurePrompt.
  ///
  /// In en, this message translates to:
  /// **'If this pattern continues, what possibility might open up?'**
  String get futurePrompt;

  /// No description provided for @situation.
  ///
  /// In en, this message translates to:
  /// **'Situation'**
  String get situation;

  /// No description provided for @situationPrompt.
  ///
  /// In en, this message translates to:
  /// **'What does this card suggest is at the heart of the matter?'**
  String get situationPrompt;

  /// No description provided for @crossing.
  ///
  /// In en, this message translates to:
  /// **'Crossing'**
  String get crossing;

  /// No description provided for @crossingPrompt.
  ///
  /// In en, this message translates to:
  /// **'How could this energy challenge or support the situation?'**
  String get crossingPrompt;

  /// No description provided for @above.
  ///
  /// In en, this message translates to:
  /// **'Above'**
  String get above;

  /// No description provided for @abovePrompt.
  ///
  /// In en, this message translates to:
  /// **'What intention or aspiration does this image bring to mind?'**
  String get abovePrompt;

  /// No description provided for @foundation.
  ///
  /// In en, this message translates to:
  /// **'Foundation'**
  String get foundation;

  /// No description provided for @foundationPrompt.
  ///
  /// In en, this message translates to:
  /// **'What underlying experience could be shaping the situation?'**
  String get foundationPrompt;

  /// No description provided for @behind.
  ///
  /// In en, this message translates to:
  /// **'Behind'**
  String get behind;

  /// No description provided for @behindPrompt.
  ///
  /// In en, this message translates to:
  /// **'What influence might be receding into the past?'**
  String get behindPrompt;

  /// No description provided for @ahead.
  ///
  /// In en, this message translates to:
  /// **'Ahead'**
  String get ahead;

  /// No description provided for @aheadPrompt.
  ///
  /// In en, this message translates to:
  /// **'What possibility appears to be approaching?'**
  String get aheadPrompt;

  /// No description provided for @stance.
  ///
  /// In en, this message translates to:
  /// **'Your stance'**
  String get stance;

  /// No description provided for @stancePrompt.
  ///
  /// In en, this message translates to:
  /// **'Where do you see your own approach in this card?'**
  String get stancePrompt;

  /// No description provided for @surroundings.
  ///
  /// In en, this message translates to:
  /// **'Surroundings'**
  String get surroundings;

  /// No description provided for @surroundingsPrompt.
  ///
  /// In en, this message translates to:
  /// **'How might this pattern appear in the people or conditions around you?'**
  String get surroundingsPrompt;

  /// No description provided for @hopesFears.
  ///
  /// In en, this message translates to:
  /// **'Hopes and fears'**
  String get hopesFears;

  /// No description provided for @hopesFearsPrompt.
  ///
  /// In en, this message translates to:
  /// **'What wish or worry does this image bring to the surface?'**
  String get hopesFearsPrompt;

  /// No description provided for @outcome.
  ///
  /// In en, this message translates to:
  /// **'Outcome'**
  String get outcome;

  /// No description provided for @outcomePrompt.
  ///
  /// In en, this message translates to:
  /// **'What direction does the spread suggest if the present pattern continues?'**
  String get outcomePrompt;

  /// No description provided for @majorLabel.
  ///
  /// In en, this message translates to:
  /// **'Major Arcana · {number}'**
  String majorLabel(String number);

  /// No description provided for @minorLabel.
  ///
  /// In en, this message translates to:
  /// **'Minor Arcana · {suit} · {rank}'**
  String minorLabel(String suit, String rank);

  /// No description provided for @unnumbered.
  ///
  /// In en, this message translates to:
  /// **'Unnumbered'**
  String get unnumbered;

  /// No description provided for @courtLabel.
  ///
  /// In en, this message translates to:
  /// **'{rank} (court)'**
  String courtLabel(String rank);

  /// No description provided for @cups.
  ///
  /// In en, this message translates to:
  /// **'Cups'**
  String get cups;

  /// No description provided for @swords.
  ///
  /// In en, this message translates to:
  /// **'Swords'**
  String get swords;

  /// No description provided for @batons.
  ///
  /// In en, this message translates to:
  /// **'Batons'**
  String get batons;

  /// No description provided for @wands.
  ///
  /// In en, this message translates to:
  /// **'Wands'**
  String get wands;

  /// No description provided for @coins.
  ///
  /// In en, this message translates to:
  /// **'Coins'**
  String get coins;

  /// No description provided for @pentacles.
  ///
  /// In en, this message translates to:
  /// **'Pentacles'**
  String get pentacles;

  /// No description provided for @page.
  ///
  /// In en, this message translates to:
  /// **'Page'**
  String get page;

  /// No description provided for @knight.
  ///
  /// In en, this message translates to:
  /// **'Knight'**
  String get knight;

  /// No description provided for @queen.
  ///
  /// In en, this message translates to:
  /// **'Queen'**
  String get queen;

  /// No description provided for @king.
  ///
  /// In en, this message translates to:
  /// **'King'**
  String get king;

  /// No description provided for @majorLesson.
  ///
  /// In en, this message translates to:
  /// **'Read this image as a turning point and ask what larger change its central figure or event might represent.'**
  String get majorLesson;

  /// No description provided for @cupsLesson.
  ///
  /// In en, this message translates to:
  /// **'A cup holds, offers or spills its contents, giving you a way to explore how feelings pass between people.'**
  String get cupsLesson;

  /// No description provided for @swordsLesson.
  ///
  /// In en, this message translates to:
  /// **'Read the blade as a tool of judgment and ask what needs to be separated, questioned or decided.'**
  String get swordsLesson;

  /// No description provided for @wandsLesson.
  ///
  /// In en, this message translates to:
  /// **'A staff can support a traveler or direct a movement, so look for where effort is being put to work.'**
  String get wandsLesson;

  /// No description provided for @coinsLesson.
  ///
  /// In en, this message translates to:
  /// **'Read the disc as a resource and ask who holds, shares or cultivates something of practical value.'**
  String get coinsLesson;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'he', 'ru'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'he':
      return AppLocalizationsHe();
    case 'ru':
      return AppLocalizationsRu();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
