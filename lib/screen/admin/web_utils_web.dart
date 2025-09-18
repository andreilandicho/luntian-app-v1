// Only compiled for web
import 'dart:html' as html;
import 'dart:typed_data';

void downloadPdfWeb(Uint8List pdfBytes, String fileName) {
  final blob = html.Blob([pdfBytes]);
  final url = html.Url.createObjectUrlFromBlob(blob);
  final anchor = html.AnchorElement(href: url)
    ..setAttribute("download", fileName)
    ..click();
  html.Url.revokeObjectUrl(url);
}
