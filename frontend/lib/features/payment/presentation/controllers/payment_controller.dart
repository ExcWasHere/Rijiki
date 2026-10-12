import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rijiki/app/providers.dart';
import 'package:rijiki/core/enums/payment_status.dart';
import 'package:rijiki/features/order/presentation/controllers/order_detail_controller.dart';
import 'package:rijiki/features/order/presentation/controllers/order_list_controller.dart';
import 'package:rijiki/features/payment/domain/payment.dart';

enum PaymentPhase { creating, pending, paid, failed, expired, error }

@immutable
class PaymentState {
  const PaymentState({this.phase = PaymentPhase.creating, this.payment});

  final PaymentPhase phase;
  final Payment? payment;
}

class PaymentController extends Notifier<PaymentState> {
  PaymentController(this.orderId);

  final String orderId;

  static const Duration _pollInterval = Duration(seconds: 3);

  Timer? _poll;
  bool _disposed = false;
  bool _checking = false;

  @override
  PaymentState build() {
    ref.onDispose(() {
      _disposed = true;
      _poll?.cancel();
    });
    scheduleMicrotask(createPayment);
    return const PaymentState();
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
      _poll = Timer.periodic(_pollInterval, (_) => checkNow());
    } catch (_) {
      if (_disposed) return;
      state = const PaymentState(phase: PaymentPhase.error);
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
          ref.invalidate(ordersProvider);
          ref.invalidate(orderDetailProvider(orderId));
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
}

final paymentControllerProvider = NotifierProvider.autoDispose
    .family<PaymentController, PaymentState, String>(PaymentController.new);
