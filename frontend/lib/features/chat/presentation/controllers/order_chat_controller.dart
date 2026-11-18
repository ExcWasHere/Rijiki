import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rijiki/app/providers.dart';
import 'package:rijiki/features/chat/domain/order_message.dart';

@immutable
class OrderChatState {
  const OrderChatState({
    this.messages = const [],
    this.loading = true,
    this.sending = false,
    this.loadFailed = false,
    this.errorMessage,
  });

  final List<OrderMessage> messages;

  /// Muat pertama masih berjalan.
  final bool loading;

  /// Pesan sedang dikirim.
  final bool sending;

  /// Muat pertama gagal; layar menampilkan tombol coba lagi.
  final bool loadFailed;
  final String? errorMessage;

  OrderChatState copyWith({
    List<OrderMessage>? messages,
    bool? loading,
    bool? sending,
    bool? loadFailed,
    String? errorMessage,
    bool clearError = false,
  }) {
    return OrderChatState(
      messages: messages ?? this.messages,
      loading: loading ?? this.loading,
      sending: sending ?? this.sending,
      loadFailed: loadFailed ?? this.loadFailed,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class OrderChatController extends Notifier<OrderChatState> {
  OrderChatController(this.orderId);

  final String orderId;

  /// Tanpa WebSocket, pesan baru diambil dengan polling.
  static const Duration _pollInterval = Duration(seconds: 5);

  Timer? _poll;
  bool _disposed = false;
  bool _fetching = false;

  @override
  OrderChatState build() {
    ref.onDispose(() {
      _disposed = true;
      _poll?.cancel();
    });
    scheduleMicrotask(() => _load());
    return const OrderChatState();
  }

  Future<void> retry() {
    state = state.copyWith(loading: true, loadFailed: false, clearError: true);
    return _load();
  }

  Future<void> _load() async {
    if (_disposed || _fetching) return;
    _fetching = true;
    try {
      final thread = await ref
          .read(orderChatRepositoryProvider)
          .fetchThread(orderId);
      if (_disposed) return;

      state = state.copyWith(
        messages: thread.messages,
        loading: false,
        loadFailed: false,
        clearError: true,
      );
      _startPolling();

      // Pesan dari lawan bicara langsung ditandai terbaca saat layar terbuka.
      if (thread.unread > 0) {
        await ref.read(orderChatRepositoryProvider).markRead(orderId);
      }
    } catch (error) {
      if (_disposed) return;
      final message = error is Exception ? _messageOf(error) : null;
      state = state.copyWith(
        loading: false,
        loadFailed: state.messages.isEmpty,
        errorMessage: state.messages.isEmpty ? message : null,
      );
    } finally {
      _fetching = false;
    }
  }

  void _startPolling() {
    _poll ??= Timer.periodic(_pollInterval, (_) {
      if (!state.sending) unawaited(_load());
    });
  }

  /// Mengirim pesan; mengembalikan true bila berhasil sehingga kolom input
  /// boleh dikosongkan.
  Future<bool> send(String rawBody) async {
    final body = rawBody.trim();
    if (body.isEmpty || state.sending) return false;

    state = state.copyWith(sending: true, clearError: true);
    try {
      final sent = await ref
          .read(orderChatRepositoryProvider)
          .send(orderId, body);
      if (_disposed) return true;
      state = state.copyWith(
        messages: [...state.messages, sent],
        sending: false,
      );
      unawaited(_load());
      return true;
    } catch (error) {
      if (_disposed) return false;
      state = state.copyWith(
        sending: false,
        errorMessage: _messageOf(error),
      );
      return false;
    }
  }

  void clearError() {
    if (state.errorMessage != null) state = state.copyWith(clearError: true);
  }

  static String _messageOf(Object error) {
    final text = error.toString();
    return text.isEmpty ? 'Pesan gagal dikirim. Coba lagi ya.' : text;
  }
}

final orderChatProvider =
    NotifierProvider.autoDispose.family<OrderChatController, OrderChatState, String>(
      OrderChatController.new,
    );
