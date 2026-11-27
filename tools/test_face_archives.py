import json
import unittest
from pathlib import Path
from tempfile import TemporaryDirectory
from unittest.mock import patch
from zipfile import ZIP_STORED, ZipFile

from face_archive import write_faces_archive


DECKS = Path(__file__).resolve().parents[1] / 'assets' / 'decks'


class FaceArchiveTests(unittest.TestCase):
    def test_all_decks_match_catalogs_and_integrity_checks(self):
        for deck in ('waite_smith', 'marseille', 'celestial'):
            folder = DECKS / deck
            catalog = json.loads((folder / 'catalog.json').read_text(encoding='utf-8'))
            names = [card['image'] for card in catalog['cards']]
            self.assertEqual(len(names), 78)
            self.assertEqual(len(set(names)), 78)
            with self.subTest(deck=deck), ZipFile(folder / 'faces.zip') as archive:
                self.assertIsNone(archive.testzip(), 'invalid CRC')
                self.assertEqual(archive.namelist(), sorted(names))
                for entry in archive.infolist():
                    self.assertRegex(entry.filename, r'^[a-z0-9_]+\.webp$')
                    self.assertEqual(entry.compress_type, ZIP_STORED)
                    self.assertEqual(entry.compress_size, entry.file_size)
                    self.assertEqual(entry.date_time, (1980, 1, 1, 0, 0, 0))
                    self.assertEqual(entry.create_system, 3)
                    self.assertEqual(entry.external_attr >> 16, 0o100644)
                    self.assertEqual(entry.flag_bits, 0)
                    self.assertEqual(entry.extra, b'')
                    self.assertEqual(entry.comment, b'')

    def test_bytes_do_not_depend_on_input_order(self):
        faces = {f'card_{n}.webp': bytes([n]) for n in range(78)}
        with TemporaryDirectory() as folder:
            path = Path(folder) / 'faces.zip'
            write_faces_archive(path, faces)
            expected = path.read_bytes()
            write_faces_archive(path, dict(reversed(faces.items())))
            self.assertEqual(path.read_bytes(), expected)

    def test_failed_write_preserves_previous_archive(self):
        faces = {f'card_{n}.webp': bytes([n]) for n in range(78)}
        with TemporaryDirectory() as folder:
            path = Path(folder) / 'faces.zip'
            path.write_bytes(b'old archive')
            with patch.object(ZipFile, 'writestr', side_effect=OSError('Disk full')):
                with self.assertRaises(OSError):
                    write_faces_archive(path, faces)
            self.assertEqual(path.read_bytes(), b'old archive')
            self.assertEqual(list(Path(folder).iterdir()), [path])
