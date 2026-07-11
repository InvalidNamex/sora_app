import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/models/banner_model.dart';
import '../../../global_widgets/network_image_with_placeholder.dart';
import '../../../routes/app_pages.dart';

class BannerCarousel extends StatelessWidget {
  const BannerCarousel({super.key, required this.banners});

  final List<BannerModel> banners;

  @override
  Widget build(BuildContext context) {
    if (banners.isEmpty) {
      return Container(
        color: AppConstants.lightBeige,
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.photo_library_outlined,
              color: AppConstants.mediumBeige,
              size: 34,
            ),
            const SizedBox(height: 8),
            Text(
              'no_banners'.tr,
              style: const TextStyle(
                color: AppConstants.mediumBeige,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    return CarouselSlider.builder(
      itemCount: banners.length,
      itemBuilder: (context, index, _) => _BannerTile(banner: banners[index]),
      options: CarouselOptions(
        height: 180,
        viewportFraction: MediaQuery.of(context).size.width > 600 ? 0.6 : 0.9,
        initialPage: 0,
        autoPlay: banners.length > 1,
        autoPlayInterval: const Duration(seconds: 4),
        autoPlayCurve: Curves.easeInOut,
        enlargeCenterPage: true,
      ),
    );
  }
}

class _BannerTile extends StatelessWidget {
  const _BannerTile({required this.banner});

  final BannerModel banner;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical : 5.0),
      child: GestureDetector(
        onTap: () {
          final itemId = banner.bannerItemId;
          if (itemId != null) {
            Get.toNamed(
              Routes.item,
              arguments: {'itemId': itemId, 'heroTag': 'banner_$itemId'},
            );
          }
        },
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox.expand(
              child: NetworkImageWithPlaceholder(
                imageUrl: banner.bannerImage,
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
