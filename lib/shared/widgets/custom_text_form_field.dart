/// 프로젝트 전반에서 공용으로 사용하는 입력 필드 스타일 위젯이다.
import 'package:flutter/material.dart';
import 'package:jg_business/shared/theme/app_tokens.dart';

class CustomTextFormField extends StatelessWidget {
  const CustomTextFormField({
    super.key,
    this.controller,
    this.focusNode,
    this.label,
    this.hintText,
    this.helperText,
    this.errorText,
    this.prefixIcon,
    this.suffixIcon,
    this.keyboardType,
    this.textInputAction,
    this.validator,
    this.onChanged,
    this.onTap,
    this.onFieldSubmitted,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.autofocus = false,
    this.enabled = true,
    this.readOnly = false,
    this.obscureText = false,
    this.autovalidateMode,
    this.contentPadding,
    this.fillColor,
  });

  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String? label;
  final String? hintText;
  final String? helperText;
  final String? errorText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onTap;
  final ValueChanged<String>? onFieldSubmitted;
  final int maxLines;
  final int? minLines;
  final int? maxLength;
  final bool autofocus;
  final bool enabled;
  final bool readOnly;
  final bool obscureText;
  final AutovalidateMode? autovalidateMode;
  final EdgeInsetsGeometry? contentPadding;
  final Color? fillColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              label!,
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.inkStrong,
              ),
            ),
          ),
        ],
        TextFormField(
          controller: controller,
          focusNode: focusNode,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          validator: validator,
          onChanged: onChanged,
          onTap: onTap,
          onFieldSubmitted: onFieldSubmitted,
          maxLines: obscureText ? 1 : maxLines,
          minLines: minLines,
          maxLength: maxLength,
          autofocus: autofocus,
          enabled: enabled,
          readOnly: readOnly,
          obscureText: obscureText,
          autovalidateMode: autovalidateMode,
          style: theme.textTheme.bodyLarge?.copyWith(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: AppColors.inkStrong,
          ),
          decoration: InputDecoration(
            hintText: hintText,
            helperText: helperText,
            errorText: errorText,
            filled: true,
            fillColor:
                enabled
                    ? (fillColor ?? AppColors.surfaceSoft)
                    : AppColors.surfaceDisabled,
            prefixIcon: prefixIcon,
            suffixIcon: suffixIcon,
            counterText: '',
            hintStyle: theme.textTheme.bodyLarge?.copyWith(
              color: const Color(0xFF9CA3AF),
              fontWeight: FontWeight.w400,
            ),
            helperStyle: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.mutedLight,
            ),
            errorStyle: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.error,
              fontWeight: FontWeight.w600,
            ),
            contentPadding:
                contentPadding ??
                const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            border: _border(Colors.grey),
            enabledBorder: _border(Colors.grey),
            focusedBorder: _border(AppColors.inkStrong, width: 1.4),
            errorBorder: _border(colorScheme.error),
            focusedErrorBorder: _border(colorScheme.error, width: 1.4),
            disabledBorder: _border(const Color(0x00000000)),
          ),
        ),
      ],
    );
  }

  OutlineInputBorder _border(Color color, {double width = 1}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: BorderSide(color: color, width: width),
    );
  }
}
