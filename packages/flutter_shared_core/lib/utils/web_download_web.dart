// ignore_for_file: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:typed_data';
import 'dart:convert';

/// Web implementation for file downloads using HTML5 APIs

/// Download file on web using HTML5 download API
void downloadFile(Uint8List bytes, String fileName, String mimeType) {
  final blob = html.Blob([bytes], mimeType);
  final url = html.Url.createObjectUrlFromBlob(blob);
  final anchor = html.AnchorElement()
    ..href = url
    ..style.display = 'none'
    ..download = fileName;
  html.document.body!.children.add(anchor);
  anchor.click();
  html.document.body!.children.remove(anchor);
  html.Url.revokeObjectUrl(url);
}

/// Create object URL from blob bytes
String createObjectUrlFromBlob(List<int> bytes, String mimeType) {
  final blob = html.Blob([bytes], mimeType);
  return html.Url.createObjectUrlFromBlob(blob);
}

/// Revoke object URL to free memory
void revokeObjectUrl(String url) {
  html.Url.revokeObjectUrl(url);
}

/// Download CSV data as a file
void downloadCSV(String csvContent, String fileName) {
  final bytes = utf8.encode(csvContent);
  final blob = html.Blob([bytes]);
  final url = html.Url.createObjectUrlFromBlob(blob);
  final anchor = html.document.createElement('a') as html.AnchorElement
    ..href = url
    ..style.display = 'none'
    ..download = fileName;
  html.document.body?.children.add(anchor);
  anchor.click();
  html.document.body?.children.remove(anchor);
  html.Url.revokeObjectUrl(url);
}

/// Open URL in new tab
void openUrlInNewTab(String url) {
  html.window.open(url, '_blank');
}
