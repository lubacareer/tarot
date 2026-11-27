import hashlib
import io
import tarfile
import unittest
import zipfile
from pathlib import Path
from tempfile import TemporaryDirectory
from unittest.mock import patch

import install_flutter


class FlutterInstallationTests(unittest.TestCase):
    def archive(self, platform):
        buffer = io.BytesIO()
        if platform == 'Windows':
            with zipfile.ZipFile(buffer, 'w') as archive:
                archive.writestr('flutter/bin/flutter.bat', b'test launcher')
        else:
            with tarfile.open(fileobj=buffer, mode='w:xz') as archive:
                launcher = tarfile.TarInfo('flutter/bin/flutter')
                launcher.mode = 0o755
                launcher.size = len(b'test launcher')
                archive.addfile(launcher, io.BytesIO(b'test launcher'))
        return buffer.getvalue()

    def test_verified_archives_install_in_fresh_directories(self):
        for platform in ('Linux', 'Windows'):
            with self.subTest(platform=platform), TemporaryDirectory() as tmp:
                root = Path(tmp)
                other = root / 'flutter' / 'bin'
                other.mkdir(parents=True)
                path_file = root / 'runner-path'
                data = self.archive(platform)
                url = install_flutter.RELEASES[platform][0]
                with patch.dict(install_flutter.RELEASES, {
                    platform: (url, hashlib.sha256(data).hexdigest())
                }), patch.object(install_flutter, 'urlopen', return_value=io.BytesIO(data)):
                    install_flutter.install(platform, root, path_file)
                added = Path(path_file.read_text(encoding='utf-8').strip())
                self.assertTrue(added.is_relative_to(root))
                self.assertNotEqual(added, other)
                launcher = 'flutter.bat' if platform == 'Windows' else 'flutter'
                self.assertEqual((added / launcher).read_bytes(), b'test launcher')

    def test_checksum_failure_does_not_extract_or_change_path(self):
        with TemporaryDirectory() as tmp:
            root = Path(tmp)
            path_file = root / 'runner-path'
            path_file.write_bytes(b'previous path\n')
            with patch.object(install_flutter, 'urlopen', return_value=io.BytesIO(b'wrong')), \
                    patch.object(install_flutter.subprocess, 'run') as extract:
                with self.assertRaisesRegex(ValueError, 'SHA-256'):
                    install_flutter.install('Linux', root, path_file)
            extract.assert_not_called()
            self.assertEqual(path_file.read_bytes(), b'previous path\n')
            self.assertEqual(list(root.iterdir()), [path_file])
