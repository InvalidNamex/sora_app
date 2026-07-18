import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage_wasm/get_storage_wasm.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../routes/app_pages.dart';
import '../models/in_app_message_model.dart';
import '../widgets/in_app_message_presenter.dart';
import 'link_navigation_service.dart';
import 'supabase_service.dart';

class InAppMessagingService extends GetxService with WidgetsBindingObserver {
  static InAppMessagingService get to => Get.find();

  static const _seenStorageKey = 'seen_in_app_message_ids';

  final _storage = GetStorage();
  final _queuedIds = <int>{};
  final _sessionShownIds = <int>{};
  final _queue = <InAppMessageModel>[];

  RealtimeChannel? _channel;
  Timer? _refreshTimer;
  bool _isPresenting = false;
  bool _isForeground = true;

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
    _subscribe();
    _scheduleRefresh(const Duration(seconds: 2));
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    _refreshTimer?.cancel();
    final channel = _channel;
    if (channel != null) {
      SupabaseService.client.removeChannel(channel);
    }
    super.onClose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _isForeground = state == AppLifecycleState.resumed;
    if (_isForeground) {
      _scheduleRefresh(const Duration(milliseconds: 500));
      unawaited(_presentNext());
    }
  }

  Future<void> refreshNow() => _refresh();

  void _subscribe() {
    final channel = SupabaseService.client.channel('sora-in-app-messages');
    channel
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'in_app_messages',
          callback: (payload) {
            final record = payload.newRecord;
            if (record.isEmpty) return;
            try {
              _enqueue(InAppMessageModel.fromJson(record));
            } catch (e) {
              debugPrint(
                '[InAppMessagingService] invalid realtime message: $e',
              );
            }
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'in_app_messages',
          callback: (_) => _scheduleRefresh(const Duration(milliseconds: 250)),
        )
        .subscribe();
    _channel = channel;
  }

  void _scheduleRefresh(Duration delay) {
    _refreshTimer?.cancel();
    _refreshTimer = Timer(delay, () => unawaited(_refresh()));
  }

  Future<void> _refresh() async {
    if (!_isForeground) return;

    try {
      final now = DateTime.now().toUtc();
      final rows = await SupabaseService.client
          .from('in_app_messages')
          .select()
          .eq('is_active', true)
          .lte('starts_at', now.toIso8601String())
          .order('priority', ascending: false)
          .order('created_at', ascending: false)
          .limit(25);

      for (final row in rows) {
        final message = InAppMessageModel.fromJson(row);
        _enqueue(message, now: now);
      }
    } catch (e) {
      debugPrint('[InAppMessagingService] refresh skipped: $e');
    } finally {
      if (_isForeground) {
        _scheduleRefresh(const Duration(seconds: 45));
      }
    }
  }

  void _enqueue(InAppMessageModel message, {DateTime? now}) {
    final currentTime = now ?? DateTime.now().toUtc();
    if (!_isEligible(message, currentTime)) return;
    if (_queuedIds.contains(message.id)) return;
    if (_sessionShownIds.contains(message.id)) return;
    if (message.displayOnce && _seenIds.contains(message.id)) return;

    _queuedIds.add(message.id);
    _queue.add(message);
    unawaited(_presentNext());
  }

  bool _isEligible(InAppMessageModel message, DateTime now) {
    if (!message.isActive || message.startsAt.isAfter(now)) return false;
    if (message.endsAt != null && !message.endsAt!.isAfter(now)) return false;

    final platform = _currentPlatform;
    if (message.targetPlatform != 'all' && message.targetPlatform != platform) {
      return false;
    }

    final language = Get.locale?.languageCode ?? 'en';
    return message.targetLanguage == 'all' ||
        message.targetLanguage == language;
  }

  String get _currentPlatform {
    if (kIsWeb) return 'web';
    return switch (defaultTargetPlatform) {
      TargetPlatform.android => 'android',
      TargetPlatform.iOS => 'ios',
      _ => 'other',
    };
  }

  Set<int> get _seenIds {
    final stored = _storage.read<List<dynamic>>(_seenStorageKey) ?? const [];
    return stored.whereType<num>().map((id) => id.toInt()).toSet();
  }

  Future<void> _presentNext() async {
    if (_isPresenting || !_isForeground || _queue.isEmpty) return;

    if ((Get.overlayContext ?? Get.context) == null ||
        Get.currentRoute.isEmpty ||
        Get.currentRoute == Routes.splash) {
      _scheduleRefresh(const Duration(seconds: 1));
      return;
    }

    _isPresenting = true;
    final message = _queue.removeAt(0);
    _queuedIds.remove(message.id);
    _sessionShownIds.add(message.id);

    try {
      final context = Get.overlayContext ?? Get.context;
      if (context == null) return;
      await InAppMessagePresenter.show(
        context: context,
        message: message,
        onAction: LinkNavigationService.open,
      );
      if (message.displayOnce) {
        final ids = _seenIds..add(message.id);
        await _storage.write(_seenStorageKey, ids.toList(growable: false));
      }
    } catch (e) {
      debugPrint('[InAppMessagingService] display failed: $e');
    } finally {
      _isPresenting = false;
      if (_queue.isNotEmpty && _isForeground) {
        await Future<void>.delayed(const Duration(milliseconds: 350));
        unawaited(_presentNext());
      }
    }
  }
}
