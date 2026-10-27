import 'package:flutter/foundation.dart';

@immutable
class AssignableWorker {
  const AssignableWorker({
    required this.id,
    required this.fullName,
    required this.employeeCode,
    required this.division,
    this.avatarUrl,
  });

  final String id;
  final String fullName;
  final String employeeCode;
  final String division;
  final String? avatarUrl;
}
