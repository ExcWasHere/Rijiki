import 'package:flutter/material.dart';
import 'package:rijiki/core/theme/app_spacing.dart';

Future<String?> showAddressEditSheet(
  BuildContext context, {
  required String title,
  required String initial,
}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => _AddressEditContent(title: title, initial: initial),
  );
}

class _AddressEditContent extends StatefulWidget {
  const _AddressEditContent({required this.title, required this.initial});

  final String title;
  final String initial;

  @override
  State<_AddressEditContent> createState() => _AddressEditContentState();
}

class _AddressEditContentState extends State<_AddressEditContent> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initial,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.lg + bottomInset,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _controller,
            autofocus: true,
            minLines: 2,
            maxLines: 4,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              hintText: 'Tulis alamat lengkap',
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          FilledButton(
            onPressed: () {
              final value = _controller.text.trim();
              if (value.isNotEmpty) Navigator.of(context).pop(value);
            },
            child: const Text('Simpan alamat'),
          ),
        ],
      ),
    );
  }
}
