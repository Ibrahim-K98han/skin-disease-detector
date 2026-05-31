import 'dart:io';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';

class PdfService {
  static Future<void> generateReport({
    required String imagePath,
    required String disease,
    required String diseaseBangla,
    required double confidence,
    required List<dynamic> top3,
    required String advice,
    required Map<String, String> diseaseInBangla,
  }) async {
    // ✅ Bangla Font load করছি
    final fontData = await rootBundle.load(
      'assets/fonts/NotoSansBengali-Regular.ttf',
    );
    final banglaFont = pw.Font.ttf(fontData);

    // PDF document তৈরি
    final pdf = pw.Document();

    // ছবি load করো
    pw.MemoryImage? scanImage;
    if (File(imagePath).existsSync()) {
      final imageBytes = await File(imagePath).readAsBytes();
      scanImage = pw.MemoryImage(imageBytes);
    }

    // তারিখ format
    final now = DateTime.now();
    final dateFormat = DateFormat('dd MMMM yyyy, hh:mm a');
    final formattedDate = dateFormat.format(now);

    // PDF page বানাচ্ছি
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // ✅ Header
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(16),
                decoration: pw.BoxDecoration(
                  color: PdfColors.teal,
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Column(
                  children: [
                    pw.Text(
                      'Skin Disease Detection Report',
                      style: pw.TextStyle(
                        fontSize: 20,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.white,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'AI-powered Analysis',
                      style: pw.TextStyle(fontSize: 12, color: PdfColors.white),
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 16),

              // ✅ তারিখ
              pw.Row(
                children: [
                  pw.Text(
                    'Report Date: ',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                  pw.Text(formattedDate),
                ],
              ),

              pw.SizedBox(height: 16),
              pw.Divider(),
              pw.SizedBox(height: 16),

              // ✅ ছবি ও Result পাশাপাশি
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // ছবি
                  if (scanImage != null)
                    pw.Container(
                      width: 150,
                      height: 150,
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(color: PdfColors.teal),
                        borderRadius: pw.BorderRadius.circular(8),
                      ),
                      child: pw.ClipRRect(
                        horizontalRadius: 8,
                        verticalRadius: 8,
                        child: pw.Image(scanImage, fit: pw.BoxFit.cover),
                      ),
                    ),

                  pw.SizedBox(width: 16),

                  // Result
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'Detected Disease:',
                          style: pw.TextStyle(
                            fontSize: 12,
                            color: PdfColors.grey700,
                          ),
                        ),
                        pw.SizedBox(height: 4),

                        // ✅ বাংলায় রোগের নাম
                        pw.Text(
                          diseaseBangla,
                          style: pw.TextStyle(
                            font: banglaFont,
                            fontSize: 16,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),

                        pw.Text(
                          '($disease)',
                          style: pw.TextStyle(
                            fontSize: 11,
                            color: PdfColors.grey600,
                            fontStyle: pw.FontStyle.italic,
                          ),
                        ),
                        pw.SizedBox(height: 12),

                        pw.Text(
                          'Confidence: ${confidence.toStringAsFixed(1)}%',
                          style: pw.TextStyle(
                            fontSize: 14,
                            fontWeight: pw.FontWeight.bold,
                            color: confidence > 70
                                ? PdfColors.green700
                                : PdfColors.orange700,
                          ),
                        ),
                        pw.SizedBox(height: 8),

                        // ✅ Confidence bar (Stack দিয়ে)
                        pw.Stack(
                          children: [
                            pw.Container(
                              height: 10,
                              width: double.infinity,
                              decoration: pw.BoxDecoration(
                                color: PdfColors.grey300,
                                borderRadius: pw.BorderRadius.circular(5),
                              ),
                            ),
                            pw.Container(
                              height: 10,
                              width: 200 * (confidence / 100),
                              decoration: pw.BoxDecoration(
                                color: confidence > 70
                                    ? PdfColors.green
                                    : PdfColors.orange,
                                borderRadius: pw.BorderRadius.circular(5),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              pw.SizedBox(height: 20),
              pw.Divider(),
              pw.SizedBox(height: 12),

              // ✅ Top 3
              pw.Text(
                'Other Possibilities:',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 8),

              ...top3.asMap().entries.map((entry) {
                final index = entry.key + 1;
                final item = entry.value;
                final itemBangla =
                    diseaseInBangla[item['disease']] ?? item['disease'];
                final itemConf = item['confidence'] as double;

                return pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 8),
                  child: pw.Row(
                    children: [
                      // নম্বর circle
                      pw.Container(
                        width: 24,
                        height: 24,
                        decoration: const pw.BoxDecoration(
                          color: PdfColors.teal,
                          shape: pw.BoxShape.circle,
                        ),
                        child: pw.Center(
                          child: pw.Text(
                            '$index',
                            style: pw.TextStyle(
                              color: PdfColors.white,
                              fontSize: 12,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      pw.SizedBox(width: 8),

                      // ✅ বাংলা নাম
                      pw.Expanded(
                        child: pw.Text(
                          '$itemBangla (${item['disease']})',
                          style: pw.TextStyle(font: banglaFont, fontSize: 11),
                        ),
                      ),

                      // Percentage
                      pw.Text(
                        '${itemConf.toStringAsFixed(1)}%',
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.teal700,
                        ),
                      ),
                    ],
                  ),
                );
              }),

              pw.SizedBox(height: 16),
              pw.Divider(),
              pw.SizedBox(height: 12),

              // ✅ পরামর্শ
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  color: PdfColors.teal50,
                  borderRadius: pw.BorderRadius.circular(8),
                  border: pw.Border.all(color: PdfColors.teal200),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Advice / পরামর্শ:',
                      style: pw.TextStyle(
                        font: banglaFont,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.teal700,
                        fontSize: 13,
                      ),
                    ),
                    pw.SizedBox(height: 6),

                    // ✅ বাংলা পরামর্শ
                    pw.Text(
                      advice,
                      style: pw.TextStyle(font: banglaFont, fontSize: 12),
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 16),

              // ✅ Warning
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  color: PdfColors.amber50,
                  borderRadius: pw.BorderRadius.circular(8),
                  border: pw.Border.all(color: PdfColors.amber),
                ),
                child: pw.Text(
                  'WARNING: This is an AI-based analysis only. '
                  'Please consult a qualified dermatologist for accurate diagnosis.',
                  style: pw.TextStyle(fontSize: 11, color: PdfColors.orange900),
                ),
              ),

              pw.Spacer(),

              // ✅ Footer
              pw.Divider(),
              pw.Center(
                child: pw.Text(
                  'Generated by Skin Disease Detector App | AI-powered Analysis',
                  style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
                ),
              ),
            ],
          );
        },
      ),
    );

    // ✅ PDF save করো
    final directory = await getExternalStorageDirectory();
    final fileName =
        'skin_report_${DateFormat('yyyyMMdd_HHmmss').format(now)}.pdf';
    final filePath = '${directory!.path}/$fileName';

    final file = File(filePath);
    await file.writeAsBytes(await pdf.save());

    // ✅ PDF খোলো
    await OpenFile.open(filePath);
  }
}
