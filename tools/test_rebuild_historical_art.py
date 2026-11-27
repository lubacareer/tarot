import hashlib
import io
import unittest

from PIL import Image

from rebuild_historical_art import prepare_card


class ArtworkImportTests(unittest.TestCase):
    def setUp(self):
        sheet = Image.new('RGB', (80, 60), 'red')
        sheet.paste('blue', (40, 0, 80, 60))
        buffer = io.BytesIO()
        sheet.save(buffer, 'PNG')
        self.source = buffer.getvalue()
        self.entry = {
            'id': 'example',
            'crop': [40, 0, 80, 60],
            'sourceImageSha256': hashlib.sha256(self.source).hexdigest(),
        }

    def test_extracts_the_recorded_region(self):
        with Image.open(io.BytesIO(prepare_card(self.entry, self.source))) as image:
            self.assertEqual(image.format, 'WEBP')
            self.assertEqual(image.size, (40, 60))
            self.assertGreater(image.getpixel((20, 30))[2], 240)

    def test_rejects_changed_source_bytes(self):
        with self.assertRaisesRegex(ValueError, 'checksum'):
            prepare_card(self.entry, self.source + b'changed')

    def test_rejects_out_of_bounds_crop_instead_of_padding(self):
        self.entry['crop'] = [40, 0, 81, 60]
        with self.assertRaisesRegex(ValueError, 'crop'):
            prepare_card(self.entry, self.source)
