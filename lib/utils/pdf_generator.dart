import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/user_profile.dart';
import '../models/health_log.dart';
import '../screens/activity_log.dart';

class PdfGenerator {
  static String _getUnit(String category, double? value) {
    switch (category) {
      case 'Temperature':
        // Detect if the app is using Celsius (e.g. 37) or Fahrenheit (e.g. 98)
        if (value != null && value > 60) return '°F';
        return '°C';
      case 'Fluid Intake':
        return 'L';
      case 'Urine Output':
        return 'ml';
      case 'Platelets':
        return '/µL';
      case 'Blood Pressure':
        return 'mmHg';
      default:
        return '';
    }
  }

  static PdfColor _getRowColor(String category) {
    switch (category) {
      case 'Temperature':
        return PdfColor.fromHex('#FFF7ED'); // Light Orange
      case 'Urine Output':
        return PdfColor.fromHex('#FEFCE8'); // Light Yellow
      case 'Fluid Intake':
        return PdfColor.fromHex('#ECFEFF'); // Light Cyan
      case 'Platelets':
        return PdfColor.fromHex('#FEF2F2'); // Light Red
      case 'Blood Pressure':
        return PdfColor.fromHex('#F5F3FF'); // Light Purple
      case 'Symptoms':
        return PdfColor.fromHex('#EFF6FF'); // Light Blue
      default:
        return PdfColors.white;
    }
  }

  static Future<void> generateAndShareReport({
    required UserProfile patient,
    required String filter,
    required List<ActivityItem> logs,
    required Map<String, List<double>> chartData,
  }) async {
    final pdf = pw.Document();

    Map<String, dynamic>? caretakerData;
    if (patient.linkedCaretakerId != null) {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(patient.linkedCaretakerId)
            .get();
        if (doc.exists) caretakerData = doc.data();
      } catch (e) {
        debugPrint("Could not fetch caretaker for PDF: $e");
      }
    }

    String age = 'Unknown';
    if (patient.dob.isNotEmpty) {
      try {
        DateTime dob = DateTime.parse(patient.dob);
        int years = DateTime.now().year - dob.year;
        age = '$years yrs';
      } catch (_) {}
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          List<pw.Widget> graphWidgets = [];
          if (chartData.isNotEmpty) {
            if (filter == 'All') {
              graphWidgets.add(pw.Text('7-Day Medical Trends',
                  style: pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.teal800)));
              graphWidgets.add(pw.SizedBox(height: 12));

              List<pw.Widget> gridChildren = [];
              chartData.forEach((category, values) {
                if (values.isNotEmpty) {
                  gridChildren.add(pw.Container(
                      width: 240,
                      child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(category,
                                style: pw.TextStyle(
                                    fontSize: 12,
                                    fontWeight: pw.FontWeight.bold)),
                            pw.SizedBox(height: 4),
                            _buildGraph(
                                values, _getUnit(category, values.last), 240),
                          ])));
                }
              });

