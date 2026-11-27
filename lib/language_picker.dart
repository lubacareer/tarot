import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'strings.dart';

const _names = {'en': 'English', 'he': 'עברית', 'ru': 'Русский'};

Locale resolveDeviceLanguage(List<Locale> locales) {
  for (final locale in locales) {
    if (_names.containsKey(locale.languageCode)) {
      return Locale(locale.languageCode);
    }
  }
  return const Locale('en');
}

abstract interface class LanguagePreferences {
  Future<String?> read();
  Future<void> write(String value);
}

class LocalLanguagePreferences implements LanguagePreferences {
  const LocalLanguagePreferences();

  @override
  Future<String?> read() => SharedPreferencesAsync().getString('language');

  @override
  Future<void> write(String value) =>
      SharedPreferencesAsync().setString('language', value);
}

class LanguageController extends ChangeNotifier {
  LanguageController(this._preferences);

  final LanguagePreferences _preferences;
  Future<void> _pendingWrite = Future.value();
  Locale? _override;
  bool _selected = false;
  bool _disposed = false;
  Locale? get explicitLocale => _override;

  Future<void> restore() async {
    final String? saved;
    try {
      saved = await _preferences.read();
    } on Exception catch (error) {
      // A missing backend or unreadable local file must not interrupt startup.
      if (error is! MissingPluginException &&
          error is! PlatformException &&
          error is! FormatException &&
          error is! FileSystemException) {
        rethrow;
      }
      return;
    } on StateError {
      // A headless Flutter engine may have no registered preferences implementation.
      return;
    }
    if (!_disposed &&
        !_selected &&
        saved != null &&
        _names.containsKey(saved)) {
      _override = Locale(saved);
      notifyListeners();
    }
  }

  Future<void> select(Locale locale) {
    if (!_names.containsKey(locale.languageCode)) {
      throw ArgumentError.value(locale);
    }
    _selected = true;
    _override = Locale(locale.languageCode);
    notifyListeners();
    // Serialize disk writes so rapid selections survive a restart in the same order.
    final write = _pendingWrite.then(
      (_) => _preferences.write(locale.languageCode),
    );
    _pendingWrite = write.catchError((Object _) {});
    return write;
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

class LanguageScope extends InheritedNotifier<LanguageController> {
  const LanguageScope({
    super.key,
    required LanguageController controller,
    required super.child,
  }) : super(notifier: controller);

  static LanguageController? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<LanguageScope>()?.notifier;
}

class LanguagePicker extends StatelessWidget {
  const LanguagePicker({super.key, this.compact = false});
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final controller = LanguageScope.maybeOf(context);
    final current = Localizations.localeOf(context).languageCode;
    return PopupMenuButton<String>(
      key: const ValueKey('language-picker'),
      tooltip: context.tr('Language'),
      position: PopupMenuPosition.under,
      initialValue: current,
      enabled: controller != null,
      onSelected: (code) async {
        try {
          await controller!.select(Locale(code));
        } catch (_) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  context.tr('Could not save the language preference.'),
                ),
              ),
            );
          }
        }
      },
      itemBuilder: (_) => [
        for (final item in _names.entries)
          CheckedPopupMenuItem<String>(
            key: ValueKey('language-${item.key}'),
            value: item.key,
            checked: current == item.key,
            child: Text(
              item.value,
              textDirection: item.key == 'he'
                  ? TextDirection.rtl
                  : TextDirection.ltr,
            ),
          ),
      ],
      child: Container(
        constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
        padding: EdgeInsets.symmetric(horizontal: compact ? 8 : 12),
        decoration: BoxDecoration(
          color: const Color(0xab141b29),
          border: Border.all(color: const Color(0x806f7c94)),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.language, size: 20),
            if (!compact) ...[
              const SizedBox(width: 8),
              Text(_names[current] ?? 'English'),
              const Icon(Icons.arrow_drop_down, size: 20),
            ],
          ],
        ),
      ),
    );
  }
}
