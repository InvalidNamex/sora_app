import 'package:get/get.dart';
import 'returns_controller.dart';

class ReturnsBinding extends Binding {
  @override
  List<Bind> dependencies() => [
    Bind.lazyPut<ReturnsController>(() => ReturnsController()),
  ];
}
