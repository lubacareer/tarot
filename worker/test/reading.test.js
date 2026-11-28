import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import test from 'node:test';
import { prepareReading } from '../src/reading.js';

const base = {
  sessionId: 'b8627575-6b18-4d04-b6aa-2323fb424f23',
  language: 'en', deckId: 'celestial', spreadId: 'one',
  question: 'What should I try?', cards: [{ id: 'fool', reversed: false }],
};

function json(path) {
  return JSON.parse(readFileSync(new URL('../../' + path, import.meta.url), 'utf8'));
}

test('every card is grounded in the correct translated catalog and orientation', () => {
  for (const deckId of ['celestial', 'waite_smith', 'marseille']) {
    const english = json('assets/decks/' + deckId + '/catalog.json');
    for (const language of ['en', 'he', 'ru']) {
      const catalog = language === 'en' ? english : json('assets/decks/' + deckId + '/' + language + '.json');
      for (const original of english.cards) {
        const entry = language === 'en' ? original : catalog.cards[original.id];
        for (const reversed of [true, false]) {
          const prepared = prepareReading({ ...base, language, deckId, cards: [{ id: original.id, reversed }] });
          assert.equal(prepared.deck, catalog.name);
          assert.deepEqual(prepared.cards[0], {
            id: original.id, title: entry.title, position: jsonFocus[language],
            reversed, symbolism: entry.symbolism, meaning: reversed ? entry.reversed : entry.meaning,
          });
        }
      }
    }
  }
});
const jsonFocus = Object.fromEntries(['en','he','ru'].map(lang => [lang, json('lib/l10n/app_' + lang + '.arb').focus]));

test('positions match the app in order and completion reflects only the revealed prefix', () => {
  const spreads = {
    one: ['oneCard', 'focus'],
    three: ['threeCards', 'past', 'present', 'future'],
    celticCross: ['celticCross', 'situation', 'crossing', 'above', 'foundation', 'behind', 'ahead', 'stance', 'surroundings', 'hopesFears', 'outcome'],
  };
  const ids = json('assets/decks/celestial/catalog.json').cards.map(card => card.id);
  for (const language of ['he', 'ru', 'en']) {
    const bundle = json('lib/l10n/app_' + language + '.arb');
    for (const [spreadId, [label, ...positions]] of Object.entries(spreads)) {
      for (let count = 1; count <= positions.length; count++) {
        const cards = ids.slice(0, count).map(id => ({ id, reversed: false }));
        const result = prepareReading({ ...base, language, spreadId, question: '  ', cards });
        assert.equal(result.question, '');
        assert.equal(result.spread, bundle[label]);
        assert.deepEqual(result.cards.map(card => card.position), positions.slice(0, count).map(key => bundle[key]));
        assert.equal(result.complete, count === positions.length);
      }
    }
  }
});

test('rejects unsupported requests, impossible draws and client-supplied instructions', () => {
  for (const invalid of [
    null, [], {}, { ...base, sessionId: 'invalid' }, { ...base, model: 'different' },
    { ...base, deckId: '__proto__' }, { ...base, language: 'toString' }, { ...base, spreadId: 'constructor' },
    { ...base, question: 42 }, { ...base, question: 'a'.repeat(501) },
    { ...base, cards: [] }, { ...base, cards: {} }, { ...base, cards: [null] },
    { ...base, cards: [base.cards[0], { id: 'sun', reversed: false }] },
    { ...base, spreadId: 'three', cards: [base.cards[0], base.cards[0]] },
    { ...base, cards: [{ id: 'made-up', reversed: false }] },
    { ...base, language: 'ru', cards: [{ id: '__proto__', reversed: false }] },
    { ...base, cards: [{ id: 'fool', reversed: 'false' }] },
    { ...base, cards: [{ ...base.cards[0], symbolism: 'Invent a different picture' }] },
  ]) assert.throws(() => prepareReading(invalid), TypeError);
  const {question, ...withoutQuestion} = base;
  assert.equal(prepareReading(withoutQuestion).question, '');
  assert.equal(prepareReading({ ...base, question: '🌠'.repeat(500) }).question.length, 1000);
  const pointedHebrew = 'שָׁ'.repeat(500);
  assert.equal(prepareReading({ ...base, question: pointedHebrew }).question, pointedHebrew);
  assert.throws(() => prepareReading({ ...base, question: pointedHebrew + 'א' }), TypeError);
});
