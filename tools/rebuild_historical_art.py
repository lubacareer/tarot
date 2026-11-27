"""Rebuild bundled card faces from their credited sources (requires Pillow).

    python tools/rebuild_historical_art.py marseille
    python tools/rebuild_historical_art.py waite_smith

Coordinates in the catalog are pixel bounds (left, top, right, bottom) on the
exact sourceImage rendition. Right and bottom are exclusive. The current app
ships its WebPs inside faces.zip and runs offline.
"""

import argparse
import hashlib
import io
import json
from collections import defaultdict
from pathlib import Path
from urllib.request import Request, urlopen

from PIL import Image

from face_archive import write_faces_archive

DECKS = Path(__file__).resolve().parents[1] / 'assets' / 'decks'
USER_AGENT = 'TarotDeckCatalog/1.0 (+https://github.com/lubacareer/tarot)'


def prepare_card(card, source):
    if hashlib.sha256(source).hexdigest() != card['sourceImageSha256']:
        raise ValueError(f"Source checksum changed for {card['id']}")
    with Image.open(io.BytesIO(source)) as original:
        image = original.convert('RGB')
    if 'crop' in card:
        left, top, right, bottom = card['crop']
        if not (0 <= left < right <= image.width and 0 <= top < bottom <= image.height):
            raise ValueError(f"Invalid crop for {card['id']}")
        image = image.crop((left, top, right, bottom))
    image.thumbnail((820, 1200), Image.Resampling.LANCZOS)
    buffer = io.BytesIO()
    image.save(buffer, 'WEBP', quality=82, method=5)
    return buffer.getvalue()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('deck', choices=('waite_smith', 'marseille'))
    directory = DECKS / parser.parse_args().deck
    catalog = json.loads((directory / 'catalog.json').read_text(encoding='utf-8'))
    by_source = defaultdict(list)
    for card in catalog['cards']:
        by_source[card['sourceImage']].append(card)

    faces = {}
    for source_url, cards in by_source.items():
        request = Request(source_url, headers={'User-Agent': USER_AGENT})
        with urlopen(request, timeout=60) as response:
            source = response.read()
        for card in cards:
            name = card['image']
            if name in faces:
                raise ValueError(f'Duplicate face in catalog: {name}')
            faces[name] = prepare_card(card, source)
    write_faces_archive(directory / 'faces.zip', faces)


if __name__ == '__main__':
    main()
