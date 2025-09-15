import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
// still needed for mobile save

class ReportPdf {
  /// Generate PDF
  static Future<Uint8List?> generate(
      BuildContext context, Map<String, dynamic> report) async {
    try {
      final pdf = pw.Document();

      // ✅ Load logo from assets
      final logoBytes = await rootBundle.load('barangay.png');
      final logo = pw.MemoryImage(logoBytes.buffer.asUint8List());

      // ✅ Load proof image (from bytes instead of File)
      pw.ImageProvider? proofImage;
      if (report["proofBytes"] != null) {
        proofImage = pw.MemoryImage(report["proofBytes"]);
      }

      // ✅ Build PDF page
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context ctx) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Image(logo, width: 60, height: 60),
                    pw.Text("Report Document",
                        style: pw.TextStyle(
                            fontSize: 20, fontWeight: pw.FontWeight.bold)),
                  ],
                ),
                pw.SizedBox(height: 20),

                _buildDetail("Title", report["title"]),
                _buildDetail("Location", report["location"]),
                _buildDetail("Description", report["description"]),
                _buildDetail("Date", report["date"]),
                _buildDetail("Time", report["time"]),
                _buildDetail("Priority", report["priority"]),
                _buildDetail("Status", report["status"]),
                pw.SizedBox(height: 10),

                if (proofImage != null) ...[
                  pw.Text("Proof:", style: pw.TextStyle(fontSize: 14)),
                  pw.SizedBox(height: 10),
                  pw.Image(proofImage, width: 200, height: 200),
                ],
              ],
            );
          },
        ),
      );

      return await pdf.save(); // ✅ return raw bytes (works everywhere)
    } catch (e) {
      debugPrint("PDF generation error: $e");
      return null;
    }
  }

  static pw.Widget _buildDetail(String label, dynamic value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text("$label: ",
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          pw.Expanded(
            child: pw.Text(value?.toString() ?? "-"),
          ),
        ],
      ),
    );
  }
}

Widget buildProofImage(
  Uint8List? bytes, [
  String? urlOrAsset,
  BoxFit fit = BoxFit.cover,
]) {
  if (bytes != null) {
    // ✅ Works on Web + Mobile
    return Image.memory(bytes, width: 60, height: 60, fit: fit);
  }

  if (urlOrAsset == null || urlOrAsset.isEmpty) {
    return const Icon(Icons.image_not_supported, size: 60, color: Colors.grey);
  }

  if (urlOrAsset.startsWith("http")) {
    // ✅ From network
    return Image.network(urlOrAsset, width: 60, height: 60, fit: fit);
  } else if (urlOrAsset.startsWith("assets/")) {
    // ✅ From bundled assets (clean.png, clean.jpg, etc.)
    return Image.asset(urlOrAsset, width: 60, height: 60, fit: fit);
  }

  // Unknown → fallback
  return const Icon(Icons.image_not_supported, size: 60, color: Colors.grey);
}
