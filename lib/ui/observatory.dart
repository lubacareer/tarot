import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../reading.dart';
import 'library.dart';
import 'reading_table.dart';
import 'setup.dart';
import 'style.dart';

enum _Page { table, library, guide }

class Observatory extends StatefulWidget {
  const Observatory({super.key, required this.loadDecks});
  final Future<List<TarotDeck>> Function() loadDecks;
  @override
  State<Observatory> createState() => _ObservatoryState();
}

class _ObservatoryState extends State<Observatory> {
  late Future<List<TarotDeck>> catalog = widget.loadDecks();
  _Page page = _Page.table;
  TarotDeck? chosen;
  SpreadType spread = SpreadType.one;
  bool reversals = false;
  ReadingSession? session;
  final scroll = ScrollController();

  @override
  void dispose() {
    scroll.dispose();
    super.dispose();
  }

  void _toTop() {
    if (scroll.hasClients) scroll.jumpTo(0);
  }

  void _open(_Page next) {
    setState(() => page = next);
    _toTop();
  }

  Future<bool> _canEndReading({bool exiting = false}) async {
    if (session == null || session!.complete) return true;
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Leave this reading?'),
            content: Text(
              exiting
                  ? 'Exiting clears the cards on this table.'
                  : 'Starting again clears the cards on this table.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Keep reading'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(exiting ? 'Exit app' : 'Start again'),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _onBack(bool didPop, Object? result) async {
    if (didPop) return;
    if (page != _Page.table) {
      _open(_Page.table);
    } else if (session != null && !session!.complete) {
      if (!await _canEndReading(exiting: true) || !mounted) return;
      setState(() => session = null);
      await SystemNavigator.pop();
    }
  }

  Future<void> _setup([TarotDeck? deck]) async {
    if (!await _canEndReading() || !mounted) return;
    setState(() {
      session = null;
      if (deck != null) chosen = deck;
      page = _Page.table;
    });
    _toTop();
  }

  void _start(TarotDeck deck) {
    setState(
      () => session = ReadingSession.start(deck, spread, reversals: reversals),
    );
    _toTop();
  }

  @override
  Widget build(BuildContext context) {
    final labelScale = MediaQuery.textScalerOf(context).scale(14) / 14;
    final narrow =
        MediaQuery.sizeOf(context).width < 760 * labelScale.clamp(1.0, 3.0);
    final scaffold = Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Container(
              decoration: const BoxDecoration(
                color: ivory,
                border: Border(bottom: BorderSide(color: line)),
              ),
              alignment: Alignment.center,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1300),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: narrow ? 18 : 32,
                    vertical: narrow ? 11 : 14,
                  ),
                  child: Row(
                    children: [
                      const ObservatoryMark(),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Arcana Observatory',
                          style: display(narrow ? 25 : 29),
                        ),
                      ),
                      if (!narrow)
                        ..._Page.values.map(
                          (value) => _navItem(value, compact: false),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: FutureBuilder<List<TarotDeck>>(
                future: catalog,
                builder: (context, snap) {
                  if (snap.connectionState != ConnectionState.done) {
                    return const Center(
                      child: CircularProgressIndicator(
                        semanticsLabel: 'Opening deck library',
                      ),
                    );
                  }
                  if (snap.hasError ||
                      snap.data == null ||
                      snap.data!.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('The deck library could not be opened.'),
                          const SizedBox(height: 12),
                          FilledButton(
                            onPressed: () =>
                                setState(() => catalog = widget.loadDecks()),
                            child: const Text('Try again'),
                          ),
                        ],
                      ),
                    );
                  }
                  final decks = snap.data!;
                  final deck = chosen ?? decks.first;
                  final body = Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (session != null)
                        Visibility(
                          visible: page == _Page.table,
                          maintainState: true,
                          child: ReadingTable(
                            key: ObjectKey(session),
                            session: session!,
                            onNew: _setup,
                            // Rebuild PopScope so Android Back can exit a completed reading.
                            onComplete: () => setState(() {}),
                          ),
                        ),
                      if (page == _Page.table && session == null)
                        ReadingSetup(
                          decks: decks,
                          selected: deck,
                          spread: spread,
                          reversals: reversals,
                          onDeck: (v) => setState(() => chosen = v),
                          onSpread: (v) => setState(() => spread = v),
                          onReversals: (v) => setState(() => reversals = v),
                          onStart: () => _start(deck),
                        ),
                      if (page == _Page.library)
                        DeckLibrary(
                          decks: decks,
                          selected: deck,
                          onUse: _setup,
                        ),
                      if (page == _Page.guide) const FieldGuide(),
                    ],
                  );
                  return SingleChildScrollView(
                    controller: scroll,
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1300),
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(
                            narrow ? 16 : 32,
                            narrow ? 18 : 26,
                            narrow ? 16 : 32,
                            32,
                          ),
                          child: body,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: narrow
          ? SafeArea(
              top: false,
              child: Container(
                decoration: const BoxDecoration(
                  color: ivory,
                  border: Border(top: BorderSide(color: line)),
                ),
                child: Row(
                  children: [
                    for (final value in _Page.values)
                      Expanded(child: _navItem(value, compact: true)),
                  ],
                ),
              ),
            )
          : null,
    );
    if (Theme.of(context).platform != TargetPlatform.android) return scaffold;
    return PopScope<Object?>(
      canPop: page == _Page.table && (session == null || session!.complete),
      onPopInvokedWithResult: _onBack,
      child: scaffold,
    );
  }

  Widget _navItem(_Page dest, {required bool compact}) {
    final active = dest == page;
    final (icon, title, key) = switch (dest) {
      _Page.table => (Icons.auto_awesome_outlined, 'Reading table', 'table'),
      _Page.library => (Icons.style_outlined, 'Deck library', 'library'),
      _Page.guide => (Icons.menu_book_outlined, 'Field guide', 'guide'),
    };
    final color = active ? night : muted;
    final children = [
      Icon(icon, size: compact ? 19 : 17, color: active ? accent : color),
      SizedBox(width: compact ? 0 : 7, height: compact ? 4 : 0),
      Text(
        title,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: color,
          fontSize: compact ? 11 : 14,
          fontWeight: active ? FontWeight.w700 : FontWeight.w500,
        ),
      ),
    ];
    return Semantics(
      selected: active,
      button: true,
      child: Material(
        color: active ? const Color(0xffebe7dc) : Colors.transparent,
        borderRadius: BorderRadius.circular(compact ? 0 : 8),
        child: InkWell(
          key: ValueKey('nav-$key'),
          borderRadius: BorderRadius.circular(compact ? 0 : 8),
          onTap: () => _open(dest),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 4 : 14,
              vertical: compact ? 8 : 11,
            ),
            child: compact
                ? Column(mainAxisSize: MainAxisSize.min, children: children)
                : Row(children: children),
          ),
        ),
      ),
    );
  }
}
