import 'package:flutter/material.dart';

enum InAppMessageType {
  card,
  modal,
  image,
  banner;

  String get databaseValue => switch (this) {
    InAppMessageType.card => 'card',
    InAppMessageType.modal => 'modal',
    InAppMessageType.image => 'image',
    InAppMessageType.banner => 'banner',
  };

  String get label => switch (this) {
    InAppMessageType.card => 'Card',
    InAppMessageType.modal => 'Modal',
    InAppMessageType.image => 'Image',
    InAppMessageType.banner => 'Top banner',
  };

  IconData get icon => switch (this) {
    InAppMessageType.card => Icons.view_agenda_outlined,
    InAppMessageType.modal => Icons.web_asset_outlined,
    InAppMessageType.image => Icons.image_outlined,
    InAppMessageType.banner => Icons.vertical_align_top,
  };

  static InAppMessageType fromDatabase(String? value) {
    return InAppMessageType.values.firstWhere(
      (type) => type.databaseValue == value,
      orElse: () => InAppMessageType.card,
    );
  }
}

class InAppMessageModel {
  const InAppMessageModel({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.imageUrl,
    required this.backgroundColor,
    required this.textColor,
    required this.buttonColor,
    required this.buttonTextColor,
    required this.primaryButtonText,
    required this.primaryActionUrl,
    required this.secondaryButtonText,
    required this.secondaryActionUrl,
    required this.targetPlatform,
    required this.targetLanguage,
    required this.displayOnce,
    required this.isActive,
    required this.startsAt,
    required this.endsAt,
  });

  final int id;
  final InAppMessageType type;
  final String title;
  final String body;
  final String imageUrl;
  final Color backgroundColor;
  final Color textColor;
  final Color buttonColor;
  final Color buttonTextColor;
  final String primaryButtonText;
  final String primaryActionUrl;
  final String secondaryButtonText;
  final String secondaryActionUrl;
  final String targetPlatform;
  final String targetLanguage;
  final bool displayOnce;
  final bool isActive;
  final DateTime startsAt;
  final DateTime? endsAt;

  bool get hasPrimaryAction =>
      primaryActionUrl.isNotEmpty || primaryButtonText.isNotEmpty;

  bool get hasSecondaryAction =>
      secondaryActionUrl.isNotEmpty || secondaryButtonText.isNotEmpty;

  factory InAppMessageModel.fromJson(Map<String, dynamic> json) {
    return InAppMessageModel(
      id: (json['id'] as num).toInt(),
      type: InAppMessageType.fromDatabase(json['type'] as String?),
      title: (json['title'] as String?) ?? '',
      body: (json['body'] as String?) ?? '',
      imageUrl: (json['image_url'] as String?) ?? '',
      backgroundColor: colorFromHex(
        json['background_color'] as String?,
        fallback: Colors.white,
      ),
      textColor: colorFromHex(
        json['text_color'] as String?,
        fallback: const Color(0xFF171717),
      ),
      buttonColor: colorFromHex(
        json['button_color'] as String?,
        fallback: const Color(0xFFB09263),
      ),
      buttonTextColor: colorFromHex(
        json['button_text_color'] as String?,
        fallback: Colors.white,
      ),
      primaryButtonText: (json['primary_button_text'] as String?) ?? '',
      primaryActionUrl: (json['primary_action_url'] as String?) ?? '',
      secondaryButtonText: (json['secondary_button_text'] as String?) ?? '',
      secondaryActionUrl: (json['secondary_action_url'] as String?) ?? '',
      targetPlatform: (json['target_platform'] as String?) ?? 'all',
      targetLanguage: (json['target_language'] as String?) ?? 'all',
      displayOnce: (json['display_once'] as bool?) ?? true,
      isActive: (json['is_active'] as bool?) ?? true,
      startsAt:
          DateTime.tryParse((json['starts_at'] as String?) ?? '')?.toUtc() ??
          DateTime.now().toUtc(),
      endsAt: DateTime.tryParse((json['ends_at'] as String?) ?? '')?.toUtc(),
    );
  }
}

Color colorFromHex(String? value, {required Color fallback}) {
  final normalized = value?.trim().replaceFirst('#', '');
  if (normalized == null ||
      (normalized.length != 6 && normalized.length != 8)) {
    return fallback;
  }

  final parsed = int.tryParse(normalized, radix: 16);
  if (parsed == null) return fallback;
  return Color(normalized.length == 6 ? 0xFF000000 | parsed : parsed);
}

bool isValidHexColor(String value) {
  return RegExp(r'^#[0-9a-fA-F]{6}$').hasMatch(value.trim());
}
