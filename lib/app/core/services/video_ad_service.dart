import '../models/video_ad_model.dart';
import 'supabase_service.dart';

class VideoAdService {
  VideoAdService._();

  static const _selectColumns = 'id, videoURL, bannerURL, isVertical, itemID';

  static Future<List<VideoAdModel>> fetchAds() async {
    final response = await SupabaseService.client
        .from('video_ads')
        .select(_selectColumns)
        .order('id', ascending: false);

    return (response as List)
        .whereType<Map>()
        .map((row) => VideoAdModel.fromJson(Map<String, dynamic>.from(row)))
        .where((ad) => (ad.hasVideo || ad.hasBanner) && ad.itemId > 0)
        .toList(growable: false);
  }

  static Future<VideoAdModel> saveAd({
    int? id,
    required String videoUrl,
    required String bannerUrl,
    required bool isVertical,
    required int itemId,
  }) async {
    final payload = {
      'videoURL': videoUrl.trim(),
      'bannerURL': bannerUrl.trim().isEmpty ? null : bannerUrl.trim(),
      'isVertical': isVertical,
      'itemID': itemId,
    };

    final response = id == null
        ? await SupabaseService.client
              .from('video_ads')
              .insert(payload)
              .select(_selectColumns)
              .single()
        : await SupabaseService.client
              .from('video_ads')
              .update(payload)
              .eq('id', id)
              .select(_selectColumns)
              .single();

    return VideoAdModel.fromJson(Map<String, dynamic>.from(response));
  }

  static Future<void> deleteAd(int id) async {
    await SupabaseService.client.from('video_ads').delete().eq('id', id);
  }
}