              graphWidgets.add(
                  pw.Wrap(spacing: 20, runSpacing: 20, children: gridChildren));
              graphWidgets.add(pw.SizedBox(height: 30));
            } else if (filter != 'Symptoms' &&
                chartData[filter] != null &&
                chartData[filter]!.isNotEmpty) {
              graphWidgets.add(pw.Text('7-Day Trend: $filter',
                  style: pw.TextStyle(
                      fontSize: 14, fontWeight: pw.FontWeight.bold)));
              graphWidgets.add(pw.SizedBox(height: 10));
              graphWidgets.add(_buildGraph(chartData[filter]!,
                  _getUnit(filter, chartData[filter]!.last), 530));
              graphWidgets.add(pw.SizedBox(height: 30));
            }
          }

          return [
            _buildHeader(filter),
            pw.SizedBox(height: 20),
            _buildPatientAndCaretakerInfo(patient, age, caretakerData),
            pw.SizedBox(height: 30),
            ...graphWidgets,
            pw.Text('Detailed Medical Logs',
                style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.teal800)),
            pw.SizedBox(height: 10),
            _buildLogsTable(logs),
          ];
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: '${patient.fullName.replaceAll(' ', '_')}_Medical_Report.pdf',
    );
  }

  static pw.Widget _buildHeader(String filter) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('VitalTrack Medical Report',
                style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.teal800)),
            pw.Text(DateFormat('MMM dd, yyyy').format(DateTime.now()),
                style:
                    const pw.TextStyle(fontSize: 12, color: PdfColors.grey700)),
          ],
        ),
        pw.Divider(color: PdfColors.teal200),
        pw.Text(
            'Report Type: ${filter == 'All' ? 'Complete Medical History' : '$filter Logs'}',
            style: pw.TextStyle(fontSize: 14, color: PdfColors.grey800)),
      ],
    );
  }

  static pw.Widget _buildPatientAndCaretakerInfo(
      UserProfile patient, String age, Map<String, dynamic>? caretaker) {
    // FIXED: Safe ID generation
    final safeId = patient.uid.length >= 8
        ? patient.uid.substring(0, 8).toUpperCase()
        : patient.uid.toUpperCase();

    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(
          child: pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
                color: PdfColors.grey100,
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8))),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('PATIENT INFORMATION',
                    style: pw.TextStyle(
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.grey600)),
                pw.SizedBox(height: 8),
                pw.Text(patient.fullName,
                    style: pw.TextStyle(
                        fontSize: 16, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 4),
                pw.Text('Patient ID: $safeId'),
                pw.Text(
                    'Age: $age | Blood Type: ${patient.bloodType ?? 'N/A'}'),
                pw.Text('Weight: ${patient.weight ?? 'N/A'} kg'),
                if (patient.phone.isNotEmpty)
                  pw.Text('Phone: ${patient.phone}'),
              ],
            ),
          ),
        ),
        pw.SizedBox(width: 20),
        pw.Expanded(
          child: pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
                color: PdfColors.teal50,
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8))),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('AUTHORIZED CARETAKER',
                    style: pw.TextStyle(
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.teal700)),
                pw.SizedBox(height: 8),
                if (caretaker != null) ...[
                  pw.Text(caretaker['fullName'] ?? 'Unknown',
                      style: pw.TextStyle(
                          fontSize: 16, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 4),
                  pw.Text('Phone: ${caretaker['phone'] ?? 'N/A'}'),
                ] else ...[
                  pw.Text('No Caretaker Linked',
                      style: const pw.TextStyle(fontSize: 14)),
                  pw.Text('Patient is managing their own care.',
                      style: const pw.TextStyle(
                          fontSize: 12, color: PdfColors.grey600)),
                ]
              ],
            ),
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildGraph(
      List<double> dataPoints, String unit, double containerWidth) {
    if (dataPoints.isEmpty) return pw.SizedBox();

    double minVal = dataPoints.reduce(math.min);
    double maxVal = dataPoints.reduce(math.max);

    double padding = (maxVal - minVal).abs();
    if (padding == 0) {
      padding = maxVal == 0 ? 5.0 : (maxVal * 0.1).abs();
    } else {
      padding = padding * 0.4;
    }

    minVal -= padding;
    maxVal += padding;
    double range = maxVal - minVal;
    if (range <= 0) range = 1;

    double chartWidth = containerWidth - 65;
    if (chartWidth < 50) chartWidth = 50;
    double chartHeight = 86;
    double stepX =
        chartWidth / (dataPoints.length > 1 ? dataPoints.length - 1 : 1);

    List<pw.Widget> stackChildren = [];

    stackChildren.add(
      pw.CustomPaint(
        size: PdfPoint(chartWidth, chartHeight),
        painter: (PdfGraphics canvas, PdfPoint size) {
          canvas.setStrokeColor(PdfColors.grey200);
          canvas.setLineWidth(1);
          for (int i = 0; i <= 4; i++) {
            double y = size.y * (i / 4);
            canvas.drawLine(0, y, size.x, y);
            canvas.strokePath();
          }

          canvas.setStrokeColor(PdfColors.teal);
          canvas.setLineWidth(2);
          for (int i = 0; i < dataPoints.length; i++) {
            double x = i * stepX;
            double normalizedY = (dataPoints[i] - minVal) / range;
            double y = normalizedY * size.y;

            if (i == 0) {
              canvas.moveTo(x, y);
            } else {
              canvas.lineTo(x, y);
            }
          }
          canvas.strokePath();
        },
      ),
    );

    for (int i = 0; i < dataPoints.length; i++) {
      double val = dataPoints[i];
      double x = i * stepX;
      double normalizedY = (val - minVal) / range;
      double y = normalizedY * chartHeight;

      String valStr =
          val == val.toInt() ? val.toInt().toString() : val.toStringAsFixed(1);

      bool isLastPoint = i == dataPoints.length - 1 && dataPoints.length > 1;
      double textOffsetX = isLastPoint ? x - 12 : x - 6;

      stackChildren.add(
        pw.Positioned(
          left: x - 3,
          bottom: y - 3,
          child: pw.Container(
            width: 6,
            height: 6,
            decoration: const pw.BoxDecoration(
                color: PdfColors.teal700, shape: pw.BoxShape.circle),
          ),
        ),
      );

      stackChildren.add(
        pw.Positioned(
          left: textOffsetX,
          bottom: y + 4,
          child: pw.Text(
            valStr,
            style: pw.TextStyle(
                fontSize: 8,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.teal900),
          ),
        ),
      );
    }

    return pw.Container(
      height: 120,
      width: containerWidth,
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Row(
        children: [
          pw.Container(
            width: 45,
            padding: const pw.EdgeInsets.only(
                left: 4, right: 4, top: 12, bottom: 12),
            child: pw.Column(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: List.generate(5, (i) {
                double val = maxVal - (range * (i / 4));
                String labelStr = val == val.toInt()
                    ? val.toInt().toString()
                    : val.toStringAsFixed(1);
                return pw.Text('$labelStr $unit',
                    style: const pw.TextStyle(
                        fontSize: 6, color: PdfColors.grey700));
              }),
            ),
          ),
          pw.Expanded(
            child: pw.Padding(
              padding: const pw.EdgeInsets.only(top: 16, bottom: 16, right: 16),
              child: pw.SizedBox(
                width: chartWidth,
                height: chartHeight,
                child: pw.Stack(
                  children: stackChildren,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildLogsTable(List<ActivityItem> logs) {
    final headers = ['Date', 'Time', 'Metric', 'Value', 'Status', 'Notes'];

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300),
      columnWidths: {
        0: const pw.FlexColumnWidth(2),
        1: const pw.FlexColumnWidth(2),
        2: const pw.FlexColumnWidth(2.5),
        3: const pw.FlexColumnWidth(2),
        4: const pw.FlexColumnWidth(2),
        5: const pw.FlexColumnWidth(3),
      },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.teal700),
          children: headers.asMap().entries.map((entry) {
            int idx = entry.key;
            pw.Alignment align = (idx == 3 || idx == 4)
                ? pw.Alignment.center
                : pw.Alignment.centerLeft;
            return pw.Container(
              padding:
                  const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 6),
              alignment: align,
              child: pw.Text(entry.value,
                  style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.white,
                      fontSize: 10)),
            );
          }).toList(),
        ),
        ...logs.map((item) {
          final log = item.log;
          String unit = _getUnit(item.category, log.value1);
          String valueStr = '';

          if (item.category == 'Blood Pressure' && log.value2 != null) {
            valueStr = '${log.value1?.toInt()}/${log.value2?.toInt()} $unit';
          } else if (item.category == 'Symptoms') {
            valueStr = '${log.symptoms?.length ?? 0} issues';
          } else {
            num val = log.value1 ?? 0;
            valueStr =
                '${val == val.toInt() ? val.toInt() : val.toStringAsFixed(1)} $unit';
          }

          final rowData = [
            DateFormat('MM/dd/yyyy').format(log.timestamp),
            DateFormat('hh:mm a').format(log.timestamp),
            item.category,
            valueStr,
            log.status,
            log.notes.isNotEmpty
                ? log.notes
                : (log.hasVoiceNote ? 'Voice Note' : '-'),
          ];

          return pw.TableRow(
            decoration: pw.BoxDecoration(color: _getRowColor(item.category)),
            children: rowData.asMap().entries.map((entry) {
              int idx = entry.key;
              pw.Alignment align = (idx == 3 || idx == 4)
                  ? pw.Alignment.center
                  : pw.Alignment.centerLeft;
              return pw.Container(
                padding:
                    const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 6),
                alignment: align,
                child: pw.Text(entry.value,
                    style: const pw.TextStyle(fontSize: 10)),
              );
            }).toList(),
          );
        }),
      ],
    );
  }
}
