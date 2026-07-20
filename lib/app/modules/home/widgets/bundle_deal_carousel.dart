import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/models/bundle_deal_model.dart';
import '../../../global_widgets/network_image_with_placeholder.dart';
import '../../../routes/app_pages.dart';

class BundleDealCarousel extends StatelessWidget {
  const BundleDealCarousel({super.key, required this.bundles});

  final List<BundleDealModel> bundles;

  @override
  Widget build(BuildContext context) {
    if (bundles.isEmpty) return const SizedBox.shrink();
    return CarouselSlider.builder(
      itemCount: bundles.length,
      itemBuilder: (context, index, _) => _BundleBanner(bundle: bundles[index]),
      options: CarouselOptions(
        height: 150,
        viewportFraction: MediaQuery.sizeOf(context).width > 700 ? 0.62 : 0.92,
        autoPlay: bundles.length > 1,
        autoPlayInterval: const Duration(seconds: 5),
        autoPlayCurve: Curves.easeInOutCubic,
        enlargeCenterPage: true,
      ),
    );
  }
}

class _BundleBanner extends StatelessWidget {
  const _BundleBanner({required this.bundle});
  final BundleDealModel bundle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Material(
        clipBehavior: Clip.antiAlias,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: () =>
              Get.toNamed(Routes.bundlePath(bundle.id), arguments: bundle),
          child: Stack(
            fit: StackFit.expand,
            children: [
              NetworkImageWithPlaceholder(
                imageUrl: bundle.bannerImage,
                fit: BoxFit.cover,
              ),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Color(0xB3000000)],
                  ),
                ),
              ),
              PositionedDirectional(
                start: 16,
                end: 16,
                bottom: 12,
                child: Text(
                  bundle.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    shadows: [Shadow(blurRadius: 5, color: Colors.black54)],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
