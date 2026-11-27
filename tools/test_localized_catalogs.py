import json
import re
import unittest
from pathlib import Path


DECKS = Path(__file__).resolve().parents[1] / 'assets' / 'decks'
FIELDS = {'title', 'symbolism', 'meaning', 'reversed'}
SCRIPTS = {'he': re.compile(r'[\u05d0-\u05ea]'), 'ru': re.compile(r'[\u0400-\u04ff]')}


def unique_object(pairs):
    result = {}
    for key, value in pairs:
        if key in result:
            raise ValueError(f'Duplicate catalog key: {key}')
        result[key] = value
    return result


class LocalizedCatalogTests(unittest.TestCase):
    def test_translations_cover_every_deck_specific_card_and_field(self):
        for directory in ('waite_smith', 'marseille', 'celestial'):
            folder = DECKS / directory
            base = json.loads((folder / 'catalog.json').read_text(encoding='utf-8'))
            for locale, script in SCRIPTS.items():
                with self.subTest(deck=directory, locale=locale):
                    text = (folder / f'{locale}.json').read_text(encoding='utf-8')
                    overlay = json.loads(text, object_pairs_hook=unique_object)
                    self.assertEqual(set(overlay), {'name', 'credit', 'rights', 'cards'})
                    self.assertEqual(len(overlay['cards']), 78)
                    self.assertEqual(set(overlay['cards']), {card['id'] for card in base['cards']})
                    for key in ('name', 'credit', 'rights'):
                        self.assertRegex(overlay[key], script)
                    for original in base['cards']:
                        card = overlay['cards'][original['id']]
                        self.assertEqual(set(card), FIELDS)
                        for field in FIELDS:
                            value = card[field]
                            self.assertEqual(value, value.strip())
                            self.assertRegex(value, script)
                            self.assertNotEqual(value, original[field])
                            self.assertNotIn('\ufffd', value)
                            self.assertNotRegex(value, r'[A-Za-z]{3,}\s+[A-Za-z]{3,}')
                        self.assertNotEqual(card['meaning'], card['reversed'])
                    for field in FIELDS:
                        values = {card[field] for card in overlay['cards'].values()}
                        self.assertEqual(len(values), 78, f'Repeated {field} in {directory}/{locale}')
