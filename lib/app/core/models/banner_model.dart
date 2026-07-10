class BannerModel {
  final int id;
  final String bannerImage;
  final int? bannerItemId;

  const BannerModel({
    required this.id,
    required this.bannerImage,
    this.bannerItemId,
  });

  factory BannerModel.fromJson(Map<String, dynamic> json) => BannerModel(
    id: (json['id'] as num?)?.toInt() ?? 0,
    bannerImage: (json['bannerImage'] as String?) ??
      (json['image'] as String?) ??
      '',
    bannerItemId: (json['bannerItem'] as num?)?.toInt() ??
      (json['bannerItemID'] as num?)?.toInt() ??
      (json['itemID'] as num?)?.toInt(),
      );
}
