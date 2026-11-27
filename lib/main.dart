import 'package:flutter/material.dart';

import 'language_picker.dart';
import 'localized_reading.dart';
import 'reading.dart';
import 'strings.dart';
import 'ui/observatory.dart';
import 'ui/style.dart';

void main() => runApp(const ObservatoryApp());

class ObservatoryApp extends StatefulWidget {
  const ObservatoryApp({
    super.key,
    this.loadDecks = DeckCatalog.load,
    this.preferences = const LocalLanguagePreferences(),
  });

  final Future<List<TarotDeck>> Function() loadDecks;
  final LanguagePreferences preferences;

  @override
  State<ObservatoryApp> createState() => _ObservatoryAppState();
}

class _ObservatoryAppState extends State<ObservatoryApp> {
  late final LanguageController _language;

  @override
  void initState() {
    super.initState();
    _language = LanguageController(widget.preferences)..restore();
  }

  @override
  void dispose() {
    _language.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => LanguageScope(
    controller: _language,
    child: ListenableBuilder(
      listenable: _language,
      builder: (context, child) => MaterialApp(
        onGenerateTitle: (context) => context.tr('Arcana Observatory'),
        debugShowCheckedModeBanner: false,
        theme: observatoryTheme(),
        localizationsDelegates: const [
          ReadingText.delegate,
          ...AppLocalizations.localizationsDelegates,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        locale: _language.explicitLocale,
        localeListResolutionCallback: (locales, _) =>
            resolveDeviceLanguage(locales ?? const []),
        home: child,
      ),
      child: Observatory(loadDecks: widget.loadDecks),
    ),
  );
}
