import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/models/category_model.dart';
import '../../../core/models/sub_category_model.dart';

/// Horizontal scrolling category chips.
/// If [subCategories] is non-empty it renders a second row of sub-category chips.
class CategoryStrip extends StatelessWidget {
  const CategoryStrip({
    super.key,
    required this.categories,
    required this.subCategories,
    required this.selectedCategoryId,
    required this.selectedSubCategoryId,
    required this.onCategoryTap,
    required this.onSubCategoryTap,
  });

  final List<CategoryModel> categories;
  final List<SubCategoryModel> subCategories;
  final int? selectedCategoryId;
  final int? selectedSubCategoryId;
  final ValueChanged<int?> onCategoryTap;
  final ValueChanged<int?> onSubCategoryTap;

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Category row ──────────────────────────────────────────────
        SizedBox(
          height: 96,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              _CategoryTile(
                label: 'all'.tr,
                imageUrl: null,
                selected: selectedCategoryId == null,
                onTap: () => onCategoryTap(null),
              ),
              ...categories.map(
                (c) => _CategoryTile(
                  label: c.categoryName,
                  imageUrl: c.categoryImage,
                  selected: selectedCategoryId == c.id,
                  onTap: () => onCategoryTap(c.id),
                ),
              ),
            ],
          ),
        ),

        if (categories.isEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 2),
            child: Row(
              children: [
                const Icon(Icons.info_outline,
                    size: 14, color: AppConstants.mediumBeige),
                const SizedBox(width: 6),
                Text(
                  'no_categories'.tr,
                  style: const TextStyle(
                    color: AppConstants.mediumBeige,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

        // ── Sub-category row (only when a category is selected) ───────
        if (subCategories.isNotEmpty) ...[
          const SizedBox(height: 8),
          SizedBox(
            height: 38,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _Chip(
                  label: 'all'.tr,
                  selected: selectedSubCategoryId == null,
                  small: true,
                  onTap: () => onSubCategoryTap(null),
                ),
                ...subCategories.map(
                  (s) => _Chip(
                    label: s.subCategoryName,
                    selected: selectedSubCategoryId == s.id,
                    small: true,
                    onTap: () => onSubCategoryTap(s.id),
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 8),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.small = false,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool small;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(
          label,
          style: TextStyle(
            fontSize: small ? 12 : 13,
            fontWeight:
                selected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        selected: selected,
        onSelected: (_) => onTap(),
        selectedColor: AppConstants.darkBeige,
        labelStyle: TextStyle(
          color: selected
              ? Colors.white
              : Theme.of(context).colorScheme.onSurface,
        ),
        showCheckmark: false,
        backgroundColor:
            Theme.of(context).colorScheme.surface,
        side: BorderSide(
          color: selected
              ? AppConstants.darkBeige
              : AppConstants.mediumBeige.withValues(alpha: 0.4),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({
    required this.label,
    required this.imageUrl,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String? imageUrl;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: 82,
          padding: const EdgeInsets.fromLTRB(6, 6, 6, 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected
                  ? AppConstants.darkBeige
                  : AppConstants.mediumBeige.withValues(alpha: 0.45),
              width: selected ? 2 : 1,
            ),
            color: Theme.of(context).colorScheme.surface,
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: AppConstants.darkBeige.withValues(alpha: 0.18),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Column(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 56,
                  height: 56,
                  child: (imageUrl != null && imageUrl!.isNotEmpty)
                      ? Image.network(
                          imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Image.asset(
                            AppConstants.placeholderPath,
                            fit: BoxFit.cover,
                          ),
                        )
                      : Image.asset(
                          AppConstants.placeholderPath,
                          fit: BoxFit.cover,
                        ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                  color: selected
                      ? AppConstants.darkBeige
                      : Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
