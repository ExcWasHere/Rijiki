import 'package:flutter/material.dart';

class ShoeConditionNotesField extends StatelessWidget {
  const ShoeConditionNotesField({
    super.key,
    required this.controller,
    required this.onChanged,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      maxLines: 3,
      minLines: 2,
      maxLength: 200,
      textCapitalization: TextCapitalization.sentences,
      decoration: const InputDecoration(
        labelText: 'Catatan kondisi sepatu (opsional)',
        hintText: 'Mis. ada noda tinta di bagian depan',
        alignLabelWithHint: true,
      ),
    );
  }
}
