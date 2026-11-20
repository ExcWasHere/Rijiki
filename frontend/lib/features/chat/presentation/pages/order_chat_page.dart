import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rijiki/core/session/session_provider.dart';
import 'package:rijiki/core/theme/app_colors.dart';
import 'package:rijiki/core/theme/app_spacing.dart';
import 'package:rijiki/core/utils/date_formatter.dart';
import 'package:rijiki/features/chat/domain/order_message.dart';
import 'package:rijiki/features/chat/presentation/controllers/order_chat_controller.dart';
import 'package:rijiki/shared/widgets/error_state.dart';
import 'package:rijiki/shared/widgets/loading_skeleton.dart';

/// Chat satu order. Dipakai customer, worker, dan owner; lawan bicara
/// ditentukan backend (customer ↔ worker penangan/owner).
class OrderChatPage extends ConsumerStatefulWidget {
  const OrderChatPage({
    super.key,
    required this.orderId,
    this.title = 'Chat order',
  });

  final String orderId;
  final String title;

  @override
  ConsumerState<OrderChatPage> createState() => _OrderChatPageState();
}

class _OrderChatPageState extends ConsumerState<OrderChatPage> {
  final TextEditingController _input = TextEditingController();
  final ScrollController _scroll = ScrollController();

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _scrollToBottom({bool animate = true}) {
    if (!_scroll.hasClients) return;
    final target = _scroll.position.maxScrollExtent;
    if (animate) {
      _scroll.animateTo(
        target,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    } else {
      _scroll.jumpTo(target);
    }
  }

  Future<void> _send() async {
    final controller = ref.read(orderChatProvider(widget.orderId).notifier);
    final body = _input.text;
    if (body.trim().isEmpty) return;

    final ok = await controller.send(body);
    if (!mounted) return;

    if (ok) {
      _input.clear();
      _scrollToBottom();
      return;
    }
    final message =
        ref.read(orderChatProvider(widget.orderId)).errorMessage ??
        'Pesan gagal dikirim. Coba lagi ya.';
    controller.clearError();
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final provider = orderChatProvider(widget.orderId);
    final state = ref.watch(provider);
    final myRole = ref.watch(sessionProvider)?.role;

    // Pesan baru (dari polling) menggeser daftar ke bawah.
    ref.listen(provider, (previous, next) {
      final grew =
          previous == null || next.messages.length > previous.messages.length;
      if (!grew) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _scrollToBottom(animate: previous != null);
      });
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(widget.title)),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(child: _buildBody(state, myRole)),
            _Composer(
              controller: _input,
              sending: state.sending,
              enabled: !state.loading && !state.loadFailed,
              onSend: _send,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(OrderChatState state, Object? myRole) {
    if (state.loading) {
      return ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: const [
          LoadingSkeleton(height: 48),
          SizedBox(height: 12),
          LoadingSkeleton(height: 64),
          SizedBox(height: 12),
          LoadingSkeleton(height: 48),
        ],
      );
    }

    if (state.loadFailed) {
      return Center(
        child: ErrorState(
          message: state.errorMessage ?? 'Chat gagal dimuat. Coba lagi ya.',
          onRetry: () =>
              ref.read(orderChatProvider(widget.orderId).notifier).retry(),
        ),
      );
    }

    if (state.messages.isEmpty) {
      return const _EmptyChat();
    }

    return ListView.builder(
      controller: _scroll,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.sm,
      ),
      itemCount: state.messages.length,
      itemBuilder: (context, index) {
        final message = state.messages[index];
        final previous = index == 0 ? null : state.messages[index - 1];
        final showDay =
            previous == null ||
            !_sameDay(previous.createdAt, message.createdAt);
        return Column(
          children: [
            if (showDay) _DayDivider(date: message.createdAt),
            _MessageBubble(message: message, showRole: !message.mine),
          ],
        );
      },
    );
  }

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

class _EmptyChat extends StatelessWidget {
  const _EmptyChat();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.18),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.chat_bubble_outline_rounded,
                color: AppColors.primaryDark,
                size: 30,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text('Belum ada pesan', style: textTheme.titleSmall),
            const SizedBox(height: 4),
            Text(
              'Tanyakan kondisi sepatu, jadwal jemput, atau hal lain soal order ini.',
              textAlign: TextAlign.center,
              style: textTheme.bodySmall?.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DayDivider extends StatelessWidget {
  const _DayDivider({required this.date});

  final DateTime date;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(date.year, date.month, date.day);
    final label = day == today
        ? 'Hari ini'
        : day == today.subtract(const Duration(days: 1))
        ? 'Kemarin'
        : DateFormatter.shortDate(date);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.outline.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message, required this.showRole});

  final OrderMessage message;
  final bool showRole;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final mine = message.mine;

    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.78,
        ),
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
          decoration: BoxDecoration(
            color: mine ? AppColors.primary : AppColors.surface,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(16),
              topRight: const Radius.circular(16),
              bottomLeft: Radius.circular(mine ? 16 : 4),
              bottomRight: Radius.circular(mine ? 4 : 16),
            ),
            border: mine
                ? null
                : Border.all(color: AppColors.outline.withValues(alpha: 0.35)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (showRole)
                Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Text(
                    message.senderRole.label,
                    style: textTheme.labelSmall?.copyWith(
                      color: AppColors.primaryDark,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              Text(
                message.body,
                style: textTheme.bodyMedium?.copyWith(
                  color: mine ? AppColors.onPrimary : AppColors.onSurface,
                ),
              ),
              const SizedBox(height: 2),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  DateFormatter.time(message.createdAt),
                  style: textTheme.labelSmall?.copyWith(
                    color: mine
                        ? AppColors.onPrimary.withValues(alpha: 0.7)
                        : AppColors.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  const _Composer({
    required this.controller,
    required this.sending,
    required this.enabled,
    required this.onSend,
  });

  final TextEditingController controller;
  final bool sending;
  final bool enabled;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(color: AppColors.outline.withValues(alpha: 0.25)),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.sm,
          AppSpacing.md,
          AppSpacing.sm,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                enabled: enabled && !sending,
                minLines: 1,
                maxLines: 4,
                maxLength: 1000,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.newline,
                decoration: const InputDecoration(
                  hintText: 'Tulis pesan…',
                  counterText: '',
                  isDense: true,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            IconButton.filled(
              onPressed: enabled && !sending ? onSend : null,
              icon: sending
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send_rounded, size: 20),
              tooltip: 'Kirim',
            ),
          ],
        ),
      ),
    );
  }
}
