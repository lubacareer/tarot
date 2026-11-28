// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hebrew (`he`).
class AppLocalizationsHe extends AppLocalizations {
  AppLocalizationsHe([String locale = 'he']) : super(locale);

  @override
  String get reconnectingReading => 'החיבור לקריאה מתחדש…';

  @override
  String get checkSavedReading =>
      'אין חיבור לשירות הקריאה. כשהחיבור יחזור, אפשר לבדוק אם הפרשנות נשמרה.';

  @override
  String get checkAgain => 'בדיקה חוזרת';

  @override
  String get expiredReading =>
      'הפרשנות השמורה כבר אינה זמינה. עדיין אפשר לעיין במשמעויות הקלפים.';

  @override
  String get readingTimeout =>
      'תם הזמן שהוקצב ל־Gemini להשלמת הפרשנות. אפשר לנסות שוב.';

  @override
  String get geminiReading => 'קריאה עם Gemini 4 Carbon';

  @override
  String get geminiDisclosure =>
      'השאלה, אם הוספת אותה, והקלפים שנחשפו נשלחים ל־Google Gemini.';

  @override
  String get offlineReading =>
      'בקריאה ללא חיבור משתמשים בפירושי הקלפים השמורים במכשיר.';

  @override
  String get readingQuestion => 'השאלה שלך (לא חובה)';

  @override
  String get interpretationHeading => 'הפירוש של Gemini';

  @override
  String get synthesisHeading => 'הקריאה שלך';

  @override
  String get quotaMessage =>
      'מכסת הקריאות החודשית של Gemini נוצלה. אפשר להמשיך לקרוא את פירושי החפיסה.';

  @override
  String get rateLimitMessage =>
      'יש כרגע עומס של בקשות. אפשר לנסות שוב בעוד מעט.';

  @override
  String get interpretationError =>
      'Gemini לא הצליח להשלים את הפירוש. אפשר להמשיך לקרוא את פירושי החפיסה.';

  @override
  String get synthesisLoading => 'Gemini מפרש את הקשרים בין הקלפים…';

  @override
  String get interpretationLoading => 'Gemini מפרש את הקלף…';

  @override
  String get navTable => 'שולחן';

  @override
  String get navLibrary => 'ספרייה';

  @override
  String get navGuide => 'מדריך';

  @override
  String get appTitle => 'מצפה הארקנה';

  @override
  String get language => 'שפה';

  @override
  String get languageSaveError => 'לא הצלחנו לשמור את בחירת השפה.';

  @override
  String get readingTable => 'שולחן הקריאה';

  @override
  String get tableHeading => 'שולחן הקריאה';

  @override
  String get deckLibrary => 'ספריית החפיסות';

  @override
  String get fieldGuide => 'מדריך לקריאה';

  @override
  String get uprightReversed => 'קלפים ישרים והפוכים';

  @override
  String get uprightCards => 'קלפים ישרים';

  @override
  String get beginReading => 'התחלת קריאה';

  @override
  String get chooseDeck => 'בחירת חפיסה';

  @override
  String get chooseSpread => 'בחירת פריסה';

  @override
  String get singleDescription => 'קלף אחד עוזר להתמקד בשאלה אחת.';

  @override
  String get threeDescription =>
      'קריאה משותפת של שלוש העמדות חושפת את הקשר בין המשמעויות שלהן.';

  @override
  String get crossDescription =>
      'עשר עמדות הקשורות זו לזו מאפשרות לבחון שאלה לעומק.';

  @override
  String get includeReversals => 'לכלול קלפים הפוכים';

  @override
  String get reversalsHelp =>
      'קלף יכול להופיע הפוך, ולכיוון הזה יש פירוש משלו.';

  @override
  String get beginSpread => 'התחלת הפריסה';

