import 'dart:html' as html;

class PdfDownloadHelper {
  static void downloadPdf(List<int> bytes, String filename) {
    final blob = html.Blob([bytes]);
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..download = filename
      ..click();
    html.Url.revokeObjectUrl(url);
  }
}
