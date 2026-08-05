import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class AdminReportsPage extends StatefulWidget {
  final bool isEmbedded;
  const AdminReportsPage({super.key, this.isEmbedded = false});

  @override
  State<AdminReportsPage> createState() => _AdminReportsPageState();
}

class _AdminReportsPageState extends State<AdminReportsPage> {
  // Filters
  String _selectedReportType = 'Executive Summary';
  String _selectedDateFilter = 'All Time';
  DateTimeRange? _customDateRange;
  DateTime _selectedReportMonth = DateTime(DateTime.now().year, DateTime.now().month);
  String _selectedSpecialization = 'All';
  String _selectedStatus = 'All';

  final List<String> _reportTypes = [
    'Executive Summary',
    'Financial & Revenue',
    'Appointments & Bookings',
    'Doctor & Hospital Performance',
    'Patient Demographics',
  ];

  final List<String> _dateFilterPresets = [
    'All Time',
    'Select Month',
    'Today',
    'This Week',
    'This Month',
    'Last 30 Days',
    'This Year',
    'Custom Range',
  ];

  final List<String> _specializations = [
    'All',
    'Cardiology',
    'Pediatrics',
    'Orthopedics',
    'Neurology',
    'General Medicine',
    'Dermatology',
  ];

  final List<String> _statuses = [
    'All',
    'Completed',
    'Confirmed',
    'Pending',
    'Cancelled',
  ];

  // Helper date parser with multi-format support
  DateTime? _parseDate(dynamic dateVal) {
    if (dateVal == null) return null;
    if (dateVal is Timestamp) return dateVal.toDate();
    if (dateVal is DateTime) return dateVal;
    final str = dateVal.toString().trim();
    if (str.isEmpty) return null;

    final formats = [
      "MMMM d, yyyy",
      "yyyy-MM-dd",
      "dd/MM/yyyy",
      "MM/dd/yyyy",
      "d MMM yyyy",
      "d MMMM yyyy",
      "EEE, MMM d, yyyy",
      "yyyy/MM/dd",
    ];

    for (var fmt in formats) {
      try {
        return DateFormat(fmt).parse(str);
      } catch (_) {}
    }

    return DateTime.tryParse(str);
  }

  DateTime? _extractDateFromDoc(Map<String, dynamic> data) {
    return _parseDate(data['date']) ??
        _parseDate(data['createdAt']) ??
        _parseDate(data['appointmentDate']) ??
        _parseDate(data['timestamp']);
  }

  double _extractFee(dynamic val) {
    if (val == null) return 0;
    if (val is num) return val.toDouble();
    return double.tryParse(val.toString()) ?? 0;
  }

  bool _isDateInRange(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    if (_selectedDateFilter == 'Today') {
      return date.year == today.year && date.month == today.month && date.day == today.day;
    } else if (_selectedDateFilter == 'This Week') {
      final startOfWeek = today.subtract(Duration(days: today.weekday - 1));
      return date.isAfter(startOfWeek.subtract(const Duration(seconds: 1))) &&
          date.isBefore(today.add(const Duration(days: 1)));
    } else if (_selectedDateFilter == 'This Month') {
      return date.year == today.year && date.month == today.month;
    } else if (_selectedDateFilter == 'Select Month') {
      return date.year == _selectedReportMonth.year && date.month == _selectedReportMonth.month;
    } else if (_selectedDateFilter == 'Last 30 Days') {
      final thirtyDaysAgo = today.subtract(const Duration(days: 30));
      return date.isAfter(thirtyDaysAgo) && date.isBefore(today.add(const Duration(days: 1)));
    } else if (_selectedDateFilter == 'This Year') {
      return date.year == today.year;
    } else if (_selectedDateFilter == 'Custom Range' && _customDateRange != null) {
      final start = DateTime(_customDateRange!.start.year, _customDateRange!.start.month, _customDateRange!.start.day);
      final end = DateTime(_customDateRange!.end.year, _customDateRange!.end.month, _customDateRange!.end.day, 23, 59, 59);
      return date.isAfter(start.subtract(const Duration(seconds: 1))) && date.isBefore(end.add(const Duration(seconds: 1)));
    }
    return true; // "All Time"
  }

