import 'package:get/get.dart';

import 'feedback_controller.dart';

class FeedbackBinding extends Binding {
  @override
  List<Bind> dependencies() => [
    Bind.lazyPut<FeedbackController>(() => FeedbackController()),
  ];
}
