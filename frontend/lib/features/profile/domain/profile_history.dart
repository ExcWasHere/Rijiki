import 'package:flutter/foundation.dart';

/// Satu pasang sepatu pada satu order, diambil dari riwayat order customer.
@immutable
class MyShoe {
  const MyShoe({
    required this.id,
    required this.orderId,
    required this.orderNumber,
    required this.orderStatus,
    required this.quantity,
    required this.orderDate,
    this.serviceName,
    this.shoeBrand,
    this.notes,
  });

  final String id;
  final String orderId;
  final String orderNumber;
  final String orderStatus;
  final String? serviceName;
  final String? shoeBrand;
  final int quantity;
  final String? notes;
  final DateTime orderDate;

  /// Judul baris: merek sepatu, atau nama layanan bila merek tidak diisi.
  String get title {
    final brand = shoeBrand?.trim();
    if (brand != null && brand.isNotEmpty) return brand;
    return serviceName ?? 'Sepatu';
  }

  factory MyShoe.fromJson(Map<String, dynamic> json) {
    return MyShoe(
      id: json['id'] as String,
      orderId: json['order_id'] as String,
      orderNumber: json['order_number'] as String? ?? '',
      orderStatus: json['order_status'] as String? ?? '',
      serviceName: json['service_name'] as String?,
      shoeBrand: json['shoe_brand'] as String?,
      quantity: (json['quantity'] as num? ?? 1).round(),
      notes: json['notes'] as String?,
      orderDate:
          DateTime.tryParse(json['order_date'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}

@immutable
class MyShoePage {
  const MyShoePage({required this.items, required this.total});

  final List<MyShoe> items;
  final int total;
}

/// Rating yang pernah diberikan customer.
@immutable
class CustomerRating {
  const CustomerRating({
    required this.id,
    required this.orderId,
    required this.ratingValue,
    required this.isFeatured,
    required this.createdAt,
    this.orderNumber,
    this.workerName,
    this.comment,
    this.photoKey,
  });

  final String id;
  final String orderId;
  final String? orderNumber;
  final String? workerName;
  final int ratingValue;
  final String? comment;

  /// Key objek privat; dibaca lewat `GET /api/media/private/*key`.
  final String? photoKey;
  final bool isFeatured;
  final DateTime createdAt;

  factory CustomerRating.fromJson(Map<String, dynamic> json) {
    return CustomerRating(
      id: json['id'] as String,
      orderId: json['order_id'] as String,
      orderNumber: json['order_number'] as String?,
      workerName: json['worker_name'] as String?,
      ratingValue: (json['rating_value'] as num? ?? 0).round(),
      comment: json['comment'] as String?,
      photoKey: json['photo_key'] as String?,
      isFeatured: json['is_featured'] == true,
      createdAt:
          DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}

@immutable
class CustomerRatingPage {
  const CustomerRatingPage({
    required this.items,
    required this.total,
    this.average,
  });

  final List<CustomerRating> items;
  final int total;
  final double? average;
}