  String _formatCurrency(double amount) {
    return 'LKR ${amount.toStringAsFixed(amount.truncateToDouble() == amount ? 0 : 2).replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (match) => ',',
    )}';
  }

  Future<void> _selectMonthForReport() async {
    final now = DateTime.now();
    final years = List.generate(5, (index) => now.year - index);
    final months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];

    int selectedYear = _selectedReportMonth.year;
    int selectedMonthIndex = _selectedReportMonth.month - 1;

    final picked = await showDialog<DateTime>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Row(
                children: [
                  Icon(Icons.calendar_month_rounded, color: Color(0xFF2563EB)),
                  SizedBox(width: 8),
                  Text("Select Month for Report", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<int>(
                    initialValue: selectedYear,
                    decoration: InputDecoration(
                      labelText: "Year",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    items: years.map((y) => DropdownMenuItem(value: y, child: Text(y.toString()))).toList(),
                    onChanged: (val) {
                      if (val != null) setDialogState(() => selectedYear = val);
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int>(
                    initialValue: selectedMonthIndex,
                    decoration: InputDecoration(
                      labelText: "Month",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    items: List.generate(
                      12,
                      (i) => DropdownMenuItem(value: i, child: Text(months[i])),
                    ),
                    onChanged: (val) {
                      if (val != null) setDialogState(() => selectedMonthIndex = val);
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () => Navigator.pop(ctx, DateTime(selectedYear, selectedMonthIndex + 1)),
                  child: const Text("Apply Month"),
                ),
              ],
            );
          },
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedReportMonth = picked;
        _selectedDateFilter = 'Select Month';
      });
    }
  }

  Future<void> _selectCustomDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: _customDateRange ??
          DateTimeRange(
            start: DateTime.now().subtract(const Duration(days: 7)),
            end: DateTime.now(),
          ),
    );
    if (picked != null) {
      setState(() {
        _customDateRange = picked;
        _selectedDateFilter = 'Custom Range';
      });
    }
  }

  Future<void> _exportPDF(List<Map<String, dynamic>> records, Map<String, String> summaryMetrics) async {
    if (records.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No data available to export.')),
      );
      return;
    }

    final pdf = pw.Document();
    final metricsEntries = summaryMetrics.entries.toList();
    final headers = ['Booking ID', 'Date', 'Patient Name', 'Doctor Name', 'Hospital', 'Total Amount', 'Status'];

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 28, vertical: 24),
        footer: (pw.Context context) {
          return pw.Container(
            margin: const pw.EdgeInsets.only(top: 10),
            padding: const pw.EdgeInsets.only(top: 6),
            decoration: const pw.BoxDecoration(
              border: pw.Border(top: pw.BorderSide(color: PdfColors.grey300, width: 0.5)),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'DocTime Healthcare Systems • Confidential Admin Report',
                  style: const pw.TextStyle(color: PdfColors.grey600, fontSize: 8),
                ),
                pw.Text(
                  'Page ${context.pageNumber} of ${context.pagesCount}',
                  style: pw.TextStyle(color: PdfColor.fromHex('#2563EB'), fontSize: 8, fontWeight: pw.FontWeight.bold),
                ),
              ],
            ),
          );
        },
        build: (pw.Context context) {
          return [
            // Executive Header Banner
            pw.Container(
              padding: const pw.EdgeInsets.all(16),
              decoration: pw.BoxDecoration(
                color: PdfColor.fromHex('#0F172A'),
                borderRadius: pw.BorderRadius.circular(10),
              ),
              child: pw.Row(
                children: [
                  pw.Container(
                    width: 4,
                    height: 36,
                    decoration: pw.BoxDecoration(
                      color: PdfColor.fromHex('#2563EB'),
                      borderRadius: pw.BorderRadius.circular(2),
                    ),
                  ),
                  pw.SizedBox(width: 12),
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'DOC TIME HEALTHCARE',
                          style: pw.TextStyle(
                            color: PdfColor.fromHex('#38BDF8'),
                            fontSize: 9,
                            fontWeight: pw.FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                        pw.SizedBox(height: 2),
                        pw.Text(
                          _selectedReportType.toUpperCase(),
                          style: pw.TextStyle(
                            color: PdfColors.white,
                            fontSize: 15,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: pw.BoxDecoration(
                          color: PdfColor.fromHex('#1E293B'),
                          borderRadius: pw.BorderRadius.circular(4),
                          border: pw.Border.all(color: PdfColor.fromHex('#38BDF8'), width: 0.5),
                        ),
                        child: pw.Text(
                          'Filter: $_selectedDateFilter',
                          style: pw.TextStyle(
                            color: PdfColor.fromHex('#38BDF8'),
                            fontSize: 9,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'Generated: ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}',
                        style: const pw.TextStyle(color: PdfColors.grey400, fontSize: 8),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 16),

            // Executive Metrics Title
            pw.Row(
              children: [
                pw.Container(
                  width: 8,
                  height: 8,
                  decoration: const pw.BoxDecoration(
                    color: PdfColor.fromInt(0xFF2563EB),
                    shape: pw.BoxShape.circle,
                  ),
                ),
                pw.SizedBox(width: 6),
                pw.Text(
                  'Executive Metrics Summary',
                  style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#0F172A')),
                ),
              ],
            ),
            pw.SizedBox(height: 8),

            // 2-Row Metric Grid using Table
            pw.Table(
              children: [
                pw.TableRow(
                  children: List.generate(4, (i) {
                    if (i >= metricsEntries.length) return pw.Container();
                    final entry = metricsEntries[i];
                    return pw.Container(
                      margin: const pw.EdgeInsets.all(3),
                      padding: const pw.EdgeInsets.all(8),
                      decoration: pw.BoxDecoration(
                        color: PdfColor.fromHex('#F8FAFC'),
                        borderRadius: pw.BorderRadius.circular(6),
                        border: pw.Border.all(color: PdfColor.fromHex('#E2E8F0')),
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            entry.key.toUpperCase(),
                            style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey600),
                            maxLines: 1,
                          ),
                          pw.SizedBox(height: 3),
                          pw.Text(
                            entry.value,
                            style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#1E293B')),
                            maxLines: 1,
                          ),
                        ],
                      ),
                    );
                  }),
                ),
                if (metricsEntries.length > 4)
                  pw.TableRow(
                    children: List.generate(4, (i) {
                      final idx = i + 4;
                      if (idx >= metricsEntries.length) return pw.Container();
                      final entry = metricsEntries[idx];
                      return pw.Container(
                        margin: const pw.EdgeInsets.all(3),
                        padding: const pw.EdgeInsets.all(8),
                        decoration: pw.BoxDecoration(
                          color: PdfColor.fromHex('#F8FAFC'),
                          borderRadius: pw.BorderRadius.circular(6),
                          border: pw.Border.all(color: PdfColor.fromHex('#E2E8F0')),
                        ),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              entry.key.toUpperCase(),
                              style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey600),
                              maxLines: 1,
                            ),
                            pw.SizedBox(height: 3),
                            pw.Text(
                              entry.value,
                              style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#1E293B')),
                              maxLines: 1,
                            ),
                          ],
                        ),
                      );
                    }),
                  ),
              ],
            ),
            pw.SizedBox(height: 16),

            // Records Table Header
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Row(
                  children: [
                    pw.Container(
                      width: 8,
                      height: 8,
                      decoration: const pw.BoxDecoration(
                        color: PdfColor.fromInt(0xFF10B981),
                        shape: pw.BoxShape.circle,
                      ),
                    ),
                    pw.SizedBox(width: 6),
                    pw.Text(
                      'Matching Transactions Log',
                      style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#0F172A')),
                    ),
                  ],
                ),
                pw.Text(
                  'Total Records: ${records.length}',
                  style: pw.TextStyle(fontSize: 9, color: PdfColor.fromHex('#2563EB'), fontWeight: pw.FontWeight.bold),
                ),
              ],
            ),
            pw.SizedBox(height: 8),

            // Formatted Itemized Table
            pw.TableHelper.fromTextArray(
              headers: headers,
              data: records.map((r) {
                return [
                  r['Booking ID'] ?? '',
                  r['Date'] ?? '',
                  r['Patient Name'] ?? '',
                  r['Doctor Name'] ?? '',
                  r['Hospital'] ?? '',
                  r['Total Amount'] ?? '',
                  (r['Status'] ?? 'PENDING').toString().toUpperCase(),
                ];
              }).toList(),
              columnWidths: {
                0: const pw.FlexColumnWidth(1.2),
                1: const pw.FlexColumnWidth(1.0),
                2: const pw.FlexColumnWidth(1.4),
                3: const pw.FlexColumnWidth(1.6),
                4: const pw.FlexColumnWidth(1.3),
                5: const pw.FlexColumnWidth(1.2),
                6: const pw.FlexColumnWidth(1.1),
              },
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 8),
              headerDecoration: pw.BoxDecoration(color: PdfColor.fromHex('#1E293B')),
              rowDecoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5))),
              oddRowDecoration: pw.BoxDecoration(color: PdfColor.fromHex('#F8FAFC')),
              cellStyle: const pw.TextStyle(fontSize: 7.5),
              cellAlignment: pw.Alignment.centerLeft,
              cellPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 6),
            ),
          ];
        },
      ),
    );

    final pdfBytes = await pdf.save();

    // Direct file save to Downloads
    String savedPath = "";
    bool saveSuccess = false;

    try {
      Directory? outputDir;
      if (Platform.isAndroid) {
        final downloadsDir = Directory('/storage/emulated/0/Download');
        if (await downloadsDir.exists()) {
          outputDir = downloadsDir;
        } else {
          outputDir = await getExternalStorageDirectory();
        }
      } else if (Platform.isIOS || Platform.isMacOS) {
        outputDir = await getApplicationDocumentsDirectory();
      } else {
        outputDir = await getDownloadsDirectory() ?? await getApplicationDocumentsDirectory();
      }

      if (outputDir != null) {
        final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
        final fileName = 'DocTime_Report_$timestamp.pdf';
        final file = File('${outputDir.path}/$fileName');
        await file.writeAsBytes(pdfBytes);
        savedPath = file.path;
        saveSuccess = true;
      }
    } catch (e) {
      debugPrint("PDF Save Error: $e");
    }

    try {
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final fileName = 'DocTime_Report_$timestamp.pdf';
      await Printing.sharePdf(bytes: pdfBytes, filename: fileName);
    } catch (e) {
      debugPrint("Printing plugin share missing or unhandled: $e");
    }
    if (!mounted) return;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: isDark ? const Color(0xFF334155) : Colors.transparent),
        ),
        title: Row(
          children: [
            const Icon(Icons.picture_as_pdf_rounded, color: Color(0xFFDC2626), size: 30),
            const SizedBox(width: 10),
            Text(
              'PDF Downloaded',
              style: TextStyle(
                color: isDark ? Colors.white : const Color(0xFF0F172A),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Successfully generated and downloaded PDF report for ${records.length} records!',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 12),
            if (saveSuccess) ...[
              Text(
                'Saved PDF Location:',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? const Color(0xFF94A3B8) : Colors.black54,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
                ),
                child: SelectableText(
                  savedPath,
                  style: TextStyle(
                    fontSize: 11,
                    fontFamily: 'monospace',
                    color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF1E293B),
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],
            Text(
              'The .pdf document is saved directly to your device storage and opened in the system viewer.',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? const Color(0xFF94A3B8) : Colors.black54,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'OK',
              style: TextStyle(
                color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0EA5E9),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showPrintPreviewModal(
    String reportTitle,
    Map<String, String> summaryMetrics,
    List<Map<String, dynamic>> records,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.88,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F172A) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            // Modal Bar
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF334155) : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  const Icon(Icons.print_rounded, color: Color(0xFF2563EB), size: 26),
                  const SizedBox(width: 10),
                  Text(
                    'Print / PDF Summary',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.grey.shade900),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: Icon(Icons.close_rounded, color: isDark ? Colors.white : Colors.black87),
                    onPressed: () => Navigator.pop(ctx),
                  )
                ],
              ),
            ),
            Divider(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Official Document Header
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'DOC TIME ADMIN REPORT',
                                  style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  reportTitle,
                                  style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now()),
                                style: const TextStyle(color: Colors.white70, fontSize: 11),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Filter: $_selectedDateFilter',
                                style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 11, fontWeight: FontWeight.w600),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Executive Metrics',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: summaryMetrics.entries.map((e) {
                        return Container(
                          width: (MediaQuery.of(context).size.width - 64) / 2,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(e.key, style: TextStyle(fontSize: 12, color: isDark ? const Color(0xFF94A3B8) : Colors.grey.shade600)),
                              const SizedBox(height: 4),
                              Text(e.value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF0F172A))),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Detailed Records',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87),
                        ),
                        Text(
                          'Total Records: ${records.length}',
                          style: TextStyle(fontSize: 12, color: isDark ? const Color(0xFF94A3B8) : Colors.grey.shade600, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (records.isNotEmpty)
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          headingRowColor: WidgetStateProperty.all(isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
                          columns: records.first.keys.map((k) => DataColumn(label: Text(k, style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)))).toList(),
                          rows: records.take(50).map((r) {
                            return DataRow(
                              cells: r.values.map((v) => DataCell(Text(v.toString(), style: TextStyle(color: isDark ? Colors.white70 : Colors.black87)))).toList(),
                            );
                          }).toList(),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () {
                  _exportPDF(records, summaryMetrics);
                },
                icon: const Icon(Icons.picture_as_pdf_rounded),
                label: const Text('Export PDF Document'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _dropdownDeco(String label, IconData icon, Color primaryColor, bool isDark) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(
        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
        fontSize: 13,
        fontWeight: FontWeight.w600,
      ),
      floatingLabelStyle: TextStyle(
        color: isDark ? const Color(0xFF38BDF8) : primaryColor,
        fontSize: 13,
        fontWeight: FontWeight.bold,
      ),
      filled: true,
      fillColor: isDark ? const Color(0xFF0F172A) : Colors.white,
      prefixIcon: Icon(icon, color: isDark ? const Color(0xFF818CF8) : primaryColor, size: 20),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : Colors.grey.shade200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: isDark ? const Color(0xFF38BDF8) : primaryColor, width: 1.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bodyContent = StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('appointments').snapshots(),
      builder: (context, apptSnap) {
        final apptDocs = apptSnap.data?.docs ?? [];

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('patients').snapshots(),
          builder: (context, patientSnap) {
            final patientDocs = patientSnap.data?.docs ?? [];

            return StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('doctors').snapshots(),
              builder: (context, doctorSnap) {
                final doctorDocs = doctorSnap.data?.docs ?? [];

                return StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('hospital').snapshots(),
                  builder: (context, hospitalSnap) {
                    final hospitalDocs = hospitalSnap.data?.docs ?? [];
                    return _buildReportBody(
                      apptDocs,
                      patientDocs,
                      doctorDocs,
                      hospitalDocs,
                      isDark,
                    );
                  },
                );
              },
            );
          },
        );
      },
    );

    if (widget.isEmbedded) {
      return bodyContent;
    }

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          "Admin Report Generator",
          style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
        elevation: 0.5,
        iconTheme: IconThemeData(color: isDark ? Colors.white : Colors.black87),
        actions: [
          IconButton(
            icon: const Icon(Icons.date_range_rounded, color: Color(0xFF2563EB)),
            tooltip: "Custom Date Range",
            onPressed: _selectCustomDateRange,
          ),
        ],
      ),
      body: bodyContent,
    );
  }

  Widget _buildReportBody(
    List<DocumentSnapshot> apptDocs,
    List<DocumentSnapshot> patientDocs,
    List<DocumentSnapshot> doctorDocs,
    List<DocumentSnapshot> hospitalDocs,
    bool isDark,
  ) {
    // 1. Filter appointments by date range, specialization, and status
    final filteredAppts = apptDocs.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final date = _extractDateFromDoc(data);
      if (date != null && !_isDateInRange(date)) return false;

      if (_selectedSpecialization != 'All') {
        final spec = (data['specialization'] ?? '').toString().toLowerCase();
        if (!spec.contains(_selectedSpecialization.toLowerCase())) return false;
      }

      if (_selectedStatus != 'All') {
        final st = (data['status'] ?? '').toString().toLowerCase();
        final selSt = _selectedStatus.toLowerCase();
        if (!st.contains(selSt) && !selSt.contains(st)) return false;
      }

      return true;
    }).toList();

    // Calculate aggregated metrics
    double totalRevenue = 0;
    double doctorEarnings = 0;
    double hospitalEarnings = 0;
    int completedCount = 0;
    int confirmedCount = 0;
    int pendingCount = 0;
    int cancelledCount = 0;

    List<Map<String, dynamic>> recordsForExport = [];

    for (var doc in filteredAppts) {
      final data = doc.data() as Map<String, dynamic>;
      final status = (data['status'] ?? 'Pending').toString().toLowerCase();

      double fee = _extractFee(data['consultationFee'] ?? data['amount'] ?? data['fee'] ?? data['doctorFee']);
      double hCharge = _extractFee(data['hospitalCharges'] ?? data['hospitalFee'] ?? data['facilityCharge']);

      double itemTotal = fee + hCharge;
      totalRevenue += itemTotal;
      doctorEarnings += fee;
      hospitalEarnings += hCharge;

      if (status.contains('completed')) {
        completedCount++;
      } else if (status.contains('confirm') || status.contains('book')) {
        confirmedCount++;
      } else if (status.contains('cancel')) {
        cancelledCount++;
      } else {
        pendingCount++;
      }

      final apptDate = _extractDateFromDoc(data);
      final dateFormatted = apptDate != null
          ? DateFormat('yyyy-MM-dd').format(apptDate)
          : (data['date'] ?? '').toString();

      recordsForExport.add({
        'Booking ID': data['bookingNo'] ?? 'DOC-${doc.id.substring(0, doc.id.length >= 6 ? 6 : doc.id.length).toUpperCase()}',
        'Date': dateFormatted,
        'Patient Name': data['patientName'] ?? 'N/A',
        'Doctor Name': data['doctorName'] ?? 'N/A',
        'Specialization': data['specialization'] ?? 'N/A',
        'Hospital': data['hospital'] ?? data['hospitalName'] ?? 'N/A',
        'Consultation Fee': _formatCurrency(fee),
        'Hospital Fee': _formatCurrency(hCharge),
        'Total Amount': _formatCurrency(itemTotal),
        'Status': (data['status'] ?? 'Pending').toString().toUpperCase(),
      });
    }

    final double completionRate = filteredAppts.isNotEmpty
        ? (completedCount / filteredAppts.length) * 100
        : 0;

    final summaryMetricsMap = <String, String>{
      'Total Revenue': _formatCurrency(totalRevenue),
      'Doctor Payouts': _formatCurrency(doctorEarnings),
      'Hospital Charges': _formatCurrency(hospitalEarnings),
      'Total Bookings': filteredAppts.length.toString(),
      'Completion Rate': '${completionRate.toStringAsFixed(1)}%',
      'Active Patients': patientDocs.length.toString(),
      'Registered Doctors': doctorDocs.length.toString(),
      'Active Hospitals': hospitalDocs.length.toString(),
    };

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9)),
              boxShadow: [
                BoxShadow(
                  color: Colors.blueGrey.withValues(alpha: isDark ? 0.2 : 0.06),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                )
              ],
            ),
            child: LayoutBuilder(
              builder: (context, configConstraints) {
                final isNarrowConfig = configConstraints.maxWidth < 420;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF4F46E5).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.tune_rounded, color: Color(0xFF4F46E5), size: 18),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          "Report Configuration Filters",
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF0F172A)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    DropdownButtonFormField<String>(
                      isExpanded: true,
                      initialValue: _selectedReportType,
                      dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                      style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                      decoration: _dropdownDeco("Report Category", Icons.assessment_rounded, const Color(0xFF4F46E5), isDark),
                      items: _reportTypes
                          .map((t) => DropdownMenuItem(
                                value: t,
                                child: Text(t, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isDark ? Colors.white : Colors.black87), overflow: TextOverflow.ellipsis),
                              ))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedReportType = val);
                      },
                    ),
                    const SizedBox(height: 14),
                    if (isNarrowConfig) ...[
                      DropdownButtonFormField<String>(
                        isExpanded: true,
                        initialValue: _selectedDateFilter,
                        dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                        style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                        decoration: _dropdownDeco("Timeframe", Icons.date_range_rounded, const Color(0xFF0EA5E9), isDark),
                        items: _dateFilterPresets
                            .map((p) => DropdownMenuItem(
                                  value: p,
                                  child: Text(p, style: TextStyle(fontSize: 12.5, color: isDark ? Colors.white : Colors.black87), overflow: TextOverflow.ellipsis),
                                ))
                            .toList(),
                        onChanged: (val) {
                          if (val == 'Custom Range') {
                            _selectCustomDateRange();
                          } else if (val == 'Select Month') {
                            _selectMonthForReport();
                          } else if (val != null) {
                            setState(() => _selectedDateFilter = val);
                          }
                        },
                      ),
                      const SizedBox(height: 14),
                      DropdownButtonFormField<String>(
                        isExpanded: true,
                        initialValue: _selectedStatus,
                        dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                        style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                        decoration: _dropdownDeco("Status", Icons.filter_alt_rounded, const Color(0xFF8B5CF6), isDark),
                        items: _statuses
                            .map((s) => DropdownMenuItem(
                                  value: s,
                                  child: Text(s, style: TextStyle(fontSize: 12.5, color: isDark ? Colors.white : Colors.black87), overflow: TextOverflow.ellipsis),
                                ))
                            .toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedStatus = val);
                        },
                      ),
                    ] else ...[
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              isExpanded: true,
                              initialValue: _selectedDateFilter,
                              dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                              style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                              decoration: _dropdownDeco("Timeframe", Icons.date_range_rounded, const Color(0xFF0EA5E9), isDark),
                              items: _dateFilterPresets
                                  .map((p) => DropdownMenuItem(
                                        value: p,
                                        child: Text(p, style: TextStyle(fontSize: 12.5, color: isDark ? Colors.white : Colors.black87), overflow: TextOverflow.ellipsis),
                                      ))
                                  .toList(),
                              onChanged: (val) {
                                if (val == 'Custom Range') {
                                  _selectCustomDateRange();
                                } else if (val == 'Select Month') {
                                  _selectMonthForReport();
                                } else if (val != null) {
                                  setState(() => _selectedDateFilter = val);
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              isExpanded: true,
                              initialValue: _selectedStatus,
                              dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                              style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                              decoration: _dropdownDeco("Status", Icons.filter_alt_rounded, const Color(0xFF8B5CF6), isDark),
                              items: _statuses
                                  .map((s) => DropdownMenuItem(
                                        value: s,
                                        child: Text(s, style: TextStyle(fontSize: 12.5, color: isDark ? Colors.white : Colors.black87), overflow: TextOverflow.ellipsis),
                                      ))
                                  .toList(),
                              onChanged: (val) {
                                if (val != null) setState(() => _selectedStatus = val);
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      isExpanded: true,
                      initialValue: _selectedSpecialization,
                      dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                      style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                      decoration: _dropdownDeco("Specialization / Department", Icons.medical_services_rounded, const Color(0xFF10B981), isDark),
                      items: _specializations
                          .map((sp) => DropdownMenuItem(
                                value: sp,
                                child: Text(sp, style: TextStyle(fontSize: 13, color: isDark ? Colors.white : Colors.black87), overflow: TextOverflow.ellipsis),
                              ))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedSpecialization = val);
                      },
                    ),
                    if (_selectedDateFilter == 'Select Month') ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF4F46E5).withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFF4F46E5).withValues(alpha: 0.2)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.calendar_month_rounded, size: 18, color: Color(0xFF4F46E5)),
                                const SizedBox(width: 8),
                                Text(
                                  "Report Month: ${DateFormat('MMMM yyyy').format(_selectedReportMonth)}",
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF4F46E5)),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.chevron_left_rounded, size: 20, color: Color(0xFF4F46E5)),
                                  onPressed: () {
                                    setState(() {
                                      _selectedReportMonth = DateTime(_selectedReportMonth.year, _selectedReportMonth.month - 1);
                                    });
                                  },
                                  tooltip: "Previous Month",
                                  constraints: const BoxConstraints(),
                                  padding: const EdgeInsets.all(4),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.chevron_right_rounded, size: 20, color: Color(0xFF4F46E5)),
                                  onPressed: () {
                                    setState(() {
                                      _selectedReportMonth = DateTime(_selectedReportMonth.year, _selectedReportMonth.month + 1);
                                    });
                                  },
                                  tooltip: "Next Month",
                                  constraints: const BoxConstraints(),
                                  padding: const EdgeInsets.all(4),
                                ),
                                InkWell(
                                  onTap: _selectMonthForReport,
                                  borderRadius: BorderRadius.circular(8),
                                  child: const Padding(
                                    padding: EdgeInsets.all(4.0),
                                    child: Icon(Icons.edit_calendar_rounded, size: 18, color: Color(0xFF4F46E5)),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                    if (_selectedDateFilter == 'Custom Range' && _customDateRange != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF4F46E5).withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFF4F46E5).withValues(alpha: 0.2)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Custom Range: ${DateFormat('MMM d, yyyy').format(_customDateRange!.start)} - ${DateFormat('MMM d, yyyy').format(_customDateRange!.end)}",
                              style: const TextStyle(color: Color(0xFF4F46E5), fontSize: 13, fontWeight: FontWeight.bold),
                            ),
                            InkWell(
                              onTap: _selectCustomDateRange,
                              child: const Text("Edit", style: TextStyle(color: Color(0xFF4F46E5), fontWeight: FontWeight.bold)),
                            )
                          ],
                        ),
                      ),
                    ],
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 20),

          // Action Toolbar (Print / PDF Export Buttons)
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF4F46E5), Color(0xFF6366F1)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF6366F1).withValues(alpha: 0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: () => _showPrintPreviewModal(_selectedReportType, summaryMetricsMap, recordsForExport),
                    icon: const Icon(Icons.print_rounded, size: 18, color: Colors.white),
                    label: const Text("Print / PDF Summary", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white)),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFF43F5E), Color(0xFFE11D48)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFE11D48).withValues(alpha: 0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: () => _exportPDF(recordsForExport, summaryMetricsMap),
                    icon: const Icon(Icons.picture_as_pdf_rounded, color: Colors.white, size: 18),
                    label: const Text("Export PDF Report", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Vibrant KPI Metric Cards Header Grid
          GridView.count(
            crossAxisCount: MediaQuery.of(context).size.width > 600 ? 4 : 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            childAspectRatio: MediaQuery.of(context).size.width > 600 ? 1.5 : 1.3,
            children: [
              _buildKPICard(
                title: "Total Revenue",
                value: _formatCurrency(totalRevenue),
                icon: Icons.payments_rounded,
                gradientColors: [const Color(0xFF059669), const Color(0xFF10B981)],
              ),
              _buildKPICard(
                title: "Total Appointments",
                value: filteredAppts.length.toString(),
                icon: Icons.calendar_month_rounded,
                gradientColors: [const Color(0xFF2563EB), const Color(0xFF3B82F6)],
              ),
              _buildKPICard(
                title: "Completion Rate",
                value: "${completionRate.toStringAsFixed(1)}%",
                icon: Icons.task_alt_rounded,
                gradientColors: [const Color(0xFF7C3AED), const Color(0xFF8B5CF6)],
              ),
              _buildKPICard(
                title: "Doctor Share",
                value: _formatCurrency(doctorEarnings),
                icon: Icons.medical_services_rounded,
                gradientColors: [const Color(0xFFD97706), const Color(0xFFF59E0B)],
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Report Content Specific Views
          _buildReportDetailContent(
            filteredAppts: filteredAppts,
            patientDocs: patientDocs,
            doctorDocs: doctorDocs,
            hospitalDocs: hospitalDocs,
            completedCount: completedCount,
            confirmedCount: confirmedCount,
            pendingCount: pendingCount,
            cancelledCount: cancelledCount,
            totalRevenue: totalRevenue,
            doctorEarnings: doctorEarnings,
            hospitalEarnings: hospitalEarnings,
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildKPICard({
    required String title,
    required String value,
    required IconData icon,
    required List<Color> gradientColors,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: gradientColors.first.withValues(alpha: 0.3),
            blurRadius: 14,
            offset: const Offset(0, 6),
          )
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Stack(
          children: [
            Positioned(
              right: -10,
              bottom: -10,
              child: Icon(
                icon,
                size: 76,
                color: Colors.white.withValues(alpha: 0.15),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.22),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(icon, color: Colors.white, size: 15),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            title,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.92),
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      value,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportDetailContent({
    required List<DocumentSnapshot> filteredAppts,
    required List<DocumentSnapshot> patientDocs,
    required List<DocumentSnapshot> doctorDocs,
    required List<DocumentSnapshot> hospitalDocs,
    required int completedCount,
    required int confirmedCount,
    required int pendingCount,
    required int cancelledCount,
    required double totalRevenue,
    required double doctorEarnings,
    required double hospitalEarnings,
    required bool isDark,
  }) {
    if (_selectedReportType == 'Appointments & Bookings') {
      return _buildAppointmentDistributionSection(
        completedCount: completedCount,
        confirmedCount: confirmedCount,
        pendingCount: pendingCount,
        cancelledCount: cancelledCount,
        total: filteredAppts.length,
        isDark: isDark,
      );
    } else if (_selectedReportType == 'Financial & Revenue') {
      return _buildFinancialBreakdownSection(
        totalRevenue: totalRevenue,
        doctorEarnings: doctorEarnings,
        hospitalEarnings: hospitalEarnings,
        isDark: isDark,
      );
    } else if (_selectedReportType == 'Doctor & Hospital Performance') {
      return _buildPerformanceSection(doctorDocs, hospitalDocs, filteredAppts, isDark);
    } else if (_selectedReportType == 'Patient Demographics') {
      return _buildDemographicsSection(patientDocs, isDark);
    }

    // Default: Executive Summary Table & Breakdown
    return _buildExecutiveSummarySection(filteredAppts, isDark);
  }

  Widget _buildExecutiveSummarySection(List<DocumentSnapshot> apptDocs, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04), blurRadius: 16, offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Recent Matching Transactions",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87),
                ),
                Text(
                  "${apptDocs.length} Total",
                  style: const TextStyle(fontSize: 13, color: Color(0xFF2563EB), fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
          if (apptDocs.isEmpty)
            Padding(
              padding: const EdgeInsets.all(32),
              child: Center(
                child: Text(
                  "No records match the selected date range and filter.",
                  style: TextStyle(color: isDark ? const Color(0xFF94A3B8) : Colors.black54),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: apptDocs.length > 15 ? 15 : apptDocs.length,
              separatorBuilder: (_, __) => Divider(height: 1, color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
              itemBuilder: (context, index) {
                final data = apptDocs[index].data() as Map<String, dynamic>;
                final patientName = data['patientName'] ?? 'Patient';
                final doctorName = data['doctorName'] ?? 'Doctor';
                final status = (data['status'] ?? 'Pending').toString();
                final double fee = _extractFee(data['consultationFee'] ?? data['amount'] ?? data['fee'] ?? data['doctorFee']);
                final double hCharge = _extractFee(data['hospitalCharges'] ?? data['hospitalFee'] ?? data['facilityCharge']);
                final double total = fee + hCharge;

                Color statusColor = Colors.orange;
                if (status.toLowerCase().contains('completed')) {
                  statusColor = Colors.green;
                } else if (status.toLowerCase().contains('confirm')) {
                  statusColor = Colors.blue;
                } else if (status.toLowerCase().contains('cancel')) {
                  statusColor = Colors.red;
                }

                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                  leading: CircleAvatar(
                    backgroundColor: statusColor.withValues(alpha: 0.12),
                    child: Icon(Icons.receipt_long_rounded, color: statusColor, size: 20),
                  ),
                  title: Text(patientName, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: isDark ? Colors.white : Colors.black87)),
                  subtitle: Text("Dr. $doctorName • ${data['date'] ?? ''}", style: TextStyle(fontSize: 12, color: isDark ? const Color(0xFF94A3B8) : Colors.grey.shade600)),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(_formatCurrency(total), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: isDark ? Colors.white : Colors.black87)),
                      const SizedBox(height: 2),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          status.toUpperCase(),
                          style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildAppointmentDistributionSection({
    required int completedCount,
    required int confirmedCount,
    required int pendingCount,
    required int cancelledCount,
    required int total,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04), blurRadius: 16, offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Booking Status Breakdown",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87),
          ),
          const SizedBox(height: 20),
          _buildProgressBarItem("Completed", completedCount, total, Colors.green, isDark),
          const SizedBox(height: 14),
          _buildProgressBarItem("Confirmed", confirmedCount, total, Colors.blue, isDark),
          const SizedBox(height: 14),
          _buildProgressBarItem("Pending Approval", pendingCount, total, Colors.amber, isDark),
          const SizedBox(height: 14),
          _buildProgressBarItem("Cancelled", cancelledCount, total, Colors.red, isDark),
        ],
      ),
    );
  }

  Widget _buildProgressBarItem(String label, int count, int total, Color color, bool isDark) {
    final double pct = total > 0 ? (count / total) : 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: isDark ? Colors.white70 : Colors.black87)),
            Text("$count (${(pct * 100).toStringAsFixed(1)}%)", style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 13)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: pct,
            minHeight: 10,
            backgroundColor: color.withValues(alpha: 0.12),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }

  Widget _buildFinancialBreakdownSection({
    required double totalRevenue,
    required double doctorEarnings,
    required double hospitalEarnings,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04), blurRadius: 16, offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Revenue Allocation Summary",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87),
          ),
          const SizedBox(height: 20),
          _buildFinancialRow("Gross Platform Revenue", totalRevenue, Colors.indigo, isDark),
          Divider(height: 24, color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
          _buildFinancialRow("Doctor Professional Fees", doctorEarnings, Colors.blue, isDark),
          const SizedBox(height: 12),
          _buildFinancialRow("Hospital Facility Charges", hospitalEarnings, const Color(0xFF10B981), isDark),
        ],
      ),
    );
  }

  Widget _buildFinancialRow(String title, double amount, Color color, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
            const SizedBox(width: 10),
            Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: isDark ? Colors.white : Colors.black87)),
          ],
        ),
        Text(_formatCurrency(amount), style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }

  Widget _buildPerformanceSection(
    List<DocumentSnapshot> doctors,
    List<DocumentSnapshot> hospitals,
    List<DocumentSnapshot> appts,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04), blurRadius: 16, offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Provider Performance & Capacity",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87),
          ),
          const SizedBox(height: 16),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const CircleAvatar(backgroundColor: Color(0xFFEFF6FF), child: Icon(Icons.badge_rounded, color: Color(0xFF2563EB))),
            title: Text("Total Registered Doctors", style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
            trailing: Text("${doctors.length} Doctors", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF2563EB))),
          ),
          Divider(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const CircleAvatar(backgroundColor: Color(0xFFECFDF5), child: Icon(Icons.local_hospital_rounded, color: Color(0xFF10B981))),
            title: Text("Partner Hospitals", style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
            trailing: Text("${hospitals.length} Facilities", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF10B981))),
          ),
        ],
      ),
    );
  }

  Widget _buildDemographicsSection(List<DocumentSnapshot> patients, bool isDark) {
    int male = 0;
    int female = 0;
    int other = 0;

    for (var p in patients) {
      final g = (p['gender'] ?? '').toString().toLowerCase();
      if (g.contains('male') && !g.contains('female')) {
        male++;
      } else if (g.contains('female')) {
        female++;
      } else {
        other++;
      }
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04), blurRadius: 16, offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Patient Gender Distribution",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87),
          ),
          const SizedBox(height: 20),
          _buildProgressBarItem("Male Patients", male, patients.length, Colors.blue, isDark),
          const SizedBox(height: 14),
          _buildProgressBarItem("Female Patients", female, patients.length, Colors.pink, isDark),
          const SizedBox(height: 14),
          _buildProgressBarItem("Other / Not Specified", other, patients.length, Colors.grey, isDark),
        ],
      ),
    );
  }
}
