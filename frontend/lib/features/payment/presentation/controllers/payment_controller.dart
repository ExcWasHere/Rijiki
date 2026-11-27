import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rijiki/app/providers.dart';
import 'package:rijiki/core/enums/payment_status.dart';
import 'package:rijiki/core/error/failure.dart';
import 'package:rijiki/features/order/presentation/controllers/order_detail_controller.dart';
import 'package:rijiki/features/order/presentation/controllers/order_list_controller.dart';
import 'package:rijiki/features/order/presentation/controllers/staff_order_controller.dart';
import 'package:rijiki/features/payment/domain/payment.dart';

enum PaymentPhase { creating, pending, paid, failed, expired, error }

@immutable
class PaymentState {
  const PaymentState({this.phase = PaymentPhase.creating, this.payment, this.message});

  final PaymentPhase phase;
  final Payment? payment;

  /// Alasan dari backend saat QR gagal dibuat (mis. order sudah dibatalkan),
  /// supaya pengguna tidak hanya melihat pesan generik.
  final String? message;
}

class PaymentController extends Notifier<PaymentState> {
  PaymentController(this.orderId);

  final String orderId;

  static const Duration _pollInterval = Duration(seconds: 3);

  Timer? _poll;
  AppLifecycleListener? _lifecycle;
  bool _disposed = false;
  bool _checking = false;

  @override
  PaymentState build() {
    // Polling tidak berguna saat app di background: hemat baterai dan kuota.
    _lifecycle = AppLifecycleListener(onStateChange: _handleLifecycle);
    ref.onDispose(() {
      _disposed = true;
      _poll?.cancel();
      _lifecycle?.dispose();
      _lifecycle = null;
    });
    scheduleMicrotask(createPayment);
    return const PaymentState();
  }

  void _handleLifecycle(AppLifecycleState lifecycleState) {
    if (_disposed) return;
    switch (lifecycleState) {
      case AppLifecycleState.resumed:
        _startPolling();
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
      case AppLifecycleState.detached:
        _poll?.cancel();
        _poll = null;
        break;
    }
  }

  void _startPolling() {
    if (_disposed) return;
    _poll?.cancel();
    if (state.phase != PaymentPhase.pending) {
      _poll = null;
      return;
    }
    _poll = Timer.periodic(_pollInterval, (_) => checkNow());
  }

  Future<void> createPayment() async {
    _poll?.cancel();
    state = const PaymentState();
    try {
      final payment = await ref
          .read(paymentRepositoryProvider)
          .createPayment(orderId);
      if (_disposed) return;
      state = PaymentState(phase: PaymentPhase.pending, payment: payment);
      _startPolling();
    } catch (error) {
      if (_disposed) return;
      state = PaymentState(
        phase: PaymentPhase.error,
        message: error is Failure ? error.message : null,
      );
    }
  }

  Future<bool> checkNow() async {
    final current = state.payment;
    if (_disposed ||
        _checking ||
        current == null ||
        state.phase != PaymentPhase.pending) {
      return false;
    }

    _checking = true;
    try {
      final updated = await ref
          .read(paymentRepositoryProvider)
          .fetchStatus(current.id);
      if (_disposed) return false;

      switch (updated.status) {
        case PaymentStatus.pending:
          state = PaymentState(phase: PaymentPhase.pending, payment: updated);
          return false;
        case PaymentStatus.paid:
          _poll?.cancel();
          state = PaymentState(phase: PaymentPhase.paid, payment: updated);
          _refreshOrders();
          return true;
        case PaymentStatus.failed:
          _poll?.cancel();
          state = PaymentState(phase: PaymentPhase.failed, payment: updated);
          return true;
        case PaymentStatus.expired:
          _poll?.cancel();
          state = PaymentState(phase: PaymentPhase.expired, payment: updated);
          return true;
      }
    } catch (_) {
      return false;
    } finally {
      _checking = false;
    }
  }

  /// Segarkan daftar dan detail order, baik tampilan customer maupun staff
  /// (order offline dibayar dari perangkat worker).
  void _refreshOrders() {
    ref.invalidate(ordersProvider);
    ref.invalidate(orderDetailProvider(orderId));
    ref.invalidate(staffOrdersProvider);
    ref.invalidate(staffOrderDetailProvider(orderId));
  }
}

final paymentControllerProvider = NotifierProvider.autoDispose
    .family<PaymentController, PaymentState, String>(PaymentController.new);
