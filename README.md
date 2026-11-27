# Arcana Observatory

Arcana Observatory is a free, offline tarot reader for Android and Windows x64. Choose a deck, pick cards from the shuffled fan, and turn them over one at a time. Each lesson starts with a detail you can see in that deck's illustration.

| Deck | What you can explore |
| --- | --- |
| Rider–Waite–Smith | Pamela Colman Smith's illustrated scenes, from the Pam-A printing |
| Tarot de Marseille | Jean-Pierre Payen's Avignon woodcuts, including the numbered suit patterns |
| Celestial Arcana | 78 original cosmic paintings with individual scene briefs |

Read a single card, follow a Past–Present–Future spread, or lay out the ten-card Celtic Cross. Reversals are optional. Enlarge a card to examine its symbols, or use the deck library to study the illustrations and meanings between readings.

## Run an app

- **Windows 10/11 x64.** Extract the entire portable ZIP, then open `arcana_observatory.exe` in that folder.
- **Android 7.0 or later.** Open the preview APK on the device and follow Android's install prompt. CI signs each preview with a build-machine key. Android may require removing a differently signed preview before installing a new one.

Builds are available as artifacts on successful **Test and package** workflow runs. Sign in to GitHub to download the artifacts. [Builds](https://github.com/lubacareer/tarot/actions/workflows/build.yml)

## Build and test

Use Flutter 3.47.2, the Android SDK for APKs, and Visual Studio with the Desktop development with C++ workload for Windows. All artwork, fonts and lessons are in the checkout. Once the build dependencies are installed, the app works offline.

```sh
flutter pub get --enforce-lockfile
dart format --output=none --set-exit-if-changed lib test integration_test
flutter analyze
flutter test
flutter devices
```

Run the end-to-end suite with `flutter test integration_test -d windows` or use the Android device ID reported by `flutter devices`. Build an APK with `flutter build apk --release`. On Windows, run `flutter build windows --release` followed by `.\tool\package_windows.ps1`. The APK is under `build/app/outputs/flutter-apk/` and the portable ZIP is under `build/`.

## Art and licensing

The code uses the MIT license. Original Celestial Arcana images, card backs and lessons use Creative Commons Attribution 4.0. The historical deck catalogs include provenance for each individual scan. Font notices ship with the app. [Code license](LICENSE) · [Artwork and font credits](ARTWORK-LICENSE.md)
