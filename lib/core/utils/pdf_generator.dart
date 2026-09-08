import 'dart:io';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:jayasha_childrens_academy/core/models/student_admission.dart';
import 'package:jayasha_childrens_academy/core/models/fee_payment.dart';
import 'package:intl/intl.dart';

class PdfGenerator {
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
}
