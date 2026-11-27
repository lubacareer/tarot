import celestial from '../../assets/decks/celestial/catalog.json' with { type: 'json' };
import celestialHe from '../../assets/decks/celestial/he.json' with { type: 'json' };
import celestialRu from '../../assets/decks/celestial/ru.json' with { type: 'json' };
import marseille from '../../assets/decks/marseille/catalog.json' with { type: 'json' };
import marseilleHe from '../../assets/decks/marseille/he.json' with { type: 'json' };
import marseilleRu from '../../assets/decks/marseille/ru.json' with { type: 'json' };
import waiteSmith from '../../assets/decks/waite_smith/catalog.json' with { type: 'json' };
import waiteSmithHe from '../../assets/decks/waite_smith/he.json' with { type: 'json' };
import waiteSmithRu from '../../assets/decks/waite_smith/ru.json' with { type: 'json' };

function indexEnglish(catalog) {
  return { name: catalog.name, cards: Object.fromEntries(catalog.cards.map(card => [card.id, card])) };
}

const catalogs = {
  celestial: { en: indexEnglish(celestial), he: celestialHe, ru: celestialRu },
  marseille: { en: indexEnglish(marseille), he: marseilleHe, ru: marseilleRu },
  waite_smith: { en: indexEnglish(waiteSmith), he: waiteSmithHe, ru: waiteSmithRu },
};

// These short display labels match the Flutter ARB resources. Each array starts
// with the spread title and continues with its positions in drawing order.
const spreads = {
  one: {
    en: ['One card', 'Focus'],
    he: ['קלף אחד', 'מוקד'],
    ru: ['Одна карта', 'Фокус'],
  },
  three: {
    en: ['Past · Present · Future', 'Past', 'Present', 'Future'],
    he: ['עבר · הווה · עתיד', 'עבר', 'הווה', 'עתיד'],
    ru: ['Прошлое · Настоящее · Будущее', 'Прошлое', 'Настоящее', 'Будущее'],
  },
  celticCross: {
    en: ['Celtic Cross', 'Situation', 'Crossing', 'Above', 'Foundation', 'Behind', 'Ahead', 'Your stance', 'Surroundings', 'Hopes and fears', 'Outcome'],
    he: ['הצלב הקלטי', 'המצב', 'ההשפעה החוצה', 'מעל', 'היסוד', 'מאחור', 'בהמשך הדרך', 'העמדה שלך', 'הסביבה', 'תקוות וחששות', 'התוצאה'],
    ru: ['Кельтский крест', 'Ситуация', 'Пересечение', 'Вверху', 'Основание', 'Позади', 'Впереди', 'Ваша позиция', 'Окружение', 'Надежды и страхи', 'Итог'],
  },
};

const sessionPattern = /^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;
const questionCharacters = new Intl.Segmenter(undefined, { granularity: 'grapheme' });
const maxQuestionCharacters = 500;

function check(condition) {
  if (!condition) throw new TypeError('Invalid reading request');
}

function hasOnlyFields(object, fields) {
  return object !== null && typeof object === 'object' && !Array.isArray(object) &&
    Object.keys(object).every(key => fields.includes(key));
}

// Flutter's TextField counts user-perceived characters. Avoid fully segmenting
// an oversized request once its 501st character is known.
function validQuestion(question) {
  if (typeof question !== 'string') return false;
  if (question.length <= maxQuestionCharacters) return true;
  let count = 0;
  for (const _ of questionCharacters.segment(question)) {
    if (++count > maxQuestionCharacters) return false;
  }
  return true;
}

export function prepareReading(payload) {
  check(hasOnlyFields(payload, ['sessionId', 'language', 'deckId', 'spreadId', 'question', 'cards']));
  const { sessionId, language, deckId, spreadId, question = '', cards } = payload;
  check(typeof sessionId === 'string' && sessionPattern.test(sessionId));
  check(typeof deckId === 'string' && Object.hasOwn(catalogs, deckId));
  check(typeof language === 'string' && Object.hasOwn(catalogs[deckId], language));
  check(typeof spreadId === 'string' && Object.hasOwn(spreads, spreadId));
  check(validQuestion(question));

  const catalog = catalogs[deckId][language];
  const [spread, ...positions] = spreads[spreadId][language];
  check(Array.isArray(cards) && cards.length > 0 && cards.length <= positions.length);
  const used = new Set();
  const revealed = cards.map((draw, index) => {
    check(hasOnlyFields(draw, ['id', 'reversed']));
    const { id, reversed } = draw;
    check(typeof id === 'string' && Object.hasOwn(catalog.cards, id) && !used.has(id));
    check(typeof reversed === 'boolean');
    used.add(id);
    const card = catalog.cards[id];
    return {
      id, title: card.title, position: positions[index], reversed,
      symbolism: card.symbolism, meaning: reversed ? card.reversed : card.meaning,
    };
  });
  return {
    sessionId: sessionId.toLowerCase(), language, deckId, deck: catalog.name, spreadId, spread,
    question: question.trim(), cards: revealed, complete: cards.length === positions.length,
  };
}
