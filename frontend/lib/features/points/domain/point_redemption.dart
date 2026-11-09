import 'package:flutter/foundation.dart';

enum RedemptionStatus {
  pending('pending', 'Menunggu'),
  approved('approved', 'Disetujui'),
  fulfilled('fulfilled', 'Sudah diserahkan'),
  rejected('rejected', 'Ditolak');

  const RedemptionStatus(this.value, this.label);

  final String value;
  final String label;

  static RedemptionStatus fromJson(String? value) {
    return RedemptionStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => RedemptionStatus.pending,
    );
  }
}

@immutable
class PointRedemption {
  const PointRedemption({
    required this.id,
    required this.customerId,
    required this.rewardName,
    required this.pointsUsed,
    required this.status,
    required this.requestedAt,
    this.customerName,
    this.customerPhone,
    this.customerBalance = 0,
    this.notes,
    this.processedAt,
    this.processedByName,
  });

  final String id;
  final String customerId;
  final String? customerName;
  final String? customerPhone;

  /// Saldo customer saat ini (bukan saat diajukan).
  final int customerBalance;
  final String rewardName;
  final int pointsUsed;
  final RedemptionStatus status;
  final String? notes;
  final DateTime requestedAt;
  final DateTime? processedAt;
  final String? processedByName;

  String get displayName {
    final name = customerName?.trim() ?? '';
    return name.isEmpty ? 'Customer' : name;
  }

  factory PointRedemption.fromJson(Map<String, dynamic> json) {
    return PointRedemption(
      id: json['id'] as String,
      customerId: json['customer_id'] as String,
      customerName: json['customer_name'] as String?,
      customerPhone: json['customer_phone'] as String?,
      customerBalance: (json['customer_balance'] as num? ?? 0).round(),
      rewardName: json['reward_name'] as String? ?? '-',
      pointsUsed: (json['points_used'] as num? ?? 0).round(),
      status: RedemptionStatus.fromJson(json['status'] as String?),
      notes: json['notes'] as String?,
      requestedAt:
          DateTime.tryParse(json['requested_at'] as String? ?? '') ??
          DateTime.now(),
      processedAt: DateTime.tryParse(json['processed_at'] as String? ?? ''),
      processedByName: json['processed_by_name'] as String?,
    );
  }

  PointRedemption copyWith({
    RedemptionStatus? status,
    String? notes,
    DateTime? processedAt,
    String? processedByName,
    int? customerBalance,
  }) {
    return PointRedemption(
      id: id,
      customerId: customerId,
      customerName: customerName,
      customerPhone: customerPhone,
      customerBalance: customerBalance ?? this.customerBalance,
      rewardName: rewardName,
      pointsUsed: pointsUsed,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      requestedAt: requestedAt,
      processedAt: processedAt ?? this.processedAt,
      processedByName: processedByName ?? this.processedByName,
    );
  }
}

@immutable
class RedemptionList {
  const RedemptionList({
    required this.items,
    required this.total,
    required this.pendingCount,
  });

  final List<PointRedemption> items;
  final int total;

  /// Jumlah pengajuan berstatus menunggu, apa pun filter yang dipakai.
  final int pendingCount;
}

@immutable
class PointCustomer {
  const PointCustomer({
    required this.id,
    required this.email,
    required this.balance,
    this.name,
    this.phone,
    this.avatarUrl,
  });

  /// `customer_profiles.id`.
  final String id;
  final String? name;
  final String email;
  final String? phone;
  final String? avatarUrl;
  final int balance;

  String get displayName {
    final value = name?.trim() ?? '';
    return value.isEmpty ? email : value;
  }

  factory PointCustomer.fromJson(Map<String, dynamic> json) {
    return PointCustomer(
      id: json['id'] as String,
      name: json['name'] as String?,
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      balance: (json['points_balance'] as num? ?? 0).round(),
    );
  }

  PointCustomer copyWith({int? balance}) {
    return PointCustomer(
      id: id,
      name: name,
      email: email,
      phone: phone,
      avatarUrl: avatarUrl,
      balance: balance ?? this.balance,
    );
  }
}
