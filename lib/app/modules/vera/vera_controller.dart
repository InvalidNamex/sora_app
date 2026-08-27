import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/models/vera_response_model.dart';
import '../../core/services/vera_service.dart';
import '../../core/utils/app_snackbar.dart';
import '../../routes/app_pages.dart';
import '../auth/auth_controller.dart';
import '../cart/cart_controller.dart';

class VeraChatMessage {
  const VeraChatMessage({
    required this.text,
    required this.isUser,
    this.recommendations = const [],
  });

  final String text;
  final bool isUser;
  final List<VeraRecommendationModel> recommendations;
}

class VeraController extends GetxController {
  static VeraController get to => Get.find();

  final messages = <VeraChatMessage>[].obs;
  final isSending = false.obs;
  final addingItemId = Rxn<int>();
  final inputController = TextEditingController();
  final scrollController = ScrollController();

  VeraSessionContext _context = const VeraSessionContext();

  @override
  void onInit() {
    super.onInit();
    ever(AuthController.to.currentUser, (user) {
      if (user == null) clearConversation(addWelcome: false);
    });
  }

  @override
  void onClose() {
    inputController.dispose();
    scrollController.dispose();
    super.onClose();
  }

  void ensureWelcome() {
    if (messages.isNotEmpty) return;
    messages.add(VeraChatMessage(text: 'vera_welcome'.tr, isUser: false));
  }

  void clearConversation({bool addWelcome = true}) {
    messages.clear();
    inputController.clear();
    _context = const VeraSessionContext();
    if (addWelcome && AuthController.to.isLoggedIn) ensureWelcome();
  }

  Future<void> sendCurrentMessage() async {
    final text = inputController.text.trim();
    if (text.length < 2 || isSending.value) return;
    if (text.length > 500) {
      AppSnackbar.show(
        'vera_name'.tr,
        'vera_message_too_long'.tr,
        type: AppSnackbarType.warning,
      );
      return;
    }
    if (!AuthController.to.isLoggedIn) {
      await Get.toNamed(Routes.auth);
      return;
    }

    inputController.clear();
    messages.add(VeraChatMessage(text: text, isUser: true));
    _scrollToBottom();
    isSending.value = true;
    try {
      final response = await VeraService.send(
        message: text,
        locale: Get.locale?.languageCode ?? 'ar',
        context: _context,
      );
      _context = response.context;
      messages.add(
        VeraChatMessage(
          text: response.assistantText.isEmpty
              ? 'vera_service_error'.tr
              : response.assistantText,
          isUser: false,
          recommendations: response.recommendations,
        ),
      );
    } on VeraException catch (error) {
      messages.add(
        VeraChatMessage(
          text: error.message.isEmpty ? 'vera_service_error'.tr : error.message,
          isUser: false,
        ),
      );
    } catch (error) {
      debugPrint('[VeraController] send failed: $error');
      messages.add(
        VeraChatMessage(text: 'vera_service_error'.tr, isUser: false),
      );
    } finally {
      isSending.value = false;
      _scrollToBottom();
    }
  }

  Future<void> addToCart(VeraRecommendationModel recommendation) async {
    final property = recommendation.property;
    if (property == null || !recommendation.inStock || !property.inStock) {
      return;
    }
    if (addingItemId.value != null) return;
    addingItemId.value = recommendation.itemId;
    try {
      await CartController.to.addItem(property, recommendation.name, 1);
      AppSnackbar.show(
        'added_to_cart'.tr,
        recommendation.name,
        type: AppSnackbarType.success,
      );
    } catch (error) {
      debugPrint('[VeraController] add to cart failed: $error');
      AppSnackbar.show(
        'error'.tr,
        error.toString(),
        type: AppSnackbarType.error,
      );
    } finally {
      addingItemId.value = null;
    }
  }

  Future<void> openProduct(int itemId) async {
    await Get.toNamed(Routes.itemPath(itemId));
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!scrollController.hasClients) return;
      unawaited(
        scrollController.animateTo(
          scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOut,
        ),
      );
    });
  }
}
