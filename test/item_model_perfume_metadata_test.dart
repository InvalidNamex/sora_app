import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:sora/app/core/models/item_model.dart';

void main() {
  tearDown(Get.reset);

  test('parses and cleans perfume notes and accords arrays', () {
    Get.locale = const Locale('ar');

    final item = ItemModel.fromJson({
      'id': 1,
      'categoryID': 2,
      'subCategoryID': 3,
      'itemName': 'عطر',
      'brandName': 'Sora',
      'itemDescription': '',
      'notes': [' برغموت ', '', null, 'فانيليا'],
      'notesEN': ['Bergamot', 'Vanilla'],
      'topNotes': [' برغموت '],
      'topNotesEN': ['Bergamot'],
      'middleNotes': ['ورد'],
      'middleNotesEN': ['Rose'],
      'baseNotes': ['فانيليا'],
      'baseNotesEN': ['Vanilla'],
      'accords': [' حمضي ', 'حلو'],
      'accordsEN': ['Citrus', 'Sweet'],
      'accordPercentages': [100, '75'],
    });

    expect(item.notes, ['برغموت', 'فانيليا']);
    expect(item.topNotes, ['برغموت']);
    expect(item.middleNotes, ['ورد']);
    expect(item.baseNotes, ['فانيليا']);
    expect(item.hasGroupedNotes, isTrue);
    expect(item.brandName, 'Sora');
    expect(item.accords, ['حمضي', 'حلو']);
    expect(item.accordPercentages, [100, 75]);
    expect(
      item.accordProfile
          .map((accord) => '${accord.name}:${accord.percentage}')
          .toList(),
      ['حمضي:100', 'حلو:75'],
    );
    expect(item.notesEn, ['Bergamot', 'Vanilla']);
    expect(item.accordsEn, ['Citrus', 'Sweet']);
  });

  test('uses English metadata and falls back to Arabic when unavailable', () {
    Get.locale = const Locale('en');

    final localized = ItemModel.fromJson({
      'itemName': 'عطر',
      'notes': ['فانيليا'],
      'notesEN': ['Vanilla'],
      'accords': ['حلو'],
      'accordPercentages': [90],
    });

    expect(localized.notes, ['Vanilla']);
    expect(localized.accords, ['حلو']);
    expect(localized.accordProfile.single.name, 'حلو');
    expect(localized.accordProfile.single.percentage, 90);
  });

  test('localizes grouped notes and accord profile in English', () {
    Get.locale = const Locale('en');

    final item = ItemModel.fromJson({
      'topNotes': ['برغموت'],
      'topNotesEN': ['Bergamot'],
      'middleNotes': ['ورد'],
      'middleNotesEN': ['Rose'],
      'baseNotes': ['فانيليا'],
      'baseNotesEN': ['Vanilla'],
      'accords': ['حمضي'],
      'accordsEN': ['Citrus'],
      'accordPercentages': [100],
    });

    expect(item.topNotes, ['Bergamot']);
    expect(item.middleNotes, ['Rose']);
    expect(item.baseNotes, ['Vanilla']);
    expect(item.accordProfile.single.name, 'Citrus');
  });
}
