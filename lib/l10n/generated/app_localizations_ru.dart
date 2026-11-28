// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get reconnectingReading => 'Восстанавливаем связь с вашим раскладом…';

  @override
  String get checkSavedReading =>
      'Не удалось связаться с сервисом. Когда связь восстановится, проверьте, сохранилось ли толкование.';

  @override
  String get checkAgain => 'Проверить снова';

  @override
  String get expiredReading =>
      'Сохранённое толкование больше недоступно. Вы по-прежнему можете изучить значения карт.';

  @override
  String get readingTimeout =>
      'Gemini не удалось завершить толкование вовремя. Можно попробовать ещё раз.';

  @override
  String get geminiReading => 'Расклад с Gemini 4 Carbon';

  @override
  String get geminiDisclosure =>
      'Ваш вопрос, если вы его укажете, и открытые карты отправляются в Google Gemini.';

  @override
  String get offlineReading =>
      'В автономном режиме используются толкования, сохранённые на устройстве.';

  @override
  String get readingQuestion => 'Ваш вопрос (необязательно)';

  @override
  String get interpretationHeading => 'Толкование Gemini';

  @override
  String get synthesisHeading => 'Ваш расклад';

  @override
  String get quotaMessage =>
      'Месячный лимит обращений к Gemini исчерпан. Толкования из колоды по-прежнему доступны.';

  @override
  String get rateLimitMessage =>
      'Сейчас поступает много запросов. Попробуйте ещё раз чуть позже.';

  @override
  String get interpretationError =>
      'Gemini не удалось завершить толкование. Значения карт из колоды по-прежнему доступны.';

  @override
  String get synthesisLoading => 'Gemini ищет связи между картами…';

  @override
  String get interpretationLoading => 'Gemini толкует эту карту…';

  @override
  String get navTable => 'Стол';

  @override
  String get navLibrary => 'Колоды';

  @override
  String get navGuide => 'Учебник';

  @override
  String get appTitle => 'Обсерватория Арканов';

  @override
  String get language => 'Язык';

  @override
  String get languageSaveError => 'Не удалось сохранить выбранный язык.';

  @override
  String get readingTable => 'Стол для расклада';

  @override
  String get tableHeading => 'Стол для расклада';

  @override
  String get deckLibrary => 'Библиотека колод';

  @override
  String get fieldGuide => 'Путеводитель';

  @override
  String get uprightReversed => 'Прямые и перевёрнутые карты';

  @override
  String get uprightCards => 'Прямые карты';

  @override
  String get beginReading => 'Начать расклад';

  @override
  String get chooseDeck => 'Выберите колоду';

  @override
  String get chooseSpread => 'Выберите расклад';

  @override
  String get singleDescription =>
      'Одна карта помогает сосредоточиться на одном вопросе.';

  @override
  String get threeDescription =>
      'Рассмотрите три позиции вместе, чтобы увидеть связь между их значениями.';

  @override
  String get crossDescription =>
      'Десять связанных позиций позволяют подробно исследовать вопрос.';

  @override
  String get includeReversals => 'Включить перевёрнутые карты';

  @override
  String get reversalsHelp =>
      'Карта может выпасть перевёрнутой и получить другое толкование.';

  @override
  String get beginSpread => 'Начать этот расклад';

  @override
  String cardCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count карты',
      many: '$count карт',
      few: '$count карты',
      one: '$count карта',
    );
    return '$_temp0';
  }

  @override
  String get chooseCard => 'Выберите карту';

  @override
  String get turnCard => 'Переверните карту';

  @override
  String positionCounter(int number, int total, String position) {
    return 'Позиция $number из $total · $position';
  }

  @override
  String get previousCards => 'Предыдущие карты';

  @override
  String pageRange(int start, int end, int total) {
    return '$start–$end из $total';
  }

  @override
  String get nextCards => 'Следующие карты';

  @override
  String get revealCard => 'Открыть карту';

  @override
  String get reversed => 'Перевёрнутое положение';

  @override
  String get upright => 'Прямое положение';

  @override
  String get enlargeCard => 'Увеличить карту';

  @override
  String get readingComplete => 'Расклад завершён';

  @override
  String get positionGuide => 'О позиции';

  @override
  String get lookAtImage => 'Рассмотрите изображение';

  @override
  String get cardMeaning => 'Значение карты';

  @override
  String get readPosition => 'Учтите позицию';

  @override
  String connectDetail(String card, String position) {
    return 'Какая деталь карты «$card» связывает её значение с позицией «$position» в вашем раскладе?';
  }

  @override
  String get closingReflection => 'Вопрос напоследок';

  @override
  String get smallAction => 'Какой небольшой шаг предлагает вам эта карта?';

  @override
  String get twoCards =>
      'Какие две карты словно ведут диалог? Объясните эту связь через их позиции и назовите один шаг, который можно сделать.';

  @override
  String get newReading => 'Новый расклад';

  @override
  String get returnToCard => 'Вернуться к вытянутой карте';

  @override
  String get chooseNext => 'Выбрать следующую карту';

  @override
  String get drawFromDeck => 'Вытяните карту';

  @override
  String get beforeReveal => 'Прежде чем открыть карту';

  @override
  String get chooseFaceDown =>
      'Выберите для этой позиции закрытую карту из перетасованной колоды.';

  @override
  String get rememberQuestion =>
      'Подержите в уме вопрос позиции, затем откройте карту и рассмотрите изображение.';

  @override
  String get startAgain => 'Начать заново';

  @override
  String get spreadLayout => 'Схема расклада';

  @override
  String drawCardNumber(int number) {
    return 'Вытянуть карту $number';
  }

  @override
  String drawFaceDownNumber(int number) {
    return 'Вытянуть закрытую карту $number';
  }

  @override
  String get close => 'Закрыть';

  @override
  String get resetZoom => 'Сбросить масштаб';

  @override
  String get zoomIn => 'Увеличить';

  @override
  String get leaveReading => 'Выйти из этого расклада?';

  @override
  String get exitingClears => 'При выходе карты будут убраны со стола.';

  @override
  String get restartClears => 'При новом раскладе карты будут убраны со стола.';

  @override
  String get keepReading => 'Остаться в раскладе';

  @override
  String get exitApp => 'Выйти из приложения';

  @override
  String get openingLibrary => 'Открывается библиотека колод';

  @override
  String get libraryOpenError => 'Не удалось открыть библиотеку колод.';

  @override
  String get tryAgain => 'Повторить';

  @override
  String get symbolism => 'Символика';

  @override
  String get useDeck => 'Выбрать эту колоду';

  @override
  String get cardGallery => 'Галерея карт';

  @override
  String get previousPage => 'Предыдущая страница';

  @override
  String get nextPage => 'Следующая страница';

  @override
  String get askQuestion => 'Задайте вопрос';

  @override
  String get guideQuestion =>
      'Сформулируйте вопрос, который оставляет место для размышлений. Например, «Что поможет мне подойти к этому решению?» даёт каждой карте роль в исследовании ваших возможностей.';

  @override
  String get noticePicture => 'Всмотритесь в рисунок';

  @override
  String get guidePicture =>
      'Прежде чем читать толкование, назовите одну деталь рисунка. Куда смотрит фигура? Что у неё в руках? Как на карте повторяются знаки масти? На карте «Звезда» вода, льющаяся из кувшинов, может напомнить об обновлении.';

  @override
  String get guidePosition =>
      'У каждой карты в раскладе своя задача. В позиции прошлого «Звезда» может напомнить о возвращении надежды. В позиции настоящего тот же образ предлагает заметить, что поддерживает вас сегодня.';

  @override
  String get exploreReversal => 'Исследуйте перевёрнутую карту';

  @override
  String get guideReversal =>
      'Включите перевёрнутые карты, чтобы они могли выпадать вверх ногами. Сравните толкования двух положений и подумайте, подсказывает ли образ задержку, внутреннее переживание или смену направления.';

  @override
  String get connectCards => 'Свяжите карты';

  @override
  String get guideConnect =>
      'Читайте карты в порядке расклада. Ищите общий цвет, масть, жест или идею. Опишите, как эта нить меняется от позиции к позиции, и назовите один небольшой шаг, который хотите попробовать.';

  @override
  String get softwareLicense => 'Лицензия программы';

  @override
  String get artworkCredits => 'Авторы иллюстраций';

  @override
  String get licenseOpenError => 'Не удалось открыть файл лицензии.';

  @override
  String get guideIntro =>
      'Узнайте, как связать рисунок карты, её позицию и значение.';

  @override
  String get creditsLicenses => 'Авторы и лицензии';

  @override
  String get openSourceLibraries => 'Библиотеки с открытым кодом';

  @override
  String get oneCard => 'Одна карта';

  @override
  String get threeCards => 'Прошлое · Настоящее · Будущее';

  @override
  String get celticCross => 'Кельтский крест';

  @override
  String get focus => 'Фокус';

  @override
  String get focusPrompt =>
      'Какая деталь этой карты заслуживает вашего внимания сегодня?';

  @override
  String get past => 'Прошлое';

  @override
  String get pastPrompt =>
      'Как этот образ может описать влияние прошлого, которое вы несёте с собой?';

  @override
  String get present => 'Настоящее';

  @override
  String get presentPrompt =>
      'Где в нынешней ситуации вы узнаёте этот образ или мотив?';

  @override
  String get future => 'Будущее';

  @override
  String get futurePrompt =>
      'Какая возможность может открыться, если эта закономерность сохранится?';

  @override
  String get situation => 'Ситуация';

  @override
  String get situationPrompt =>
      'Что эта карта предлагает считать сутью происходящего?';

  @override
  String get crossing => 'Пересечение';

  @override
  String get crossingPrompt =>
      'Как эта сила может осложнить ситуацию или поддержать вас в ней?';

  @override
  String get above => 'Вверху';

  @override
  String get abovePrompt =>
      'Какое намерение или стремление вызывает в памяти этот образ?';

  @override
  String get foundation => 'Основание';

  @override
  String get foundationPrompt =>
      'Какой прежний опыт может лежать в основе ситуации?';

  @override
  String get behind => 'Позади';

  @override
  String get behindPrompt => 'Какое влияние, возможно, отходит в прошлое?';

  @override
  String get ahead => 'Впереди';

  @override
  String get aheadPrompt => 'Какая возможность, похоже, приближается?';

  @override
  String get stance => 'Ваша позиция';

  @override
  String get stancePrompt =>
      'В какой детали карты вы узнаёте собственный подход?';

  @override
  String get surroundings => 'Окружение';

  @override
  String get surroundingsPrompt =>
      'Как этот мотив может проявляться в людях или обстоятельствах вокруг вас?';

  @override
  String get hopesFears => 'Надежды и страхи';

  @override
  String get hopesFearsPrompt =>
      'Какое желание или беспокойство вызывает этот образ?';

  @override
  String get outcome => 'Итог';

  @override
  String get outcomePrompt =>
      'На какое направление указывает расклад, если нынешняя закономерность сохранится?';

  @override
  String majorLabel(String number) {
    return 'Старшие арканы · $number';
  }

  @override
  String minorLabel(String suit, String rank) {
    return 'Младшие арканы · $suit · $rank';
  }

  @override
  String get unnumbered => 'Без номера';

  @override
  String courtLabel(String rank) {
    return '$rank (придворная карта)';
  }

  @override
  String get cups => 'Кубки';

  @override
  String get swords => 'Мечи';

  @override
  String get batons => 'Посохи';

  @override
  String get wands => 'Жезлы';

  @override
  String get coins => 'Монеты';

  @override
  String get pentacles => 'Пентакли';

  @override
  String get page => 'Паж';

  @override
  String get knight => 'Рыцарь';

  @override
  String get queen => 'Королева';

  @override
  String get king => 'Король';

  @override
  String get majorLesson =>
      'Рассмотрите образ как поворотный момент и спросите себя, какие перемены может обозначать главная фигура или событие.';

  @override
  String get cupsLesson =>
      'Кубок можно наполнить, поднести другому или расплескать его содержимое. Этот образ помогает исследовать, как люди делятся чувствами.';

  @override
  String get swordsLesson =>
      'Представьте клинок как инструмент суждения и спросите, что стоит разграничить, подвергнуть сомнению или решить.';

  @override
  String get wandsLesson =>
      'Посох может служить путнику опорой или задавать направление движения. Присмотритесь, куда здесь направлены усилия.';

  @override
  String get coinsLesson =>
      'Рассмотрите диск как зримый ресурс и спросите, кто хранит, приумножает или разделяет с другими нечто полезное.';
}
