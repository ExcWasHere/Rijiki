import 'package:flutter/foundation.dart';

@immutable
class WorkerInput {
  const WorkerInput({
    required this.fullName,
    required this.email,
    required this.phoneNumber,
    required this.employeeCode,
    required this.division,
    required this.joinDate,
    this.password,
  });

  final String fullName;
  final String email;
  final String phoneNumber;
  final String employeeCode;
  final String division;
  final DateTime joinDate;
  final String? password;
}
