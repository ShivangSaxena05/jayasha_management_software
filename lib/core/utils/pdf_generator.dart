import 'dart:io';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:jayasha_childrens_academy/core/models/student_admission.dart';
import 'package:jayasha_childrens_academy/core/models/fee_payment.dart';
import 'package:jayasha_childrens_academy/core/models/teacher.dart';
import 'package:jayasha_childrens_academy/features/classes/data/models/school_class.dart';
import 'package:intl/intl.dart';

class PdfGenerator {
  static Future<void> printCertificate({
    required StudentAdmission student,
    required String type,
    required Map<String, dynamic> details,
  }) async {
    final pdf = pw.Document();

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
        fontSize: fontSize,
        fontWeight: style['bold'] == true ? pw.FontWeight.bold : pw.FontWeight.normal,
        fontStyle: style['italic'] == true ? pw.FontStyle.italic : pw.FontStyle.normal,
        decoration: style['underline'] == true ? pw.TextDecoration.underline : pw.TextDecoration.none,
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
                  details['schoolName'] ?? 'JAYASHA CHILDREN\'S ACADEMY',
                  style: getStyle(details['schoolNameStyle'], fontSize: 26),
                ),
                pw.SizedBox(height: 5),
                pw.Text(
                  details['subtitle'] ?? 'Affiliated to CBSE, New Delhi',
                  style: getStyle(details['subtitleStyle'], fontSize: 14),
                ),
                pw.SizedBox(height: 10),
                pw.Divider(thickness: 1),
                pw.SizedBox(height: 40),
                pw.Text(
                  (details['title'] ?? type).toUpperCase(),
                  style: getStyle(details['titleStyle'], fontSize: 20),
                ),
                pw.SizedBox(height: 60),
                pw.Paragraph(
                  text: details['body'] ?? '',
                  style: getStyle(details['bodyStyle'], fontSize: 16).copyWith(lineSpacing: 5),
                  textAlign: getAlign(details['bodyStyle']?['align']),
                ),
                pw.Spacer(),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'Date: ${details['issueDate'] != null ? DateFormat('dd/MM/yyyy').format(DateTime.parse(details['issueDate'])) : DateFormat('dd/MM/yyyy').format(DateTime.now())}',
                          style: getStyle(details['dateStyle'] ?? {'color': 0xFF000000}),
                        ),
                        pw.Text(
                          'Place: ${details['place'] ?? 'School Office'}',
                          style: getStyle(details['placeStyle']),
                        ),
                      ],
                    ),
                    pw.Column(
                      children: [
                        pw.SizedBox(height: 40),
                        pw.Text(
                          details['principalLabel'] ?? 'Principal Signature',
                          style: getStyle(details['principalLabelStyle']),
                        ),
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

    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save());
  }

  static Future<void> generateCertificate({
    required StudentAdmission student,
    required String type,
    Map<String, dynamic>? details,
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
                  'JAYASHA CHILDREN\'S ACADEMY',
                  style: pw.TextStyle(
                    fontSize: 26,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.blue900,
                  ),
                ),
                pw.SizedBox(height: 5),
                pw.Text('Affiliated to CBSE, New Delhi', style: const pw.TextStyle(fontSize: 14)),
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
                        pw.Text('Date: ${DateFormat('dd/MM/yyyy').format(DateTime.now())}'),
                        pw.Text('Place: School Office'),
                      ],
                    ),
                    pw.Column(
                      children: [
                        pw.SizedBox(height: 40),
                        pw.Text('Principal Signature', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
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

    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save());
  }

  static Future<pw.Document> _buildFeeReceiptPdf({
    required StudentAdmission student,
    required FeePayment payment,
    String? sessionName,
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
                          'JAYASHA CHILDREN\'S ACADEMY',
                          style: pw.TextStyle(
                            fontSize: 24,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.blue900,
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text('Affiliated to CBSE, New Delhi', style: const pw.TextStyle(fontSize: 12)),
                        pw.Text('Address: Near City Center, Shivpuri, Madhya Pradesh', style: const pw.TextStyle(fontSize: 10)),
                        pw.Text('Contact: +91 9876543210 | Email: info@jayasha.edu.in', style: const pw.TextStyle(fontSize: 10)),
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
                        child: pw.Text('JCA', style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 10),
                pw.Divider(thickness: 2, color: PdfColors.blue900),
                pw.SizedBox(height: 10),
                pw.Center(
                  child: pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                    decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                    child: pw.Text(
                      'OFFICIAL FEE RECEIPT',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14),
                    ),
                  ),
                ),
                pw.SizedBox(height: 20),

                // Receipt and Date Info
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Receipt No: REC-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    pw.Text('Date: ${DateFormat('dd MMMM yyyy').format(payment.date)}'),
                  ],
                ),
                pw.SizedBox(height: 20),

                // Student Details Section
                pw.Text('STUDENT INFORMATION', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12, color: PdfColors.blue900)),
                pw.Divider(thickness: 1, color: PdfColors.blue900),
                pw.SizedBox(height: 8),
                pw.Row(
                  children: [
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          _receiptInfoRow('Student Name', student.name),
                          _receiptInfoRow('Admission No', student.admissionNumber),
                          _receiptInfoRow('Roll Number', student.rollNumber ?? 'N/A'),
                          _receiptInfoRow('Class & Section', '${student.className ?? 'N/A'} - ${student.section ?? 'N/A'}'),
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
                pw.Text('PAYMENT DETAILS', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12, color: PdfColors.blue900)),
                pw.Divider(thickness: 1, color: PdfColors.blue900),
                pw.SizedBox(height: 8),
                pw.Table(
                  border: pw.TableBorder.all(color: PdfColors.grey300),
                  children: [
                    pw.TableRow(
                      decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                      children: [
                        pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('Description', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                        pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('Payment Category', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                        pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('Amount (INR)', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                      ],
                    ),
                    pw.TableRow(
                      children: [
                        pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text(payment.remarks ?? 'Fee Payment')),
                        pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text(payment.category.name.toUpperCase())),
                        pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('Rs. ${payment.amount.toStringAsFixed(2)}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
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
                        pw.Text('Status: SUCCESSFUL', style: pw.TextStyle(color: PdfColors.green700, fontWeight: pw.FontWeight.bold)),
                      ],
                    ),
                    pw.Container(
                      padding: const pw.EdgeInsets.all(10),
                      decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                      child: pw.Text(
                        'TOTAL PAID: Rs. ${payment.amount.toStringAsFixed(2)}',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16),
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
                        pw.SizedBox(height: 40, width: 100, child: pw.Divider(thickness: 0.5)),
                        pw.Text('Parent\'s Signature', style: const pw.TextStyle(fontSize: 10)),
                      ],
                    ),
                    pw.Column(
                      children: [
                        pw.SizedBox(height: 40, width: 100, child: pw.Divider(thickness: 0.5)),
                        pw.Text('Accountant Signature', style: const pw.TextStyle(fontSize: 10)),
                      ],
                    ),
                    pw.Column(
                      children: [
                        pw.SizedBox(height: 40, width: 100, child: pw.Divider(thickness: 0.5)),
                        pw.Text('Principal\'s Signature', style: const pw.TextStyle(fontSize: 10)),
                      ],
                    ),
                  ],
                ),
                pw.SizedBox(height: 20),
                pw.Center(
                  child: pw.Text(
                    'Note: This is a computer-generated receipt and does not require a physical seal.',
                    style: pw.TextStyle(fontSize: 8, color: PdfColors.grey600, fontStyle: pw.FontStyle.italic),
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
            pw.TextSpan(text: '$label: ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
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
  }) async {
    final pdf = await _buildFeeReceiptPdf(student: student, payment: payment, sessionName: sessionName);
    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save());
  }

  static Future<void> downloadFeeReceipt({
    required StudentAdmission student,
    required FeePayment payment,
    String? sessionName,
  }) async {
    final pdf = await _buildFeeReceiptPdf(student: student, payment: payment, sessionName: sessionName);
    final bytes = await pdf.save();

    // Printing.sharePdf shows the native share/save sheet which handles "Downloading" locally
    await Printing.sharePdf(
      bytes: bytes,
      filename: 'Receipt_${student.admissionNumber}_${DateFormat('yyyyMMdd').format(payment.date)}.pdf'
    );
  }

  static Future<void> generateReportCard({
    required dynamic markRecord,
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
                      pw.Text('JAYASHA CHILDREN\'S ACADEMY', style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold)),
                      pw.Text('PROGRESS REPORT', style: pw.TextStyle(fontSize: 16, decoration: pw.TextDecoration.underline)),
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
                        pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('Subject', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                        pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('Max Marks', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                        pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text('Marks Obtained', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                      ],
                    ),
                    ...marks.map((m) => pw.TableRow(
                      children: [
                        pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(m['subject'])),
                        pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(m['maxMarks'].toString())),
                        pw.Padding(padding: const pw.EdgeInsets.all(5), child: pw.Text(m['totalMarks'].toString())),
                      ],
                    )),
                  ],
                ),
                pw.SizedBox(height: 20),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Total Obtained: ${markRecord['totalObtained']}'),
                    pw.Text('Percentage: ${markRecord['percentage'].toStringAsFixed(2)}%'),
                    pw.Text('Result: ${markRecord['result']}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  ],
                ),
                pw.Spacer(),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Class Teacher'),
                    pw.Text('Principal'),
                    pw.Text('Parent'),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );

    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save());
  }

  static Future<void> generateExamDatesheet({
    required dynamic exam,
    required List<dynamic> datesheet,
    required String className,
    String? sessionName,
  }) async {
    final pdf = pw.Document();
    _addDatesheetPage(pdf, exam, datesheet, className, sessionName);
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Datesheet_${className}_${exam['name']}.pdf',
    );
  }

  static Future<void> generateAllClassesDatesheet({
    required dynamic exam,
    required List<dynamic> fullDatesheet,
    required List<dynamic> classes,
    String? sessionName,
  }) async {
    final pdf = pw.Document();

    for (var cls in classes) {
      final classId = cls['_id'];
      final classEntries = fullDatesheet.where((d) => d['classId'] == classId).toList();
      if (classEntries.isNotEmpty) {
        final section = cls['section'];
        final sectionSuffix = (section != null &&
                section.toString().toLowerCase() != 'null' &&
                section.toString().isNotEmpty)
            ? ' - $section'
            : '';
        _addDatesheetPage(pdf, exam, classEntries, '${cls['name']}$sectionSuffix', sessionName);
      }
    }

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Full_Datesheet_${exam['name']}.pdf',
    );
  }

  static void _addDatesheetPage(pw.Document pdf, dynamic exam, List<dynamic> datesheet, String className, String? sessionName) {
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
                        'JAYASHA CHILDREN\'S ACADEMY',
                        style: pw.TextStyle(
                          fontSize: 22,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.blue900,
                        ),
                      ),
                      pw.SizedBox(height: 5),
                      pw.Text('EXAMINATION DATESHEET',
                          style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, decoration: pw.TextDecoration.underline)),
                      pw.SizedBox(height: 10),
                      pw.Text(exam['name'], style: pw.TextStyle(fontSize: 16)),
                      if (sessionName != null)
                        pw.Text('Academic Session: $sessionName', style: const pw.TextStyle(fontSize: 12)),
                      pw.SizedBox(height: 5),
                      pw.Text('Class: $className', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
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
                        pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('Subject', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                        pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('Date', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                        pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('Start Time', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                        pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('Duration', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                        pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('Max Marks', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                      ],
                    ),
                    ...datesheet.map((item) => pw.TableRow(
                      children: [
                        pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text(item['subject'] ?? '')),
                        pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text(item['date'] != null ? DateFormat('dd/MM/yyyy').format(DateTime.parse(item['date'])) : '-')),
                        pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text(item['startTime'] ?? '-')),
                        pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text('${item['durationHours']} Hr')),
                        pw.Padding(padding: const pw.EdgeInsets.all(8), child: pw.Text(item['maxMarks']?.toString() ?? '-')),
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
                        pw.Text('Principal'),
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

  static Future<void> generateClassTimetable({
    required SchoolClass schoolClass,
    String? sessionName,
  }) async {
    final pdf = pw.Document();
    final shortDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.only(left: 40, top: 32, bottom: 32, right: 40),
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
                        'JAYASHA CHILDREN\'S ACADEMY',
                        style: pw.TextStyle(
                          fontSize: 22,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.blue900,
                        ),
                      ),
                      pw.Text('Weekly Timetable: ${schoolClass.name}',
                          style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                      if (sessionName != null)
                        pw.Text('Academic Session: $sessionName', style: const pw.TextStyle(fontSize: 12)),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('Generated on: ${DateFormat('dd/MM/yyyy').format(DateTime.now())}',
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
                              style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold)),
                        ),
                        ...shortDays.map((day) => pw.Padding(
                              padding: const pw.EdgeInsets.all(8),
                              child: pw.Text(day,
                                  style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold)),
                            )),
                      ],
                    ),
                    // Data
                    ...List.generate(schoolClass.timetable.length, (pIdx) {
                      return pw.TableRow(
                        children: [
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8),
                            child: pw.Text('Period ${pIdx + 1}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                          ),
                          ...List.generate(6, (dIdx) {
                            final entry = schoolClass.timetable[pIdx][dIdx];
                            return pw.Padding(
                              padding: const pw.EdgeInsets.all(8),
                              child: pw.Column(
                                crossAxisAlignment: pw.CrossAxisAlignment.start,
                                children: [
                                  pw.Text(entry?.subject ?? '-',
                                      style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                                  if (entry != null && entry.subject != 'LUNCH')
                                    pw.Text(entry.teacherName,
                                        style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
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

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Timetable_${schoolClass.name.replaceAll(' ', '_')}.pdf',
    );
  }

  static Future<void> generateTeacherTimetable({
    required Teacher teacher,
    String? sessionName,
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
        margin: const pw.EdgeInsets.only(left: 40, top: 32, bottom: 32, right: 40),
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
                        'JAYASHA CHILDREN\'S ACADEMY',
                        style: pw.TextStyle(
                          fontSize: 22,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.blue900,
                        ),
                      ),
                      pw.Text('Teacher Schedule: ${teacher.name}',
                          style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                      if (sessionName != null)
                        pw.Text('Academic Session: $sessionName', style: const pw.TextStyle(fontSize: 12)),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('Generated on: ${DateFormat('dd/MM/yyyy').format(DateTime.now())}',
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
                              style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold)),
                        ),
                        ...shortDays.map((day) => pw.Padding(
                              padding: const pw.EdgeInsets.all(8),
                              child: pw.Text(day,
                                  style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold)),
                            )),
                      ],
                    ),
                    // Data
                    ...List.generate(periodCount, (pIdx) {
                      return pw.TableRow(
                        children: [
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8),
                            child: pw.Text('Period ${pIdx + 1}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                          ),
                          ...List.generate(6, (dIdx) {
                            final entry = grid[pIdx][dIdx];
                            return pw.Padding(
                              padding: const pw.EdgeInsets.all(8),
                              child: pw.Column(
                                crossAxisAlignment: pw.CrossAxisAlignment.start,
                                children: [
                                  pw.Text(entry?.className ?? '-',
                                      style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                                  if (entry != null)
                                    pw.Text(entry.subject,
                                        style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
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

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Schedule_${teacher.name.replaceAll(' ', '_')}.pdf',
    );
  }
}
