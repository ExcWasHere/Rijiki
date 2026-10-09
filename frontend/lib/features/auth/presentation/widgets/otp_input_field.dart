import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rijiki/core/constants/app_constants.dart';
import 'package:rijiki/core/theme/app_colors.dart';
import 'package:rijiki/core/theme/app_spacing.dart';

class OtpInputField extends StatefulWidget {
  const OtpInputField({
    super.key,
    required this.controller,
    required this.onCompleted,
    this.length = AppConstants.otpLength,
    this.enabled = true,
    this.hasError = false,
  });

  final TextEditingController controller;
  final ValueChanged<String> onCompleted;
  final int length;
  final bool enabled;
  final bool hasError;

  @override
  State<OtpInputField> createState() => _OtpInputFieldState();
}

class _OtpInputFieldState extends State<OtpInputField> {
  final FocusNode _focusNode = FocusNode();
  String _lastText = '';

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
    _focusNode.addListener(_rebuild);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    _focusNode.removeListener(_rebuild);
    _focusNode.dispose();
    super.dispose();
  }

  void _rebuild() => setState(() {});

  void _onTextChanged() {
    final text = widget.controller.text;
    setState(() {});
    if (text == _lastText) return;
    _lastText = text;
    if (text.length == widget.length) widget.onCompleted(text);
  }

  @override
  Widget build(BuildContext context) {
    final text = widget.controller.text;
    final activeIndex = text.length.clamp(0, widget.length - 1);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.enabled ? _focusNode.requestFocus : null,
      child: Stack(
        children: [
          Row(
            children: List.generate(widget.length, (index) {
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                  child: _OtpBox(
                    character: index < text.length ? text[index] : '',
                    isActive: _focusNode.hasFocus && index == activeIndex,
                    hasError: widget.hasError,
                  ),
                ),
              );
            }),
          ),
          Positioned.fill(
            child: Opacity(
              opacity: 0,
              child: TextField(
                controller: widget.controller,
                focusNode: _focusNode,
                enabled: widget.enabled,
                keyboardType: TextInputType.number,
                autofillHints: const [AutofillHints.oneTimeCode],
                enableInteractiveSelection: false,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(widget.length),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OtpBox extends StatelessWidget {
  const _OtpBox({
    required this.character,
    required this.isActive,
    required this.hasError,
  });

  final String character;
  final bool isActive;
  final bool hasError;

  @override
  Widget build(BuildContext context) {
    final borderColor = hasError
        ? AppColors.error
        : isActive
            ? AppColors.primary
            : AppColors.outline;

    return Container(
      height: AppSpacing.buttonHeight + AppSpacing.sm,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: borderColor, width: isActive ? 2 : 1),
      ),
      child: Text(
        character,
        style: Theme.of(context)
            .textTheme
            .headlineSmall
            ?.copyWith(fontWeight: FontWeight.w700),
      ),
    );
  }
}
