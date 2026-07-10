import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Tracks which tab is active in the main navigation shell.
class NavController extends GetxController {
  static NavController get to => Get.find();

  final currentIndex = 0.obs;
  final scaffoldKey = GlobalKey<ScaffoldState>();

  void setIndex(int index) => currentIndex.value = index;
}
