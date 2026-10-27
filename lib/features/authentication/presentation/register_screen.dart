import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/l10n/app_strings.dart';
import '../../../app/router/app_router.dart';
import '../../../design_system/design_system.dart';
import '../../../core/error/app_exception.dart';
import '../application/auth_controller.dart';
import 'auth_form_widgets.dart';

/// Pops with `true` on success so the login screen can resume the flow.
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _submitting = false;
  AppException? _error;

  @override
  void dispose() {
    for (final c in [_name, _email, _phone, _password, _confirm]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting || !_form.currentState!.validate()) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await ref.read(authControllerProvider.notifier).register(
        name: _name.text.trim(),
        email: _email.text.trim(),
        phone: _phone.text.trim(),
        password: _password.text,
        passwordConfirmation: _confirm.text,
      );
      if (!mounted) return;
      if (context.canPop()) {
        context.pop(true);
      } else {
        context.go(Routes.home);
      }
    } on AppException catch (e) {
      if (mounted) setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return Scaffold(
      appBar: AppBar(title: Text(s.register)),
      body: SafeArea(
        child: Form(
          key: _form,
          child: AutofillGroup(
            child: ListView(
              padding: const EdgeInsets.all(Gap.xl),
              children: [
                if (_error != null && _error!.fieldErrors.isEmpty) ErrorBanner(message: s.errorMessage(_error!)),
                TextFormField(
                  controller: _name,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.name],
                  decoration: InputDecoration(
                    labelText: s.name,
                    prefixIcon: const Icon(Icons.person_outline_rounded),
                    errorText: _error?.fieldError('name'),
                  ),
                  validator: (v) => validateRequired(s, v),
                ),
                const SizedBox(height: Gap.md),
                TextFormField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.email],
                  decoration: InputDecoration(
                    labelText: s.email,
                    prefixIcon: const Icon(Icons.alternate_email_rounded),
                    errorText: _error?.fieldError('email'),
                  ),
                  validator: (v) => validateEmail(s, v),
                ),
                const SizedBox(height: Gap.md),
                TextFormField(
                  controller: _phone,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.telephoneNumber],
                  decoration: InputDecoration(
                    labelText: s.phone,
                    prefixIcon: const Icon(Icons.phone_outlined),
                    errorText: _error?.fieldError('phone'),
                  ),
                  validator: (v) => validatePhone(s, v),
                ),
                const SizedBox(height: Gap.md),
                PasswordField(
                  controller: _password,
                  label: s.password,
                  isNew: true,
                  serverError: _error?.fieldError('password'),
                  validator: (v) => (v == null || v.isEmpty)
                      ? s.requiredField
                      : v.length < 8
                      ? s.passwordTooShort
                      : null,
                ),
                const SizedBox(height: Gap.md),
                PasswordField(
                  controller: _confirm,
                  label: s.confirmPassword,
                  isNew: true,
                  serverError: _error?.fieldError('password_confirmation'),
                  validator: (v) => v != _password.text ? s.passwordsDontMatch : null,
                  onSubmitted: (_) => _submit(),
                ),
                const SizedBox(height: Gap.xl),
                SubmitButton(label: s.register, loading: _submitting, onPressed: _submit),
                const SizedBox(height: Gap.md),
                Wrap(
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(s.haveAccount),
                    TextButton(onPressed: _submitting ? null : () => context.pop(), child: Text(s.login)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
