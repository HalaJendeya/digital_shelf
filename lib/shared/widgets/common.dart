import 'package:flutter/material.dart';

import '../../app/l10n/app_strings.dart';
import '../../design_system/design_system.dart';

class SectionHeader extends StatelessWidget {
  const SectionHeader({super.key, required this.title, this.onSeeAll});

  final String title;
  final VoidCallback? onSeeAll;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(Gap.lg, Gap.lg, Gap.sm, Gap.sm),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: context.textStyles.sectionTitle,
            ),
          ),
          if (onSeeAll != null) TextButton(onPressed: onSeeAll, child: Text(context.s.seeAll)),
        ],
      ),
    );
  }
}

class RatingStars extends StatelessWidget {
  const RatingStars({super.key, required this.rating, this.size = IconSizes.base});

  final double rating;
  final double size;

  @override
  Widget build(BuildContext context) {
    final color = context.status.star;
    return Semantics(
      label: '${rating.toStringAsFixed(1)} / 5',
      child: ExcludeSemantics(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 1; i <= 5; i++)
              Icon(
                rating >= i
                    ? Icons.star_rounded
                    : rating >= i - 0.5
                    ? Icons.star_half_rounded
                    : Icons.star_outline_rounded,
                size: size,
                color: color,
              ),
          ],
        ),
      ),
    );
  }
}

class QuantityStepper extends StatelessWidget {
  const QuantityStepper({
    super.key,
    required this.value,
    required this.onChanged,
    this.min = 1,
    this.max,
    this.enabled = true,
  });

  final int value;
  final int min;
  final int? max;
  final bool enabled;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final canDec = enabled && value > min;
    final canInc = enabled && (max == null || value < max!);
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(Radii.sm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            visualDensity: VisualDensity.compact,
            tooltip: '−',
            icon: const Icon(Icons.remove_rounded, size: IconSizes.md),
            onPressed: canDec ? () => onChanged(value - 1) : null,
          ),
          Semantics(
            label: s.quantity,
            value: '$value',
            child: Text('$value', style: Theme.of(context).textTheme.titleSmall),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            tooltip: '+',
            icon: const Icon(Icons.add_rounded, size: IconSizes.md),
            onPressed: canInc ? () => onChanged(value + 1) : null,
          ),
        ],
      ),
    );
  }
}

void showSnack(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}

Future<bool> confirmDialog(BuildContext context, String message) async {
  final s = context.s;
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      content: Text(message),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: Text(s.cancel)),
        FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(s.confirm)),
      ],
    ),
  );
  return result ?? false;
}
