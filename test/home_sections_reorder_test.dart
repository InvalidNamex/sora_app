import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:sora/app/core/models/home_section_model.dart';
import 'package:sora/app/modules/admin/home_sections_management/home_sections_management_controller.dart';
import 'package:sora/app/modules/home/home_controller.dart';

void main() {
  HomeSectionModel section(int id) => HomeSectionModel(
    id: id,
    titleAr: 'Section $id',
    titleEn: 'Section $id',
    type: 'manual',
    itemLimit: 10,
    displayOrder: id - 1,
    isActive: true,
  );

  test('dragging changes the dedicated order sent to the database', () {
    final controller = HomeSectionsManagementController();
    controller.sections.assignAll([section(1), section(2), section(3)]);
    controller.sectionOrder.assignAll([1, 2, 3]);

    controller.reorderSections(0, 3);

    expect(controller.sectionOrder, [2, 3, 1]);
    expect(controller.sectionAt(0).id, 2);
    expect(controller.hasUnsavedOrder.value, isTrue);
  });

  test('returning to the persisted order clears the unsaved state', () {
    final controller = HomeSectionsManagementController();
    controller.sections.assignAll([section(1), section(2), section(3)]);
    controller.sectionOrder.assignAll([1, 2, 3]);

    controller.reorderSections(0, 3);
    controller.reorderSections(2, 0);

    expect(controller.sectionOrder, [1, 2, 3]);
    expect(controller.hasUnsavedOrder.value, isFalse);
  });

  test('saved order is applied immediately to active home sections', () {
    final homeController = HomeController();
    homeController.homeSections.value = [
      section(1),
      section(2),
      section(3),
    ].toList(growable: false);

    homeController.applyHomeSectionOrder([3, 1, 2]);

    expect(homeController.homeSections.map((section) => section.id), [3, 1, 2]);
  });
}
