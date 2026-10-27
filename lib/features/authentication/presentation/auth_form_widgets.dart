import 'package:flutter/material.dart';

import '../../../app/l10n/app_strings.dart';
import '../../../design_system/design_system.dart';

final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

String? validateEmail(AppStrings s, String? value) {
  final v = value?.trim() ?? '';
  if (v.isEmpty) return s.requiredField;
  return _emailPattern.hasMatch(v) ? null : s.invalidEmail;
}

String? validatePhone(AppStrings s, String? value) {
  final digits = (value ?? '').replaceAll(RegExp(r'[\s\-+()]'), '');
  if (digits.isEmpty) return s.requiredField;
  return RegExp(r'^\d{7,15}$').hasMatch(digits) ? null : s.invalidPhone;
}

String? validateRequired(AppStrings s, String? value) =>
    (value == null || value.trim().isEmpty) ? s.requiredField : null;

class PasswordField extends StatefulWidget {
  const PasswordField({
    super.key,
    required this.controller,
    required this.label,
    this.validator,
    this.serverError,
    this.onSubmitted,
    this.isNew = false,
  });

  final TextEditingController controller;
  final String label;
  final FormFieldValidator<String>? validator;
  final String? serverError;
  final ValueChanged<String>? onSubmitted;
  final bool isNew;

  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      obscureText: _obscure,
      autofillHints: [widget.isNew ? AutofillHints.newPassword : AutofillHints.password],
      onFieldSubmitted: widget.onSubmitted,
      validator: widget.validator,
      decoration: InputDecoration(
        labelText: widget.label,
        errorText: widget.serverError,
        prefixIcon: const Icon(Icons.lock_outline_rounded),
        suffixIcon: IconButton(
          tooltip: widget.label,
          icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
          onPressed: () => setState(() => _obscure = !_obscure),
        ),
      ),
    );
  }
}

class SubmitButton extends StatelessWidget {
  const SubmitButton({super.key, required this.label, required this.loading, required this.onPressed});

  final String label;
  final bool loading;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => FilledButton(
    onPressed: loading ? null : onPressed,
    child: loading
        ? const AppSpinner(size: SpinnerSize.button)
        : Text(label),
  );
}

class ErrorBanner extends StatelessWidget {
  const ErrorBanner({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: Gap.lg),
      padding: const EdgeInsets.all(Gap.md),
      decoration: BoxDecoration(color: scheme.errorContainer, borderRadius: BorderRadius.circular(Radii.sm)),
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded, color: scheme.onErrorContainer),
          const SizedBox(width: Gap.sm),
          Expanded(child: Text(message, style: TextStyle(color: scheme.onErrorContainer))),
        ],
      ),
    );
  }
}
