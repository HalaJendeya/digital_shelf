import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/l10n/app_strings.dart';
import '../../../design_system/design_system.dart';
import '../../../core/error/app_exception.dart';
import '../../../shared/widgets/common.dart';
import '../../authentication/presentation/require_login.dart';
import '../application/reviews_providers.dart';
import '../data/reviews_repository.dart';

Future<void> showWriteReviewSheet(BuildContext context, int productId) async {
  if (!await ensureSignedIn(context) || !context.mounted) return;
  final submitted = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => WriteReviewSheet(productId: productId),
  );
  if (submitted == true && context.mounted) showSnack(context, context.s.reviewSubmitted);
}

class WriteReviewSheet extends ConsumerStatefulWidget {
  const WriteReviewSheet({super.key, required this.productId});

  final int productId;

  @override
  ConsumerState<WriteReviewSheet> createState() => _WriteReviewSheetState();
}

class _WriteReviewSheetState extends ConsumerState<WriteReviewSheet> {
  final _comment = TextEditingController();
  int _rating = 0;
  bool _submitting = false;
  String? _error;
  bool _notEligible = false;

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final s = context.s;
    if (_rating == 0) {
      setState(() => _error = s.pickRating);
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await ref
          .read(reviewsProvider(widget.productId).notifier)
          .submit(rating: _rating, comment: _comment.text);
      if (mounted) Navigator.pop(context, true);
    } on AppException catch (e) {
      if (!mounted) return;
      setState(() {
        _notEligible = e.code == kReviewRequiresPurchase;
        _error = _notEligible ? s.reviewRequiresPurchase : (e.fieldError('comment') ?? e.fieldError('rating') ?? s.errorMessage(e));
      });
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final theme = Theme.of(context);
    // Keep the reviews notifier alive while the sheet is open.
    ref.watch(reviewsProvider(widget.productId).select((_) => null));
    return Padding(
      padding: EdgeInsets.fromLTRB(Gap.lg, 0, Gap.lg, MediaQuery.viewInsetsOf(context).bottom + Gap.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(s.writeReview, style: theme.textTheme.titleLarge),
          const SizedBox(height: Gap.lg),
          Text(s.yourRating, style: theme.textTheme.titleSmall),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 1; i <= 5; i++)
                IconButton(
                  tooltip: '$i',
                  iconSize: IconSizes.rating,
                  onPressed: _submitting ? null : () => setState(() => _rating = i),
                  icon: Icon(
                    i <= _rating ? Icons.star_rounded : Icons.star_outline_rounded,
                    color: context.status.star,
                  ),
                ),
            ],
          ),
          const SizedBox(height: Gap.sm),
          TextField(
            controller: _comment,
            enabled: !_submitting,
            maxLines: 4,
            maxLength: 1000,
            decoration: InputDecoration(labelText: s.comment),
          ),
          if (_error != null)
            Container(
              margin: const EdgeInsets.only(bottom: Gap.md),
              padding: const EdgeInsets.all(Gap.md),
              decoration: BoxDecoration(
                color: _notEligible ? theme.colorScheme.secondaryContainer : theme.colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(Radii.sm),
              ),
              child: Row(
                children: [
                  Icon(_notEligible ? Icons.local_shipping_outlined : Icons.error_outline_rounded),
                  const SizedBox(width: Gap.sm),
                  Expanded(child: Text(_error!)),
                ],
              ),
            ),
          FilledButton(
            onPressed: _submitting || _notEligible ? null : _submit,
            child: _submitting
                ? const AppSpinner(size: SpinnerSize.medium)
                : Text(s.submitReview),
          ),
        ],
      ),
    );
  }
}
