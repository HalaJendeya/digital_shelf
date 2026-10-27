import 'package:flutter/material.dart';

import '../../../design_system/design_system.dart';
import '../../../shared/models/category.dart';
import '../../../shared/widgets/app_network_image.dart';

/// Shows the category image when provided, otherwise maps the API's icon name
/// (Lucide-style keys such as `book-open`, `heart`) to a Material icon.
class CategoryIcon extends StatelessWidget {
  const CategoryIcon({super.key, required this.category, this.color, this.size = IconSizes.xl});

  final Category category;
  final Color? color;
  final double size;

  static const _icons = <String, IconData>{
    'book-open': Icons.menu_book_rounded,
    'book': Icons.book_rounded,
    'heart': Icons.favorite_rounded,
    'sparkles': Icons.auto_awesome_rounded,
    'flame': Icons.local_fire_department_rounded,
    'star': Icons.star_rounded,
    'shirt': Icons.checkroom_rounded,
    'gift': Icons.card_giftcard_rounded,
  };

  @override
  Widget build(BuildContext context) {
    if (category.image != null) {
      return ClipOval(child: SizedBox.square(dimension: size * 2, child: AppNetworkImage(url: category.image)));
    }
    return Icon(_icons[category.icon] ?? Icons.category_rounded, color: color, size: size);
  }
}
