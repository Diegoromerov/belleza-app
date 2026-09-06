// frontend/lib/core/photography/photography_repository.dart
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

/// A simple repository for accessing photography metadata.
class PhotographyRepository {
  PhotographyRepository._internal();

  static final PhotographyRepository _instance = PhotographyRepository._internal();
  factory PhotographyRepository() => _instance;

  Map<String, dynamic>? _metadata;

  Future<void> loadMetadata() async {
    if (_metadata != null) return;
    final String jsonString =
        await rootBundle.loadString('images/metadata.json');
    _metadata = jsonDecode(jsonString);
  }

  /// Returns the metadata map for the given assetId, or null if not found.
  Future<Map<String, dynamic>?> getAssetData(String assetId) async {
    await loadMetadata();
    final assets = _metadata?['assets'] as List<dynamic>?;
    if (assets == null) return null;
    for (final asset in assets) {
      if (asset['id'] == assetId) {
        // Return a copy to avoid external mutation of the internal cache.
        return Map<String, dynamic>.from(asset);
      }
    }
    return null;
  }
}