import 'package:flutter/material.dart';

import 'interpretation.dart';
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
    this.interpretationClient = const InterpretationClient(),
  });

  final Future<List<TarotDeck>> Function() loadDecks;
  final LanguagePreferences preferences;
  final InterpretationClient interpretationClient;

  @override
  State<ObservatoryApp> createState() => _ObservatoryAppState();
}

class _ObservatoryAppState extends State<ObservatoryApp>
    with WidgetsBindingObserver {
  late final _language = LanguageController(widget.preferences);
  late final _restored = _language.restore();
  final _catalogs = <Locale, Future<ReadingText>>{};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeLocales(List<Locale>? locales) {
    if (_language.explicitLocale == null) setState(() {});
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _language.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<void>(
    future: _restored,
    builder: (_, snapshot) {
      if (snapshot.connectionState != ConnectionState.done) {
        return const ColoredBox(color: paper);
      }
      return _app();
    },
  );

  Widget _app() => LanguageScope(
    controller: _language,
    child: ListenableBuilder(
      listenable: _language,
      builder: (context, child) {
        final locale =
            _language.explicitLocale ??
            resolveDeviceLanguage(
              WidgetsBinding.instance.platformDispatcher.locales,
            );
        // FutureBuilder retains the displayed catalog while loading the next,
        // and only publishes a completion for the current language request.
        return FutureBuilder<ReadingText>(
          future: _catalogs.putIfAbsent(locale, () => ReadingText.load(locale)),
          builder: (_, snapshot) {
            final words = snapshot.data;
            if (snapshot.hasError) return ErrorWidget(snapshot.error!);
            if (words == null) return const ColoredBox(color: paper);
            return MaterialApp(
              onGenerateTitle: (context) => context.tr('Arcana Observatory'),
              debugShowCheckedModeBanner: false,
              theme: observatoryTheme(),
              localizationsDelegates: [
                words.delegate,
                ...AppLocalizations.localizationsDelegates,
              ],
              supportedLocales: AppLocalizations.supportedLocales,
              locale: words.locale,
              home: child,
            );
          },
        );
      },
      child: Observatory(
        loadDecks: widget.loadDecks,
        interpretationClient: widget.interpretationClient,
      ),
    ),
  );
}
