// lib/storage_native.dart  –– used on Windows/Linux/macOS
import 'dart:io';

/// Auto-save to a local JSON file next to the executable.
void autoSave(String key, String jsonData) {
  try {
    File('$key.json').writeAsStringSync(jsonData);
  } catch (_) {}
}

/// Try to load the auto-save file. Returns null if not found.
String? tryLoadAutoSave(String key) {
  try {
    final f = File('$key.json');
    if (f.existsSync()) return f.readAsStringSync();
  } catch (_) {}
  return null;
}

/// Save to a user-chosen path and return it, or null on failure.
Future<String?> saveToFile(String suggestedName, String jsonData) async {
  try {
    File(suggestedName).writeAsStringSync(jsonData);
    return suggestedName;
  } catch (_) {
    return null;
  }
}

/// Load from a file path. Returns JSON string or null on failure.
Future<String?> loadFromFile() async {
  // On native we use file_picker (imported dynamically in graph_provider)
  // This stub is replaced by the provider calling FilePicker directly.
  return null;
}