import json
import unittest
from pathlib import Path

from PIL import Image


ASSETS = Path(__file__).resolve().parents[1] / 'assets' / 'decks'
MAJORS = 'fool magician high_priestess empress emperor hierophant lovers chariot strength hermit wheel_of_fortune justice hanged_man death temperance devil tower star moon sun judgement world'.split()
SUITS = ('cups', 'pentacles', 'wands', 'swords')
RANKS = ['ace', *map(str, range(2, 11)), 'page', 'knight', 'queen', 'king']


class HistoricalDeckTests(unittest.TestCase):
    def catalog(self, deck_id):
        return json.loads((ASSETS / deck_id / 'catalog.json').read_text(encoding='utf-8'))

    def test_complete_decks_with_portrait_webp_art_and_provenance(self):
        expected = set(MAJORS) | {f'{suit}_{rank}' for suit in SUITS for rank in RANKS}
        for deck_id in ('waite_smith', 'marseille'):
            with self.subTest(deck=deck_id):
                catalog = self.catalog(deck_id)
                self.assertEqual(catalog['id'], deck_id)
                cards = catalog['cards']
                self.assertEqual(len(cards), 78)
                self.assertEqual({card['id'] for card in cards}, expected)
                self.assertEqual(len({card['image'] for card in cards}), 78)
                for card in cards:
                    for field in ('title', 'meaning', 'reversed', 'symbolism', 'source'):
                        self.assertTrue(card[field].strip(), (card['id'], field))
                    self.assertTrue(card['source'].startswith('https://'))
                    with Image.open(ASSETS / deck_id / card['image']) as img:
                        self.assertEqual(img.format, 'WEBP')
                        self.assertGreaterEqual(img.height, 800)
                        self.assertTrue(0.44 < img.width / img.height < 0.64, card['id'])
                        img.verify()

    def test_strength_and_justice_have_their_own_deck_numbers(self):
        for deck_id, strength, justice in [('waite_smith', 'VIII', 'XI'), ('marseille', 'XI', 'VIII')]:
            cards = {card['id']: card for card in self.catalog(deck_id)['cards']}
            self.assertEqual(cards['strength']['number'], strength)
            self.assertEqual(cards['justice']['number'], justice)


if __name__ == '__main__':
    unittest.main()
