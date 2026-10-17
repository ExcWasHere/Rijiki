import 'package:flutter/foundation.dart';

@immutable
class WorkerProfile {
  const WorkerProfile({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phoneNumber,
    required this.employeeCode,
    required this.division,
    required this.joinDate,
    this.avatarUrl,
  });

  final String id;
  final String fullName;
  final String email;
  final String phoneNumber;
  final String employeeCode;
  final String division;
  final DateTime joinDate;
  final String? avatarUrl;
}

@immutable
class WorkerSummary {
  const WorkerSummary({
    required this.profile,
    required this.ratingCount,
    this.avgRating,
  });

  final WorkerProfile profile;
  final double? avgRating;
  final int ratingCount;
}
