import 'package:flutter/material.dart';

import 'reading.dart';
import 'ui/observatory.dart';
import 'ui/style.dart';

void main() => runApp(const ObservatoryApp());

class ObservatoryApp extends StatelessWidget {
  const ObservatoryApp({super.key, this.loadDecks = DeckCatalog.load});

  final Future<List<TarotDeck>> Function() loadDecks;

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Arcana Observatory',
    debugShowCheckedModeBanner: false,
    theme: observatoryTheme(),
    home: Observatory(loadDecks: loadDecks),
  );
}
