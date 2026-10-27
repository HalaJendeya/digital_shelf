import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/l10n/app_strings.dart';
import '../../../app/router/app_router.dart';
import '../../../design_system/design_system.dart';
import '../../../core/error/app_exception.dart';
import '../../../shared/widgets/state_views.dart';
import '../../authentication/application/auth_controller.dart';
import '../../authentication/presentation/auth_form_widgets.dart';
import '../../cart/application/cart_controller.dart';
import '../../cart/presentation/cart_screen.dart';
import '../../orders/data/orders_repository.dart';
import '../application/checkout_controller.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _phone;
  final _address = TextEditingController();
  final _notes = TextEditingController();
  PaymentMethod _payment = PaymentMethod.cash;
  AppException? _error;

  @override
  void initState() {
    super.initState();
    final customer = ref.read(authControllerProvider).customer;
    _name = TextEditingController(text: customer?.name ?? '');
    _phone = TextEditingController(text: customer?.phone ?? '');
    // Prices, stock or coupons may have changed since the cart was loaded
    // (e.g. on another device); show the server's current totals.
    Future.microtask(() => ref.read(cartControllerProvider.notifier).refresh().catchError((_) {}));
  }

  @override
  void dispose() {
    for (final c in [_name, _phone, _address, _notes]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _placeOrder() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _error = null);
    try {
      final order = await ref.read(checkoutControllerProvider.notifier).submit(CheckoutRequest(
        customerName: _name.text.trim(),
        phone: _phone.text.trim(),
        address: _address.text.trim(),
        notes: _notes.text,
        paymentMethod: _payment,
      ));
      if (order != null && mounted) {
        context.pushReplacement(Routes.orderSuccess(order.id), extra: order);
      }
    } on AppException catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final theme = Theme.of(context);
    final submitting = ref.watch(checkoutControllerProvider.select((c) => c.isSubmitting));
    final cart = ref.watch(cartControllerProvider);

    return PopScope(
      canPop: !submitting,
      child: Scaffold(
        appBar: AppBar(title: Text(s.checkout)),
        body: AsyncValueView(
          value: cart,
          onRetry: () => ref.invalidate(cartControllerProvider),
          data: (cart) => cart.isEmpty
              ? EmptyView(message: s.emptyCart, icon: Icons.shopping_bag_outlined)
              : Form(
                  key: _form,
                  child: ListView(
                    padding: const EdgeInsets.all(Gap.lg),
                    children: [
                      Text(s.orderSummary, style: context.textStyles.sectionTitle),
                      const SizedBox(height: Gap.sm),
                      for (final item in cart.items)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: Gap.xxs),
                          child: Text('${item.quantity} × ${item.name}', style: theme.textTheme.bodyMedium),
                        ),
                      const SizedBox(height: Gap.sm),
                      CartSummaryCard(cart: cart),
                      const SizedBox(height: Gap.xl),
                      Text(s.deliveryDetails,
                          style: context.textStyles.sectionTitle),
                      const SizedBox(height: Gap.md),
                      if (_error != null && _error!.fieldErrors.isEmpty) ErrorBanner(message: s.errorMessage(_error!)),
                      TextFormField(
                        controller: _name,
                        enabled: !submitting,
                        textInputAction: TextInputAction.next,
                        decoration: InputDecoration(
                          labelText: s.customerName,
                          errorText: _error?.fieldError('customer_name'),
                        ),
                        validator: (v) => validateRequired(s, v),
                      ),
                      const SizedBox(height: Gap.md),
                      TextFormField(
                        controller: _phone,
                        enabled: !submitting,
                        keyboardType: TextInputType.phone,
                        textInputAction: TextInputAction.next,
                        decoration: InputDecoration(labelText: s.phone, errorText: _error?.fieldError('phone')),
                        validator: (v) => validatePhone(s, v),
                      ),
                      const SizedBox(height: Gap.md),
                      TextFormField(
                        controller: _address,
                        enabled: !submitting,
                        maxLines: 2,
                        decoration: InputDecoration(labelText: s.address, errorText: _error?.fieldError('address')),
                        validator: (v) => validateRequired(s, v),
                      ),
                      const SizedBox(height: Gap.md),
                      TextFormField(
                        controller: _notes,
                        enabled: !submitting,
                        maxLines: 2,
                        decoration: InputDecoration(labelText: s.notes, errorText: _error?.fieldError('notes')),
                      ),
                      const SizedBox(height: Gap.xl),
                      Text(s.paymentMethod, style: context.textStyles.sectionTitle),
                      RadioGroup<PaymentMethod>(
                        groupValue: _payment,
                        onChanged: (v) {
                          if (!submitting && v != null) setState(() => _payment = v);
                        },
                        child: Column(
                          children: [
                            RadioListTile(
                              value: PaymentMethod.cash,
                              contentPadding: EdgeInsets.zero,
                              secondary: const Icon(Icons.payments_outlined),
                              title: Text(s.payCash),
                            ),
                            RadioListTile(
                              value: PaymentMethod.cardDemo,
                              contentPadding: EdgeInsets.zero,
                              secondary: const Icon(Icons.credit_card_outlined),
                              title: Text(s.payCardDemo),
                            ),
                          ],
                        ),
                      ),
                      if (_payment == PaymentMethod.cardDemo)
                        Container(
                          padding: const EdgeInsets.all(Gap.md),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.tertiaryContainer,
                            borderRadius: BorderRadius.circular(Radii.sm),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.info_outline_rounded, color: theme.colorScheme.onTertiaryContainer),
                              const SizedBox(width: Gap.sm),
                              Expanded(
                                child: Text(s.cardDemoNotice,
                                    style: TextStyle(color: theme.colorScheme.onTertiaryContainer)),
                              ),
                            ],
                          ),
                        ),
                      if (_error?.fieldError('payment_method') != null)
                        Text(_error!.fieldError('payment_method')!, style: TextStyle(color: theme.colorScheme.error)),
                      const SizedBox(height: Gap.xl),
                      SubmitButton(
                        label: s.placeOrder,
                        loading: submitting,
                        onPressed: cart.meetsMinOrder ? _placeOrder : null,
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}
