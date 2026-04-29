import 'package:cloud_firestore/cloud_firestore.dart';

class DiseaseEpisode {
  DiseaseEpisode({
    required this.id,
    required this.diseaseName,
    required this.startDate,
    this.endDate,
    this.isActive = true,
  });

  factory DiseaseEpisode.fromFirestore(Map<String, dynamic> data, String id) {
    return DiseaseEpisode(
      id: id,
      diseaseName: data['diseaseName'] ?? '',
      startDate: data['startDate'] != null
          ? (data['startDate'] as Timestamp).toDate()
          : DateTime.now(),
      endDate: data['endDate'] != null
          ? (data['endDate'] as Timestamp).toDate()
          : null,
      isActive: data['isActive'] ?? false,
    );
  }
  final String id;
  final String diseaseName; // 'Dengue' or 'Leptospirosis'
  final DateTime startDate;
  final DateTime? endDate;
  final bool isActive;

  Map<String, dynamic> toFirestore() {
    return {
      'diseaseName': diseaseName,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': endDate != null ? Timestamp.fromDate(endDate!) : null,
      'isActive': isActive,
    };
  }
}
