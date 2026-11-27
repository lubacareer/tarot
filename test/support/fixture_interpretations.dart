import 'package:arcana_observatory/interpretation.dart';

const fixtureInterpretations = FixtureInterpretationClient();

class FixtureInterpretationClient extends InterpretationClient {
  const FixtureInterpretationClient();

  @override
  Future<Interpretation> interpret(InterpretationRequest request) async {
    final count = request.cards.length;
    final finalCount = {
      'one': 1,
      'three': 3,
      'celticCross': 10,
    }[request.spreadId];
    return Interpretation(
      card: 'Card insight ${request.language} $count',
      synthesis: count > 1 && count == finalCount
          ? 'Spread insight ${request.language} $count'
          : null,
    );
  }
}
