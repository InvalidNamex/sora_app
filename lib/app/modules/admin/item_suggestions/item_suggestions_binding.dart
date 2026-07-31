import 'package:get/get.dart';

import 'item_suggestions_controller.dart';

class ItemSuggestionsBinding extends Binding {
  @override
  List<Bind> dependencies() => [
    Bind.lazyPut<ItemSuggestionsController>(() => ItemSuggestionsController()),
  ];
}
