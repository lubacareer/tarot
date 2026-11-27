"""Install the pinned x64 Flutter SDK on a fresh GitHub Actions runner."""

import hashlib
import os
import subprocess
from pathlib import Path
from tempfile import TemporaryDirectory, mkdtemp
from urllib.request import urlopen
from zipfile import ZipFile


# Flutter's releases_linux.json and releases_windows.json both identify stable
# 3.47.2 as commit d3b14c876900e553bc736ca19295fc09e3853e8e (Dart 3.13.2).
BASE = 'https://storage.googleapis.com/flutter_infra_release/releases/stable/'
RELEASES = {
    'Linux': (
        BASE + 'linux/flutter_linux_3.47.2-stable.tar.xz',
        '447878859d01ca9bfdb99a85f245af07ed8a15fedcd9d189c4749e8e92d1f185',
    ),
    'Windows': (
        BASE + 'windows/flutter_windows_3.47.2-stable.zip',
        '37934f2128a55d77a38baba12fd611157ed23a47bf7d2b7d17e9e84da118409d',
    ),
}


def install(platform, runner_temp, github_path):
    url, expected = RELEASES[platform]
    with TemporaryDirectory(dir=runner_temp) as staging:
        stage = Path(staging)
        archive = stage / url.rsplit('/', 1)[-1]
        digest = hashlib.sha256()
        with urlopen(url, timeout=90) as response, archive.open('wb') as output:
            while chunk := response.read(1024 * 1024):
                output.write(chunk)
                digest.update(chunk)
        if digest.hexdigest() != expected:
            raise ValueError(f'SHA-256 mismatch for {archive.name}')

        if platform == 'Windows':
            with ZipFile(archive) as zipped:
                zipped.extractall(stage)
        else:
            subprocess.run(['tar', '-xf', str(archive), '-C', str(stage)], check=True)
        sdk = stage / 'flutter'
        launcher = 'flutter.bat' if platform == 'Windows' else 'flutter'
        if not (sdk / 'bin' / launcher).is_file():
            raise FileNotFoundError(f'Missing Flutter launcher in {archive.name}')
        install_dir = Path(mkdtemp(prefix='verified-flutter-', dir=runner_temp)) / 'flutter'
        sdk.rename(install_dir)
    with github_path.open('a', encoding='utf-8') as paths:
        print(install_dir / 'bin', file=paths)
    print(f'Installed {archive.name} (SHA-256 {expected})')


if __name__ == '__main__':
    if os.environ['RUNNER_ARCH'] != 'X64':
        raise SystemExit('This build requires an x64 runner.')
    install(os.environ['RUNNER_OS'], Path(os.environ['RUNNER_TEMP']), Path(os.environ['GITHUB_PATH']))
