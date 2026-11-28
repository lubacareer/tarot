import 'package:flutter/widgets.dart';

import 'l10n/generated/app_localizations.dart';
export 'l10n/generated/app_localizations.dart';

/// Connects the existing English presentation text to typed, offline ARB messages.
extension ObservatoryStrings on BuildContext {
  String tr(String english, [Map<String, Object> args = const {}]) {
    final copy =
        AppLocalizations.of(this) ?? lookupAppLocalizations(const Locale('en'));
    return switch (english) {
      'Reconnecting to your reading…' => copy.reconnectingReading,
      'The reading service could not be reached. Check for your saved reading when you’re connected.' =>
        copy.checkSavedReading,
      'Check again' => copy.checkAgain,
      'The saved interpretation is no longer available. You can still explore the card meanings below.' =>
        copy.expiredReading,
      'Gemini ran out of time on this interpretation. You can try again.' =>
        copy.readingTimeout,
      'Read with Gemini 4 Carbon' => copy.geminiReading,
      'Your optional question and revealed cards are sent to Google Gemini.' =>
        copy.geminiDisclosure,
      'Offline reading uses the meanings stored on this device.' =>
        copy.offlineReading,
      'Your question (optional)' => copy.readingQuestion,
      'Gemini’s interpretation' => copy.interpretationHeading,
      'Your reading' => copy.synthesisHeading,
      'The monthly Gemini reading limit has been reached. The deck’s meanings are still available.' =>
        copy.quotaMessage,
      'Gemini is receiving many requests. Try again shortly.' =>
        copy.rateLimitMessage,
      'Gemini could not finish this interpretation. The deck’s meanings are still available.' =>
        copy.interpretationError,
      'Gemini is connecting the cards…' => copy.synthesisLoading,
      'Gemini is interpreting this card…' => copy.interpretationLoading,
      'Table' => copy.navTable,
      'Library' => copy.navLibrary,
      'Guide' => copy.navGuide,
      'Arcana Observatory' => copy.appTitle,
      'Language' => copy.language,
      'Could not save the language preference.' => copy.languageSaveError,
      'Reading table' => copy.readingTable,
      'The reading table' => copy.tableHeading,
      'Deck library' => copy.deckLibrary,
      'Field guide' => copy.fieldGuide,
      'Upright & reversed' => copy.uprightReversed,
      'Upright cards' => copy.uprightCards,
      'Begin reading' => copy.beginReading,
      'Choose your deck' => copy.chooseDeck,
      'Choose your spread' => copy.chooseSpread,
      'One card brings a single question into focus.' => copy.singleDescription,
      'Read three positions together to explore how their meanings relate.' =>
        copy.threeDescription,
      'Explore a question in depth through ten connected positions.' =>
        copy.crossDescription,
      'Include reversed cards' => copy.includeReversals,
      'A card can appear upside down with its own interpretation.' =>
        copy.reversalsHelp,
      'Begin this spread' => copy.beginSpread,
      '{count} cards' => copy.cardCount(args['count'] as int),
      'Choose a card' => copy.chooseCard,
      'Turn your card' => copy.turnCard,
      'Position {number} of {total} · {position}' => copy.positionCounter(
        args['number'] as int,
        args['total'] as int,
        args['position']! as String,
      ),
      'Previous cards' => copy.previousCards,
      '{start}–{end} of {total}' => copy.pageRange(
        args['start'] as int,
        args['end'] as int,
        args['total'] as int,
      ),
      'Next cards' => copy.nextCards,
      'Reveal card' => copy.revealCard,
      'Reversed' => copy.reversed,
      'Upright' => copy.upright,
      'Enlarge card' => copy.enlargeCard,
      'Reading complete' => copy.readingComplete,
      'Position guide' => copy.positionGuide,
      'Look at the image' => copy.lookAtImage,
      'Card meaning' => copy.cardMeaning,
      'Read the position' => copy.readPosition,
      'What detail in {card} connects its meaning to “{position}” in your reading?' =>
        copy.connectDetail(
          args['card']! as String,
          args['position']! as String,
        ),
      'Closing reflection' => copy.closingReflection,
      'What is one small action this card invites you to try?' =>
        copy.smallAction,
      'Which two cards seem to speak to each other? Use their positions to explain the connection, then name one action to take.' =>
        copy.twoCards,
      'New reading' => copy.newReading,
      'Return to drawn card' => copy.returnToCard,
      'Choose next card' => copy.chooseNext,
      'Draw from the deck' => copy.drawFromDeck,
      'Before you reveal' => copy.beforeReveal,
      'Select a face-down card from the shuffled deck for this position.' =>
        copy.chooseFaceDown,
      'Hold the position’s question in mind, then turn the card to explore its imagery.' =>
        copy.rememberQuestion,
      'Start again' => copy.startAgain,
      'Spread layout' => copy.spreadLayout,
      'Draw card {number}' => copy.drawCardNumber(args['number'] as int),
      'Draw face-down card {number}' => copy.drawFaceDownNumber(
        args['number'] as int,
      ),
      'Close' => copy.close,
      'Reset zoom' => copy.resetZoom,
      'Zoom in' => copy.zoomIn,
      'Leave this reading?' => copy.leaveReading,
      'Exiting clears the cards on this table.' => copy.exitingClears,
      'Starting again clears the cards on this table.' => copy.restartClears,
      'Keep reading' => copy.keepReading,
      'Exit app' => copy.exitApp,
      'Opening deck library' => copy.openingLibrary,
      'The deck library could not be opened.' => copy.libraryOpenError,
      'Try again' => copy.tryAgain,
      'Symbolism' => copy.symbolism,
      'Use this deck' => copy.useDeck,
      'Card gallery' => copy.cardGallery,
      'Previous page' => copy.previousPage,
      'Next page' => copy.nextPage,
      'Ask a question' => copy.askQuestion,
      'Frame a question that leaves room for reflection. “What could help me approach this decision?” gives each card a role in exploring your choices.' =>
        copy.guideQuestion,
      'Notice the picture' => copy.noticePicture,
      'Name one visible detail before opening the meaning. Notice where a figure looks, what they carry, or how a repeated suit fills the card. In The Star, vessels pouring water can bring renewal to mind.' =>
        copy.guidePicture,
      'A spread gives each card a job. In the Past position, The Star might recall a time when hope returned. In the Present position, the same image can invite you to notice what sustains you today.' =>
        copy.guidePosition,
      'Explore a reversal' => copy.exploreReversal,
      'Enable reversed cards to include upside-down draws. Compare the upright idea with the reversed interpretation. Consider whether the image suggests a delay, a private experience, or a different direction.' =>
        copy.guideReversal,
      'Connect your cards' => copy.connectCards,
      'Read the cards in spread order. Look for a shared color, suit, gesture, or idea. Describe how that thread changes from one position to the next and name one small action you want to try.' =>
        copy.guideConnect,
      'Software license' => copy.softwareLicense,
      'Artwork credits' => copy.artworkCredits,
      'This license file could not be opened.' => copy.licenseOpenError,
      'Learn to connect the imagery, position, and meaning of each card.' =>
        copy.guideIntro,
      'Credits & licenses' => copy.creditsLicenses,
      'Open-source libraries' => copy.openSourceLibraries,
      'One card' => copy.oneCard,
      'Past · Present · Future' => copy.threeCards,
      'Celtic Cross' => copy.celticCross,
      'Focus' => copy.focus,
      'What detail in this card deserves your attention today?' =>
        copy.focusPrompt,
      'Past' => copy.past,
      'How might this image describe an influence you bring from the past?' =>
        copy.pastPrompt,
      'Present' => copy.present,
      'Where can you recognize this pattern in your situation now?' =>
        copy.presentPrompt,
      'Future' => copy.future,
      'If this pattern continues, what possibility might open up?' =>
        copy.futurePrompt,
      'Situation' => copy.situation,
      'What does this card suggest is at the heart of the matter?' =>
        copy.situationPrompt,
      'Crossing' => copy.crossing,
      'How could this energy challenge or support the situation?' =>
        copy.crossingPrompt,
      'Above' => copy.above,
      'What intention or aspiration does this image bring to mind?' =>
        copy.abovePrompt,
      'Foundation' => copy.foundation,
      'What underlying experience could be shaping the situation?' =>
        copy.foundationPrompt,
      'Behind' => copy.behind,
      'What influence might be receding into the past?' => copy.behindPrompt,
      'Ahead' => copy.ahead,
      'What possibility appears to be approaching?' => copy.aheadPrompt,
      'Your stance' => copy.stance,
      'Where do you see your own approach in this card?' => copy.stancePrompt,
      'Surroundings' => copy.surroundings,
      'How might this pattern appear in the people or conditions around you?' =>
        copy.surroundingsPrompt,
      'Hopes and fears' => copy.hopesFears,
      'What wish or worry does this image bring to the surface?' =>
        copy.hopesFearsPrompt,
      'Outcome' => copy.outcome,
      'What direction does the spread suggest if the present pattern continues?' =>
        copy.outcomePrompt,
      'Major Arcana · {number}' => copy.majorLabel(args['number']! as String),
      'Minor Arcana · {suit} · {rank}' => copy.minorLabel(
        args['suit']! as String,
        args['rank']! as String,
      ),
      'Unnumbered' => copy.unnumbered,
      '{rank} (court)' => copy.courtLabel(args['rank']! as String),
      'Cups' => copy.cups,
      'Swords' => copy.swords,
      'Batons' => copy.batons,
      'Wands' => copy.wands,
      'Coins' => copy.coins,
      'Pentacles' => copy.pentacles,
      'Page' => copy.page,
      'Knight' => copy.knight,
      'Queen' => copy.queen,
      'King' => copy.king,
      'Read this image as a turning point and ask what larger change its central figure or event might represent.' =>
        copy.majorLesson,
      'A cup holds, offers or spills its contents, giving you a way to explore how feelings pass between people.' =>
        copy.cupsLesson,
      'Read the blade as a tool of judgment and ask what needs to be separated, questioned or decided.' =>
        copy.swordsLesson,
      'A staff can support a traveler or direct a movement, so look for where effort is being put to work.' =>
        copy.wandsLesson,
      'Read the disc as a resource and ask who holds, shares or cultivates something of practical value.' =>
        copy.coinsLesson,
      _ => throw ArgumentError.value(
        english,
        'english',
        'Unregistered interface text',
      ),
    };
  }
}
