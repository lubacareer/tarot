import 'dart:async';
import 'dart:io';

import 'package:arcana_observatory/language_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class MemoryPreferences implements LanguagePreferences {
  String? saved;
  @override
  Future<String?> read() async => saved;
  @override
  Future<void> write(String value) async => saved = value;
}

void main() {
  test(
    'device locales are matched in order and unsupported lists use English',
    () {
      expect(
        resolveDeviceLanguage([const Locale('de'), const Locale('he', 'IL')]),
        const Locale('he'),
      );
      expect(
        resolveDeviceLanguage([const Locale('ru', 'RU')]),
        const Locale('ru'),
      );
      expect(resolveDeviceLanguage([const Locale('hi')]), const Locale('en'));
    },
  );
  test(
    'restoring and switching languages persists the explicit override',
    () async {
      final preferences = MemoryPreferences()..saved = 'he';
      final first = LanguageController(preferences);
      await first.restore();
      expect(first.explicitLocale, const Locale('he'));
      await first.select(const Locale('ru'));
      final reopened = LanguageController(preferences);
      await reopened.restore();
      expect(reopened.explicitLocale, const Locale('ru'));
      first.dispose();
      reopened.dispose();
    },
  );
  test('a late startup read cannot overwrite an explicit selection', () async {
    final delayed = Completer<String?>();
    final controller = LanguageController(_DelayedRead(delayed.future));
    final restoring = controller.restore();
    await controller.select(const Locale('en'));
    delayed.complete('he');
    await restoring;
    expect(controller.explicitLocale, const Locale('en'));
    controller.dispose();
  });
  test(
    'an unreadable or corrupt preference file keeps the device default',
    () async {
      for (final error in [
        const FormatException('invalid JSON'),
        const FileSystemException('unreadable'),
      ]) {
        final controller = LanguageController(
          _DelayedRead(Future.error(error)),
        );
        await controller.restore();
        expect(controller.explicitLocale, isNull);
        controller.dispose();
      }
    },
  );
}

class _DelayedRead extends MemoryPreferences {
  _DelayedRead(this.result);
  final Future<String?> result;
  @override
  Future<String?> read() => result;
}
