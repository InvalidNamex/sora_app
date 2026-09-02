class VideoAdModel {
  const VideoAdModel({
    required this.id,
    required this.videoUrl,
    required this.bannerUrl,
    required this.isVertical,
    required this.itemId,
  });

  final int id;
  final String videoUrl;
  final String bannerUrl;
  final bool isVertical;
  final int itemId;

  factory VideoAdModel.fromJson(Map<String, dynamic> json) => VideoAdModel(
    id: (json['id'] as num?)?.toInt() ?? 0,
    videoUrl: (json['videoURL'] as String?)?.trim() ?? '',
    bannerUrl: (json['bannerURL'] as String?)?.trim() ?? '',
    isVertical: (json['isVertical'] as bool?) ?? false,
    itemId: (json['itemID'] as num?)?.toInt() ?? 0,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'videoURL': videoUrl,
    'bannerURL': bannerUrl,
    'isVertical': isVertical,
    'itemID': itemId,
  };

  bool get hasVideo => videoUrl.isNotEmpty;
  bool get hasBanner => bannerUrl.isNotEmpty;
}
