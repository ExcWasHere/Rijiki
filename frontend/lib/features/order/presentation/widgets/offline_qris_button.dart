import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rijiki/app/router/route_paths.dart';
import 'package:rijiki/core/enums/user_role.dart';
import 'package:rijiki/core/session/session_provider.dart';

class OfflineQrisButton extends ConsumerWidget {
  const OfflineQrisButton({super.key, required this.orderId});

  final String orderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOwner = ref.watch(sessionProvider)?.role == UserRole.owner;

    return SizedBox(
      width: double.infinity,
      child: FilledButton.tonalIcon(
        onPressed: () => context.push(
          isOwner
              ? RoutePaths.ownerOrderPaymentFor(orderId)
              : RoutePaths.workerOrderPaymentFor(orderId),
        ),
        icon: const Icon(Icons.qr_code_2_rounded),
        label: const Text('Tampilkan QRIS'),
      ),
    );
  }
}
