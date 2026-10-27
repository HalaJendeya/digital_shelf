import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/l10n/app_strings.dart';
import '../../../design_system/design_system.dart';
import '../../../core/error/app_exception.dart';
import '../../../shared/widgets/common.dart';
import '../../authentication/application/auth_controller.dart';
import '../../authentication/presentation/auth_form_widgets.dart';

/// Edits name and phone via `PUT /auth/profile`.
class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _phone;
  late final TextEditingController _email;
  String? _originalEmail;
  bool _saving = false;
  AppException? _error;

  @override
  void initState() {
    super.initState();
    final customer = ref.read(authControllerProvider).customer;
    _name = TextEditingController(text: customer?.name ?? '');
    _phone = TextEditingController(text: customer?.phone ?? '');
    _originalEmail = customer?.email;
    _email = TextEditingController(text: _originalEmail ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _email.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving || !_form.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref
          .read(authControllerProvider.notifier)
          .updateProfile(
            name: _name.text.trim(),
            phone: _phone.text.trim(),
            email: _email.text.trim() == (_originalEmail ?? '') ? null : _email.text.trim(),
          );
      if (!mounted) return;
      showSnack(context, context.s.profileUpdated);
      context.pop();
    } on AppException catch (e) {
      if (mounted) setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return Scaffold(
      appBar: AppBar(title: Text(s.editProfile)),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(Gap.xl),
          children: [
            if (_error != null && _error!.fieldErrors.isEmpty) ErrorBanner(message: s.errorMessage(_error!)),
            TextFormField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: s.email,
                prefixIcon: const Icon(Icons.alternate_email_rounded),
                errorText: _error?.fieldError('email'),
              ),
              validator: (v) => validateEmail(s, v),
            ),
            const SizedBox(height: Gap.md),
            TextFormField(
              controller: _name,
              decoration: InputDecoration(
                labelText: s.name,
                prefixIcon: const Icon(Icons.person_outline_rounded),
                errorText: _error?.fieldError('name'),
              ),
              validator: (v) => validateRequired(s, v),
            ),
            const SizedBox(height: Gap.md),
            TextFormField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: s.phone,
                prefixIcon: const Icon(Icons.phone_outlined),
                errorText: _error?.fieldError('phone'),
              ),
              validator: (v) => validatePhone(s, v),
            ),
            const SizedBox(height: Gap.xl),
            SubmitButton(label: s.save, loading: _saving, onPressed: _save),
          ],
        ),
      ),
    );
  }
}
