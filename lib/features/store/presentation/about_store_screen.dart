import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/l10n/app_strings.dart';
import '../../../core/utils/contact_links.dart';
import '../../../design_system/design_system.dart';
import '../../../shared/widgets/app_network_image.dart';
import '../../../shared/widgets/common.dart';
import '../../../shared/widgets/price_text.dart';
import '../../../shared/widgets/state_views.dart';
import '../data/store_repository.dart';

/// Store profile from `GET /stores/{slug}`: cover, description, delivery
/// terms and contact actions.
class AboutStoreScreen extends ConsumerWidget {
  const AboutStoreScreen({super.key});

  Future<void> _open(BuildContext context, Uri uri) async {
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication).catchError((_) => false);
    if (!opened && context.mounted) showSnack(context, context.s.linkFailed);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = context.s;
    return Scaffold(
      body: AsyncValueView(
        value: ref.watch(storeProvider),
        onRetry: () => ref.invalidate(storeProvider),
        data: (store) => CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
              expandedHeight: MediaQuery.sizeOf(context).width / AppSizes.bannerAspectRatio,
              title: Text(s.aboutStore),
              flexibleSpace: FlexibleSpaceBar(background: AppNetworkImage(url: store.cover)),
            ),
            SliverPadding(
              padding: const EdgeInsets.all(Gap.lg),
              sliver: SliverList.list(
                children: [
                  Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(Radii.md),
                        child: SizedBox.square(
                          dimension: AppSizes.logoMd,
                          child: AppNetworkImage(url: store.logo),
                        ),
                      ),
                      const SizedBox(width: Gap.lg),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(store.name, style: context.textStyles.pageTitle),
                            if (store.tagline ?? store.typeName case final subtitle?)
                              Text(
                                subtitle,
                                style: context.textTheme.bodyMedium?.copyWith(color: context.colors.onSurfaceVariant),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (store.description != null) ...[
                    const SizedBox(height: Gap.xl),
                    Text(store.description!, style: context.textStyles.bodyLong),
                  ],
                  if (store.deliveryFee != null || store.minOrder != null) ...[
                    const SizedBox(height: Gap.xl),
                    Text(s.deliveryAndOrders, style: context.textStyles.sectionTitle),
                    const SizedBox(height: Gap.sm),
                    Card(
                      child: Column(
                        children: [
                          if (store.deliveryFee != null)
                            ListTile(
                              leading: const Icon(Icons.local_shipping_outlined),
                              title: Text(s.deliveryFee),
                              trailing: Money(store.deliveryFee!, style: context.textStyles.amount),
                            ),
                          if (store.minOrder != null)
                            ListTile(
                              leading: const Icon(Icons.shopping_basket_outlined),
                              title: Text(s.minOrder),
                              trailing: Money(store.minOrder!, style: context.textStyles.amount),
                            ),
                        ],
                      ),
                    ),
                  ],
                  if (store.phone != null || store.whatsapp != null || store.address != null) ...[
                    const SizedBox(height: Gap.xl),
                    Text(s.contactStore, style: context.textStyles.sectionTitle),
                    const SizedBox(height: Gap.sm),
                    Card(
                      child: Column(
                        children: [
                          if (store.phone != null)
                            ListTile(
                              leading: const Icon(Icons.phone_outlined),
                              title: Text(s.call),
                              subtitle: Text(store.phone!, textDirection: TextDirection.ltr),
                              trailing: const Icon(Icons.open_in_new_rounded),
                              onTap: () => _open(context, ContactLinks.phone(store.phone!)),
                            ),
                          if (store.whatsapp != null)
                            ListTile(
                              leading: const Icon(Icons.chat_outlined),
                              title: Text(s.whatsapp),
                              subtitle: Text(store.whatsapp!, textDirection: TextDirection.ltr),
                              trailing: const Icon(Icons.open_in_new_rounded),
                              onTap: () => _open(context, ContactLinks.whatsapp(store.whatsapp!)),
                            ),
                          if (store.address != null)
                            ListTile(
                              leading: const Icon(Icons.storefront_outlined),
                              title: Text(s.address),
                              subtitle: Text(store.address!),
                            ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
