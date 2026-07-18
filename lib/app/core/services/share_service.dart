import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../constants/app_constants.dart';

class ShareService {
  ShareService._();

  static Uri itemLink(int itemId, {String? affiliateCode}) {
    final code = affiliateCode?.trim().toUpperCase() ?? '';
    return Uri.parse(AppConstants.baseDomain).replace(
      path: '/item/$itemId',
      queryParameters: code.isEmpty ? null : {'ref': code},
    );
  }

  static Future<ShareResult> shareItem({
    required BuildContext context,
    required int itemId,
    required String itemName,
    required String message,
    String? affiliateCode,
  }) {
    final link = itemLink(itemId, affiliateCode: affiliateCode);
    final renderBox = context.findRenderObject() as RenderBox?;
    final shareOrigin = renderBox != null && renderBox.hasSize
        ? renderBox.localToGlobal(Offset.zero) & renderBox.size
        : null;

    return SharePlus.instance.share(
      ShareParams(
        title: itemName,
        subject: itemName,
        text: '$message\n$link',
        sharePositionOrigin: shareOrigin,
      ),
    );
  }

  static Future<ShareResult> shareAffiliate({
    required BuildContext context,
    required String code,
    required String link,
    required String message,
  }) {
    final renderBox = context.findRenderObject() as RenderBox?;
    final shareOrigin = renderBox != null && renderBox.hasSize
        ? renderBox.localToGlobal(Offset.zero) & renderBox.size
        : null;

    return SharePlus.instance.share(
      ShareParams(
        title: code,
        subject: code,
        text: '$message\n$code\n$link',
        sharePositionOrigin: shareOrigin,
      ),
    );
  }
}