  @override
  String cardCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count קלפים',
      one: 'קלף אחד',
    );
    return '$_temp0';
  }

  @override
  String get chooseCard => 'בחירת קלף';

  @override
  String get turnCard => 'הגיע הזמן להפוך את הקלף';

  @override
  String positionCounter(int number, int total, String position) {
    return 'עמדה $number מתוך $total · $position';
  }

  @override
  String get previousCards => 'הקלפים הקודמים';

  @override
  String pageRange(int start, int end, int total) {
    return '$start–$end מתוך $total';
  }

  @override
  String get nextCards => 'הקלפים הבאים';

  @override
  String get revealCard => 'חשיפת הקלף';

  @override
  String get reversed => 'הפוך';

  @override
  String get upright => 'ישר';

  @override
  String get enlargeCard => 'הגדלת הקלף';

  @override
  String get readingComplete => 'הקריאה הושלמה';

  @override
  String get positionGuide => 'מדריך לעמדה';

  @override
  String get lookAtImage => 'התבוננות בתמונה';

  @override
  String get cardMeaning => 'משמעות הקלף';

  @override
  String get readPosition => 'פירוש לפי העמדה';

  @override
  String connectDetail(String card, String position) {
    return 'איזה פרט בקלף ״$card״ קושר את משמעותו לעמדה ״$position״ בקריאה שלך?';
  }

  @override
  String get closingReflection => 'מחשבה לסיום';

  @override
  String get smallAction => 'איזה צעד קטן הקלף מזמין אותך לנסות?';

  @override
  String get twoCards =>
      'אילו שני קלפים נראים כאילו הם משוחחים זה עם זה? כדאי להיעזר בעמדות שלהם כדי להסביר את הקשר, ואז לבחור צעד מעשי אחד.';

  @override
  String get newReading => 'קריאה חדשה';

  @override
  String get returnToCard => 'חזרה לקלף שנשלף';

  @override
  String get chooseNext => 'בחירת הקלף הבא';

  @override
  String get drawFromDeck => 'שליפה מהחפיסה';

  @override
  String get beforeReveal => 'לפני חשיפת הקלף';

  @override
  String get chooseFaceDown =>
      'בוחרים לעמדה הזאת קלף שפניו מטה מתוך החפיסה המעורבבת.';

  @override
  String get rememberQuestion =>
      'אפשר לחשוב על השאלה של העמדה, ואז להפוך את הקלף ולהתבונן בדימויים שבו.';

  @override
  String get startAgain => 'התחלה מחדש';

  @override
  String get spreadLayout => 'תרשים הפריסה';

  @override
  String drawCardNumber(int number) {
    return 'שליפת קלף מספר $number';
  }

  @override
  String drawFaceDownNumber(int number) {
    return 'שליפת קלף מספר $number שפניו מטה';
  }

  @override
  String get close => 'סגירה';

  @override
  String get resetZoom => 'איפוס ההגדלה';

  @override
  String get zoomIn => 'הגדלה';

  @override
  String get leaveReading => 'לצאת מהקריאה הזאת?';

  @override
  String get exitingClears => 'היציאה תפנה את הקלפים משולחן הקריאה.';

  @override
  String get restartClears => 'התחלה מחדש תפנה את הקלפים משולחן הקריאה.';

  @override
  String get keepReading => 'המשך הקריאה';

  @override
  String get exitApp => 'יציאה מהיישום';

  @override
  String get openingLibrary => 'ספריית החפיסות נפתחת';

  @override
  String get libraryOpenError => 'לא הצלחנו לפתוח את ספריית החפיסות.';

  @override
  String get tryAgain => 'ניסיון נוסף';

  @override
  String get symbolism => 'סמלים ומשמעותם';

  @override
  String get useDeck => 'בחירה בחפיסה הזאת';

  @override
  String get cardGallery => 'גלריית הקלפים';

  @override
  String get previousPage => 'העמוד הקודם';

  @override
  String get nextPage => 'העמוד הבא';

  @override
  String get askQuestion => 'ניסוח שאלה';

  @override
  String get guideQuestion =>
      'כדאי לנסח שאלה שמשאירה מקום למחשבה. למשל, ״מה יכול לעזור לי לגשת להחלטה הזאת?״ נותנת לכל קלף תפקיד בבחינת האפשרויות.';

  @override
  String get noticePicture => 'התבוננות באיור';

  @override
  String get guidePicture =>
      'לפני קריאת הפירוש כדאי לציין פרט אחד שרואים בקלף. לאן הדמות מביטה? מה היא נושאת? כיצד סמלי הסדרה חוזרים באיור? בקלף הכוכב, המים הנשפכים מהכדים יכולים להזכיר התחדשות.';

  @override
  String get guidePosition =>
      'בפריסה יש לכל קלף תפקיד. בעמדת העבר, הכוכב עשוי להזכיר רגע שבו חזרה התקווה. בעמדת ההווה, אותו דימוי יכול להפנות את תשומת הלב למה שתומך בך היום.';

  @override
  String get exploreReversal => 'בחינת קלף הפוך';

  @override
  String get guideReversal =>
      'האפשרות ״לכלול קלפים הפוכים״ מאפשרת לשלוף גם קלף שראשו מטה. כדאי להשוות את שתי הקריאות ולשאול אם האיור מרמז על עיכוב, חוויה פנימית או שינוי כיוון.';

  @override
  String get connectCards => 'חיבור בין הקלפים';

  @override
  String get guideConnect =>
      'קוראים את הקלפים לפי סדר הפריסה ומחפשים צבע, סדרה, מחווה או רעיון משותפים. איך הקו המקשר משתנה בין העמדות, ואיזה צעד קטן מתחשק לך לנסות בעקבותיו?';

  @override
  String get softwareLicense => 'רישיון התוכנה';

  @override
  String get artworkCredits => 'קרדיטים לאיורים';

  @override
  String get licenseOpenError => 'לא הצלחנו לפתוח את קובץ הרישיון.';

  @override
  String get guideIntro =>
      'איך מחברים בין האיור של כל קלף, העמדה שלו בפריסה והמשמעות שלו.';

  @override
  String get creditsLicenses => 'קרדיטים ורישיונות';

  @override
  String get openSourceLibraries => 'ספריות קוד פתוח';

  @override
  String get oneCard => 'קלף אחד';

  @override
  String get threeCards => 'עבר · הווה · עתיד';

  @override
  String get celticCross => 'הצלב הקלטי';

  @override
  String get focus => 'מוקד';

  @override
  String get focusPrompt => 'איזה פרט בקלף הזה ראוי לתשומת הלב שלך היום?';

  @override
  String get past => 'עבר';

  @override
  String get pastPrompt =>
      'איך הדימוי הזה עשוי לתאר השפעה מן העבר שעדיין מלווה אותך?';

  @override
  String get present => 'הווה';

  @override
  String get presentPrompt => 'היכן אפשר לזהות את הדפוס הזה במצבך הנוכחי?';

  @override
  String get future => 'עתיד';

  @override
  String get futurePrompt => 'אם הדפוס הזה יימשך, איזו אפשרות עשויה להיפתח?';

  @override
  String get situation => 'המצב';

  @override
  String get situationPrompt => 'מה הקלף מציג כלב העניין?';

  @override
  String get crossing => 'ההשפעה החוצה';

  @override
  String get crossingPrompt =>
      'כיצד ההשפעה הזאת יכולה להקשות על המצב או לתמוך בו?';

  @override
  String get above => 'מעל';

  @override
  String get abovePrompt => 'איזו כוונה או שאיפה הדימוי הזה מעורר בך?';

  @override
  String get foundation => 'היסוד';

  @override
  String get foundationPrompt => 'איזו חוויה עמוקה עשויה לעצב את המצב?';

  @override
  String get behind => 'מאחור';

  @override
  String get behindPrompt => 'איזו השפעה עשויה לדעוך ולהישאר מאחור?';

  @override
  String get ahead => 'בהמשך הדרך';

  @override
  String get aheadPrompt => 'איזו אפשרות נראית כאילו היא מתקרבת?';

  @override
  String get stance => 'העמדה שלך';

  @override
  String get stancePrompt => 'היכן בקלף משתקפת הגישה שלך?';

  @override
  String get surroundings => 'הסביבה';

  @override
  String get surroundingsPrompt =>
      'איך הדפוס הזה עשוי להתבטא אצל אנשים סביבך או בנסיבות חייך?';

  @override
  String get hopesFears => 'תקוות וחששות';

  @override
  String get hopesFearsPrompt => 'איזו משאלה או דאגה הדימוי מעלה אל פני השטח?';

  @override
  String get outcome => 'התוצאה';

  @override
  String get outcomePrompt =>
      'על איזה כיוון הפריסה מצביעה אם הדפוס הנוכחי יימשך?';

  @override
  String majorLabel(String number) {
    return 'הארקנה הגדולה · $number';
  }

  @override
  String minorLabel(String suit, String rank) {
    return 'הארקנה הקטנה · $suit · $rank';
  }

  @override
  String get unnumbered => 'ללא מספר';

  @override
  String courtLabel(String rank) {
    return '$rank (קלף חצר)';
  }

  @override
  String get cups => 'גביעים';

  @override
  String get swords => 'חרבות';

  @override
  String get batons => 'מקלות';

  @override
  String get wands => 'מטות';

  @override
  String get coins => 'דינרים';

  @override
  String get pentacles => 'מטבעות';

  @override
  String get page => 'נער';

  @override
  String get knight => 'אביר';

  @override
  String get queen => 'מלכה';

  @override
  String get king => 'מלך';

  @override
  String get majorLesson =>
      'אפשר לקרוא את התמונה כנקודת מפנה ולשאול איזה שינוי רחב יותר הדמות או האירוע שבמרכז עשויים לייצג.';

  @override
  String get cupsLesson =>
      'גביע יכול להכיל משקה, להגיש אותו או לשפוך אותו. כך אפשר להתבונן בדרך שבה רגשות עוברים מאדם לאדם.';

  @override
  String get swordsLesson =>
      'אפשר לראות בלהב כלי להבחנה ולשאול מה מצריך הפרדה, בדיקה מחודשת או הכרעה.';

  @override
  String get wandsLesson =>
      'מטה יכול לשמש משענת להלך או לכוון תנועה. כדאי לזהות היכן מושקע מאמץ בקלף הזה.';

  @override
  String get coinsLesson =>
      'אפשר לראות בדיסק משאב ולשאול מי מחזיק בדבר בעל ערך מעשי, חולק אותו או מטפח אותו.';
}
