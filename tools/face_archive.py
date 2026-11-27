"""Write a standard, reproducible archive containing one complete tarot deck."""

import re
from pathlib import Path
from tempfile import TemporaryDirectory
from zipfile import ZIP_STORED, ZipFile, ZipInfo


def write_faces_archive(destination, faces):
    if len(faces) != 78:
        raise ValueError('A deck requires exactly 78 unique faces')
    if any(not re.fullmatch(r'[a-z0-9_]+\.webp', name) for name in faces):
        raise ValueError('Each face must have a plain WebP filename')
    destination = Path(destination)
    with TemporaryDirectory(dir=destination.parent) as staging:
        path = Path(staging) / 'faces.zip'
        with ZipFile(path, 'w') as archive:
            for name in sorted(faces):
                info = ZipInfo(name, date_time=(1980, 1, 1, 0, 0, 0))
                info.compress_type = ZIP_STORED
                info.create_system = 3
                info.external_attr = 0o100644 << 16
                archive.writestr(info, faces[name])
        path.replace(destination)
