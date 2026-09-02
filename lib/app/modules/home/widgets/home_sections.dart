import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/models/home_section_model.dart';
import '../home_controller.dart';
import 'item_card.dart';

/// Dynamic, admin-configured product rows for the home page.
class HomeSections extends GetView<HomeController> {
  const HomeSections({super.key, required this.onBrowseAll});

  final VoidCallback onBrowseAll;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isLoadingHomeSections.value) {
        return const _SectionSkeleton();
      }

      final sections = controller.homeSections;

      return Column(
        children: [
          for (final section in sections) _HomeSectionRow(section: section),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onBrowseAll,
                icon: const Icon(Icons.grid_view_rounded),
                label: Text('browse_all_perfumes'.tr),
              ),
            ),
          ),
        ],
      );
    });
  }
}

class _HomeSectionRow extends GetView<HomeController> {
  const _HomeSectionRow({required this.section});

  final HomeSectionModel section;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final items = controller.itemsForSection(section);
      if (items.isEmpty) return const SizedBox.shrink();

      return Padding(
        padding: const EdgeInsets.only(top: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                section.title,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 324,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: items.length,
                separatorBuilder: (_, _) => const SizedBox(width: 12),
                itemBuilder: (_, index) => SizedBox(
                  width: 166,
                  child: ItemCard(
                    entry: items[index],
                    heroTag:
                        'section_${section.id}_item_${index}_${items[index].item.id}',
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }
}

class _SectionSkeleton extends StatelessWidget {
  const _SectionSkeleton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 150,
            height: 22,
            decoration: BoxDecoration(
              color: AppConstants.lightBeige,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 324,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: 3,
              separatorBuilder: (_, _) => const SizedBox(width: 12),
              itemBuilder: (_, _) => Container(
                width: 166,
                decoration: BoxDecoration(
                  color: AppConstants.lightBeige,
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
