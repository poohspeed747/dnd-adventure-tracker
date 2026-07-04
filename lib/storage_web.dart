// lib/storage_web.dart  –– used on Web (dart:html)
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

const _lsKey = 'dnd_adventure_map';

/// Auto-save to localStorage.
void autoSave(String key, String jsonData) {
  try {
    html.window.localStorage[key] = jsonData;
  } catch (_) {}
}

/// Try to load from localStorage. Returns null if not found.
String? tryLoadAutoSave(String key) {
  try {
    return html.window.localStorage[key];
  } catch (_) {
    return null;
  }
}

/// Trigger a browser file download with the JSON data.
Future<String?> saveToFile(String suggestedName, String jsonData) async {
  try {
    final bytes = jsonData.codeUnits;
    final blob = html.Blob([bytes], 'application/json');
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..setAttribute('download', suggestedName)
      ..click();
    html.Url.revokeObjectUrl(url);
    return suggestedName;
  } catch (_) {
    return null;
  }
}

/// Open a browser file picker and return the file contents as a string.
Future<String?> loadFromFile() async {
  try {
    final input = html.FileUploadInputElement()..accept = '.json';
    input.click();
    await input.onChange.first;
    final file = input.files?.first;
    if (file == null) return null;
    final reader = html.FileReader();
    reader.readAsText(file);
    await reader.onLoad.first;
    return reader.result as String?;
  } catch (_) {
    return null;
  }
}