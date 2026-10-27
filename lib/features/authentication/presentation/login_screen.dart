import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/l10n/app_strings.dart';
import '../../../app/router/app_router.dart';
import '../../../design_system/design_system.dart';
import '../../../core/error/app_exception.dart';
import '../../../shared/widgets/app_network_image.dart';
import '../../store/data/store_repository.dart';
import '../application/auth_controller.dart';
import 'auth_form_widgets.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key, this.from});

  /// Destination to resume after a protected-route redirect.
  final String? from;

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _submitting = false;
  AppException? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _onSignedIn() {
    if (widget.from != null) {
      context.pushReplacement(widget.from!);
    } else if (context.canPop()) {
      context.pop(true);
    } else {
      context.go(Routes.home);
    }
  }

  Future<void> _submit() async {
    if (_submitting || !_form.currentState!.validate()) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await ref
          .read(authControllerProvider.notifier)
          .login(email: _email.text.trim(), password: _password.text);
      if (mounted) _onSignedIn();
    } on AppException catch (e) {
      if (mounted) setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final store = ref.watch(storeProvider).value;
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: Form(
          key: _form,
          child: ListView(
            padding: const EdgeInsets.all(Gap.xl),
            children: [
              Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(Radii.lg),
                  child: SizedBox.square(dimension: AppSizes.logoMd, child: AppNetworkImage(url: store?.logo)),
                ),
              ),
              const SizedBox(height: Gap.lg),
              Text(s.login,
                  textAlign: TextAlign.center,
                  style: context.textStyles.pageTitle),
              const SizedBox(height: Gap.xl),
              if (_error != null && _error!.fieldErrors.isEmpty) ErrorBanner(message: s.errorMessage(_error!)),
              TextFormField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.email],
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: s.email,
                  prefixIcon: const Icon(Icons.alternate_email_rounded),
                  errorText: _error?.fieldError('email'),
                ),
                validator: (v) => validateEmail(s, v),
              ),
              const SizedBox(height: Gap.md),
              PasswordField(
                controller: _password,
                label: s.password,
                serverError: _error?.fieldError('password'),
                validator: (v) => (v == null || v.isEmpty) ? s.requiredField : null,
                onSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: Gap.xl),
              SubmitButton(label: s.login, loading: _submitting, onPressed: _submit),
              const SizedBox(height: Gap.md),
              Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(s.noAccount),
                  TextButton(
                    onPressed: _submitting
                        ? null
                        : () async {
                            final registered = await context.push<bool>(Routes.register);
                            if (registered == true && mounted) _onSignedIn();
                          },
                    child: Text(s.register),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
