import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../interpretation.dart';
import '../reading.dart';
import '../language_picker.dart';
import '../strings.dart';
import 'library.dart';
import 'reading_table.dart';
import 'setup.dart';
import 'style.dart';

enum _Page { table, library, guide }

class Observatory extends StatefulWidget {
  const Observatory({
    super.key,
    required this.loadDecks,
    this.interpretationClient = const InterpretationClient(),
  });
  final Future<List<TarotDeck>> Function() loadDecks;
  final InterpretationClient interpretationClient;
  @override
  State<Observatory> createState() => _ObservatoryState();
}

class _ObservatoryState extends State<Observatory> {
  late Future<List<TarotDeck>> catalog = widget.loadDecks();
  _Page page = _Page.table;
  TarotDeck? chosen;
  SpreadType spread = SpreadType.one;
  bool reversals = false;
  bool online = true;
  final question = TextEditingController();
  ReadingSession? session;
  ReadingInterpretations? interpretations;
  final scroll = ScrollController();

  @override
  void dispose() {
    scroll.dispose();
    question.dispose();
    interpretations?.dispose();
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
            title: Text(context.tr('Leave this reading?')),
            content: Text(
              context.tr(
                exiting
                    ? 'Exiting clears the cards on this table.'
                    : 'Starting again clears the cards on this table.',
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(context.tr('Keep reading')),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(context.tr(exiting ? 'Exit app' : 'Start again')),
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
      setState(_clearReading);
      await SystemNavigator.pop();
    }
  }

  Future<void> _setup([TarotDeck? deck]) async {
    if (!await _canEndReading() || !mounted) return;
    setState(() {
      if (session != null) _clearReading();
      if (deck != null) chosen = deck;
      page = _Page.table;
    });
    _toTop();
  }

  void _start(TarotDeck deck) {
    if (session != null) return;
    final reading = ReadingSession.start(deck, spread, reversals: reversals);
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      session = reading;
      interpretations = ReadingInterpretations(
        session: reading,
        client: widget.interpretationClient,
        online: online,
        question: question.text.trim(),
      );
    });
    _toTop();
  }

  void _clearReading() {
    session = null;
    interpretations?.dispose();
    interpretations = null;
    question.clear();
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, size) => _layout(context, size.maxWidth),
  );

  Widget _layout(BuildContext context, double width) {
    final labelScale = MediaQuery.textScalerOf(context).scale(14) / 14;
    final narrow = width < 970 * labelScale.clamp(1.0, 3.0);
    final scaffold = Stack(
      fit: StackFit.expand,
      children: [
        ObservatorySky(key: const ValueKey("observatory-sky"), compact: narrow),
        Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
            child: Column(
              children: [
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1480),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: narrow ? 8 : 16,
                        vertical: narrow ? 5 : 14,
                      ),
                      child: SkyPanel(
                        radius: 12,
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: narrow ? 9 : 20,
                            vertical: narrow ? 7 : 10,
                          ),
                          child: Row(
                            children: [
                              ObservatoryMark(size: narrow ? 23 : 36),
                              SizedBox(width: narrow ? 6 : 12),
                              Expanded(
                                child: Text(
                                  context.tr('Arcana Observatory'),
                                  style: display(narrow ? 16 : 24),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (!narrow) ...[
                                ..._Page.values.map(
                                  (value) => _navItem(value, compact: false),
                                ),
                                const SizedBox(width: 20),
                              ],
                              LanguagePicker(
                                compact:
                                    narrow &&
                                    (MediaQuery.sizeOf(context).width < 350 ||
                                        labelScale > 1.32),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: FutureBuilder<List<TarotDeck>>(
                    future: catalog,
                    builder: (context, snap) {
                      if (snap.connectionState != ConnectionState.done) {
                        return Center(
                          child: CircularProgressIndicator(
                            semanticsLabel: context.tr('Opening deck library'),
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
                              Text(
                                context.tr(
                                  'The deck library could not be opened.',
                                ),
                              ),
                              const SizedBox(height: 12),
                              FilledButton(
                                onPressed: () => setState(
                                  () => catalog = widget.loadDecks(),
                                ),
                                child: Text(context.tr('Try again')),
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
                                interpretations: interpretations,
                                active: page == _Page.table,
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
                              online: online,
                              question: question,
                              onOnline: (value) =>
                                  setState(() => online = value),
                              onDeck: (v) => setState(() => chosen = v),
                              onSpread: (v) => setState(() => spread = v),
                              onReversals: (v) => setState(() => reversals = v),
                              onStart: () => _start(chosen ?? decks.first),
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
                            constraints: const BoxConstraints(maxWidth: 1460),
                            child: Padding(
                              padding: EdgeInsets.fromLTRB(
                                narrow ? 12 : 40,
                                narrow ? 7 : 19,
                                narrow ? 12 : 40,
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
                      color: Color(0xf00b1824),
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
        ),
      ],
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
    final color = active ? ivory : muted;
    final children = [
      Icon(icon, size: compact ? 19 : 17, color: active ? accent : color),
      SizedBox(width: compact ? 0 : 7, height: compact ? 4 : 0),
      Text(
        context.tr(
          compact
              ? switch (dest) {
                  _Page.table => 'Table',
                  _Page.library => 'Library',
                  _Page.guide => 'Guide',
                }
              : title,
        ),
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
        color: active ? const Color(0x70413b51) : Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(compact ? 0 : 8),
          side: BorderSide(
            color: active ? accent : Colors.transparent,
            width: 1.2,
          ),
        ),
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
