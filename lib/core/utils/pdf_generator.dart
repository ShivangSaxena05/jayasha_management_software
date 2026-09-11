import 'dart:io';
import 'package:flutter/material.dart' show debugPrint;
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:file_picker/file_picker.dart';
import 'package:jayasha_childrens_academy/core/models/student_admission.dart';
import 'package:jayasha_childrens_academy/core/models/fee_payment.dart';
import 'package:jayasha_childrens_academy/core/models/teacher.dart';
import 'package:jayasha_childrens_academy/core/models/school_details.dart';
import 'package:jayasha_childrens_academy/features/classes/data/models/school_class.dart';
import 'package:intl/intl.dart';

class PdfGenerator {
  static Future<pw.Document> _buildCertificatePdf({
    required StudentAdmission student,
    required String type,
    required Map<String, dynamic> details,
    SchoolDetails? schoolDetails,
  }) async {
    final pdf = pw.Document();

    pw.ImageProvider? logoImage;
    if (details['showWatermark'] ?? true) {
      if (schoolDetails != null && schoolDetails.logoUrl.isNotEmpty) {
        try {
          logoImage = await networkImage(schoolDetails.logoUrl);
        } catch (e) {
          debugPrint('Error loading school logo from URL: $e');
        }
      }

      if (logoImage == null) {
        try {
          logoImage = pw.MemoryImage(
              (await rootBundle.load('assets/images/JCB_Logo.png'))
                  .buffer
                  .asUint8List());
        } catch (e) {
          debugPrint('Fallback logo not found: $e');
        }
      }
    }

    PdfColor getColor(dynamic color) {
      if (color == null) return PdfColors.black;
      if (color is int) return PdfColor.fromInt(color);
      if (color is String) {
        try {
          final hex = color.replaceAll('#', '');
          return PdfColor.fromInt(int.parse(hex, radix: 16));
        } catch (e) {
          return PdfColors.black;
        }
      }
      return PdfColors.black;
    }

    pw.TextStyle getStyle(Map<String, dynamic>? style, {double fontSize = 12}) {
      if (style == null) return pw.TextStyle(fontSize: fontSize);
      return pw.TextStyle(
        fontSize: (style['fontSize'] ?? fontSize).toDouble(),
        fontWeight:
            style['bold'] == true ? pw.FontWeight.bold : pw.FontWeight.normal,
        fontStyle:
            style['italic'] == true ? pw.FontStyle.italic : pw.FontStyle.normal,
        decoration: style['underline'] == true
            ? pw.TextDecoration.underline
            : pw.TextDecoration.none,
        color: getColor(style['color']),
      );
    }

    pw.TextAlign getAlign(String? align) {
      switch (align) {
        case 'left':
          return pw.TextAlign.left;
        case 'right':
          return pw.TextAlign.right;
        case 'center':
          return pw.TextAlign.center;
        case 'justify':
          return pw.TextAlign.justify;
        default:
          return pw.TextAlign.center;
      }
    }

    pw.CrossAxisAlignment getCrossAlign(String? align) {
      switch (align) {
        case 'left':
          return pw.CrossAxisAlignment.start;
        case 'right':
          return pw.CrossAxisAlignment.end;
        case 'center':
          return pw.CrossAxisAlignment.center;
        default:
          return pw.CrossAxisAlignment.start;
      }
    }

    final double watermarkOpacity =
        (details['watermarkOpacity'] ?? 0.3).toDouble();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Stack(
            children: [
              if (logoImage != null)
                pw.Center(
                  child: pw.Opacity(
                    opacity: watermarkOpacity,
                    child: pw.Image(logoImage!, width: 400),
                  ),
                ),
              pw.Container(
                padding: const pw.EdgeInsets.all(40),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.black, width: 2),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                  children: [
                    pw.Text(
                      details['schoolName'] ??
                          schoolDetails?.schoolName ??
                          'JAYASHA CHILDREN\'S ACADEMY',
                      style: getStyle(details['schoolNameStyle'], fontSize: 26),
                      textAlign: getAlign(details['schoolNameStyle']?['align']),
                    ),
                    pw.SizedBox(height: 5),
                    if (details['subtitleStyle']?['enabled'] ?? true)
                      pw.Text(
                        details['subtitle'] ??
                            schoolDetails?.affiliationLine ??
                            'Affiliated to CBSE, New Delhi',
                        style: getStyle(details['subtitleStyle'], fontSize: 14),
                        textAlign: getAlign(details['subtitleStyle']?['align']),
                      ),
                    pw.SizedBox(height: 10),
                    pw.Divider(thickness: 1),
                    pw.SizedBox(height: 40),
                    pw.Text(
                      (details['title'] ?? type).toUpperCase(),
                      style: getStyle(details['titleStyle'], fontSize: 20),
                      textAlign: getAlign(details['titleStyle']?['align']),
                    ),
                    pw.SizedBox(height: 60),
                    pw.Paragraph(
                      text: details['body'] ?? '',
                      style: getStyle(details['bodyStyle'], fontSize: 16)
                          .copyWith(lineSpacing: 5),
                      textAlign: getAlign(details['bodyStyle']?['align']),
                    ),
                    pw.Spacer(),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Expanded(
                          child: pw.Column(
                            crossAxisAlignment: getCrossAlign(
                                details['dateStyle']?['align'] ??
                                    details['placeStyle']?['align']),
                            children: [
                              if (details['dateStyle']?['enabled'] ?? true)
                                pw.Text(
                                  'Date: ${details['issueDate'] != null ? DateFormat('dd/MM/yyyy').format(DateTime.parse(details['issueDate'] as String)) : DateFormat('dd/MM/yyyy').format(DateTime.now())}',
                                  style: getStyle(
                                      details['dateStyle'] ?? {'color': 0xFF000000}),
                                  textAlign:
                                      getAlign(details['dateStyle']?['align']),
                                ),
                              if (details['placeStyle']?['enabled'] ?? true)
                                pw.Text(
                                  'Place: ${details['place'] ?? 'School Office'}',
                                  style: getStyle(details['placeStyle']),
                                  textAlign:
                                      getAlign(details['placeStyle']?['align']),
                                ),
                            ],
                          ),
                        ),
                        pw.Expanded(
                          child: pw.Column(
                            crossAxisAlignment: getCrossAlign(
                                details['principalLabelStyle']?['align']),
                            children: [
                              pw.SizedBox(height: 40),
                              if (details['principalLabelStyle']?['enabled'] ??
                                  true)
                                pw.Text(
                                  details['principalLabel'] ??
                                      schoolDetails?.principalSignatureLabel ??
                                      'Principal Signature',
                                  style:
                                      getStyle(details['principalLabelStyle']),
                                  textAlign: getAlign(
                                      details['principalLabelStyle']?['align']),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
    return pdf;
  }

  static Future<void> printCertificate({
    required StudentAdmission student,
    required String type,
    required Map<String, dynamic> details,
    SchoolDetails? schoolDetails,
  }) async {
    final pdf = await _buildCertificatePdf(
        student: student,
        type: type,
        details: details,
        schoolDetails: schoolDetails);
    await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save());
  }

  static pw.Widget _networkIcon(int codePoint, {double size = 30, PdfColor color = PdfColors.grey500}) {
    // Basic fallback for icons in PDF
    return pw.Container(
      width: size,
      height: size,
      decoration: const pw.BoxDecoration(color: PdfColors.grey300, shape: pw.BoxShape.circle),
    );
  }

  static Future<pw.Document> _buildIdCardPdf({
    required StudentAdmission student,
    required Map<String, dynamic> details,
    SchoolDetails? schoolDetails,
  }) async {
    final pdf = pw.Document();

    // CR80 is 85.6mm x 53.98mm
    const double cardWidth = 85.6 * PdfPageFormat.mm;
    const double cardHeight = 54.0 * PdfPageFormat.mm;

    final cardWidget = await _buildSingleIdCardWidget(
      student: student,
      details: details,
      schoolDetails: schoolDetails,
      cardWidth: cardWidth,
      cardHeight: cardHeight,
    );

    pdf.addPage(
      pw.Page(
        pageFormat: const PdfPageFormat(cardWidth, cardHeight, marginAll: 0),
        build: (pw.Context context) => cardWidget,
      ),
    );
    return pdf;
  }

  static Future<pw.Widget> _buildSingleIdCardWidget({
    required StudentAdmission student,
    required Map<String, dynamic> details,
    SchoolDetails? schoolDetails,
    pw.ImageProvider? logoImage,
    required double cardWidth,
    required double cardHeight,
  }) async {
    final photoPath = details['cardPhotoOverride'] ?? student.photoPath;
    pw.ImageProvider? studentPhoto;
    if (photoPath != null && photoPath.isNotEmpty) {
      try {
        studentPhoto = await networkImage(photoPath);
      } catch (e) {
        debugPrint('Error loading student photo for PDF: $e');
      }
    }

    if (logoImage == null && schoolDetails != null && schoolDetails.logoUrl.isNotEmpty) {
      try {
        logoImage = await networkImage(schoolDetails.logoUrl);
      } catch (e) {
        debugPrint('Error loading school logo: $e');
      }
    }

    final double photoBoxSize = (details['photoBoxSize'] ?? 70.0).toDouble();
    final double rowSpacing = (details['rowSpacing'] ?? 3.0).toDouble();
    final double watermarkOpacity = (details['watermarkOpacity'] ?? 0.05).toDouble();
    final double horizontalPadding = (details['horizontalPadding'] ?? 10.0).toDouble();
    final double verticalPadding = (details['verticalPadding'] ?? 6.0).toDouble();
    final String principalName = details['principalName'] ?? 'Principal';
    final String signatureLabel = details['signatureLabel'] ?? 'Principal Signature';
    final Map<String, dynamic>? blockStyle = details['detailsBlockStyle'];
    final Map<String, dynamic>? studentNameStyle = details['studentNameStyle'];
    final Map<String, dynamic>? principalNameStyle = details['principalNameStyle'];

    final int schoolColorInt = details['schoolNameStyle']?['color'] ?? 0xFF0D47A1;
    final PdfColor schoolColor = PdfColor.fromInt(schoolColorInt);

    // Header background - 10% opacity
    final r = (schoolColorInt >> 16) & 0xFF;
    final g = (schoolColorInt >> 8) & 0xFF;
    final b = schoolColorInt & 0xFF;
    final PdfColor headerBgColor = PdfColor.fromInt((0x1A << 24) | (r << 16) | (g << 8) | b);

    return pw.Container(
      width: cardWidth,
      height: cardHeight,
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
      ),
      child: pw.Stack(
        children: [
          // Watermark
          pw.Center(
            child: pw.Opacity(
              opacity: watermarkOpacity,
              child: logoImage != null
                ? pw.Image(logoImage, width: cardHeight * 0.8)
                : pw.Icon(const pw.IconData(0xe80c), size: 100, color: schoolColor),
            ),
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              // Header
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 10),
                decoration: pw.BoxDecoration(
                  color: headerBgColor,
                  border: pw.Border(bottom: pw.BorderSide(color: schoolColor, width: 1.5)),
                ),
                child: pw.Row(
                  children: [
                    if (logoImage != null)
                      pw.Image(logoImage, height: 25, width: 25)
                    else
                      pw.Icon(const pw.IconData(0xe80c), color: schoolColor, size: 20),
                    pw.SizedBox(width: 8),
                    pw.Expanded(
                      child: pw.Column(
                        mainAxisSize: pw.MainAxisSize.min,
                        children: [
                          pw.Text(
                            details['schoolName'] ?? schoolDetails?.schoolName ?? 'JAYASHA CHILDREN\'S ACADEMY',
                            textAlign: _getPdfAlign(details['schoolNameStyle']?['align']),
                            style: _getPdfStyle(details['schoolNameStyle'], 12),
                          ),
                          if (details['addressStyle']?['enabled'] ?? true)
                            pw.Text(
                              details['schoolAddress'] ?? schoolDetails?.address ?? '',
                              textAlign: _getPdfAlign(details['addressStyle']?['align']),
                              style: _getPdfStyle(details['addressStyle'], 7),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Middle content
              pw.Expanded(
                child: pw.Padding(
                  padding: pw.EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: verticalPadding),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.center,
                    children: [
                      // Photo
                      pw.Container(
                        width: photoBoxSize,
                        height: photoBoxSize * 1.25,
                        decoration: pw.BoxDecoration(
                          color: PdfColors.white,
                          border: pw.Border.all(color: schoolColor, width: 1.5),
                          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(2)),
                        ),
                        child: studentPhoto != null
                            ? pw.Image(studentPhoto, fit: pw.BoxFit.cover)
                            : pw.Center(
                                child: _networkIcon(0xe7fd, size: photoBoxSize * 0.4, color: PdfColors.grey500)),
                      ),
                      pw.SizedBox(width: 12),

                      // Details
                      pw.Expanded(
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          mainAxisAlignment: pw.MainAxisAlignment.center,
                          children: [
                            _pdfCardDataRow('Student Name', student.name, isBold: true, blockStyle: blockStyle, customStyle: studentNameStyle),
                            pw.SizedBox(height: rowSpacing * 2),
                            pw.Row(
                              children: [
                                pw.Expanded(child: _pdfCardDataRow('Class', student.className ?? 'N/A', blockStyle: blockStyle)),
                                pw.Expanded(child: _pdfCardDataRow('Section', student.section ?? 'N/A', blockStyle: blockStyle)),
                              ],
                            ),
                            pw.SizedBox(height: rowSpacing * 2),
                            pw.Row(
                              children: [
                                pw.Expanded(child: _pdfCardDataRow('Roll No', student.rollNumber ?? 'N/A', blockStyle: blockStyle)),
                                pw.Expanded(child: _pdfCardDataRow('Adm No', student.admissionNumber, blockStyle: blockStyle)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Footer
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: pw.BoxDecoration(
                  border: pw.Border(top: pw.BorderSide(color: PdfColors.grey300, width: 0.5)),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text('CARD ID: ID-${student.admissionNumber}', style: pw.TextStyle(fontSize: 5, fontWeight: pw.FontWeight.bold)),
                    pw.Column(
                      children: [
                        pw.Text(principalName, style: _getPdfStyle(principalNameStyle, 6)),
                        pw.Container(width: 45, height: 0.5, color: PdfColors.black),
                        pw.SizedBox(height: 1),
                        pw.Text(signatureLabel, style: pw.TextStyle(fontSize: 5, fontWeight: pw.FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }


  static Future<void> printIdCard({
    required StudentAdmission student,
    required Map<String, dynamic> details,
    SchoolDetails? schoolDetails,
  }) async {
    final pdf = await _buildIdCardPdf(
        student: student, details: details, schoolDetails: schoolDetails);
    await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save());
  }

  static Future<void> downloadIdCard({
    required StudentAdmission student,
    required Map<String, dynamic> details,
    SchoolDetails? schoolDetails,
    String? savePath,
  }) async {
    final pdf = await _buildIdCardPdf(
        student: student, details: details, schoolDetails: schoolDetails);
    final bytes = await pdf.save();

    if (savePath != null) {
      final file = File(savePath);
      await file.writeAsBytes(bytes);
      return;
    }

    final fileName = 'ID_Card_${student.admissionNumber}.pdf';

    if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
      String? outputFile = await FilePicker.platform.saveFile(
        dialogTitle: 'Save ID Card As',
        fileName: fileName,
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (outputFile != null) {
        final file = File(outputFile);
        await file.writeAsBytes(bytes);
      }
    } else {
      await Printing.sharePdf(
        bytes: bytes,
        filename: fileName,
      );
    }
  }

  static Future<void> downloadBatchIdCards({
    required List<StudentAdmission> students,
    required Map<String, dynamic> details,
    SchoolDetails? schoolDetails,
  }) async {
    final pdf = pw.Document();

    // Standard A4 page can fit 8-10 cards (CR80)
    // We'll go with 2 columns and 4 rows per page (8 cards) to leave good margins.
    const double cardWidth = 85.6 * PdfPageFormat.mm;
    const double cardHeight = 54.0 * PdfPageFormat.mm;

    pw.ImageProvider? logoImage;
    if (schoolDetails != null && schoolDetails.logoUrl.isNotEmpty) {
      try {
        logoImage = await networkImage(schoolDetails.logoUrl);
      } catch (e) {
        debugPrint('Error loading school logo: $e');
      }
    }

    // Process in chunks of 8
    for (var i = 0; i < students.length; i += 8) {
      final chunk = students.sublist(i, i + 8 > students.length ? students.length : i + 8);

      final List<pw.Widget> cardWidgets = [];
      for (var student in chunk) {
        cardWidgets.add(await _buildSingleIdCardWidget(
          student: student,
          details: details,
          schoolDetails: schoolDetails,
          logoImage: logoImage,
          cardWidth: cardWidth,
          cardHeight: cardHeight,
        ));
      }

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(10 * PdfPageFormat.mm),
          build: (context) {
            return pw.Wrap(
              spacing: 10 * PdfPageFormat.mm,
              runSpacing: 10 * PdfPageFormat.mm,
              children: cardWidgets,
            );
          },
        ),
      );
    }

    final bytes = await pdf.save();
    final fileName = 'Batch_ID_Cards_${DateTime.now().millisecondsSinceEpoch}.pdf';

    if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
      String? outputFile = await FilePicker.platform.saveFile(
        dialogTitle: 'Save Batch ID Cards As',
        fileName: fileName,
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (outputFile != null) {
        final file = File(outputFile);
        await file.writeAsBytes(bytes);
      }
    } else {
      await Printing.sharePdf(
        bytes: bytes,
        filename: fileName,
      );
    }
  }


  static pw.TextStyle _getPdfStyle(
      Map<String, dynamic>? style, double defaultSize) {
    if (style == null) return pw.TextStyle(fontSize: defaultSize);
    return pw.TextStyle(
      fontSize: (style['fontSize'] ?? defaultSize).toDouble(),
      fontWeight:
          style['bold'] == true ? pw.FontWeight.bold : pw.FontWeight.normal,
      fontStyle:
          style['italic'] == true ? pw.FontStyle.italic : pw.FontStyle.normal,
      decoration: style['underline'] == true
          ? pw.TextDecoration.underline
          : pw.TextDecoration.none,
      color: style['color'] != null
          ? PdfColor.fromInt(style['color'])
          : PdfColors.black,
    );
  }

  static pw.TextAlign _getPdfAlign(String? align) {
    switch (align) {
      case 'left':
        return pw.TextAlign.left;
      case 'right':
        return pw.TextAlign.right;
      default:
        return pw.TextAlign.center;
    }
  }

  static pw.Widget _pdfCardDataRow(String label, String value,
      {bool isBold = false,
      Map<String, dynamic>? blockStyle,
      Map<String, dynamic>? customStyle}) {
    final Map<String, dynamic>? style = customStyle ?? blockStyle;
    final double labelSize = (blockStyle?['labelFontSize'] ?? 7.0).toDouble();
    final double valueSize = (style?['fontSize'] ?? 10.0).toDouble();
    final bool blockBold = style?['bold'] == true;
    final PdfColor textColor = style?['color'] != null
        ? PdfColor.fromInt(style!['color'])
        : PdfColors.black;

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(label.toUpperCase(),
            style: pw.TextStyle(
                fontSize: labelSize,
                color: PdfColors.grey700,
                fontWeight: pw.FontWeight.bold)),
        pw.FittedBox(
          fit: pw.BoxFit.scaleDown,
          child: pw.Text(value,
              style: pw.TextStyle(
                  fontSize: valueSize,
                  color: textColor,
                  fontWeight: (isBold || blockBold)
                      ? pw.FontWeight.bold
                      : pw.FontWeight.normal,
                  fontStyle: style?['italic'] == true
                      ? pw.FontStyle.italic
                      : pw.FontStyle.normal)),
        ),
      ],
    );
  }

  static Future<void> downloadCertificate({
    required StudentAdmission student,
    required String type,
    required Map<String, dynamic> details,
    SchoolDetails? schoolDetails,
  }) async {
    final pdf = await _buildCertificatePdf(
        student: student,
        type: type,
        details: details,
        schoolDetails: schoolDetails);
    final bytes = await pdf.save();

    final fileName =
        '${type.replaceAll(' ', '_')}_${student.admissionNumber}.pdf';

    if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
      String? outputFile = await FilePicker.platform.saveFile(
        dialogTitle: 'Save Certificate As',
        fileName: fileName,
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (outputFile != null) {
        final file = File(outputFile);
        await file.writeAsBytes(bytes);
      }
    } else {
      await Printing.sharePdf(
        bytes: bytes,
        filename: fileName,
      );
    }
  }

  static Future<void> generateCertificate({
    required StudentAdmission student,
    required String type,
    Map<String, dynamic>? details,
    SchoolDetails? schoolDetails,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Container(
            padding: const pw.EdgeInsets.all(40),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.black, width: 2),
            ),
            child: pw.Column(
              children: [
                pw.Text(
                  schoolDetails?.schoolName ?? 'JAYASHA CHILDREN\'S ACADEMY',
                  style: pw.TextStyle(
                    fontSize: 26,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.blue900,
                  ),
                ),
                pw.SizedBox(height: 5),
                pw.Text(
                    schoolDetails?.affiliationLine ??
                        'Affiliated to CBSE, New Delhi',
                    style: const pw.TextStyle(fontSize: 14)),
                pw.SizedBox(height: 10),
                pw.Divider(thickness: 1),
                pw.SizedBox(height: 40),
                pw.Text(
                  type.toUpperCase(),
                  style: pw.TextStyle(
                    fontSize: 20,
                    fontWeight: pw.FontWeight.bold,
                    decoration: pw.TextDecoration.underline,
                  ),
                ),
                pw.SizedBox(height: 60),
                pw.Paragraph(
                  text:
                      'This is to certify that Master/Miss ${student.name}, son/daughter of Mr. ${student.fatherName}, is/was a bonafide student of this school studying in section ${student.section ?? 'N/A'} during the session ${details?['session'] ?? '2023-24'}.',
                  style: pw.TextStyle(fontSize: 16, lineSpacing: 5),
                  textAlign: pw.TextAlign.justify,
                ),
                pw.SizedBox(height: 40),
                pw.Align(
                  alignment: pw.Alignment.centerLeft,
                  child: pw.Text(
                    'His/Her date of birth according to the school records is ${DateFormat('dd-MM-yyyy').format(DateTime.parse(student.dob))}.',
                    style: const pw.TextStyle(fontSize: 16),
                  ),
                ),
                pw.Spacer(),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                            'Date: ${DateFormat('dd/MM/yyyy').format(DateTime.now())}'),
                        pw.Text('Place: School Office'),
                      ],
                    ),
                    pw.Column(
                      children: [
                        pw.SizedBox(height: 40),
                        pw.Text(
                            schoolDetails?.principalSignatureLabel ??
                                'Principal Signature',
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );

    await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save());
  }

  static Future<pw.Document> _buildFeeReceiptPdf({
    required StudentAdmission student,
    required FeePayment payment,
    String? sessionName,
    SchoolDetails? schoolDetails,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Container(
            padding: const pw.EdgeInsets.all(30),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey400, width: 1),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Header
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          schoolDetails?.schoolName ??
                              'JAYASHA CHILDREN\'S ACADEMY',
                          style: pw.TextStyle(
                            fontSize: 24,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.blue900,
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                            schoolDetails?.affiliationLine ??
                                'Affiliated to CBSE, New Delhi',
                            style: const pw.TextStyle(fontSize: 12)),
                        pw.Text(
                            'Address: ${schoolDetails?.address ?? 'Near City Center, Shivpuri, Madhya Pradesh'}',
                            style: const pw.TextStyle(fontSize: 10)),
                        pw.Text(
                            'Contact: ${schoolDetails?.phone ?? '+91 9876543210'} | Email: ${schoolDetails?.email ?? 'info@jayasha.edu.in'}',
                            style: const pw.TextStyle(fontSize: 10)),
                      ],
                    ),
                    pw.Container(
                      width: 60,
                      height: 60,
                      decoration: const pw.BoxDecoration(
                        color: PdfColors.blue900,
                        shape: pw.BoxShape.circle,
                      ),
                      child: pw.Center(
                        child: pw.Text(
                            schoolDetails != null &&
                                    schoolDetails.schoolName.length >= 3
                                ? schoolDetails.schoolName
                                    .split(' ')
                                    .take(3)
                                    .map((e) => e[0])
                                    .join()
                                    .toUpperCase()
                                : 'JCA',
                            style: pw.TextStyle(
                                color: PdfColors.white,
                                fontWeight: pw.FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 10),
                pw.Divider(thickness: 2, color: PdfColors.blue900),
                pw.SizedBox(height: 10),
                pw.Center(
                  child: pw.Container(
                    padding:
                        const pw.EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                    decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                    child: pw.Text(
                      'OFFICIAL FEE RECEIPT',
                      style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold, fontSize: 14),
                    ),
                  ),
                ),
                pw.SizedBox(height: 20),

                // Receipt and Date Info
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                        'Receipt No: REC-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    pw.Text(
                        'Date: ${DateFormat('dd MMMM yyyy').format(payment.date)}'),
                  ],
                ),
                pw.SizedBox(height: 20),

                // Student Details Section
                pw.Text('STUDENT INFORMATION',
                    style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 12,
                        color: PdfColors.blue900)),
                pw.Divider(thickness: 1, color: PdfColors.blue900),
                pw.SizedBox(height: 8),
                pw.Row(
                  children: [
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          _receiptInfoRow('Student Name', student.name),
                          _receiptInfoRow(
                              'Admission No', student.admissionNumber),
                          _receiptInfoRow(
                              'Roll Number', student.rollNumber ?? 'N/A'),
                          _receiptInfoRow('Class & Section',
                              '${student.className ?? 'N/A'} - ${student.section ?? 'N/A'}'),
                        ],
                      ),
                    ),
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          _receiptInfoRow('Father\'s Name', student.fatherName),
                          _receiptInfoRow('Mother\'s Name', student.motherName),
                          _receiptInfoRow('Contact', student.guardianPhone),
                          _receiptInfoRow('Academic Session', sessionName ?? 'N/A'),
                        ],
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 25),

                // Payment Details Table
                pw.Text('PAYMENT DETAILS',
                    style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 12,
                        color: PdfColors.blue900)),
                pw.Divider(thickness: 1, color: PdfColors.blue900),
                pw.SizedBox(height: 8),
                pw.Table(
                  border: pw.TableBorder.all(color: PdfColors.grey300),
                  children: [
                    pw.TableRow(
                      decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                      children: [
                        pw.Padding(
                            padding: const pw.EdgeInsets.all(8),
                            child: pw.Text('Description',
                                style: pw.TextStyle(
                                    fontWeight: pw.FontWeight.bold))),
                        pw.Padding(
                            padding: const pw.EdgeInsets.all(8),
                            child: pw.Text('Payment Category',
                                style: pw.TextStyle(
                                    fontWeight: pw.FontWeight.bold))),
                        pw.Padding(
                            padding: const pw.EdgeInsets.all(8),
                            child: pw.Text('Amount (INR)',
                                style: pw.TextStyle(
                                    fontWeight: pw.FontWeight.bold))),
                      ],
                    ),
                    pw.TableRow(
                      children: [
                        pw.Padding(
                            padding: const pw.EdgeInsets.all(8),
                            child: pw.Text(payment.remarks ?? 'Fee Payment')),
                        pw.Padding(
                            padding: const pw.EdgeInsets.all(8),
                            child: pw.Text(
                                payment.category.name.toUpperCase())),
                        pw.Padding(
                            padding: const pw.EdgeInsets.all(8),
                            child: pw.Text(
                                'Rs. ${payment.amount.toStringAsFixed(2)}',
                                style: pw.TextStyle(
                                    fontWeight: pw.FontWeight.bold))),
                      ],
                    ),
                  ],
                ),
                pw.SizedBox(height: 15),

                // Summary and Signature Area
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('Payment Mode: ${payment.mode.name.toUpperCase()}'),
                        pw.Text('Status: SUCCESSFUL',
                            style: pw.TextStyle(
                                color: PdfColors.green700,
                                fontWeight: pw.FontWeight.bold)),
                      ],
                    ),
                    pw.Container(
                      padding: const pw.EdgeInsets.all(10),
                      decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                      child: pw.Text(
                        'TOTAL PAID: Rs. ${payment.amount.toStringAsFixed(2)}',
                        style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold, fontSize: 16),
                      ),
                    ),
                  ],
                ),
                pw.Spacer(),

                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      children: [
                        pw.SizedBox(
                            height: 40,
                            width: 100,
                            child: pw.Divider(thickness: 0.5)),
                        pw.Text('Parent\'s Signature',
                            style: const pw.TextStyle(fontSize: 10)),
                      ],
                    ),
                    pw.Column(
                      children: [
                        pw.SizedBox(
                            height: 40,
                            width: 100,
                            child: pw.Divider(thickness: 0.5)),
                        pw.Text('Accountant Signature',
                            style: const pw.TextStyle(fontSize: 10)),
                      ],
                    ),
                    pw.Column(
                      children: [
                        pw.SizedBox(
                            height: 40,
                            width: 100,
                            child: pw.Divider(thickness: 0.5)),
                        pw.Text(
                            schoolDetails?.principalSignatureLabel ??
                                'Principal\'s Signature',
                            style: const pw.TextStyle(fontSize: 10)),
                      ],
                    ),
                  ],
                ),
                pw.SizedBox(height: 20),
                pw.Center(
                  child: pw.Text(
                    'Note: This is a computer-generated receipt and does not require a physical seal.',
                    style: pw.TextStyle(
                        fontSize: 8,
                        color: PdfColors.grey600,
                        fontStyle: pw.FontStyle.italic),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
    return pdf;
  }

  static pw.Widget _receiptInfoRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.RichText(
        text: pw.TextSpan(
          children: [
            pw.TextSpan(
                text: '$label: ',
                style:
                    pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
            pw.TextSpan(text: value, style: const pw.TextStyle(fontSize: 10)),
          ],
        ),
      ),
    );
  }

  static Future<void> generateFeeReceipt({
    required StudentAdmission student,
    required FeePayment payment,
    String? sessionName,
    SchoolDetails? schoolDetails,
  }) async {
    final pdf = await _buildFeeReceiptPdf(
        student: student,
        payment: payment,
        sessionName: sessionName,
        schoolDetails: schoolDetails);
    await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save());
  }

  static Future<void> downloadFeeReceipt({
    required StudentAdmission student,
    required FeePayment payment,
    String? sessionName,
    SchoolDetails? schoolDetails,
  }) async {
    final pdf = await _buildFeeReceiptPdf(
        student: student,
        payment: payment,
        sessionName: sessionName,
        schoolDetails: schoolDetails);
    final bytes = await pdf.save();

    final fileName =
        'Receipt_${student.admissionNumber}_${DateFormat('yyyyMMdd').format(payment.date)}.pdf';

    if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
      String? outputFile = await FilePicker.platform.saveFile(
        dialogTitle: 'Save Fee Receipt As',
        fileName: fileName,
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (outputFile != null) {
        final file = File(outputFile);
        await file.writeAsBytes(bytes);
      }
    } else {
      await Printing.sharePdf(
        bytes: bytes,
        filename: fileName,
      );
    }
  }

  static Future<void> downloadReportCard({
    required dynamic markRecord,
    SchoolDetails? schoolDetails,
  }) async {
    final pdf = pw.Document();
    final student = markRecord['student'];
    final exam = markRecord['exam'];
    final className = markRecord['class']['name'];
    final marks = markRecord['subjectMarks'] as List;

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Container(
            padding: const pw.EdgeInsets.all(30),
            decoration: pw.BoxDecoration(border: pw.Border.all(width: 2)),
            child: pw.Column(
              children: [
                pw.Center(
                  child: pw.Column(
                    children: [
                      pw.Text(
                          schoolDetails?.schoolName ??
                              'JAYASHA CHILDREN\'S ACADEMY',
                          style: pw.TextStyle(
                              fontSize: 22, fontWeight: pw.FontWeight.bold)),
                      pw.Text('PROGRESS REPORT',
                          style: pw.TextStyle(
                              fontSize: 16,
                              decoration: pw.TextDecoration.underline)),
                      pw.Text(exam['name'], style: pw.TextStyle(fontSize: 14)),
                    ],
                  ),
                ),
                pw.SizedBox(height: 30),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('Name: ${student['name']}'),
                        pw.Text('Admission No: ${student['admissionNumber']}'),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('Class: $className'),
                        pw.Text('Roll No: ${student['rollNumber'] ?? 'N/A'}'),
                      ],
                    ),
                  ],
                ),
                pw.SizedBox(height: 20),
                pw.Table(
                  border: pw.TableBorder.all(),
                  children: [
                    pw.TableRow(
                      decoration: const pw.BoxDecoration(color: PdfColors.grey300),
                      children: [
                        pw.Padding(
                            padding: const pw.EdgeInsets.all(5),
                            child: pw.Text('Subject',
                                style: pw.TextStyle(
                                    fontWeight: pw.FontWeight.bold))),
                        pw.Padding(
                            padding: const pw.EdgeInsets.all(5),
                            child: pw.Text('Max Marks',
                                style: pw.TextStyle(
                                    fontWeight: pw.FontWeight.bold))),
                        pw.Padding(
                            padding: const pw.EdgeInsets.all(5),
                            child: pw.Text('Marks Obtained',
                                style: pw.TextStyle(
                                    fontWeight: pw.FontWeight.bold))),
                      ],
                    ),
                    ...marks.map((m) => pw.TableRow(
                          children: [
                            pw.Padding(
                                padding: const pw.EdgeInsets.all(5),
                                child: pw.Text(m['subject'])),
                            pw.Padding(
                                padding: const pw.EdgeInsets.all(5),
                                child: pw.Text(m['maxMarks'].toString())),
                            pw.Padding(
                                padding: const pw.EdgeInsets.all(5),
                                child: pw.Text(m['totalMarks'].toString())),
                          ],
                        )),
                  ],
                ),
                pw.SizedBox(height: 20),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Total Obtained: ${markRecord['totalObtained']}'),
                    pw.Text(
                        'Percentage: ${markRecord['percentage'].toStringAsFixed(2)}%'),
                    pw.Text('Result: ${markRecord['result']}',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  ],
                ),
                pw.Spacer(),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Class Teacher'),
                    pw.Text(schoolDetails?.principalSignatureLabel ?? 'Principal'),
                    pw.Text('Parent'),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );

    final bytes = await pdf.save();
    final fileName =
        'ReportCard_${student['admissionNumber']}_${exam['name'].toString().replaceAll(' ', '_')}.pdf';

    if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
      String? outputFile = await FilePicker.platform.saveFile(
        dialogTitle: 'Save Report Card As',
        fileName: fileName,
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (outputFile != null) {
        final file = File(outputFile);
        await file.writeAsBytes(bytes);
      }
    } else {
      await Printing.sharePdf(
        bytes: bytes,
        filename: fileName,
      );
    }
  }

  static Future<void> downloadExamDatesheet({
    required dynamic exam,
    required List<dynamic> datesheet,
    required String className,
    String? sessionName,
    SchoolDetails? schoolDetails,
  }) async {
    final pdf = pw.Document();
    _addDatesheetPage(pdf, exam, datesheet, className, sessionName, schoolDetails);
    final bytes = await pdf.save();
    final fileName =
        'Datesheet_${className.replaceAll(' ', '_')}_${exam['name'].toString().replaceAll(' ', '_')}.pdf';

    if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
      String? outputFile = await FilePicker.platform.saveFile(
        dialogTitle: 'Save Exam Datesheet As',
        fileName: fileName,
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (outputFile != null) {
        final file = File(outputFile);
        await file.writeAsBytes(bytes);
      }
    } else {
      await Printing.sharePdf(
        bytes: bytes,
        filename: fileName,
      );
    }
  }

  static Future<void> downloadAllClassesDatesheet({
    required dynamic exam,
    required List<dynamic> fullDatesheet,
    required List<dynamic> classes,
    String? sessionName,
    SchoolDetails? schoolDetails,
  }) async {
    final pdf = pw.Document();

    for (var cls in classes) {
      final classId = cls['_id'];
      final classEntries =
          fullDatesheet.where((d) => d['classId'] == classId).toList();
      if (classEntries.isNotEmpty) {
        final section = cls['section'];
        final sectionSuffix = (section != null &&
                section.toString().toLowerCase() != 'null' &&
                section.toString().isNotEmpty)
            ? ' - $section'
            : '';
        _addDatesheetPage(
            pdf,
            exam,
            classEntries,
            '${cls['name']}$sectionSuffix',
            sessionName,
            schoolDetails);
      }
    }

    final bytes = await pdf.save();
    final fileName =
        'Full_Datesheet_${exam['name'].toString().replaceAll(' ', '_')}.pdf';

    if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
      String? outputFile = await FilePicker.platform.saveFile(
        dialogTitle: 'Save Full Datesheet As',
        fileName: fileName,
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (outputFile != null) {
        final file = File(outputFile);
        await file.writeAsBytes(bytes);
      }
    } else {
      await Printing.sharePdf(
        bytes: bytes,
        filename: fileName,
      );
    }
  }

  static void _addDatesheetPage(
      pw.Document pdf,
      dynamic exam,
      List<dynamic> datesheet,
      String className,
      String? sessionName,
      SchoolDetails? schoolDetails) {
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Container(
            padding: const pw.EdgeInsets.all(30),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.black, width: 2),
            ),
            child: pw.Column(
              children: [
                pw.Center(
                  child: pw.Column(
                    children: [
                      pw.Text(
                        schoolDetails?.schoolName ??
                            'JAYASHA CHILDREN\'S ACADEMY',
                        style: pw.TextStyle(
                          fontSize: 22,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.blue900,
                        ),
                      ),
                      pw.SizedBox(height: 5),
                      pw.Text('EXAMINATION DATESHEET',
                          style: pw.TextStyle(
                              fontSize: 18,
                              fontWeight: pw.FontWeight.bold,
                              decoration: pw.TextDecoration.underline)),
                      pw.SizedBox(height: 10),
                      pw.Text(exam['name'], style: pw.TextStyle(fontSize: 16)),
                      if (sessionName != null)
                        pw.Text('Academic Session: $sessionName',
                            style: const pw.TextStyle(fontSize: 12)),
                      pw.SizedBox(height: 5),
                      pw.Text('Class: $className',
                          style: pw.TextStyle(
                              fontSize: 14, fontWeight: pw.FontWeight.bold)),
                    ],
                  ),
                ),
                pw.SizedBox(height: 30),
                pw.Table(
                  border: pw.TableBorder.all(),
                  columnWidths: {
                    0: const pw.FlexColumnWidth(2),
                    1: const pw.FlexColumnWidth(2),
                    2: const pw.FlexColumnWidth(1.5),
                    3: const pw.FlexColumnWidth(1.5),
                    4: const pw.FlexColumnWidth(1.5),
                  },
                  children: [
                    pw.TableRow(
                      decoration: const pw.BoxDecoration(color: PdfColors.grey300),
                      children: [
                        pw.Padding(
                            padding: const pw.EdgeInsets.all(8),
                            child: pw.Text('Subject',
                                style: pw.TextStyle(
                                    fontWeight: pw.FontWeight.bold))),
                        pw.Padding(
                            padding: const pw.EdgeInsets.all(8),
                            child: pw.Text('Date',
                                style: pw.TextStyle(
                                    fontWeight: pw.FontWeight.bold))),
                        pw.Padding(
                            padding: const pw.EdgeInsets.all(8),
                            child: pw.Text('Start Time',
                                style: pw.TextStyle(
                                    fontWeight: pw.FontWeight.bold))),
                        pw.Padding(
                            padding: const pw.EdgeInsets.all(8),
                            child: pw.Text('Duration',
                                style: pw.TextStyle(
                                    fontWeight: pw.FontWeight.bold))),
                        pw.Padding(
                            padding: const pw.EdgeInsets.all(8),
                            child: pw.Text('Max Marks',
                                style: pw.TextStyle(
                                    fontWeight: pw.FontWeight.bold))),
                      ],
                    ),
                    ...datesheet.map((item) => pw.TableRow(
                          children: [
                            pw.Padding(
                                padding: const pw.EdgeInsets.all(8),
                                child: pw.Text(item['subject'] ?? '')),
                            pw.Padding(
                                padding: const pw.EdgeInsets.all(8),
                                child: pw.Text(item['date'] != null
                                    ? DateFormat('dd/MM/yyyy')
                                        .format(DateTime.parse(item['date']))
                                    : '-')),
                            pw.Padding(
                                padding: const pw.EdgeInsets.all(8),
                                child: pw.Text(item['startTime'] ?? '-')),
                            pw.Padding(
                                padding: const pw.EdgeInsets.all(8),
                                child: pw.Text('${item['durationHours']} Hr')),
                            pw.Padding(
                                padding: const pw.EdgeInsets.all(8),
                                child: pw.Text(
                                    item['maxMarks']?.toString() ?? '-')),
                          ],
                        )),
                  ],
                ),
                pw.Spacer(),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      children: [
                        pw.SizedBox(height: 40),
                        pw.Text('Examination Controller'),
                      ],
                    ),
                    pw.Column(
                      children: [
                        pw.SizedBox(height: 40),
                        pw.Text(
                            schoolDetails?.principalSignatureLabel ??
                                'Principal',
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  static Future<pw.Document> _buildClassTimetablePdf({
    required SchoolClass schoolClass,
    String? sessionName,
    SchoolDetails? schoolDetails,
  }) async {
    final pdf = pw.Document();
    final shortDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4.landscape,
        margin:
            const pw.EdgeInsets.only(left: 40, top: 32, bottom: 32, right: 40),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        schoolDetails?.schoolName ??
                            'JAYASHA CHILDREN\'S ACADEMY',
                        style: pw.TextStyle(
                          fontSize: 22,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.blue900,
                        ),
                      ),
                      pw.Text('Weekly Timetable: ${schoolClass.name}',
                          style: pw.TextStyle(
                              fontSize: 16, fontWeight: pw.FontWeight.bold)),
                      if (sessionName != null)
                        pw.Text('Academic Session: $sessionName',
                            style: const pw.TextStyle(fontSize: 12)),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                          'Generated on: ${DateFormat('dd/MM/yyyy').format(DateTime.now())}',
                          style: const pw.TextStyle(fontSize: 10)),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 20),
              pw.Padding(
                padding: const pw.EdgeInsets.only(right: 16),
                child: pw.Table(
                  border: pw.TableBorder.all(color: PdfColors.grey400),
                  columnWidths: {
                    0: const pw.FlexColumnWidth(1.2),
                    for (var i = 1; i <= 6; i++) i: const pw.FlexColumnWidth(1),
                  },
                  children: [
                    // Header
                    pw.TableRow(
                      decoration: const pw.BoxDecoration(color: PdfColors.blue900),
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text('Period',
                              style: pw.TextStyle(
                                  color: PdfColors.white,
                                  fontWeight: pw.FontWeight.bold)),
                        ),
                        ...shortDays.map((day) => pw.Padding(
                              padding: const pw.EdgeInsets.all(8),
                              child: pw.Text(day,
                                  style: pw.TextStyle(
                                      color: PdfColors.white,
                                      fontWeight: pw.FontWeight.bold)),
                            )),
                      ],
                    ),
                    // Data
                    ...List.generate(schoolClass.timetable.length, (pIdx) {
                      return pw.TableRow(
                        children: [
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8),
                            child: pw.Text('Period ${pIdx + 1}',
                                style: pw.TextStyle(
                                    fontWeight: pw.FontWeight.bold)),
                          ),
                          ...List.generate(6, (dIdx) {
                            final entry = schoolClass.timetable[pIdx][dIdx];
                            return pw.Padding(
                              padding: const pw.EdgeInsets.all(8),
                              child: pw.Column(
                                crossAxisAlignment: pw.CrossAxisAlignment.start,
                                children: [
                                  pw.Text(entry?.subject ?? '-',
                                      style: pw.TextStyle(
                                          fontSize: 10,
                                          fontWeight: pw.FontWeight.bold)),
                                  if (entry != null && entry.subject != 'LUNCH')
                                    pw.Text(entry.teacherName,
                                        style: const pw.TextStyle(
                                            fontSize: 8,
                                            color: PdfColors.grey700)),
                                ],
                              ),
                            );
                          }),
                        ],
                      );
                    }),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
    return pdf;
  }

  static Future<void> downloadClassTimetable({
    required SchoolClass schoolClass,
    String? sessionName,
    SchoolDetails? schoolDetails,
  }) async {
    final pdf = await _buildClassTimetablePdf(
        schoolClass: schoolClass,
        sessionName: sessionName,
        schoolDetails: schoolDetails);
    final bytes = await pdf.save();
    final fileName = 'Timetable_${schoolClass.name.replaceAll(' ', '_')}.pdf';

    if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
      String? outputFile = await FilePicker.platform.saveFile(
        dialogTitle: 'Save Timetable As',
        fileName: fileName,
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (outputFile != null) {
        final file = File(outputFile);
        await file.writeAsBytes(bytes);
      }
    } else {
      await Printing.sharePdf(
        bytes: bytes,
        filename: fileName,
      );
    }
  }

  static Future<pw.Document> _buildTeacherTimetablePdf({
    required Teacher teacher,
    String? sessionName,
    SchoolDetails? schoolDetails,
  }) async {
    final pdf = pw.Document();
    final shortDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

    // Find max period to determine grid size
    int maxPeriod = 0;
    for (var entry in teacher.schedule) {
      if (entry.period > maxPeriod) maxPeriod = entry.period;
    }
    int periodCount = maxPeriod + 1;
    if (periodCount < 6) periodCount = 6;

    // Reconstruct grid
    final List<List<TeacherScheduleEntry?>> grid = List.generate(
      periodCount,
      (p) => List.generate(6, (d) => null),
    );

    for (var entry in teacher.schedule) {
      if (entry.period < periodCount && entry.day < 6) {
        grid[entry.period][entry.day] = entry;
      }
    }

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4.landscape,
        margin:
            const pw.EdgeInsets.only(left: 40, top: 32, bottom: 32, right: 40),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        schoolDetails?.schoolName ??
                            'JAYASHA CHILDREN\'S ACADEMY',
                        style: pw.TextStyle(
                          fontSize: 22,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.blue900,
                        ),
                      ),
                      pw.Text('Teacher Schedule: ${teacher.name}',
                          style: pw.TextStyle(
                              fontSize: 16, fontWeight: pw.FontWeight.bold)),
                      if (sessionName != null)
                        pw.Text('Academic Session: $sessionName',
                            style: const pw.TextStyle(fontSize: 12)),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                          'Generated on: ${DateFormat('dd/MM/yyyy').format(DateTime.now())}',
                          style: const pw.TextStyle(fontSize: 10)),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 20),
              pw.Padding(
                padding: const pw.EdgeInsets.only(right: 16),
                child: pw.Table(
                  border: pw.TableBorder.all(color: PdfColors.grey400),
                  columnWidths: {
                    0: const pw.FlexColumnWidth(1.2),
                    for (var i = 1; i <= 6; i++) i: const pw.FlexColumnWidth(1),
                  },
                  children: [
                    // Header
                    pw.TableRow(
                      decoration: const pw.BoxDecoration(color: PdfColors.blue900),
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text('Period',
                              style: pw.TextStyle(
                                  color: PdfColors.white,
                                  fontWeight: pw.FontWeight.bold)),
                        ),
                        ...shortDays.map((day) => pw.Padding(
                              padding: const pw.EdgeInsets.all(8),
                              child: pw.Text(day,
                                  style: pw.TextStyle(
                                      color: PdfColors.white,
                                      fontWeight: pw.FontWeight.bold)),
                            )),
                      ],
                    ),
                    // Data
                    ...List.generate(periodCount, (pIdx) {
                      return pw.TableRow(
                        children: [
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8),
                            child: pw.Text('Period ${pIdx + 1}',
                                style: pw.TextStyle(
                                    fontWeight: pw.FontWeight.bold)),
                          ),
                          ...List.generate(6, (dIdx) {
                            final entry = grid[pIdx][dIdx];
                            return pw.Padding(
                              padding: const pw.EdgeInsets.all(8),
                              child: pw.Column(
                                crossAxisAlignment: pw.CrossAxisAlignment.start,
                                children: [
                                  pw.Text(entry?.className ?? '-',
                                      style: pw.TextStyle(
                                          fontSize: 10,
                                          fontWeight: pw.FontWeight.bold)),
                                  if (entry != null)
                                    pw.Text(entry.subject,
                                        style: const pw.TextStyle(
                                            fontSize: 8,
                                            color: PdfColors.grey700)),
                                ],
                              ),
                            );
                          }),
                        ],
                      );
                    }),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
    return pdf;
  }

  static Future<void> downloadTeacherTimetable({
    required Teacher teacher,
    String? sessionName,
    SchoolDetails? schoolDetails,
  }) async {
    final pdf = await _buildTeacherTimetablePdf(
        teacher: teacher, sessionName: sessionName, schoolDetails: schoolDetails);
    final bytes = await pdf.save();
    final fileName = 'Schedule_${teacher.name.replaceAll(' ', '_')}.pdf';

    if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
      String? outputFile = await FilePicker.platform.saveFile(
        dialogTitle: 'Save Schedule As',
        fileName: fileName,
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (outputFile != null) {
        final file = File(outputFile);
        await file.writeAsBytes(bytes);
      }
    } else {
      await Printing.sharePdf(
        bytes: bytes,
        filename: fileName,
      );
    }
  }
}
