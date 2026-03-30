import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../providers/health_data_provider.dart';
import '../models/health_log.dart';
import '../providers/patient_provider.dart';
import '../utils/pdf_generator.dart';

// A simple helper class to bundle the log with its category name
class ActivityItem {
  final String category;
  final HealthLog log;

  ActivityItem({required this.category, required this.log});
}

class ActivityLogScreen extends StatefulWidget {
  const ActivityLogScreen({super.key});

  @override
  State<ActivityLogScreen> createState() => _ActivityLogScreenState();
}

class _ActivityLogScreenState extends State<ActivityLogScreen> {
  String _selectedFilter = 'All';

  final List<String> _filters = [
    'All',
    'Temperature',
    'Platelets',
    'Fluid Intake',
    'Urine Output',
    'Blood Pressure',
    'Symptoms'
  ];

  // Group the logs by their formatted date string (e.g., "TODAY, APRIL 24")
  Map<String, List<ActivityItem>> _groupLogsByDate(List<ActivityItem> logs) {
    final Map<String, List<ActivityItem>> grouped = {};
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    for (var item in logs) {
      final logDate = DateTime(item.log.timestamp.year,
          item.log.timestamp.month, item.log.timestamp.day);

      String dateLabel;
      if (logDate == today) {
        dateLabel =
            'TODAY, ${DateFormat('MMMM d').format(item.log.timestamp).toUpperCase()}';
      } else if (logDate == yesterday) {
        dateLabel =
            'YESTERDAY, ${DateFormat('MMMM d').format(item.log.timestamp).toUpperCase()}';
      } else {
        dateLabel =
            DateFormat('EEEE, MMMM d').format(item.log.timestamp).toUpperCase();
      }

      if (!grouped.containsKey(dateLabel)) {
        grouped[dateLabel] = [];
      }
      grouped[dateLabel]!.add(item);
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<HealthDataProvider>();

    // 1. Gather ALL logs from the provider
    List<ActivityItem> allLogs = [];
    final categories = [
      'Temperature',
      'Platelets',
      'Fluid Intake',
      'Urine Output',
      'Blood Pressure',
      'Symptoms'
    ];

    for (String category in categories) {
      final logs = provider.getLogsByType(category);
      for (var log in logs) {
        allLogs.add(ActivityItem(category: category, log: log));
      }
    }

    // 2. Sort all logs by newest first
    allLogs.sort((a, b) => b.log.timestamp.compareTo(a.log.timestamp));

    // 3. Apply the selected tab filter
    if (_selectedFilter != 'All') {
      allLogs =
          allLogs.where((item) => item.category == _selectedFilter).toList();
    }

    // 4. Group them by Date
    final groupedLogs = _groupLogsByDate(allLogs);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF0F172A)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Activity Log',
          style: GoogleFonts.nunito(
              color: const Color(0xFF0F172A),
              fontSize: 18,
              fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF2DD4BF), Color(0xFF0E7490)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(Icons.picture_as_pdf,
                  color: Colors.white, size: 20),
              onPressed: () async {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Row(
                      children: [
                        CircularProgressIndicator(color: Colors.white),
                        SizedBox(width: 16),
                        Text('Generating Medical Report...'),
                      ],
                    ),
                    backgroundColor: Color(0xFF0E7490),
                    duration: Duration(seconds: 2),
                  ),
                );

                final patientProvider = context.read<PatientProvider>();
                final healthProvider = context.read<HealthDataProvider>();
                final activePatient = patientProvider.activePatient;

