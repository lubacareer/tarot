import 'package:archive/archive.dart';
import 'package:flutter/services.dart';

import 'deck.dart';

/// Resolves card image keys inside the three bundled, uncompressed ZIP files.
/// Flutter's image cache can still evict decoded bitmaps independently.
class CardArtBundle extends CachingAssetBundle {
  CardArtBundle._();

  static final instance = CardArtBundle._();
  final _archives = <String, Future<Archive>>{};

  @override
  Future<ByteData> load(String key) async {
    final parts = key.split('/');
    if (parts.length != 4 ||
        parts[0] != 'assets' ||
        parts[1] != 'decks' ||
        !DeckCatalog.ids.contains(parts[2]) ||
        !parts.last.endsWith('.webp')) {
      return rootBundle.load(key);
    }
    final id = parts[2];
    final archive = await _archives.putIfAbsent(id, () => _open(id));
    final content = archive.find(parts.last)?.readBytes();
    if (content == null) {
      throw FormatException('Missing artwork in $id: ${parts.last}');
    }
    return ByteData.sublistView(content);
  }

  Future<Archive> _open(String id) async {
    try {
      final data = await rootBundle.load('assets/decks/$id/faces.zip');
      return ZipDecoder().decodeBytes(Uint8List.sublistView(data));
    } catch (_) {
      _archives.remove(id);
      rethrow;
    }
  }
}
