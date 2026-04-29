import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfile {
  UserProfile({
    required this.uid,
    required this.fullName,
    required this.phone,
    required this.dob,
    required this.gender,
    required this.role,
    required this.address,
    this.createdAt,
    this.caretakerCode,
    this.linkedPatients = const [],
    this.linkedCaretakerId,
    this.weight,
    this.bloodType,
    this.hasDiabetes,
    this.preExistingConditions,
    this.allergies,
  });

  factory UserProfile.fromFirestore(Map<String, dynamic> data, String uid) {
    return UserProfile(
      uid: uid,
      fullName: data['fullName'] ?? '',
      phone: data['phone'] ?? '',
      dob: data['dob'] ?? '',
      gender: data['gender'] ?? '',
      role: data['role'] ?? 'Patient',
      address: data['address'] ?? '',
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : null,
      caretakerCode: data['caretakerCode'],
      linkedPatients: List<String>.from(data['linkedPatients'] ?? []),
      linkedCaretakerId: data['linkedCaretakerId'],
      weight: data['weight'],
      bloodType: data['bloodType'],
      hasDiabetes: data['hasDiabetes'],
      preExistingConditions: data['preExistingConditions'],
      allergies: data['allergies'],
    );
  }
  final String uid;
  final String fullName;
  final String phone;
  final String dob;
  final String gender;
  final String role;
  final String address;
  final DateTime? createdAt;

  // Caretaker Specific
  final String? caretakerCode;
  final List<String> linkedPatients;

  // Patient Specific
  final String? linkedCaretakerId;
  final String? weight;
  final String? bloodType;
  final bool? hasDiabetes;
  final String? preExistingConditions;
  final String? allergies;

  // THIS IS THE METHOD THAT WAS MISSING!
  Map<String, dynamic> toFirestore() {
    return {
      'fullName': fullName,
      'phone': phone,
      'dob': dob,
      'gender': gender,
      'role': role,
      'address': address,
      if (createdAt != null) 'createdAt': Timestamp.fromDate(createdAt!),
      if (caretakerCode != null) 'caretakerCode': caretakerCode,
      'linkedPatients': linkedPatients,
      if (linkedCaretakerId != null) 'linkedCaretakerId': linkedCaretakerId,
      if (weight != null) 'weight': weight,
      if (bloodType != null) 'bloodType': bloodType,
      if (hasDiabetes != null) 'hasDiabetes': hasDiabetes,
      if (preExistingConditions != null)
        'preExistingConditions': preExistingConditions,
      if (allergies != null) 'allergies': allergies,
    };
  }
}