                if (activePatient != null) {
                  Map<String, List<double>> chartData = {};

                  if (_selectedFilter == 'All') {
                    chartData['Temperature'] =
                        healthProvider.getChartData('Temperature');
                    chartData['Platelets'] =
                        healthProvider.getChartData('Platelets');
                    chartData['Fluid Intake'] =
                        healthProvider.getChartData('Fluid Intake');
                    chartData['Urine Output'] =
                        healthProvider.getChartData('Urine Output');
                  } else if (_selectedFilter != 'Symptoms') {
                    chartData[_selectedFilter] =
                        healthProvider.getChartData(_selectedFilter);
                  }

                  await PdfGenerator.generateAndShareReport(
                    patient: activePatient,
                    filter: _selectedFilter,
                    logs: allLogs,
                    chartData: chartData,
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Error: No active patient found.'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
            ),
          )
        ],
      ),
      // THE FIX: The body is now a Column containing the scrolling tabs and the list!
      body: Column(
        children: [
          _buildFilterTabs(),
          Expanded(
            child: allLogs.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.history_toggle_off,
                            size: 64, color: Colors.grey.shade300),
                        const SizedBox(height: 16),
                        Text('No activity recorded yet.',
                            style: GoogleFonts.nunito(
                                fontSize: 16, color: Colors.blueGrey)),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 24),
                    itemCount: groupedLogs.keys.length,
                    itemBuilder: (context, index) {
                      String dateKey = groupedLogs.keys.elementAt(index);
                      List<ActivityItem> dailyLogs = groupedLogs[dateKey]!;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildDateHeader(dateKey),
                          ...dailyLogs.map((item) => _buildLogCard(item)),
                          const SizedBox(height: 16),
                        ],
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  // --- FIXED: SCROLLING TABS ---
  Widget _buildFilterTabs() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min, // Essential for scrolling
          children: _filters.map((tab) {
            final bool isActive = tab == _selectedFilter;
            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedFilter = tab;
                });
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: isActive
                          ? const Color(0xFF14B8A6)
                          : Colors.transparent,
                      width: 3,
                    ),
                  ),
                ),
                child: Text(
                  tab,
                  style: GoogleFonts.nunito(
                    fontSize: 14,
                    fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
                    color: isActive
                        ? const Color(0xFF0D9488)
                        : const Color(0xFF64748B),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildDateHeader(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        text,
        style: GoogleFonts.nunito(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: const Color(0xFF64748B),
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildLogCard(ActivityItem item) {
    final log = item.log;
    final timeStr = DateFormat('hh:mm a').format(log.timestamp);

    // Determine UI elements based on category
    IconData icon;
    Color iconColor;
    Color iconBgColor;
    String titleValue = '';

    switch (item.category) {
      case 'Temperature':
        icon = Icons.thermostat;
        iconColor = const Color(0xFFF97316);
        iconBgColor = const Color(0xFFFFF7ED);
        titleValue = '${log.value1}°F';
        break;
      case 'Urine Output':
        icon = Icons.water_drop;
        iconColor = const Color(0xFFEAB308);
        iconBgColor = const Color(0xFFFEFCE8);
        titleValue = '${log.value1?.toInt()} ml';
        break;
      case 'Fluid Intake':
        icon = Icons.local_drink;
        iconColor = const Color(0xFF06B6D4);
        iconBgColor = const Color(0xFFECFEFF);
        titleValue = '${log.value1} L';
        break;
      case 'Platelets':
        icon = Icons.bloodtype;
        iconColor = const Color(0xFFEF4444);
        iconBgColor = const Color(0xFFFEF2F2);
        titleValue = '${log.value1?.toInt()}';
        break;
      case 'Blood Pressure':
        icon = Icons.favorite;
        iconColor = const Color(0xFF8B5CF6);
        iconBgColor = const Color(0xFFF5F3FF);
        titleValue = '${log.value1?.toInt()}/${log.value2?.toInt()} mmHg';
        break;
      case 'Symptoms':
        icon = Icons.sick;
        iconColor = const Color(0xFF3B82F6);
        iconBgColor = const Color(0xFFEFF6FF);
        titleValue = '${log.value1?.toInt() ?? 0} Symptoms Logged';
        break;
      default:
        icon = Icons.info_outline;
        iconColor = Colors.grey;
        iconBgColor = Colors.grey.shade100;
        titleValue = '${log.value1}';
    }

    // Determine status color automatically
    Color statusColor = const Color(0xFF64748B); // Default grey
    if (log.status.contains('HIGH') ||
        log.status.contains('LOW') ||
        log.status == 'EVALUATE' ||
        log.status == 'ELEVATED') {
      statusColor = const Color(0xFFEF4444); // Red for alerts
    } else if (log.status == 'STABLE' ||
        log.status == 'NORMAL' ||
        log.status == 'ON TRACK') {
      statusColor = const Color(0xFF0D9488); // Green/Teal for good
    } else if (log.status == 'MONITOR') {
      statusColor = const Color(0xFFF59E0B); // Orange for warning
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: iconColor.withOpacity(0.2)),
                ),
                child: Icon(icon, color: iconColor, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          titleValue,
                          style: GoogleFonts.nunito(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: const Color(0xFF0F172A)),
                        ),
                        Text(
                          timeStr,
                          style: GoogleFonts.nunito(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF94A3B8)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          item.category,
                          style: GoogleFonts.nunito(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF64748B)),
                        ),
                        if (log.status.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Container(
                              width: 4,
                              height: 4,
                              decoration: const BoxDecoration(
                                  color: Color(0xFFCBD5E1),
                                  shape: BoxShape.circle)),
                          const SizedBox(width: 8),
                          Text(
                            log.status,
                            style: GoogleFonts.nunito(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: statusColor,
                            ),
                          ),
                        ]
                      ],
                    )
                  ],
                ),
              )
            ],
          ),

          // Show Notes if they exist!
          if (log.notes.isNotEmpty ||
              log.hasVoiceNote ||
              (log.symptoms != null && log.symptoms!.isNotEmpty)) ...[
            const Padding(
              padding: EdgeInsets.only(top: 12, bottom: 8),
              child: Divider(height: 1, color: Color(0xFFF1F5F9)),
            ),
            if (log.symptoms != null && log.symptoms!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: log.symptoms!
                      .map((sym) => Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(8),
                              border:
                                  Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: Text(sym,
                                style: GoogleFonts.nunito(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF475569))),
                          ))
                      .toList(),
                ),
              ),
            if (log.notes.isNotEmpty)
              Text(
                'Note: "${log.notes}"',
                style: GoogleFonts.nunito(
                  fontSize: 13,
                  color: const Color(0xFF475569),
                  fontStyle: FontStyle.italic,
                ),
              ),
            if (log.hasVoiceNote)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  children: [
                    const Icon(Icons.mic, size: 14, color: Color(0xFF14B8A6)),
                    const SizedBox(width: 4),
                    Text('Voice note attached',
                        style: GoogleFonts.nunito(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF14B8A6))),
                  ],
                ),
              ),
          ]
        ],
      ),
    );
  }
}
