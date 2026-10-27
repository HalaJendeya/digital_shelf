import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/l10n/app_strings.dart';
import '../../../design_system/design_system.dart';
import '../../../shared/models/product.dart';
import '../../../shared/widgets/common.dart';
import '../../authentication/presentation/require_login.dart';
import '../application/favorites_controller.dart';

class FavoriteButton extends ConsumerWidget {
  const FavoriteButton({super.key, required this.product, this.filled = false});

  final Product product;

  /// Draws a translucent circle behind the icon (for use on images).
  final bool filled;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = context.s;
    final isFavorite = ref.watch(
      isFavoriteProvider((id: product.id, fallback: product.isFavorite)),
    );
    final scheme = Theme.of(context).colorScheme;
    return IconButton(
      tooltip: isFavorite ? s.removeFavorite : s.addFavorite,
      style: filled
          ? IconButton.styleFrom(backgroundColor: scheme.surface.withValues(alpha: AppOpacity.overlay))
          : null,
      icon: Icon(
        isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
        color: isFavorite ? context.status.favorite : scheme.onSurfaceVariant,
      ),
      onPressed: () async {
        if (!await ensureSignedIn(context)) return;
        try {
          await ref.read(favoritesControllerProvider.notifier).toggle(product);
        } catch (e) {
          if (context.mounted) showSnack(context, s.errorMessage(e));
        }
      },
    );
  }
}
